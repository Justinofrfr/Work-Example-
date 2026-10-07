import { atom, read, update } from 'claude-code'
import type { On } from 'claude-code'

import type { PipelineView, StageStatus, UsageView, WindowView } from '../types'
import { CONFIG } from './config'
import { Router } from './router'

const pipelineAtom = atom({ plugin: 'usage-router', key: 'pipeline' } as const, null)
const routeAtom = atom({ plugin: 'usage-router', key: 'route' } as const, null)
const routerEnabledAtom = atom(
  { plugin: 'usage-router', key: 'routerEnabled' } as const,
  CONFIG.Router.EnabledByDefault,
)
const tickAtom = atom({ plugin: 'usage-router', key: 'tick' } as const, 0)
const usageAtom = atom({ plugin: 'usage-router', key: 'usage' } as const, null)

export type Row = { key: string; text: string; color?: string; isDim?: boolean }

const U = CONFIG.Usage

const STAGE_COLOR: Record<StageStatus, string> = {
  waiting: 'inactive',
  running: 'warning',
  done: 'success',
  failed: 'error',
}

export class Panel {
  static pct(n: number): string {
    return `${Math.round(n * 10) / 10}%`
  }

  static duration(ms: number): string {
    const total = Math.max(0, Math.round(ms / 60000))
    const h = Math.floor(total / 60)
    const m = total % 60
    if (h >= 24) return `${Math.floor(h / 24)}d ${h % 24}h`
    return h > 0 ? `${h}h ${String(m).padStart(2, '0')}m` : `${m}m`
  }

  static clockTime(ms: number): string {
    const d = new Date(ms)
    return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
  }

  static color(used: number): string {
    if (used >= U.DangerAtPercent) return 'error'
    if (used >= U.WarnAtPercent) return 'warning'
    return 'success'
  }

  static bar(used: number): string {
    const filled = Math.min(U.BarWidth, Math.max(0, Math.round((used / 100) * U.BarWidth)))
    return `${'█'.repeat(filled)}${'░'.repeat(U.BarWidth - filled)}`
  }

  static runsOutFirst(w: WindowView): boolean {
    return w.emptyAt !== null && (w.resetsAt === null || w.emptyAt < w.resetsAt)
  }

  static forecast(w: WindowView, now: number): string {
    if (w.ratePerHour === null) return 'measuring pace'
    if (w.emptyAt === null) return 'idle last hour'
    if (!Panel.runsOutFirst(w)) return 'lasts until reset'
    return `empty in ~${Panel.duration(w.emptyAt - now)}`
  }

  static usageRows(usage: UsageView | null, now: number): Row[] {
    if (!usage || usage.windows.length === 0) {
      return [
        {
          key: 'usage-none',
          text: 'No rate-limit data yet. It shows after the first reply on a Pro/Max plan (API keys report none).',
          isDim: true,
        },
      ]
    }

    const rows: Row[] = []
    for (const w of usage.windows) {
      rows.push({
        key: `u-${w.kind}`,
        text: `${w.label.padEnd(5)} ${Panel.bar(w.used)} ${Panel.pct(w.used)} used  ${Panel.pct(w.left)} left`,
        color: Panel.color(w.used),
      })
      const pace =
        w.ratePerHour === null
          ? `pace: measuring (${w.sampleMinutes}m of ${Math.round(U.MinSampleMs / 60000)}m)`
          : `pace: ${w.ratePerHour}%/h over last ${w.sampleMinutes}m`
      const eta =
        w.emptyAt !== null && Panel.runsOutFirst(w)
          ? ` | runs out ~${Panel.clockTime(w.emptyAt)} (in ${Panel.duration(w.emptyAt - now)})`
          : w.ratePerHour !== null
            ? ' | lasts until reset at this pace'
            : ''
      const reset =
        w.resetsAt !== null
          ? ` | resets ${Panel.clockTime(w.resetsAt)} (in ${Panel.duration(w.resetsAt - now)})`
          : ''
      rows.push({ key: `p-${w.kind}`, text: `      ${pace}${eta}${reset}`, isDim: true })
    }
    if (usage.costUsd !== null) {
      rows.push({ key: 'cost', text: `Session cost (as /cost shows): $${usage.costUsd.toFixed(2)}`, isDim: true })
    }
    rows.push({ key: 'updated', text: `Updated ${Panel.duration(now - usage.updatedAt)} ago`, isDim: true })
    return rows
  }

  static pipelineRows(p: PipelineView | null): Row[] {
    if (!p) return [{ key: 'pl-none', text: `Idle. Run /${CONFIG.Pipeline.Command} <task>`, isDim: true }]
    const rows: Row[] = [
      { key: 'pl-task', text: `Task: ${p.task.slice(0, 100)}` },
      {
        key: 'pl-round',
        text: `Round ${p.round}/${CONFIG.Pipeline.MaxRounds} - ${p.verdict}`,
        color: p.verdict === 'passed' ? 'success' : p.verdict === 'running' ? 'warning' : 'error',
      },
      ...p.stages.map(s => ({
        key: `pl-${s.name}`,
        text: `${s.name.padEnd(9)} ${s.status.padEnd(8)} ${s.summary}`,
        color: STAGE_COLOR[s.status],
      })),
    ]
    if (p.reportPath) rows.push({ key: 'pl-report', text: `Report: ${p.reportPath}`, isDim: true })
    return rows
  }
}

export function bindPanel(on: On): void {
  on('command.run', { command: CONFIG.Pane.Command }, async $ => {
    const opened = await $.ui.open({ id: CONFIG.Pane.Id, title: CONFIG.Pane.Title })
    return { text: opened.isPlaced ? 'Usage Router panel opened.' : 'Widen the terminal to show the panel.' }
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (!U.BandEnabled || e.props.hasSurvey) return next(e)
    const usage = await read($, usageAtom)
    const route = await read($, routeAtom)
    const isRouting = await read($, routerEnabledAtom)
    await read($, tickAtom)
    const windows = usage?.windows ?? []
    if (windows.length === 0 && !(isRouting && route)) return next(e)

    const now = await $.clock.now()
    const { Box, Text } = $.ui.resolve(e)
    return (
      <Box flexDirection="row" flexWrap="wrap">
        {windows.map(w => (
          <Text key={`band-${w.kind}`} color={Panel.color(w.used)}>
            {`${w.label} ${Panel.pct(w.used)} `}
            <Text dimColor>{`(${Panel.pct(w.left)} left, ${Panel.forecast(w, now)})  `}</Text>
          </Text>
        ))}
        {isRouting && route ? (
          <Text key="band-route" color="suggestion">{`${route.model}/${route.effort}`}</Text>
        ) : null}
      </Box>
    )
  })

  on('ui.render', { component: 'Pane', requestId: CONFIG.Pane.Id }, async ($, e) => {
    const { Box, Text, Button } = $.ui.resolve(e)
    const usage = await read($, usageAtom)
    const route = await read($, routeAtom)
    const isRouting = await read($, routerEnabledAtom)
    const pipeline = await read($, pipelineAtom)
    await read($, tickAtom)
    const now = await $.clock.now()

    return (
      <Box flexDirection="column">
        <Text bold>Usage</Text>
        {Panel.usageRows(usage, now).map(row => (
          <Text key={row.key} color={row.color} dimColor={row.isDim}>
            {row.text}
          </Text>
        ))}
        <Text bold>Router</Text>
        <Text>{Router.describe(isRouting, route)}</Text>
        <Text dimColor>{`Force a model: ${CONFIG.Router.OverridePrefix}opus:high your prompt`}</Text>
        <Box flexDirection="row">
          <Button
            key="toggle-router"
            label={isRouting ? 'Router off' : 'Router on'}
            onPress={() => update($, routerEnabledAtom, v => !v)}
          />
        </Box>
        <Text bold>Pipeline</Text>
        {Panel.pipelineRows(pipeline).map(row => (
          <Text key={row.key} color={row.color} dimColor={row.isDim}>
            {row.text}
          </Text>
        ))}
        <Box flexDirection="row">
          <Button key="close" label="Close" onPress={() => $.ui.close({ id: CONFIG.Pane.Id })} />
        </Box>
      </Box>
    )
  })
}
