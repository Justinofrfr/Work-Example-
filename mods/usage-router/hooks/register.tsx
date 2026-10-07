import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import { CONFIG } from './config'
import { Pipeline, bindPipeline } from './pipeline'
import { Router, bindRouter } from './router'
import { USAGE_STORE_KEY, UsageTracker, bindUsage } from './usage'
import { bindPanel } from './view'

const routeAtom = atom({ plugin: 'usage-router', key: 'route' } as const, null)
const tickAtom = atom({ plugin: 'usage-router', key: 'tick' } as const, 0)

const COMMANDS = [
  { name: CONFIG.Pane.Command, description: 'Open the Usage Router panel', immediate: true as const },
  {
    name: CONFIG.Pane.RouteCommand,
    description: 'Model router: on, off, or status',
    argumentHint: '[on|off|status]',
    immediate: true as const,
  },
  {
    name: CONFIG.Pipeline.Command,
    description: 'Writer -> reviewer -> tester agent pipeline for a Roblox task',
    argumentHint: '<task> | stop',
  },
]

export const register: Register = on => {
  const tracker = new UsageTracker()
  const router = new Router()
  const pipeline = new Pipeline()

  bindUsage(on, tracker)
  bindRouter(on, router)
  bindPipeline(on, pipeline, router)
  bindPanel(on)

  on('session.start', async ($, e, next) => {
    const ran = await next(e)
    for (const command of COMMANDS) await $.command.register(command)
    for (const def of Pipeline.agentDefs()) await $.agent.register(def)
    tracker.hydrate(await $.store.get(USAGE_STORE_KEY))
    router.last = await read($, routeAtom)
    $.clock.every(CONFIG.Usage.TickMs, () => {
      void update($, tickAtom, n => n + 1)
    })
    if (CONFIG.Usage.PaneOpenOnStart) void $.ui.open({ id: CONFIG.Pane.Id, title: CONFIG.Pane.Title })
    return ran
  })

  on('turn.complete', ($, e, next) => {
    router.endTurn(e.turnId, e.agentId)
    if (e.agentId !== undefined) pipeline.settle(e.agentId, e.answer)
    return next(e)
  })
}
