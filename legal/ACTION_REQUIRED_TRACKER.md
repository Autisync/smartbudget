# Action Required Tracker

**Scope:** SmartSpend legal publication readiness
**Owner:** Firmeza Consulting cc
**Last Reviewed:** 03 April 2026

---

## 1. Mandatory Placeholder Completion

| Item | Placeholder | Files | Suggested Owner | Status | Notes |
|---|---|---|---|---|---|
| Support contact email | [SUPPORT_EMAIL] | TERMS_OF_USE.md, ACCEPTABLE_USE_POLICY.md, SECURITY_DISCLOSURE_POLICY.md | Operations / Support | Open | Use monitored inbox with SLA ownership. |
| Privacy contact email | [PRIVACY_EMAIL] | PRIVACY_POLICY.md | Privacy / Legal | Open | Should be a dedicated privacy mailbox. |
| DPO or privacy representative | [DPO_EMAIL_OR_CONTACT] | PRIVACY_POLICY.md | Legal / Privacy | Open | Required where jurisdiction mandates DPO/representative. |
| Registered postal address | [POSTAL_ADDRESS] | PRIVACY_POLICY.md | Legal / Corporate | Open | Include full legal service address. |
| Public app legal URL | [APP_STORE_URL_OR_WEBSITE] | TERMS_OF_USE.md | Product / Legal | Open | Replace with canonical legal landing URL. |
| Analytics vendor name | [ANALYTICS_PROVIDER] | PRIVACY_POLICY.md, COOKIES_AND_TRACKING_NOTICE.md, DATA_RETENTION_POLICY.md, THIRD_PARTY_SERVICES_NOTICE.md | Product / Engineering | Open | Ensure vendor naming is consistent across all files. |
| Analytics privacy URL | [ANALYTICS_PRIVACY_URL] | COOKIES_AND_TRACKING_NOTICE.md, THIRD_PARTY_SERVICES_NOTICE.md | Product / Privacy | Open | Must be exact policy page URL. |

## 2. Jurisdiction and Transfer Validation

| Task | File(s) | Suggested Owner | Status | Notes |
|---|---|---|---|---|
| Confirm global availability and local legal overrides are acceptable | TERMS_OF_USE.md, PRIVACY_POLICY.md | External Counsel | Open | Validate enforceability and consumer-right wording by target markets. |
| Confirm cross-border transfer clauses for analytics provider | PRIVACY_POLICY.md, THIRD_PARTY_SERVICES_NOTICE.md | Privacy Counsel | Open | Add SCC/IDTA references if needed per destination. |
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
