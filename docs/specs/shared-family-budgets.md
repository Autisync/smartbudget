# Spec: Shared Family Budgets

Status: **design only — not implemented, not scheduled**
Owner: unassigned
Depends on: nothing external (no third-party API), but this is the largest architectural change
in the entire Phase 5 roadmap — larger than the Plaid integration — because it doesn't extend the
existing model, it contradicts one of its foundational assumptions. Read §2 before estimating
this as "just add sharing."

## 1. Problem

SmartSpend currently assumes one person, one device, one encrypted local database. A couple or
family who wants to budget together today has no option but to share a login (defeating the
per-user auth model entirely) or keep separate, unreconciled SmartSpend installs. This spec is
about letting N users collaborate on a shared budget while keeping their individual financial
data private.

## 2. Why this contradicts the current architecture, not just extends it

Every other Phase 5 item (bank linking, net worth, recurring detection, trend charts, guided
first-run) adds new data *to the existing single-device model* — new account types, new local
tables, new client-side heuristics. None of them require a second device to ever see the same
row of data.

Shared budgets fundamentally requires that: two different phones, two different SQLCipher
databases, need to converge on the same view of a shared `Budget`. That means:
- **A server-authoritative source of truth is required for shared entities.** The backend's
  currently-unused `/finance` API (`backend/app/api/v1/endpoints/finance.py` — flagged as
  unused-by-the-client in `bank-account-linking.md`'s architecture section, §3, still relevant
  context here) stops being an optional future integration and becomes **required
  infrastructure** for this feature specifically, because there is no other place two devices can
  agree on a value.
- **The local SQLCipher database can no longer be assumed authoritative for shared data.** It
  remains authoritative for the user's private accounts/transactions (nothing about this feature
  should force *all* of a user's data server-side — see §5 on scope), but a shared `Budget` row
  now has to be treated as a cache of server state, with the usual cache-invalidation and
  conflict problems that local-first apps specifically avoid by not doing this.
- This is a genuine build-vs-defer decision, not just an estimate. If sync infrastructure is
  considered out of scope for the product's near-term roadmap, this feature should be explicitly
  deprioritized below every other Phase 5 item rather than estimated alongside them, because it's
  the one item whose cost is dominated by infrastructure the other five don't need at all.

## 3. Scope decision: which data is shared

Recommend the smallest useful surface for v1, not "share everything":
- **Shared**: `Budget` rows (category + limit + period) explicitly marked shared to a household,
  and the *aggregate* spend-vs-limit number for that category.
- **Not shared**: individual `Transaction` rows. A household member should see "Groceries: $340
  of $500 spent this month" without seeing every line item their partner bought — this is both a
  reasonable privacy default (nobody signed up to have every purchase visible to a spouse) and
  dramatically reduces sync surface (aggregates change less often and are smaller than a full
  transaction feed).
- **Not shared for v1**: `Account`, `SavingsGoal`, `Subscription` — each could plausibly become
  shareable later, but bundling all of them into v1 multiplies the conflict-resolution surface
  (§4) for marginal value; a shared category-limit budget is the smallest thing that makes
  "budgeting together" real.

This means the aggregate spend number itself has to be computed somewhere both users' data can
reach — see §4.

## 4. Sync and conflict resolution

Given the reduced scope (§3), the sync problem is: N devices each report "I spent $X in category
C this period" privately; the server aggregates; every device in the household displays the
household total against the shared limit. This is closer to a **write-and-aggregate** problem
than a general document-sync problem, which meaningfully simplifies the options:

- **Rejected: CRDTs / operational transform.** Appropriate for arbitrary concurrent document
  edits (e.g. two people editing the budget's *limit* at the same time), overkill for
  append-only spend aggregation where individual transactions never need to merge across users.
- **Rejected: full bidirectional transaction sync.** Would require solving general conflict
  resolution for a data type (transactions) this app currently never conflicts on (single device,
  single writer). Out of scope per §3 in any case.
- **Recommended: server-authoritative aggregates, client-private transactions.**
  1. Each user's device privately reports period-to-date spend-per-shared-category to the
     backend (a small, frequent sync — not the full transaction, just a category+amount+period
     delta), authenticated as that user.
  2. The backend sums contributions per household per shared budget category — this is a simple
     `SUM(...) GROUP BY` query, not a merge algorithm, because the backend is the only writer of
     the aggregate; devices only ever contribute their own delta.
  3. The shared budget's *limit* itself (as opposed to spend-against-it) is the one field with a
     real "two people edit it concurrently" conflict case. For that specific field: last-write-
     wins with a visible "Sam changed the Groceries limit to $500 (was $450) 2 minutes ago"
     activity note, not a silent overwrite — cheap to build, and transparent conflict resolution
     is more trustworthy for a household-money feature than an invisible one, even if it's not
     theoretically optimal.

This scoped-down design avoids needing general sync/merge machinery entirely — deliberately, since
building that well is its own multi-month effort and isn't what "share a budget with my partner"
actually requires once the requirement is scoped precisely.

## 5. Data model

**Backend (new tables)**:
```
Household
  id, name, created_by (user_id), created_at

HouseholdMember
  id, household_id (FK), user_id (FK), role (owner | member), joined_at

HouseholdInvite
  id, household_id (FK), invited_email, invited_by (user_id), status (pending | accepted | declined | expired),
  token (opaque, single-use), created_at, expires_at

SharedBudget
  id, household_id (FK), category, limit_amount, currency, period, updated_by (user_id), updated_at
  -- note: no per-transaction rows server-side; see §3/§4

SharedBudgetContribution
  id, shared_budget_id (FK), user_id (FK), period_start, amount_spent, reported_at
  -- one row per (user, budget, period); overwritten (not appended) on each device sync,
  -- since it's "my current total," not an event log
```

**Client**: a new `sharedBudgetId` (nullable) association on the local `Budget` entity, marking
it as linked to a household budget; the local budget's own limit/spend display logic needs a
branch for "this number came from the household aggregate, not purely local computation."

## 6. Invite flow

1. Household owner (whoever creates the household — no household exists until someone does)
   taps "Invite" from a household budget screen, enters a partner's email.
2. Backend creates a `HouseholdInvite`, sends an email (reuse the existing `email_service.py` /
   Celery email task infrastructure — this app already sends verification/reset emails, so this
   is a new template on an existing pipe, not new email infrastructure) with a deep link
   containing the invite token.
3. If the invited email doesn't have a SmartSpend account: link goes to signup, invite auto-
   applies post-verification. If it does: link opens the app (or a landing page prompting app
   install) directly to an accept/decline screen.
4. Accept creates the `HouseholdMember` row with role `member`. Decline or a 7-day expiry
   (`expires_at`) invalidates the token.
5. **Leaving/removal**: a member can leave a household (their `SharedBudgetContribution` rows are
   excluded from future aggregates but not deleted, so historical household totals for past
   periods don't silently change); an owner can remove a member. Either action should surface a
   confirmation given it changes what data a household sees going forward.

## 7. Permission model

v1 needs exactly two roles, not a general RBAC system:
- **Owner**: creates/deletes shared budgets, invites/removes members, edits shared budget limits.
- **Member**: contributes spend data, sees the shared budget and household total, edits shared
  budget limits (per §4's transparent last-write-wins — restricting limit edits to owner-only is
  a reasonable v1.1 hardening, but a couple budgeting together likely expects both partners to
  adjust a shared limit, so defaulting to open edit access within the household is closer to the
  actual use case than an ownership hierarchy).
- No view-only role for v1 — if that's wanted later (e.g. a teenager who can see but not change
  the family grocery budget) it's a straightforward third role to add once the two-role model is
  proven, not a reason to over-design the permission model up front.

## 8. Security considerations

- Shared budget data crossing the server means it's no longer purely protected by the device's
  SQLCipher key — it needs its own encryption-at-rest and in-transit story on the backend,
  reusing the field-level encryption pattern referenced in `bank-account-linking.md` §5.6 rather
  than inventing a second one.
- Invite tokens: single-use, expiring, and should not be guessable/enumerable (standard opaque
  random token, not a sequential id) — an invite token effectively grants access to a household's
  shared financial data.
- A removed household member must lose access immediately (revoke their ability to fetch
  `SharedBudget`/`SharedBudgetContribution` rows for that household server-side, not just hide
  the UI client-side) — this needs an actual authorization check per household-scoped request,
  not a client-trust model.

## 9. Effort estimate

This is explicitly the largest item in the roadmap, and the estimate below assumes the *scoped-
down* design in §3-4, not a general sync system:

- Backend: `Household`/`HouseholdMember`/`HouseholdInvite`/`SharedBudget`/
  `SharedBudgetContribution` tables + migrations, invite email flow, aggregation endpoint,
  authorization checks per household — **~2-2.5 weeks**.
- Client: household creation/management screens, invite accept/decline flow, shared-budget
  linking UI on the existing Budget screen, contribution-reporting sync job, activity-note UI for
  limit-change transparency (§4) — **~2-2.5 weeks**.
- Cross-device testing (this is the one feature in the whole roadmap that cannot be fully
  validated with a single test device/simulator — needs at minimum two accounts on two devices/
  simulators exercising real concurrent edits) — **~1 week**.

**Total: ~5.5-6 engineering-weeks**, comparable to bank-account-linking, but with a materially
higher long-term maintenance cost (this is the only Phase 5 item that adds an ongoing multi-
device consistency surface to the codebase — every future budget-related feature now has to ask
"does this need to work for shared budgets too"). Recommend treating the build-vs-defer question
in §2 as a real product decision, not a scheduling detail, before greenlighting this one.
