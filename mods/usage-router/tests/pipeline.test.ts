import { describe, expect, mock, test } from 'claude-code/testing'

import type { StageIO, StageName } from '../hooks/pipeline'
import { Pipeline } from '../hooks/pipeline'

const USAGE = { input_tokens: 1, output_tokens: 1, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 }
const TASK = 'Build a server-authoritative shop with purchase validation and DataStore saving'

const scripted = (answers: string[]) => {
  const calls: { name: StageName; agent: string; prompt: string }[] = []
  const io: StageIO = {
    stage: async (name, agent, prompt) => {
      calls.push({ name, agent, prompt })
      return answers.shift() ?? ''
    },
    round: async () => undefined,
    skip: async () => undefined,
  }
  return { calls, io }
}

describe('pipeline rounds', () => {
  test('review failure sends the writer back with findings, then passes', async () => {
    const pipeline = new Pipeline()
    pipeline.begin(TASK)
    const { calls, io } = scripted([
      'wrote ShopService',
      '[critical] ShopService:12 - price from client\nVERDICT: FAIL',
      'fixed',
      'clean\nVERDICT: PASS',
      'luau-analyze clean\nVERDICT: PASS',
    ])
    const outcome = await pipeline.rounds(TASK, { agent: 'writer-high' }, io)
    expect(outcome).toEqual({ verdict: 'passed', rounds: 2 })
    expect(calls.map(c => c.name)).toEqual(['Writer', 'Reviewer', 'Writer', 'Reviewer', 'Tester'])
    expect(calls[2]?.prompt).toContain('price from client')
  })

  test('gives up after the configured rounds', async () => {
    const pipeline = new Pipeline()
    pipeline.begin(TASK)
    const { calls, io } = scripted(Array.from({ length: 20 }, (_, i) => (i % 2 ? 'VERDICT: FAIL' : 'wrote')))
    const outcome = await pipeline.rounds(TASK, { agent: 'writer-high' }, io)
    expect(outcome.verdict).toBe('failed')
    expect(outcome.rounds).toBe(3)
    expect(calls.length).toBe(6)
  })

  test('stop request ends after the current stage', async () => {
    const pipeline = new Pipeline()
    pipeline.begin(TASK)
    const io: StageIO = {
      stage: async () => {
        pipeline.isStopRequested = true
        return 'wrote'
      },
      round: async () => undefined,
      skip: async () => undefined,
    }
    expect(await pipeline.rounds(TASK, { agent: 'writer-high' }, io)).toEqual({ verdict: 'stopped', rounds: 1 })
  })
})

test('/build routes the task and spawns the writer on the judged model and effort', async ($, on) => {
  const clock = mock.clock(on, { now: 1_000_000 })
  mock.store(on)
  const spawned: { type: string | undefined; model: string | undefined }[] = []

  on('model.complete', () => ({
    value: { isAnswered: true as const, text: '{"model":"opus","effort":"xhigh","reason":"x"}', usage: USAGE },
  }))
  on('agent.spawn', ($, e) => {
    const input = e as unknown as { subagent_type?: string; model?: string }
    spawned.push({ type: input.subagent_type, model: input.model })
    return { model: input.model ?? 'session' }
  })
  on('ui.open', () => ({ value: { isPlaced: true as const } }))
  on('fs.write', () => ({ value: undefined }))
  on('ui.toast', () => ({ value: undefined }))
  on('ui.log', () => ({ value: undefined }))

  const started = await $.command.run({ command: 'build', args: TASK } as never)
  expect(started.text).toContain('Pipeline started')
  await clock.settle()

  expect(spawned[0]).toEqual({ type: 'usage-router:writer-xhigh', model: 'claude-opus-5-5' })
})
