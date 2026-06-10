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

- support@smaartspend.com
- admin@smaartspend.com
- info@smaartspend.com
- 030915, Namibia
- [APP_STORE_URL_OR_WEBSITE]

Use the values from your production/legal team before publishing to app stores.

> Note: `[ANALYTICS_PROVIDER]` / `[ANALYTICS_PRIVACY_URL]` are intentionally **not** used.
> SmartSpend ships with no third-party analytics; the policy documents state this explicitly.
> If an analytics provider is ever added, restore those placeholders and the related sections.

## Safe Replacement Workflow

1. Copy `legal/placeholders.example.env` to `legal/placeholders.env`.
2. Fill in final legal/compliance values.
3. Validate values and unresolved placeholders:
   - `scripts/apply_legal_placeholders.sh --check`
4. Apply replacements to the 8 legal markdown files:
   - `scripts/apply_legal_placeholders.sh --apply`

You can pass a custom env file with `--env <path>`.
