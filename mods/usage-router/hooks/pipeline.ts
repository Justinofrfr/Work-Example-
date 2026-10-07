import { atom, update } from 'claude-code'
import type { On } from 'claude-code'

import type { Effort, PipelineView, RouteView, StageStatus } from '../types'
import { CONFIG } from './config'
import { Router } from './router'

const pipelineAtom = atom({ plugin: 'usage-router', key: 'pipeline' } as const, null)

export type StageName = 'Writer' | 'Reviewer' | 'Tester'
type Waiter = { resolve: (text: string) => void; reject: (err: Error) => void }
type Verdict = PipelineView['verdict']
export type WriterPlan = { agent: string; model?: string }
export type StageIO = {
  stage: (name: StageName, agent: string, prompt: string, model?: string) => Promise<string>
  round: (round: number) => Promise<unknown>
  skip: (name: StageName, summary: string) => Promise<unknown>
}
type AgentDef = {
  name: string
  description: string
  prompt: string
  model?: string
  effort?: Effort
  disallowedTools?: string[]
}

const P = CONFIG.Pipeline
const PLUGIN = 'usage-router'
const EARLY_LIMIT = 50
const READ_ONLY = ['Write', 'Edit', 'NotebookEdit']
const STAGES: readonly StageName[] = ['Writer', 'Reviewer', 'Tester']

export class Pipeline {
  isRunning = false
  isStopRequested = false
  round = 0
  log: string[] = []
  private waiters = new Map<string, Waiter>()
  private early = new Map<string, string>()

  static agentDefs(): AgentDef[] {
    const efforts: readonly Effort[] = P.Writer.Effort === 'auto' ? CONFIG.Router.Efforts : [P.Writer.Effort]
    return [
      ...efforts.map(effort => ({
        name: `writer-${effort}`,
        description: 'Writes Roblox Luau code for the usage-router pipeline',
        prompt: P.WriterPrompt,
        effort,
      })),
      {
        name: 'reviewer',
        description: 'Reviews Roblox Luau code for exploits, lag and bugs',
        prompt: P.ReviewerPrompt,
        model: P.Reviewer.Model,
        effort: P.Reviewer.Effort,
        disallowedTools: READ_ONLY,
      },
      {
        name: 'tester',
        description: 'Tests Roblox Luau code with static tools and path tracing',
        prompt: P.TesterPrompt,
        model: P.Tester.Model,
        effort: P.Tester.Effort,
        disallowedTools: READ_ONLY,
      },
    ]
  }

  static agentType(name: string): string {
    return `${PLUGIN}:${name}`
  }

  static writerPlan(route: RouteView | null): WriterPlan {
    const effort = P.Writer.Effort === 'auto' ? route?.effort ?? 'medium' : P.Writer.Effort
    const model = P.Writer.Model === 'auto' ? route?.model : P.Writer.Model
    return model ? { agent: `writer-${effort}`, model: Router.modelId(model) } : { agent: `writer-${effort}` }
  }

  static isPass(text: string): boolean {
    return text.lastIndexOf(P.PassToken) > text.lastIndexOf(P.FailToken)
  }

  static summarize(text: string): string {
    const lines = text.trim().split('\n').map(l => l.trim()).filter(Boolean)
    const head = lines[0] ?? ''
    const verdict = lines.find(l => l.startsWith('VERDICT:'))
    const out = verdict && verdict !== head ? `${head} | ${verdict}` : head
    return out.length > 160 ? `${out.slice(0, 157)}...` : out
  }

  static initialView(task: string, startedAt: number): PipelineView {
    return {
      task,
      round: 1,
      stages: STAGES.map(name => ({ name, status: 'waiting', summary: '' })),
      verdict: 'running',
      reportPath: null,
      startedAt,
    }
  }

  static withStage(view: PipelineView | null, name: StageName, status: StageStatus, summary: string): PipelineView | null {
    if (!view) return view
    return { ...view, stages: view.stages.map(s => (s.name === name ? { ...s, status, summary } : s)) }
  }

  static withRound(view: PipelineView | null, round: number): PipelineView | null {
    if (!view) return view
    return { ...view, round, stages: view.stages.map(s => ({ ...s, status: 'waiting', summary: '' })) }
  }

  static reportPath(startedAt: number): string {
    return `${P.ReportDir}/${new Date(startedAt).toISOString().replace(/[:.]/g, '-')}.md`
  }

  static fixPrompt(task: string, feedback: string): string {
    return `Fix every problem below, then re-check your work.\n\n${feedback}\n\nOriginal task:\n${task}`
  }

  static checkPrompt(task: string, written: string, action: string): string {
    return `Task:\n${task}\n\nWriter report:\n${written}\n\n${action} the files it changed.`
  }

  async rounds(task: string, writer: WriterPlan, io: StageIO): Promise<{ verdict: Verdict; rounds: number }> {
    let feedback = ''
    let rounds = 0
    for (let round = 1; round <= P.MaxRounds; round++) {
      if (this.isStopRequested) return { verdict: 'stopped', rounds }
      rounds = round
      this.round = round
      await io.round(round)
      this.log.push(`# Round ${round}`)

      const prompt = round === 1 ? task : Pipeline.fixPrompt(task, feedback)
      const written = await io.stage('Writer', writer.agent, prompt, writer.model)
      if (this.isStopRequested) return { verdict: 'stopped', rounds }

      const review = await io.stage('Reviewer', 'reviewer', Pipeline.checkPrompt(task, written, 'Review'))
      if (!Pipeline.isPass(review)) {
        feedback = `Reviewer findings:\n${review}`
        await io.skip('Tester', 'skipped: review failed')
        continue
      }
      if (this.isStopRequested) return { verdict: 'stopped', rounds }

      const tested = await io.stage('Tester', 'tester', Pipeline.checkPrompt(task, written, 'Test'))
      if (Pipeline.isPass(tested)) return { verdict: 'passed', rounds }
      feedback = `Tester failures:\n${tested}`
    }
    return { verdict: 'failed', rounds }
  }

  begin(task: string): void {
    this.isRunning = true
    this.isStopRequested = false
    this.round = 0
    this.log = [`# Pipeline report\n\nTask: ${task}`]
  }

  finish(): void {
    this.isRunning = false
    this.isStopRequested = false
  }

  settle(agentId: string, answer: string): void {
    const waiter = this.waiters.get(agentId)
    if (waiter) {
      this.waiters.delete(agentId)
      waiter.resolve(answer)
      return
    }
    this.early.set(agentId, answer)
    if (this.early.size > EARLY_LIMIT) {
      const first = this.early.keys().next()
      if (!first.done) this.early.delete(first.value)
    }
  }

  expire(agentId: string, label: string): void {
    const waiter = this.waiters.get(agentId)
    if (!waiter) return
    this.waiters.delete(agentId)
    waiter.reject(new Error(`${label} timed out`))
  }

  waitFor(agentId: string): Promise<string> {
    const done = this.early.get(agentId)
    if (done !== undefined) {
      this.early.delete(agentId)
      return Promise.resolve(done)
    }
    return new Promise<string>((resolve, reject) => {
      this.waiters.set(agentId, { resolve, reject })
    })
  }
}

export function bindPipeline(on: On, pipeline: Pipeline, router: Router): void {
  on('command.run', { command: P.Command }, async ($, e) => {
    const task = e.args.trim()
    if (task.toLowerCase() === 'stop') {
      pipeline.isStopRequested = pipeline.isRunning
      return { text: pipeline.isRunning ? 'Pipeline stops after the current stage.' : 'Nothing running.' }
    }
    if (task.length === 0) return { text: `Usage: /${P.Command} <task>  or  /${P.Command} stop` }
    if (pipeline.isRunning) return { text: `A pipeline is already running. Use /${P.Command} stop first.` }

    pipeline.begin(task)
    await $.ui.open({ id: CONFIG.Pane.Id, title: CONFIG.Pane.Title })

    const setStage = (name: StageName, status: StageStatus, summary = '') =>
      update($, pipelineAtom, v => Pipeline.withStage(v, name, status, summary))

    const runStage = async (name: StageName, agent: string, prompt: string, model?: string) => {
      await setStage(name, 'running')
      try {
        const started = await $.agent.spawn({
          prompt,
          description: `${name} (usage-router)`,
          subagentType: Pipeline.agentType(agent),
          ...(model ? { model } : {}),
        })
        if (started.deny !== undefined) throw new Error(started.deny)
        const agentId = started.agentId
        if (!agentId) throw new Error(`${name} did not start`)
        const timer = $.clock.after(P.StageTimeoutMs, () => pipeline.expire(agentId, name))
        const out = await pipeline.waitFor(agentId)
        timer.cancel()
        pipeline.log.push(`## ${name}\n\n${out}`)
        await setStage(name, 'done', Pipeline.summarize(out))
        return out
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err)
        pipeline.log.push(`## ${name}\n\nFAILED: ${message}`)
        await setStage(name, 'failed', message)
        throw err
      }
    }

    const run = async () => {
      const startedAt = await $.clock.now()
      await update($, pipelineAtom, () => Pipeline.initialView(task, startedAt))
      let verdict: Verdict = 'failed'

      try {
        const needsRoute = P.Writer.Model === 'auto' || P.Writer.Effort === 'auto'
        const at = await $.clock.now()
        const route = needsRoute
          ? router.preRoute(task, at) ?? router.fromJudge(await $.model.complete(router.judgeRequest(task)), at)
          : null
        const writer = Pipeline.writerPlan(route)
        pipeline.log.push(`Writer: ${writer.agent} on ${writer.model ?? 'session model'}`)

        const outcome = await pipeline.rounds(task, writer, {
          stage: runStage,
          round: n => update($, pipelineAtom, v => Pipeline.withRound(v, n)),
          skip: (name, summary) => setStage(name, 'waiting', summary),
        })
        verdict = outcome.verdict
      } catch (err) {
        pipeline.log.push(`Stopped on error: ${err instanceof Error ? err.message : String(err)}`)
        verdict = 'failed'
      }

      const reportPath = Pipeline.reportPath(startedAt)
      try {
        await $.fs.write(reportPath, pipeline.log.join('\n\n'))
      } catch {
        $.ui.log(`usage-router: could not write ${reportPath}`, { to: 'debug' })
      }
      await update($, pipelineAtom, v => (v ? { ...v, verdict, reportPath } : v))
      const rounds = pipeline.round
      pipeline.finish()
      $.ui.toast(`Pipeline ${verdict} after ${rounds} round(s)`)
      $.ui.log(`usage-router pipeline ${verdict} after ${rounds} round(s). Report: ${reportPath}`)
    }

    $.clock.after(0, () => {
      run().catch(() => pipeline.finish())
    })
    return { text: `Pipeline started: ${task.slice(0, 120)}` }
  })
}
