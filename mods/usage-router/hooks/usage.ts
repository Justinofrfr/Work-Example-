import { atom, update } from 'claude-code'
import type { On, SessionCost, SessionRateLimit } from 'claude-code'

import type { UsageView, WindowView } from '../types'
import { CONFIG } from './config'

const usageAtom = atom({ plugin: 'usage-router', key: 'usage' } as const, null)

export type Sample = { t: number; k: string; p: number; r: number | null }

export type UsageRecord = { view: UsageView; samples: Sample[]; toasts: string[] }

export const USAGE_STORE_KEY = 'samples'

const HOUR_MS = 60 * 60 * 1000
const RESET_TOLERANCE_MS = 10 * 60 * 1000

export class UsageTracker {
  samples: Sample[] = []
  isLoaded = false
  private warned = new Map<string, number>()

  hydrate(raw: unknown): void {
    this.samples = Array.isArray(raw) ? raw.filter(UsageTracker.isSample) : []
    this.isLoaded = true
  }

  record(limits: readonly SessionRateLimit[], cost: SessionCost | undefined, now: number): UsageRecord {
    const current: Sample[] = limits.map(limit => ({
      t: now,
      k: limit.kind,
      p: limit.percentUsed,
      r: UsageTracker.parseReset(limit),
    }))

    if (current.length > 0) {
      const cutoff = now - CONFIG.Usage.HistoryMs
      this.samples = [...this.samples.filter(s => s.t >= cutoff), ...current].slice(
        -CONFIG.Usage.MaxSamples,
      )
    }

    const windows = current.map(c => UsageTracker.computeWindow(this.samples, c, now))
    return {
      view: { windows, costUsd: cost ? cost.usd : null, updatedAt: now },
      samples: this.samples,
      toasts: this.thresholdToasts(windows),
    }
  }

  static isSample(v: unknown): v is Sample {
    if (typeof v !== 'object' || v === null) return false
    const s = v as Record<string, unknown>
    return typeof s.t === 'number' && typeof s.k === 'string' && typeof s.p === 'number'
  }

  static parseReset(limit: SessionRateLimit): number | null {
    if (!limit.resetsAt) return null
    const ms = Date.parse(limit.resetsAt)
    return Number.isFinite(ms) ? ms : null
  }

  static sameCycle(a: Sample, b: Sample): boolean {
    if (a.r === null || b.r === null) return true
    return Math.abs(a.r - b.r) <= RESET_TOLERANCE_MS
  }

  static computeWindow(samples: readonly Sample[], current: Sample, now: number): WindowView {
    const from = now - CONFIG.Usage.RateWindowMs
    let oldest: Sample | null = null
    for (const s of samples) {
      if (s.k !== current.k || s.t < from || s.t > current.t) continue
      if (!UsageTracker.sameCycle(s, current) || s.p > current.p) continue
      if (oldest === null || s.t < oldest.t) oldest = s
    }

    const span = oldest ? current.t - oldest.t : 0
    const rate =
      oldest !== null && span >= CONFIG.Usage.MinSampleMs
        ? Math.max(0, (current.p - oldest.p) / (span / HOUR_MS))
        : null
    const left = Math.max(0, Math.round((100 - current.p) * 10) / 10)
    const emptyAt = rate !== null && rate > 0 ? current.t + (left / rate) * HOUR_MS : null

    return {
      kind: current.k,
      label: CONFIG.Usage.Labels[current.k] ?? current.k,
      used: current.p,
      left,
      resetsAt: current.r,
      ratePerHour: rate === null ? null : Math.round(rate * 10) / 10,
      sampleMinutes: Math.round(span / 60000),
      emptyAt,
    }
  }

  private thresholdToasts(windows: readonly WindowView[]): string[] {
    const toasts: string[] = []
    for (const w of windows) {
      const level =
        w.used >= CONFIG.Usage.DangerAtPercent ? 2 : w.used >= CONFIG.Usage.WarnAtPercent ? 1 : 0
      const key = `${w.kind}:${w.resetsAt ?? 'none'}`
      if (level > (this.warned.get(key) ?? 0)) {
        this.warned.set(key, level)
        toasts.push(`${w.label} usage at ${w.used}% (${w.left}% left)`)
      }
    }
    return toasts
  }
}

export function bindUsage(on: On, tracker: UsageTracker): void {
  on('session.measure', async ($, e, next) => {
    if (e.changed.includes('rateLimits') || e.changed.includes('cost')) {
      if (!tracker.isLoaded) tracker.hydrate(await $.store.get(USAGE_STORE_KEY))
      const result = tracker.record(e.rateLimits, e.cost, await $.clock.now())
      if (e.changed.includes('rateLimits')) await $.store.set(USAGE_STORE_KEY, result.samples)
      await update($, usageAtom, () => result.view)
      for (const text of result.toasts) $.ui.toast(text)
    }
    return next(e)
  })
}
