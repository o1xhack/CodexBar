# 001 — Daily Provider Utilization Chart

- **Status:** `blocked-upstream` — waiting for [upstream PR #565](https://github.com/steipete/CodexBar/pull/565) to merge
- **Created:** 2026-03-19
- **Updated:** 2026-03-19

## Summary

Add a daily utilization (session usage %) chart to each provider's detail page on iOS, alongside the existing Cost chart.

## Requirements

- Show per-day session utilization percentage (e.g., yesterday 50%, day before 30%)
- Data sourced from Mac via iCloud sync
- **No changes** to Mac-side core storage logic; at most add fields to the CloudSync shared layer
- UI: new "Utilization" chart section in provider detail view

## Current Data Landscape

### What IS synced to iOS today

| Data | Historical? | Structure |
|------|-------------|-----------|
| Rate limit `usedPercent` (Session/Weekly/Opus) | No — current snapshot only | `SyncRateWindow.usedPercent` |
| Daily Cost & Tokens | Yes — 50 days | `SyncDailyPoint` array in `SyncCostSummary` |
| Budget usage | No — current snapshot only | `SyncBudgetSnapshot` |

### What EXISTS on Mac but is NOT synced

| Data | Details |
|------|---------|
| `HistoricalUsageHistoryStore` | 56-day retention, sampled every 30 min (>1% change threshold) |
| Scope | Currently **Codex (OpenAI) only**, not all providers |
| Location | `Sources/CodexBar/HistoricalUsagePace.swift` |

### Key constraints

- iCloud KVS payload limit: **1 MB** per key
- Daily utilization aggregates would add ~few KB (negligible)

## Proposed Approaches

### Approach A — Extend Sync Payload (Recommended)

Add `SyncDailyUtilization` to `Shared/Models/UsageSnapshot.swift`:

```swift
public struct SyncDailyUtilization: Codable {
    public let dayKey: String          // "2026-03-19"
    public let avgUsedPercent: Double  // Daily average utilization
    public let peakUsedPercent: Double // Daily peak
    public let windowLabel: String     // "Session", "Weekly"
}
```

**Changes required:**
1. `Shared/Models/UsageSnapshot.swift` — add model (shared layer)
2. Mac `SyncCoordinator.swift` — read from `HistoricalUsageHistoryStore`, compute daily aggregates, include in sync
3. Extend `HistoricalUsageHistoryStore` to all providers (currently Codex only)
4. iOS — add Utilization chart View

**Pros:** Accurate, has historical backfill, architecturally consistent with Cost chart
**Cons:** Requires Mac sync code changes; need to generalize historical tracking to all providers
**Risk:** Low — 1MB limit not a concern; no core storage changes

### Approach B — iOS-Side Accumulation (Zero Mac Changes)

iOS records each sync snapshot's `usedPercent` + timestamp locally, builds up history over time.

**Pros:** No Mac changes at all
**Cons:** No backfill (history starts from feature launch); sparse/uneven sampling; inaccurate daily averages
**Risk:** Medium — data quality may be poor

### Approach C — Cost as Proxy (Simplest, Roughest)

Use existing daily cost data as a utilization proxy.

**Pros:** Zero changes needed
**Cons:** Cost ≠ utilization; misleading for API users
**Risk:** High — fundamentally inaccurate

## Recommendation

**Approach A** is the cleanest path. The Mac already has the raw data (`HistoricalUsageHistoryStore`); we just need to aggregate it and add it to the sync payload.

## Key Files

| File | Role |
|------|------|
| `Shared/Models/UsageSnapshot.swift` | Sync data models (add new struct here) |
| `Shared/iCloud/CloudSyncManager.swift` | iCloud KVS push/fetch |
| `Sources/CodexBar/HistoricalUsagePace.swift` | Mac-side historical usage (56-day, 30-min samples) |
| `Sources/CodexBar/Sync/SyncCoordinator.swift` | Mac → iCloud push logic |
| `CodexBarMobile/CodexBarMobile/Views/ProviderUsageView.swift` | iOS provider detail (add chart here) |

## Upstream Research (2026-03-19)

### PR #565 — "Subscription Utilization History" (OPEN)

- **Author:** maxceem
- **Created:** 2026-03-18 (just yesterday!)
- **State:** OPEN, not yet merged
- **URL:** https://github.com/steipete/CodexBar/pull/565

#### What it does

Adds a **Subscription Utilization** menu item to the Mac app with three chart views:
- **Daily** (last 30 days) — estimated from 5-hour windows
- **Weekly** (last 24 weeks) — directly from provider 7-day windows (most reliable)
- **Monthly** (last 24 months) — estimated from 7-day windows

#### Supported providers
- Codex (OpenAI)
- Claude

#### Key implementation details
- Stores **raw window-based samples** (not precomputed daily/weekly/monthly), allowing chart format changes later
- History retained for ~2 years
- Samples recorded at most once per hour
- History persisted as JSON file, ~4 MB per account for 2 years
- Per-account tracking (supports multiple Claude/Codex accounts)
- Extra usage is NOT counted (only "prepaid" subscription tokens)
- Provider-agnostic charting logic

#### Daily chart calculation
- Groups samples by reset period within each day
- Takes max observed `usedPercent` per reset period
- Averages those across the day
- Note: daily will rarely show 100% because people sleep (max ~50% typical)

#### New files (Mac-side only, ~3,400+ lines)
- `PlanUtilizationHistoryStore.swift` — persistence layer
- `PlanUtilizationHistoryChartMenuView.swift` — SwiftUI chart views (1,070 lines)
- `UsageStore+PlanUtilization.swift` — core logic (508 lines)
- `StatusItemController+UsageHistoryMenu.swift` — menu integration
- Plus extensive tests (~2,400+ lines)

#### Limitations noted by author
1. CodexBar must be running to capture data (missed periods = lower reported usage)
2. Multi-account identity issues (Claude identity sometimes unrecognized)

### Impact on our iOS feature

This PR is **Mac-side only** — no iCloud sync, no iOS support. But it validates:
- [x] The concept is in demand (someone else independently proposed it)
- [x] The raw data capture approach works (window-based samples)
- [x] Daily/Weekly/Monthly aggregation logic is proven
- [x] `HistoricalUsageHistoryStore` is being superseded by `PlanUtilizationHistoryStore`

**For our iOS implementation**, once this PR merges upstream, we would:
1. Sync the aggregated utilization data via iCloud (add to `Shared/Models/`)
2. Build iOS chart views mirroring the Mac charts
3. Reuse the same calculation logic

**Recommendation:** Wait for PR #565 to merge, then rebase onto it and add iCloud sync + iOS UI.

## Open Questions

- [x] ~~Does upstream already have this feature?~~ → No, not merged yet
- [x] ~~Are there upstream PRs?~~ → Yes! PR #565, opened 2026-03-18
- [ ] Should we wait for #565 to merge, or build independently?
- [ ] Should we contribute iOS sync support back to upstream as a follow-up PR?
- [ ] What chart style for iOS? Bar chart (like Cost) or line chart?
