# SmartSpend Legal Documents

This directory contains the legal documents that are displayed in-app.

## Included Documents

- TERMS_OF_USE.md
- PRIVACY_POLICY.md
- COOKIES_AND_TRACKING_NOTICE.md
- ACCEPTABLE_USE_POLICY.md
- DATA_RETENTION_POLICY.md
- SECURITY_DISCLOSURE_POLICY.md
- THIRD_PARTY_SERVICES_NOTICE.md
- DISCLAIMERS.md

## Placeholder Values To Replace Before Publication

- [SUPPORT_EMAIL]
- [PRIVACY_EMAIL]
- [DPO_EMAIL_OR_CONTACT]
- [POSTAL_ADDRESS]
- [APP_STORE_URL_OR_WEBSITE]
- [ANALYTICS_PROVIDER]
- [ANALYTICS_PRIVACY_URL]

Use the values from your production/legal team before publishing to app stores.

## Safe Replacement Workflow

1. Copy `legal/placeholders.example.env` to `legal/placeholders.env`.
2. Fill in final legal/compliance values.
3. Validate values and unresolved placeholders:
   - `scripts/apply_legal_placeholders.sh --check`
4. Apply replacements to the 8 legal markdown files:
   - `scripts/apply_legal_placeholders.sh --apply`

You can pass a custom env file with `--env <path>`.
