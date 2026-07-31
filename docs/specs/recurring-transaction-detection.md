# Spec: Recurring Transaction Detection

Status: **design only — not implemented, not scheduled**
Owner: unassigned
Depends on: nothing external — pure client-side heuristic over data already on-device.

## 1. Problem

SmartSpend has two separate notions of "recurring" today, both of which require the user to
declare it up front:
- `Transaction.recurrence` (`lib/domain/entities/transaction.dart:19`) — set at entry time,
  drives `RecurringSchedulerService` to auto-generate the *next* occurrence going forward
  (`lib/core/services/recurring_scheduler_service.dart`). Purely forward-looking; it does nothing
  retroactively.
- `Subscription` (`lib/domain/entities/subscription.dart`) — a standalone entity for known bills
  (streaming services, gym memberships) with its own `billingCycle`/`nextBillingDate`, entered
  manually via Add Subscription.

Neither looks backward at transaction *history* to notice "you've paid $14.99 to something
categorized 'Streaming' on roughly the 3rd of the month, four months running — is this a
subscription you haven't logged as one?" This spec covers that retroactive detection.

## 2. Constraint: no merchant/payee field

`Transaction` has `amount`, `currency`, `type`, `category`, `date`, and an optional free-text
`note` — no structured merchant/payee field. This meaningfully limits match quality: two "Netflix"
charges are only linkable via matching amount + category + a rough date interval, not by name.
Two options:
- **(a) Work within the current schema** — match on `(category, amount within tolerance, interval
  regularity)` only, ignoring `note` (which many users leave blank) or treating it as a soft
  signal (bonus confidence if two candidates share a non-empty, string-similar `note`, penalty
  never applied for missing/differing notes since absence isn't evidence of non-recurrence).
- **(b) Add an optional `merchant` field to `Transaction` first** — meaningfully better match
  quality (an exact merchant match is far stronger evidence than "same category, similar
  amount"), but is itself a small schema-migration project (add column, migrate existing rows to
  null, add the field to the Add Transaction form) that this spec doesn't include.

**Recommend (a) for v1.** It ships without touching the transaction schema and is honestly
weaker at avoiding false positives (e.g. two unrelated $12 lunches in the same "Food" category,
roughly three weeks apart, would look like a false candidate). The confidence threshold and
required-occurrence-count in §3 exist specifically to keep (a) usably precise despite that; (b)
is a natural follow-up once this ships and its false-positive rate is measured against real data.

## 3. Detection approach

Runs entirely on-device (Dart, no ML model, no backend call — this is pattern-matching over data
the phone already has, not a good fit for a network round-trip or a heavyweight ML dependency).

1. **Candidate grouping**: for expense transactions not already `recurrence != none` and not
   already linked to an existing `Subscription`, group by `category`, then within each category
   bucket sub-group by amount similarity (within 5% or $1, whichever is larger — covers small
   price increases like a subscription tier bump without conflating unrelated purchases).
2. **Interval regularity check**: within a sub-group with ≥3 occurrences, compute the day-gaps
   between consecutive occurrences sorted by date. Classify as a candidate if the gaps cluster
   around a recognizable cadence:
   - weekly: 6-8 days
   - monthly: 27-33 days (handles month-length variance)
   - yearly: 350-380 days
   Reject (not a candidate) if gaps are irregular — a coefficient-of-variation threshold (e.g.
   std-dev / mean-gap < 0.15) is a reasonable single number to tune during implementation rather
   than fixing here.
3. **Confidence score**: a simple weighted composite, not a trained model —
   `occurrence_count` (more repeats = higher confidence, capped) +
   `interval_regularity` (tighter clustering = higher) +
   `note_similarity_bonus` (if applicable, per §2).
   Expressed as a 0-100 score for the threshold in §4, not a probability — this is a heuristic,
   presenting it as a calibrated probability would overclaim precision it doesn't have.
4. **Recomputation trigger**: run on app foreground (debounced — not on every single transaction
   add, which would make data entry feel laggy) similar in spirit to the existing
   `RecurringSchedulerService.syncRecurringTransactions` boot-time check, not a continuous
   background job.

## 4. Confidence threshold and user-confirmation UX

**No auto-tagging without confirmation, at any confidence level.** Even a high-confidence match
is still a heuristic guess about the user's finances; auto-marking a transaction as recurring (or
worse, auto-creating a `Subscription` with billing reminders) without explicit confirmation risks
being both wrong and mildly unsettling ("why does the app think it knows my subscriptions"). The
threshold controls *whether to surface a suggestion at all*, not whether to act:

- Score ≥ 70: surface as a suggestion card.
- Score 40-69: don't surface proactively, but do apply as a soft hint if the user is later
  manually marking that same transaction as recurring anyway (pre-fill the cadence).
- Score < 40: discard, no suggestion.

**Confirmation flow**: a dismissible suggestion card (in the existing Insights surface — the app
already has a pattern for this via `lib/intelligence/` and insight cards elsewhere in the app, so
this reuses an existing UI language rather than inventing a new one) —
"Looks like a recurring $14.99 charge in Streaming, roughly monthly. Add as a subscription?"
with three actions:
- **Yes, track it** → opens Add Subscription pre-filled with detected amount/category/cadence/
  next-expected-date, user reviews and confirms (never silently created).
- **It's recurring, but I'll track it as a transaction, not a subscription** → marks the most
  recent matching `Transaction.recurrence` field instead (lighter-weight than a full Subscription
  for things like recurring transfers that aren't "bills").
- **Dismiss** → suppress this specific candidate group permanently (needs a persisted
  dismissal — a `dismissedAt` marker keyed on the candidate's grouping signature, e.g. hash of
  category + rounded amount, stored locally, so a dismissed suggestion doesn't reappear next
  time detection reruns and regenerates the same candidate).

## 5. Data model changes

Minimal — this is intentionally a light-touch feature:
- New local table `DismissedRecurringCandidate(signatureHash, dismissedAt)` for the dismissal
  state in §4. No changes to `Transaction` or `Subscription` schemas themselves for v1 (see §2
  for the deferred `merchant` field option).
- No backend involvement — detection, scoring, and dismissal state are all local-only, consistent
  with the rest of the app's local-first model.

## 6. Effort estimate

- Detection/scoring algorithm + its own unit tests (this is the part that most benefits from
  real test coverage — synthetic transaction histories exercising each cadence class, the
  amount-tolerance boundary, and the irregular-gap rejection case) — **~3-4 days**.
- Dismissal persistence + wiring into the Insights surface — **~1-2 days**.
- Suggestion card UI + the three confirmation actions (including the Add Subscription pre-fill
  path) — **~2-3 days**.

**Total: ~1.5 weeks.** The smallest-scope item in the Phase 5 roadmap after
`budget-savings-trend-charts.md`; the main risk is tuning false-positive rate post-launch (§2),
not implementation complexity.
