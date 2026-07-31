# Spec: Net Worth Tracking

Status: **design only — not implemented, not scheduled**
Owner: unassigned
Depends on: nothing external — this is the lowest-external-risk item in the Phase 5 roadmap
(no third-party API), but it does need new local schema and a new chart.

## 1. Problem

SmartSpend tracks cash-flow-style accounts (Cash, Bank Transfer, Credit Card, Mobile Money) and
derives their balances from the transaction ledger. It has no concept of point-in-time net worth
— total assets minus total liabilities, tracked over time. A user with a mortgage, a brokerage
account, and a car loan has no way to see "am I getting wealthier" as a single number, only "what
did I spend this month."

## 2. Relationship to the existing "Balance Sheet" feature — these are different things

`lib/features/balance_sheet/presentation/screens/recurring_balance_sheet_screen.dart` (nav label
"Balance Sheet", `l10n.navBalanceSheet`) already exists, but despite the name it is **not** a
traditional balance sheet. It projects recurring income vs. recurring obligations (rent, loan
payments, subscriptions marked recurring) to answer "does my recurring income cover my recurring
commitments this month" — a cash-flow forecast, entirely derived from `Transaction` and
`Subscription` rows already in the ledger, with no persisted history of its own
(`recurringBalanceSheetProvider` recomputes on every read).

Net worth tracking is conceptually distinct: it's assets − liabilities at a point in time,
persisted as a **time series** so it can be charted, not recomputed fresh from the ledger (an
investment account's value isn't derivable from transactions the way a cash account's is — see
§3). The two features will likely sit next to each other in navigation (both answer "how am I
doing financially," just on different axes — flow vs. stock) but share no code beyond the
existing `Account` entity and formatting helpers. Recommend **not** merging them into one screen;
keep net worth as a new screen, cross-linked from Balance Sheet's summary card.

## 3. New account types

`AccountType` (`lib/data/models/tables.dart:97`) currently has `cash, bank, mobileMoney,
creditCard, investment`. `investment` already exists but nothing in the app currently treats it
specially — worth confirming its current behavior is truly generic before building on it.

This feature needs two more:
- `property` — real estate, vehicles: the kind of asset with no live market feed. Balance is
  **manually updated** by the user (see §5), not derived from transactions.
- `loan` — mortgages, student loans, car loans, personal loans not on a credit card. Distinct
  from `creditCard` because credit cards also track day-to-day spending transactions;
  a loan's balance only moves via manual principal-update or scheduled payment amount, and its
  transactions (if tracked at all) are just payments, not purchases.

### Sign convention

The existing `Account.currentBalance` derivation (opening + income − expense) assumes a cash-like
account where a positive balance is good. For `loan`, net worth math needs the *liability*
framing: a $20,000 car loan should subtract $20,000 from net worth, not add it. Two viable
approaches:
- **(a)** Store loan balances as positive numbers (the amount owed) and have net-worth
  calculation subtract `loan`-typed and `creditCard`-typed (when in debt) balances instead of
  adding them.
- **(b)** Store them as negative balances directly, so `sum(all account balances)` is already net
  worth with no type-based branching.

**Recommend (a).** Users think of "I owe $20,000," a positive number, not "-$20,000" — matching
mental model over implementation convenience avoids a confusing account-detail screen. The
type-based sign flip happens once, in the net-worth aggregation function, not throughout the UI.

## 4. Historical snapshotting

This is the actual new piece of infrastructure. Everything else in SmartSpend is either
transaction-derived (recomputed on read) or a single current-state row. Net worth needs a
**time series** to chart, which nothing in the current schema provides.

New local Drift table:
```
NetWorthSnapshot
  id, takenAt (DateTime), totalAssets, totalLiabilities, netWorth, currency, createdAt
  -- optionally, a per-account breakdown table (NetWorthSnapshotEntry) if the trend chart
  -- should support "which account changed" drill-down; skip for v1, add if requested.
```

**Snapshot cadence**: capture on app foreground once per calendar day (compare `takenAt` of the
most recent snapshot; if not today, capture a new one), piggybacking on the same kind of
lightweight per-launch check `RecurringSchedulerService.syncRecurringTransactions` already does
in `main.dart`'s boot sequence — no new background-task infrastructure (no WorkManager/BGTaskScheduler)
needed for v1, at the cost of gaps if the user doesn't open the app for several days. That's an
acceptable v1 tradeoff (the trend chart just has a flatter line across the gap) rather than a
blocker — background scheduling can be added later if users want it.

**Manual asset updates**: `property`-typed (and optionally `investment`-typed) accounts have no
transaction feed, so their balance can only change via an explicit "Update value" action on the
account detail screen (a simple amount-entry form, not a transaction — this does not create a
`Transaction` row, it directly updates the account's stored value, which is a deliberate
exception to every other account type's "balance is always derived" rule and should be called
out clearly in the account-detail UI, e.g. a small "manually tracked" label, so it doesn't look
like a bug when it behaves differently from a Cash account).

## 5. Net worth calculation

```
totalAssets = sum(balance for accounts where type in {cash, bank, mobileMoney, investment, property} and balance > 0... )
totalLiabilities = sum(balance for accounts where type in {creditCard, loan})
netWorth = totalAssets - totalLiabilities
```
(Credit card balances that are currently in credit, i.e. the user overpaid, would need the same
positive/negative handling as loans get in reverse — an edge case worth a unit test, not a
special-cased code path.)

Computed on-demand from current `Account` rows for "current net worth," and persisted as a
`NetWorthSnapshot` row on the cadence described in §4 for the trend line.

## 6. UX flow

1. New "Net Worth" screen, likely nested under or linked from the existing Balance Sheet screen
   (see §2) rather than a new top-level nav item — SmartSpend's bottom nav is already at
   capacity based on the current IA; a cross-link avoids a nav redesign.
2. Hero number: current net worth, styled consistently with the dashboard's hero balance
   (reuse `TextScaleClamp` per this session's P4.4 work, since it's the same "large financial
   number that must not overflow" problem).
3. Trend chart: `fl_chart` line chart (already a dependency — see the
   `budget-savings-trend-charts.md` spec for the other consumer of this same library) over
   `NetWorthSnapshot` history, default range last 90 days with a range selector
   (30/90/365/all), same pattern as any other in-app time-series chart.
4. Breakdown: two grouped lists below the chart — Assets (cash/bank/investment/property, each
   with its current value) and Liabilities (credit cards in debt, loans), with a running subtotal
   per group. Each row deep-links to the underlying account detail screen.
5. Empty state: a user with no `investment`/`property`/`loan` accounts yet sees net worth exactly
   equal to their existing cash accounts' sum, with a callout ("Add an investment or property
   account to see your full net worth") rather than an empty/broken-looking screen — net worth
   tracking should feel useful immediately even before the user adds anything new.

## 7. Effort estimate

- Schema: `NetWorthSnapshot` table + migration, `property`/`loan` `AccountType` variants +
  migration for the enum change, manual-value-update path on account detail — **~3-4 days**.
- Snapshot capture wiring (boot-time check + on-demand recompute) — **~1-2 days**.
- Net Worth screen (hero, chart, breakdown lists, empty state, range selector) — **~4-5 days**.
- Tests (balance-sign edge cases, snapshot cadence logic, chart data transformation) — **~2 days**.

**Total: ~2 weeks.** No third-party dependency, no backend changes — the whole feature is local
schema plus UI, making it one of the more self-contained items in the Phase 5 roadmap despite the
schema change being non-trivial (an `AccountType` enum migration touches every existing
account-creation surface).
