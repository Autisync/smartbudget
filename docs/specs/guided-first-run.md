# Spec: Guided First Run

Status: **design only — not implemented, not scheduled**
Owner: unassigned
Depends on: nothing — pure client-side UX work over existing screens/flows.

## 1. Problem

`lib/features/onboarding/presentation/screens/onboarding_screen.dart` (1095 lines) is a
3-slide illustrated `PageView` tour (spending tracking, insights, security) with Skip and
"Get Started" buttons. It's entirely passive — no slide is interactive, nothing in it is
connected to real app state, and `_finish()` sends the user straight to `/login` regardless of
which path they took through it. A new user who taps through the tour, signs up, and lands on
the dashboard has seen three marketing slides and nothing that taught them how to actually use
the app. The dashboard does have an `AppEmptyState` for the zero-transactions case
(`dashboard_screen.dart:451`), but it's a static empty state, not a guided next step.

Worth noting as existing groundwork: the app already auto-seeds three default accounts (Cash,
Bank Transfer, Credit Card) on first boot via `ensureDefaultAccounts` (`main.dart`), so a brand
-new user already has *accounts* to act on — they're just never told to.

## 2. Two options, as posed by the roadmap item

### Option A — Turn the tour into a real CTA (deep-link into a first action)

Replace (or append to) the passive tour with a guided first action: after signup, instead of
landing on an empty dashboard, the user is walked directly into "Add your first transaction" or
"Create your first budget" with a lightweight spotlight/tooltip overlay pointing at the relevant
button, and the flow doesn't consider first-run "done" until they've either completed that action
or explicitly dismissed the prompt.

**Pros**: teaches real usage immediately, using real data from the first interaction — no
cleanup step, no confusion about what's "real." **Cons**: more implementation surface (needs a
spotlight/overlay component that doesn't exist yet, and has to work across whichever screen the
CTA points to); a small risk of feeling pushy if not dismissible cleanly.

### Option B — A clearly-marked, removable sample budget

Seed one obviously-fake budget (e.g. "Sample: Coffee Budget," a small pre-filled category with a
couple of illustrative transactions) at signup, visually marked as a sample (a persistent badge/
banner, not just a name prefix a user might miss) with a prominent one-tap "Remove sample data"
action.

**Pros**: lets a cautious user explore the UI risk-free before committing real data; simpler to
build (reuses existing budget/transaction creation code paths, just called programmatically with
canned data instead of user input). **Cons**: real risk of the sample data being forgotten and
mistaken for real data later (mitigated only by however good the "clearly marked" visual
treatment actually is, which is doing a lot of the safety work); adds a "delete sample data"
edge case to account/budget deletion logic that has to be gotten right (e.g. what happens if a
user edits the sample budget instead of removing it — does it silently become a real one?).

## 3. Recommendation: Option A, with a light-touch fallback to B's spirit

Recommend **Option A** as the primary mechanism: a guided CTA that deep-links into a real first
action is more valuable (teaches the actual product) and avoids Option B's central risk (fake
data being mistaken for real data — a genuinely bad experience for a *finance* app specifically,
where "wait, is this $340 real?" is a worse moment of confusion than in a to-do-list app). Given
accounts are already auto-seeded, Option A's minimum viable version is small: point the user at
"Add your first transaction" against their existing default Cash account, not a full guided tour
of every feature.

Option B's underlying idea — let a hesitant user see the app "working" before committing — is
worth preserving in a lighter form: the dashboard's existing empty state can show a **static,
clearly-labeled illustrative preview** (a greyed-out/watermarked mock chart showing "this is what
your spending trends will look like") rather than actual seeded, deletable fake data — same
"show, don't just tell" value as Option B, none of the real-vs-fake data confusion risk, and it's
just a visual treatment on the existing empty state rather than new seed-data lifecycle logic.

## 4. Proposed flow (Option A)

1. On first successful login/signup (gated on `OnboardingService`'s existing
   `onboarding_complete` flag — reuse, don't duplicate, the tracking this session's P3.4 work
   already hardened against surviving uninstall incorrectly), route to the dashboard as today,
   but with a one-time guided-CTA state active.
2. Dashboard renders its existing `AppEmptyState` (`dashboard_screen.dart:451`), upgraded with a
   primary action wired to open Add Transaction directly (today's empty state likely already has
   *some* CTA button — confirm and reuse its exact styling/placement rather than adding a second,
   competing call-to-action element) plus a **spotlight overlay** (new component: a
   semi-transparent scrim with a cutout highlighting the CTA button, one line of guidance text —
   "Log your first expense to see your budget come to life") that appears once, dismissible by
   tapping anywhere or completing the action.
3. Once a first transaction exists, the guided state ends permanently (persisted via
   `OnboardingService`, a new `_keyFirstActionComplete`-style flag alongside its existing keys) —
   no re-prompting on subsequent empty states (e.g. after the user later deletes all their
   transactions, don't re-trigger the tutorial spotlight, that would be patronizing to a returning
   user; a plain empty state without the overlay is the correct treatment there).
4. Optional second nudge (not required for v1, worth flagging as a natural follow-up): once the
   user has logged a transaction or two, a similar one-time spotlight on "Create your first
   budget" from the Budgets tab, using the same overlay component.

## 5. Effort estimate

- Spotlight/overlay component (scrim + cutout + positioned tooltip, dismissible, one-shot) —
  **~2-3 days**. This is the one new piece of UI infrastructure this spec needs; everything else
  wires into screens that already exist.
- Wiring into dashboard empty state + first-transaction-complete tracking via
  `OnboardingService` — **~1-2 days**.
- Illustrative-preview treatment for the "show, don't just tell" empty-state upgrade (§3) —
  **~1 day**.
- Tests (onboarding flag persistence across the guided state, spotlight dismissal, no re-trigger
  after data is later cleared) — **~1 day**.

**Total: ~1-1.5 weeks.** Comparable in size to `recurring-transaction-detection.md`; smaller than
every other Phase 5 item except `budget-savings-trend-charts.md`.
