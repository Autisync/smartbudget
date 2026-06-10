# Action Required Tracker

**Scope:** SmartSpend legal publication readiness
**Owner:** Firmeza Consulting cc
**Last Reviewed:** 03 April 2026

---

## 1. Mandatory Placeholder Completion

| Item | Placeholder | Files | Suggested Owner | Status | Notes |
|---|---|---|---|---|---|
| Support contact email | support@smaartspend.com | TERMS_OF_USE.md, ACCEPTABLE_USE_POLICY.md, SECURITY_DISCLOSURE_POLICY.md | Operations / Support | Resolved | Use monitored inbox with SLA ownership. |
| Privacy contact email | admin@smaartspend.com | PRIVACY_POLICY.md | Privacy / Legal | Resolved | Should be a dedicated privacy mailbox. |
| DPO or privacy representative | info@smaartspend.com | PRIVACY_POLICY.md | Legal / Privacy | Resolved | Required where jurisdiction mandates DPO/representative. |
| Registered postal address | 030915, Namibia | PRIVACY_POLICY.md | Legal / Corporate | Resolved | Include full legal service address. |
| Public app legal URL | [APP_STORE_URL_OR_WEBSITE] | TERMS_OF_USE.md | Product / Legal | Open | Replace with canonical legal landing URL. |
| Analytics vendor name | (none) | PRIVACY_POLICY.md, COOKIES_AND_TRACKING_NOTICE.md, DATA_RETENTION_POLICY.md, THIRD_PARTY_SERVICES_NOTICE.md | Product / Engineering | Resolved for beta | **DECISION POINT before final (non-beta) release:** re-evaluate whether to add analytics. Options: (A) ship with none — current state; (B) Firebase Analytics (already have Firebase for FCM); (C) PostHog (privacy-first, EU/self-host); (D) Sentry (crash/error only). If any is adopted, restore the analytics sections + placeholders and add a DPA/SCC + opt-out. |
| Analytics privacy URL | (none) | COOKIES_AND_TRACKING_NOTICE.md, THIRD_PARTY_SERVICES_NOTICE.md | Product / Privacy | Resolved | N/A while no analytics provider is used. |

## 2. Jurisdiction and Transfer Validation

| Task | File(s) | Suggested Owner | Status | Notes |
|---|---|---|---|---|
| Confirm global availability and local legal overrides are acceptable | TERMS_OF_USE.md, PRIVACY_POLICY.md | External Counsel | Open | Validate enforceability and consumer-right wording by target markets. |
| Confirm cross-border transfer clauses for analytics provider | PRIVACY_POLICY.md, THIRD_PARTY_SERVICES_NOTICE.md | Privacy Counsel | Resolved | No analytics provider used; only FCM push tokens transfer, covered by Google's SCCs. |
| Confirm retention periods meet local obligations | DATA_RETENTION_POLICY.md | Security / Legal | Open | Verify against accounting, tax, and fraud retention rules. |

## 3. Product and UI Publication Tasks

| Task | Area | Suggested Owner | Status | Notes |
|---|---|---|---|---|
| Verify all legal routes load in release builds | In-app Legal Center | QA | Open | Test each route under /legal and onboarding/settings entry points. |
| Validate markdown asset bundling on iOS/Android/Web | Build pipeline | Engineering | Open | Confirm legal/*.md packaged and readable via rootBundle. |
| Ensure app store listing links match legal docs | App store metadata | Product / Legal | Open | Keep Terms and Privacy links synchronized with app content. |

## 4. Final Sign-Off Checklist

- Legal review completed by qualified counsel.
- Placeholders replaced and proofread in all legal documents.
- Product/legal URLs verified in app and app store metadata.
- Effective and last-updated dates aligned across all documents.
- Versioned legal archive retained for audit.
