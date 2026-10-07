import { expect, mock, test } from 'claude-code/testing'

const USAGE = { input_tokens: 1, output_tokens: 1, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 }
const JUDGE = '{"model":"opus","effort":"high","reason":"anti-exploit design"}'
const LONG = 'Make a server-authoritative coin pickup system with remote validation and rate limiting'

test('router judges the prompt and rewrites the turn model and effort', async ($, on) => {
  mock.clock(on, { now: 1_000_000 })
  mock.store(on)
  let judged = 0
  const seen: { model: string; effort: unknown }[] = []

  on('model.complete', () => {
    judged += 1
    return { value: { isAnswered: true as const, text: JUDGE, usage: USAGE } }
  })
  on('prompt.submit', ($, e) => ({ text: e.text }))
  on('turn.start', ($, e) => ({ turnId: e.turnId }))
  on('turn.step', async function* ($, e) {
    seen.push({ model: e.model, effort: e.effort })
    return { turnId: e.turnId, index: e.index, answer: '', toolUses: [], stopReason: 'end_turn', usage: null }
  })
  on('turn.complete', () => ({ text: '' }))

  const submitted = await $.prompt.submit({ text: LONG, wait: false, origin: { kind: 'composer' } })
  expect(submitted.text).toBe(LONG)
  expect(judged).toBe(1)

  await $.turn.start({ text: LONG, turnId: 't1' })
  const stream = $.turn.step({ turnId: 't1', index: 0, model: 'claude-sonnet-5-5', effort: 'medium', messageCount: 1 })
  for await (const _ of stream) void _
  expect(seen[0]).toEqual({ model: 'claude-opus-5-5', effort: 'high' })

  const sub = $.turn.step({ turnId: 't1', index: 1, model: 'claude-sonnet-5-5', messageCount: 2, agentId: 'a1' })
  for await (const _ of sub) void _
  expect(seen[1]?.model).toBe('claude-sonnet-5-5')
})

test('override prefix skips the judge and is stripped', async ($, on) => {
  mock.clock(on, { now: 1_000_000 })
  mock.store(on)
  let judged = 0
  on('model.complete', () => {
    judged += 1
    return { value: { isAnswered: true as const, text: JUDGE, usage: USAGE } }
  })
  on('prompt.submit', ($, e) => ({ text: e.text }))

  const submitted = await $.prompt.submit({ text: '~haiku:low rename the variable', wait: false, origin: { kind: 'composer' } })
  expect(submitted.text).toBe('rename the variable')
  expect(judged).toBe(0)
})

test('usage band shows used, left and forecast after a measurement', async ($, on) => {
  const clock = mock.clock(on, { now: Date.parse('2030-01-01T10:00:00Z') })
  mock.store(on)
  on('session.measure', ($, e) => ({ changed: e.changed }))

  const measure = (p: number) =>
    $.session.measure({
      context: { window: 200000 } as never,
      rateLimits: [{ kind: 'five_hour', percentUsed: p, resetsAt: '2030-01-01T14:00:00Z' }],
      changed: ['rateLimits'],
    })

  await measure(10)
  await clock.advance(30 * 60 * 1000)
  await measure(30)

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ plugin: 'usage-router', surface, component: 'AbovePrompt', props: {} as never })
    const band = await ui.find({ type: 'Text', text: /^5h / })
    expect(band?.text).toContain('5h 30%')
    expect(band?.text).toContain('70% left')
    expect(band?.text).toContain('empty in ~1h 45m')
    await ui.unmount()
  }
})
