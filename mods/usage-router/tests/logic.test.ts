import { describe, expect, test } from 'claude-code/testing'

import { Pipeline } from '../hooks/pipeline'
import { Router } from '../hooks/router'
import type { Sample } from '../hooks/usage'
import { UsageTracker } from '../hooks/usage'

const MIN = 60 * 1000
const RESET = 10_000 * MIN

describe('usage forecast', () => {
  test('rate and empty time come from the last hour', () => {
    const now = 1_000 * MIN
    const samples: Sample[] = [
      { t: now - 90 * MIN, k: 'five_hour', p: 5, r: RESET },
      { t: now - 60 * MIN, k: 'five_hour', p: 20, r: RESET },
      { t: now - 30 * MIN, k: 'five_hour', p: 30, r: RESET },
    ]
    const current: Sample = { t: now, k: 'five_hour', p: 40, r: RESET }
    const w = UsageTracker.computeWindow([...samples, current], current, now)
    expect(w.ratePerHour).toBe(20)
    expect(w.left).toBe(60)
    expect(w.emptyAt).toBe(now + 3 * 60 * MIN)
    expect(w.label).toBe('5h')
  })

  test('a new reset cycle is not mixed into the rate', () => {
    const now = 1_000 * MIN
    const old: Sample = { t: now - 40 * MIN, k: 'five_hour', p: 90, r: RESET - 300 * MIN }
    const current: Sample = { t: now, k: 'five_hour', p: 4, r: RESET }
    const w = UsageTracker.computeWindow([old, current], current, now)
    expect(w.ratePerHour).toBe(null)
    expect(w.emptyAt).toBe(null)
  })

  test('too little history reports no pace yet', () => {
    const now = 1_000 * MIN
    const prev: Sample = { t: now - 2 * MIN, k: 'seven_day', p: 10, r: null }
    const current: Sample = { t: now, k: 'seven_day', p: 11, r: null }
    expect(UsageTracker.computeWindow([prev, current], current, now).ratePerHour).toBe(null)
  })

  test('threshold toasts fire once per level', () => {
    const tracker = new UsageTracker()
    const limit = (p: number) => [{ kind: 'five_hour', percentUsed: p, resetsAt: '2030-01-01T00:00:00Z' }]
    expect(tracker.record(limit(50), undefined, 1).toasts.length).toBe(0)
    expect(tracker.record(limit(81), undefined, 2).toasts.length).toBe(1)
    expect(tracker.record(limit(85), undefined, 3).toasts.length).toBe(0)
    expect(tracker.record(limit(96), undefined, 4).toasts.length).toBe(1)
  })
})

describe('router parsing', () => {
  test('reads the judge JSON even with extra text', () => {
    expect(Router.parseChoice('sure {"model":"Opus","effort":"high","reason":"hard"} ok')).toEqual({
      model: 'opus',
      effort: 'high',
      reason: 'hard',
    })
  })

  test('rejects unknown models and efforts', () => {
    expect(Router.parseChoice('{"model":"gpt","effort":"high"}')).toBe(null)
    expect(Router.parseChoice('{"model":"opus","effort":"insane"}')).toBe(null)
    expect(Router.parseChoice('not json')).toBe(null)
  })

  test('manual override strips the prefix', () => {
    expect(Router.parseOverride('~opus:max fix the datastore')).toEqual({
      model: 'opus',
      effort: 'max',
      text: 'fix the datastore',
    })
    expect(Router.parseOverride('~haiku rename x')).toEqual({ model: 'haiku', effort: null, text: 'rename x' })
    expect(Router.parseOverride('~nothing here')).toBe(null)
  })

  test('short follow-ups keep the last route', () => {
    const router = new Router()
    router.decide({ model: 'opus', effort: 'high', reason: 'r', source: 'judge', at: 0 })
    expect(router.preRoute('yes do it', 5)?.source).toBe('sticky')
    expect(router.preRoute('x'.repeat(200), 5)).toBe(null)
  })
})

describe('pipeline verdicts', () => {
  test('the last verdict line wins', () => {
    expect(Pipeline.isPass('VERDICT: FAIL\nfixed\nVERDICT: PASS')).toBe(true)
    expect(Pipeline.isPass('VERDICT: PASS\nVERDICT: FAIL')).toBe(false)
    expect(Pipeline.isPass('no verdict')).toBe(false)
  })

  test('auto writer follows the route', () => {
    const plan = Pipeline.writerPlan({ model: 'opus', effort: 'xhigh', reason: '', source: 'judge', at: 0 })
    expect(plan).toEqual({ agent: 'writer-xhigh', model: 'claude-opus-5-5' })
  })
})
