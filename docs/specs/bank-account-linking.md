# Spec: Bank Account Linking (Plaid)

Status: **design only — not implemented, not scheduled**
Owner: unassigned
Depends on: a Plaid developer account + API keys (see "Blocker" below)

## 1. Problem

Every account and transaction in SmartSpend today is entered manually into an on-device,
SQLCipher-encrypted SQLite database (`lib/data/datasources/local/`). There is no automatic
ingestion of real bank activity. Users who want SmartSpend to reflect their actual balances
have to keep it in sync by hand. Bank account linking (via [Plaid](https://plaid.com)) would let
a user connect a real checking/savings/credit account once and have transactions and balances
flow in automatically.

This is the most architecturally invasive item in the Phase 5 roadmap because SmartSpend is
currently **local-first with no device-to-server data sync for financial data** (see §3). Every
other roadmap item extends the existing on-device model; this one requires a new sync path.

## 2. Third-party dependency — blocker

Implementation cannot start until:
- A Plaid developer account exists for SmartSpend, with API keys for `sandbox`, `development`,
  and (eventually) `production` environments.
- A decision on Plaid product tier: this feature needs **Transactions** and **Balance** at
  minimum; **Identity** or **Auth** are not needed since SmartSpend never initiates transfers.
- Plaid's production access requires an application review (they ask about data use, security
  practices, and expected volume) — this has a multi-day-to-multi-week lead time and should be
  started well before implementation, not after.
- A Plaid pricing tier decision — Plaid charges per linked item/month in production; this is a
  recurring operating cost, not a one-time integration cost, and should be sized against expected
  user count before committing.

None of the above can be done inside this repo. This spec assumes those keys exist and focuses
on what to build once they do.

## 3. Current architecture context

- **Client**: Flutter + Riverpod + Drift/SQLCipher. `Account` (`lib/domain/entities/account.dart`)
  already has an `AccountType` enum with `cash`, `bank`, `mobileMoney`, `creditCard`, and
  `investment` variants, and every account's `currentBalance` is *derived* from its transaction
  ledger (opening balance + income − expense), never stored directly. This derivation logic
  (`AccountRepositoryImpl`, covered by `test/data/account_repository_test.dart`) is a hard
  constraint: any Plaid-sourced balance must be reconciled through the same ledger, not written
  as a raw balance override, or the two numbers will silently drift apart the next time a manual
  transaction is added.
- **Backend**: FastAPI + Postgres, primarily used for auth (`backend/app/api/v1/endpoints/auth.py`)
  and account-session management. It also exposes a `/finance` router
  (`backend/app/api/v1/endpoints/finance.py`) with `Transaction`/`Budget`/`SavingsGoal`/
  `Subscription` CRUD backed by real Postgres tables (`backend/app/models/finance.py`) — but **the
  Flutter app does not call any of these endpoints today** (confirmed: no references to
  `/finance`, `/transactions`, `/budgets`, etc. anywhere under `lib/`). This is live, tested,
  paginated backend code (hardened in Phase 2 of this remediation pass) that currently has no
  client. It is the natural home for Plaid data — the client-side gap for *reading it back* is
  the actual new work.
- **No existing sync protocol.** There is no mechanism today for the backend to push data to a
  specific user's device, or for the device to pull anything beyond auth state. This has to be
  designed from scratch (§5.3), not bolted onto an existing sync path.

## 4. Why this can't be "just call Plaid from the app"

Plaid's `access_token` (obtained by exchanging the `public_token` Link returns) is a long-lived
secret that grants read access to the user's real bank account. It must **never** reach the
client — Plaid's own integration guidelines require the exchange and all subsequent data calls to
happen server-side. This single constraint is why the feature needs the backend's finance API
engaged rather than being addable as a self-contained client feature like the other Phase 5 items.

## 5. Proposed architecture

### 5.1 Linking flow (client-initiated, server-mediated)

1. Client requests a Link token: `POST /api/v1/plaid/link-token` (new endpoint) → backend calls
   Plaid's `/link/token/create` with the authenticated user's id, returns the `link_token`.
2. Client opens Plaid Link (via the `plaid_flutter` plugin, which wraps Plaid's native Link SDKs
   — this is the one new Flutter dependency this feature needs) with that token.
3. User authenticates with their bank inside Plaid's hosted UI (SmartSpend never sees bank
   credentials — this is the whole point of Plaid).
4. Link returns a `public_token` to the client, which the client immediately forwards to
   `POST /api/v1/plaid/exchange` (new endpoint).
5. Backend exchanges `public_token` → `access_token` + `item_id` via Plaid's `/item/public_token/exchange`,
   and stores `access_token` **encrypted at rest**, associated with the user and the new
   `PlaidItem` row (§5.2). The client never sees `access_token`.
6. Backend does an initial `/accounts/get` + `/transactions/sync` pull, creates the linked
   `Account` row(s) and initial `Transaction` rows server-side, and returns a summary to the
   client (accounts found, names, masked numbers) so the client can render "3 accounts linked."

### 5.2 Data model changes

**Backend (new tables, `backend/app/models/finance.py` or a new `plaid.py`):**
```
PlaidItem
  id, user_id (FK), plaid_item_id, access_token (encrypted), institution_name,
  status (active | login_required | error), last_synced_at, created_at

PlaidAccount
  id, plaid_item_id (FK), plaid_account_id, name, mask, account_type, account_subtype,
  current_balance, available_balance, currency, linked_local_account_id (nullable —
  set once the client has created/matched a local Account for this)
```

**Backend `Transaction` (existing table, extend):**
- `source: manual | plaid` (default `manual`)
- `plaid_transaction_id` (nullable, unique when set) — Plaid's own dedupe key, used for
  upsert-on-sync via their `/transactions/sync` cursor API (not the older `/transactions/get`
  polling API, which Plaid has deprecated for new integrations).

**Client (`lib/domain/entities/`):**
- `Account` gains an optional `externalAccountId` (nullable) marking it as Plaid-linked vs.
  manual, and a `syncStatus` for surfacing "needs reauth" in the UI (Plaid Items expire and
  require the user to re-link periodically, or immediately if they change their bank password).
- `Transaction` gains an optional `externalTransactionId` for the same reason, and to support
  the reconciliation logic below.

### 5.3 Sync path (the new piece)

Since there's no existing device sync protocol, this needs one of:
- **(a) Pull-based polling**: client periodically calls `GET /api/v1/plaid/transactions?since=...`
  on app foreground / a background fetch trigger, merges results into the local SQLCipher DB.
  Simple, no new infrastructure, but not real-time and burns battery/data if polled aggressively.
- **(b) Push via existing notification service**: backend enqueues a "new transactions available"
  push (reusing the Firebase infra already wired up per P3.1) when Plaid's webhook fires; client
  wakes up and pulls the delta. Better latency, more moving parts (webhook → Celery task → FCM →
  client pull, four systems that all have to stay in sync).

**Recommendation: start with (a).** It's a fraction of the implementation cost, and given this
app's current install base there's no latency requirement that justifies the push
infrastructure yet. (b) is a natural phase-2 once (a) is validated.

Either way, Plaid webhooks (`POST /api/v1/plaid/webhook`, new endpoint, signature-verified per
Plaid's webhook verification docs) must be handled server-side regardless of which sync path is
chosen, since `TRANSACTIONS_UPDATES_AVAILABLE` and `ITEM_LOGIN_REQUIRED` events only arrive there
— the polling client just changes how those events reach the device afterward.

### 5.4 Reconciliation against the manual-entry model

This is the trickiest UX/data problem, not a technical one. A user who manually logs "$12.50
coffee" the morning it happens, then links their card that afternoon, will see Plaid report the
same purchase a day or two later once it posts. Without reconciliation this becomes a duplicate.

Proposed matching heuristic, applied when a Plaid transaction is pulled and no
`plaid_transaction_id` match exists yet:
1. Same account (or the manual entry's account maps to this Plaid account).
2. Amount matches exactly (Plaid amounts are precise; no fuzzy tolerance needed here).
3. Date within a **3-day window** (manual entry is same-day; Plaid transactions can post 1-3
   business days after the purchase date).
4. If exactly one manual, unlinked transaction matches (1)-(3): auto-merge — attach the
   `plaid_transaction_id` to the existing manual row rather than creating a new one, and prefer
   Plaid's merchant name/category over the user's manual note only if the manual note was empty.
5. If zero or multiple candidates match: do **not** auto-merge — surface it as a new Plaid
   transaction and let the user manually dismiss/merge it if it's a duplicate they can see. Silent
   incorrect merges (merging the wrong two transactions) are worse than an occasional visible
   duplicate the user can fix in two taps.

### 5.5 UX flow

1. Settings → "Linked Accounts" (new screen) → "Link a bank account" button.
2. Plaid Link opens (native modal via `plaid_flutter`), user picks institution, authenticates.
3. On return, a summary screen: "We found 3 accounts at Chase — which would you like to track?"
   with a checkbox per discovered account, since not every account at an institution should
   become a SmartSpend `Account` (e.g. a linked savings account they don't want budgeted).
4. Each selected Plaid account is either matched to an existing manual `Account` (if the user
   already had a manually-tracked "Chase Checking" they want to convert) or created fresh.
5. A persistent status indicator (small icon on the account card) shows sync health: synced /
   syncing / needs reauth. Tapping "needs reauth" relaunches Plaid Link in update mode.
6. Unlink flow: "Remove linked account" in account settings — deletes the `PlaidItem` server-side
   (calls Plaid's `/item/remove` so the access token is invalidated on Plaid's side, not just
   locally), converts the local `Account` to a plain manual account rather than deleting its
   transaction history.
7. A one-time consent screen before the first Link launch, disclosing what data is fetched
   (transactions, balances) and how long it's retained — this is both a trust and (depending on
   jurisdiction) a compliance requirement, and should be reviewed by whoever owns SmartSpend's
   privacy policy before shipping, not written solely by engineering.

### 5.6 Security considerations

- `access_token` stored encrypted at rest server-side (reuse the field-level encryption pattern
  already used for other sensitive columns per this session's earlier hardening work), never
  logged, never returned in any API response.
- Webhook endpoint must verify Plaid's JWT signature on every request (Plaid rotates signing
  keys; use their verification library rather than hand-rolling it).
- Rate-limit the new `/plaid/*` endpoints the same way auth endpoints were hardened in Phase 2
  of this remediation (per-account limits, not just per-IP).
- This introduces a new class of data breach risk (real bank transaction history, not just app
  data) — worth an explicit incident-response note in whatever runbook covers the secret-rotation
  procedure prepared in P1.2, since a Plaid access-token leak needs Plaid-side item revocation,
  not just a local secret rotation.

## 6. Effort estimate

Rough sizing, assuming Plaid sandbox keys are already available:
- Backend: Plaid SDK integration, link-token/exchange/webhook endpoints, `PlaidItem`/
  `PlaidAccount` tables + migration, `/transactions/sync` cursor-based ingestion job,
  encryption-at-rest for tokens — **~1.5–2 weeks**.
- Client: `plaid_flutter` integration, Linked Accounts screen, account-selection/matching flow,
  sync-status UI, reauth flow, unlink flow — **~1.5–2 weeks**.
- Reconciliation logic + its own test suite (this is the part most likely to have subtle bugs
  and deserves real edge-case coverage: same-amount same-day double purchases, refunds, pending
  vs. posted transaction transitions) — **~1 week**.
- End-to-end testing against Plaid sandbox institutions, plus the production-access application
  lead time (§2, largely parallelizable with the above) — **~1 week engineering + external
  lead time outside engineering's control**.

**Total: ~5–6 engineering-weeks**, the largest single item in the Phase 5 roadmap, gated on an
external dependency (§2) that has to be kicked off before engineering time is scheduled against it.
