# Spec: Budget & Savings Trend Charts

Status: **design only — not implemented, not scheduled** (per the user's blanket "Phase 5 =
spec only" decision for this remediation pass — see the note in §5 on why this is nonetheless
flagged as the best candidate to promote out of the roadmap and into an actual build in a future
pass)
Owner: unassigned
Depends on: nothing — `fl_chart` (`pubspec.yaml:59`) is already a dependency, already used
elsewhere (`lib/features/insights/`, `lib/features/dashboard/presentation/screens/
financial_health_screen.dart`, `lib/features/exchange_rates/`), with reusable chart components
already extracted in `lib/components/charts/app_finance_charts.dart` (`AppLineSparkChart`,
`AppDonutChart`). This is the lightest-effort item in the entire Phase 5 roadmap.

## 1. Problem

Both the Budget screen and Savings screen show only current-period snapshots — "you've spent
$340 of $500 this month," "$1,200 of $5,000 saved" — with no visual sense of trajectory. Users
can't see whether their spending pace is accelerating toward the limit, or whether their savings
contributions are steady, sporadic, or stalled.

## 2. Budget trend — nearly free, no schema change needed

Every `Transaction` already persists `amount`, `category`, and `date` indefinitely
(`lib/domain/entities/transaction.dart`). Both trend views this feature wants are fully derivable
from data that already exists on-device today:

- **Within-period cumulative spend**: for the budget's current period, group its category's
  expense transactions by day, running-sum them, and plot against a straight "pace line" from $0
  to the limit across the period — the classic "am I on pace" burn-down chart. Zero new queries
  beyond what `budgetSpendingProvider` already computes; this just needs the day-by-day
  intermediate values instead of only the final total.
- **Cross-period trend**: total spend per category per month, over the last N months — a bar or
  line chart of "Groceries: $420 in April, $380 in May, $510 in June." Also fully derivable by
  querying existing `Transaction` rows grouped by month; no new table.

**Net new backend/schema work for the budget side: none.** This is purely a new query
(category+date-range grouped aggregation, straightforward on the existing indexed `Transaction`
table) plus a chart widget.

## 3. Savings trend — needs one small new table

`SavingsGoal.savedAmount` (`lib/domain/entities/savings_goal.dart`) is a single mutable field,
overwritten on every update (`SavingsGoalRepositoryImpl.updateSavingsGoal`,
`lib/data/repositories/savings_goal_repository_impl.dart:67`) — there is no record of *when*
money was added or how much each contribution was, only the current running total. Unlike the
budget side, this data genuinely doesn't exist yet, so a real trend line needs a new local table:

```
SavingsContribution
  id, savingsGoalId (FK), amount, date, note (nullable), createdAt
```

Adding this is a net improvement beyond just enabling a chart: it turns "add to savings" from a
lossy overwrite into an append-only ledger, which also fixes a latent (if minor) usability gap —
today there's no way to see contribution history at all, chart or otherwise. `updateSavingsGoal`
would insert a `SavingsContribution` row alongside updating the cached `savedAmount` (kept as a
denormalized running total for the same reason `Account.currentBalance` is derived rather than
looked up fresh on every render — display performance — but now backed by a real ledger instead
of being the only record).

Existing goals with a pre-existing `savedAmount` and no contribution history would show a flat
line from account creation to now, with a note that trend data starts from when this feature
shipped — an honest empty-history state rather than fabricating retroactive data points.

## 4. UX

- **Budget screen**: expand the existing budget detail view (or its insight card) with a
  small `AppLineSparkChart`-style burn-down for the current period, plus a "Last 6 months"
  bar chart on tap/expand — consistent with the sparkline pattern already used elsewhere rather
  than introducing a new chart idiom.
- **Savings screen**: goal detail view gets a cumulative contribution line chart (contributions
  running-summed over time toward the target line), reusing the same line-chart component as the
  budget burn-down for visual consistency between the two screens this spec covers.
- Both charts: reuse `AppLineSparkChart`/the underlying `fl_chart` `LineChartData` styling already
  established in the codebase (axis formatting, color tokens via `AppColors`, tooltip style) —
  this is explicitly a "wire existing components to a new query," not a new charting subsystem.

## 5. Why this is flagged as a promotion candidate

Every other Phase 5 item either needs a third-party dependency not yet available
(`bank-account-linking.md`), a genuinely large architecture decision
(`shared-family-budgets.md`), or new-but-substantial local infrastructure
(`net-worth-tracking.md`'s snapshot system, `recurring-transaction-detection.md`'s heuristic
engine). This item needs one new table (§3), a couple of new aggregation queries (§2, already
close to what existing providers compute), and wiring into chart components that already exist
and are already proven in production. If a future pass wants one Phase 5 item promoted to an
actual Phase 4-style build rather than staying a spec, this is the one with the best effort-to-
value ratio — noted here explicitly so that decision doesn't require re-deriving this comparison
from scratch later.

## 6. Effort estimate

- Budget trend queries (within-period cumulative, cross-period aggregation) + chart wiring —
  **~2-3 days**.
- `SavingsContribution` table + migration + updated contribution-recording flow + chart wiring —
  **~2-3 days**.
- Tests (aggregation correctness across period boundaries, empty-history state, migration of
  existing goals) — **~1-2 days**.

**Total: ~1-1.5 weeks** — the smallest estimate of any Phase 5 item.
