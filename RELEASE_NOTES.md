# SmartSpend — Release Notes

**Build:** 1.0.0 · **Date:** 18 Jun 2026

A stability and polish release focused on sign-in, email verification, and offline use.

## ✨ New
- **Works offline.** The app now keeps you signed in and usable without a connection — it no longer logs you out or gets stuck loading when the network is slow.
- **Email verification just works.** Tapping the verify link now confirms your email instantly from any device (phone or computer) — no need to open the app first.

## 🛠️ Fixed
- Fixed the **"Something went wrong"** screen that could appear after the app was already running.
- Fixed the app getting **stuck on the "Getting things ready…" splash** on flaky connections.
- **Resend verification email** now allows up to **3 sends per hour**, one minute apart, with a clear countdown.
- Corrected a **money-rounding** edge case so amounts ending in half a cent round up correctly.
- Polished wording and consistency across the app and emails (now uniformly **SmartSpend**).

## 🧪 Please test
- Sign up → verify your email → sign in.
- Use the app with your connection off, then back on.
- Switch languages and look for any untranslated text.

Questions or bugs? **support@smaartspend.com**
