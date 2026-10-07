import { atom, read, update } from 'claude-code'
import type { ModelCompleteRequest, ModelCompleteResult, On } from 'claude-code'

import type { Effort, RouteView } from '../types'
import { CONFIG } from './config'

const routeAtom = atom({ plugin: 'usage-router', key: 'route' } as const, null)
const routerEnabledAtom = atom(
  { plugin: 'usage-router', key: 'routerEnabled' } as const,
  CONFIG.Router.EnabledByDefault,
)

type Choice = { model: string; effort: Effort; reason: string }
type Override = { model: string; effort: Effort | null; text: string }

const R = CONFIG.Router
const USER_ORIGINS: ReadonlySet<string> = new Set(['composer', 'bridge'])

export class Router {
  last: RouteView | null = null
  private pending: RouteView | null = null
  private byTurn = new Map<string, RouteView>()

  static modelId(name: string): string {
    return R.Models[name] ?? name
  }

  static asEffort(value: unknown): Effort | null {
    return typeof value === 'string' && (R.Efforts as readonly string[]).includes(value)
      ? (value as Effort)
      : null
  }

  static parseOverride(text: string): Override | null {
    if (!text.startsWith(R.OverridePrefix)) return null
    const match = /^(\w+)(?::(\w+))?\s+([\s\S]*)$/.exec(text.slice(R.OverridePrefix.length))
    if (!match) return null
    const [, model = '', effort = '', rest = ''] = match
    if (!(model.toLowerCase() in R.Models)) return null
    return { model: model.toLowerCase(), effort: Router.asEffort(effort.toLowerCase()), text: rest }
  }

  static parseChoice(text: string): Choice | null {
    const json = /\{[\s\S]*\}/.exec(text)
    if (!json) return null
    let data: unknown
    try {
      data = JSON.parse(json[0])
    } catch {
      return null
    }
    if (typeof data !== 'object' || data === null) return null
    const o = data as Record<string, unknown>
    const model = typeof o.model === 'string' ? o.model.toLowerCase() : ''
    const effort = Router.asEffort(typeof o.effort === 'string' ? o.effort.toLowerCase() : null)
    if (!(model in R.Models) || !effort) return null
    const reason = typeof o.reason === 'string' ? o.reason.slice(0, 120) : ''
    return { model, effort, reason }
  }

  static isUserOrigin(kind: string | undefined): boolean {
    return kind === undefined || USER_ORIGINS.has(kind)
  }

  preRoute(text: string, at: number): RouteView | null {
    const override = Router.parseOverride(text)
    if (override) {
      return {
        model: override.model,
        effort: override.effort ?? R.Fallback.effort,
        reason: 'manual override',
        source: 'override',
        at,
      }
    }
    if (this.last && text.trim().length <= R.FollowUpMaxChars) {
      return { ...this.last, source: 'sticky', reason: 'short follow-up keeps last route', at }
    }
    return null
  }

  judgeRequest(text: string): ModelCompleteRequest {
    return {
      model: R.JudgeModel,
      effort: R.JudgeEffort,
      system: R.Rubric,
      prompt: text.slice(0, R.MaxPromptChars),
      maxTokens: R.JudgeMaxTokens,
      timeoutMs: R.JudgeTimeoutMs,
    }
  }

  fromJudge(result: ModelCompleteResult, at: number): RouteView {
    const choice = result.isAnswered ? Router.parseChoice(result.text) : null
    if (choice) return { ...choice, source: 'judge', at }
    return {
      ...R.Fallback,
      reason: result.isAnswered ? 'judge reply unreadable' : `judge ${result.reason}`,
      source: 'fallback',
      at,
    }
  }

  decide(route: RouteView): void {
    this.last = route
    this.pending = route
  }

  carryOver(): void {
    this.pending = this.last
  }

  startTurn(turnId: string): void {
    if (!this.pending) return
    this.byTurn.set(turnId, this.pending)
    this.pending = null
  }

  routeFor(turnId: string, agentId: string | undefined): RouteView | undefined {
    return agentId === undefined ? this.byTurn.get(turnId) : undefined
  }

  endTurn(turnId: string, agentId: string | undefined): void {
    if (agentId === undefined) this.byTurn.delete(turnId)
  }

  static describe(isOn: boolean, route: RouteView | null): string {
    const state = isOn ? 'on' : 'off'
    if (!route) return `Router ${state}. No prompt routed yet.`
    return `Router ${state}. Last: ${route.model} / ${route.effort} (${route.source}) - ${route.reason}`
  }

  static statusLine(route: RouteView): string {
    return `Route: ${route.model} / ${route.effort} - ${route.reason}`
  }
}

export function bindRouter(on: On, router: Router): void {
  on('command.run', { command: CONFIG.Pane.RouteCommand }, async ($, e) => {
    const arg = e.args.trim().toLowerCase()
    if (arg === 'on' || arg === 'off') {
      await update($, routerEnabledAtom, () => arg === 'on')
      if (arg === 'off') $.ui.status(undefined)
      return { text: `Router ${arg}.` }
    }
    return { text: Router.describe(await read($, routerEnabledAtom), router.last) }
  })

  on('prompt.submit', async ($, e, next) => {
    if (!(await read($, routerEnabledAtom))) return next(e)
    if (!Router.isUserOrigin(e.origin?.kind)) {
      router.carryOver()
      return next(e)
    }

    const at = await $.clock.now()
    const route =
      router.preRoute(e.text, at) ??
      router.fromJudge(await $.model.complete(router.judgeRequest(e.text), { signal: next.signal }), at)

    router.decide(route)
    await update($, routeAtom, () => route)
    $.ui.status(Router.statusLine(route))

    const override = Router.parseOverride(e.text)
    return next(override ? { ...e, text: override.text } : e)
  })

  on('turn.start', ($, e, next) => {
    router.startTurn(e.turnId)
    return next(e)
  })

  on('turn.step', async function* ($, e, next) {
    const route = router.routeFor(e.turnId, e.agentId)
    if (!route) return yield* next(e)
    return yield* next({ ...e, model: Router.modelId(route.model), effort: route.effort })
  })
}
