# SmartBudget — Beta Release Notes

**Build:** 1.0.0 (beta) · **Date:** 17 Jun 2026

Thanks for testing SmartBudget! This build is a big stability + polish pass. Below is what's new and what we fixed. Please report anything odd (steps to reproduce + a screenshot help a lot).

---

## ✨ What's new

- **Refreshed, consistent design.** A unified color system across the app — income green, expense red, and status colors now match everywhere (Dashboard, Transactions, Budgets, Savings, Subscriptions, Accounts, Balance Sheet). The Home balance card has a bold new look and the spending trend line now reflects your **real** balance history.
- **Simpler navigation.** The bottom bar is now four focused tabs — **Home, Transactions, Savings, More**. Budgets and Subscriptions moved into **More** to reduce clutter. Tap **+** to quickly add a transaction, subscription, savings goal, or budget.
- **Full multi-language support.** The app is now fully translated across **English, Spanish, French, German, and Portuguese** — including insights, reports, scenario lab, settings, and all cards.
- **Redesigned email templates.** Verification, password-reset, welcome, and alert emails have a new branded design with the SmartBudget logo and a working **Verify / action button**.
- **Cleaner Settings.** Notifications are now a single master toggle (with per-category switches), and the Settings screen got a tidier layout.

---

## 🛠️ What we fixed

**Crashes & stability**
- Fixed the **"Something went wrong"** red error screen that could appear after signing in or signing up.
- Fixed an intermittent crash/blank screen (the `_dependents.isEmpty` / duplicate-key error) that could occur "from time to time" — caused by the app rebuilding its navigation on session changes.
- Fixed a crash when tapping **Resend verification email**.

**Email & verification**
- **Verification and reset emails now actually send and arrive.** (The server wasn't configured to send mail in the background — now fixed.)
- The **Verify Email button in emails is now clickable** (previously only the fallback link worked).
- **Add Subscription** is now reachable — it was previously missing an entry point.
- The **"Resend email" limit (once per hour)** is now shown clearly with a countdown, instead of failing silently.

**Polish**
- Toast/snackbar messages **stay on screen long enough to read** (no longer vanish in ~1 second).
- The **Savings** list and other screens no longer hide content behind the bottom navigation bar.
- Insight/summary cards are tighter with less wasted space.
- Removed a few misleading elements (e.g., the Balance Sheet shortcut no longer looks like an error, and a fake trend chart was replaced with real data).

---

## 🧪 How you can help

- Try **sign up → verify email → sign in** and confirm the verification email arrives and the button works.
- Switch the app **language** (Settings) and look for any untranslated text.
- Add/edit **transactions, budgets, savings goals, subscriptions** and watch for visual glitches or crashes.
- Use the app across a session (leave it open a while) and report any unexpected error screens.

## ⚠️ Known / in progress

- Push notifications require Firebase setup and may not fire yet in beta.
- A couple of system biometric prompts and the onboarding tour may still show English in non-English locales.
- If a verification email still doesn't arrive, check spam and let us know your email provider.

Questions or bugs? **support@smaartspend.com**
