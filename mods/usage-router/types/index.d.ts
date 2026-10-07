export type Effort = 'low' | 'medium' | 'high' | 'xhigh' | 'max'

export type WindowView = {
  kind: string
  label: string
  used: number
  left: number
  resetsAt: number | null
  ratePerHour: number | null
  sampleMinutes: number
  emptyAt: number | null
}

export type UsageView = {
  windows: WindowView[]
  costUsd: number | null
  updatedAt: number
}

export type RouteView = {
  model: string
  effort: Effort
  reason: string
  source: 'judge' | 'override' | 'sticky' | 'fallback'
  at: number
}

export type StageStatus = 'waiting' | 'running' | 'done' | 'failed'

export type StageView = {
  name: string
  status: StageStatus
  summary: string
}

export type PipelineView = {
  task: string
  round: number
  stages: StageView[]
  verdict: 'running' | 'passed' | 'failed' | 'stopped'
  reportPath: string | null
  startedAt: number
}

declare module 'claude-code' {
  interface PluginState {
    'usage-router': {
      usage: UsageView | null
      route: RouteView | null
      routerEnabled: boolean
      pipeline: PipelineView | null
      tick: number
    }
  }
}
