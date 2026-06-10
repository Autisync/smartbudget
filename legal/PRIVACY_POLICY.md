# Privacy Policy

**App:** SmartSpend
**Data Controller:** Firmeza Consulting cc, [POSTAL_ADDRESS], Republic of Namibia
**Effective Date:** 05 April 2026
**Last Updated:** 10 June 2026
**Privacy Contact:** [PRIVACY_EMAIL]
**Data Protection Officer / Representative:** [DPO_EMAIL_OR_CONTACT]

---

## 1. Introduction and Scope

This Privacy Policy explains how Firmeza Consulting cc ("we," "us," "our") processes personal
data when you use the SmartSpend mobile application ("App"). It applies to:

- Data processed entirely on your device (local-first mode);
- Data processed by our optional backend authentication service when you create an account;
- Data incidentally processed when you use third-party integrations or OS-level features; and
- Data collected via analytics.

SmartSpend is available worldwide. This Policy applies to all users regardless of country of
residence. We have designed our data practices to meet the requirements of the EU General Data
Protection Regulation (GDPR), UK GDPR, Brazil's Lei Geral de Protecao de Dados (LGPD), and
California Consumer Privacy Act (CCPA)/CPRA as high-water marks, providing protections
applicable globally. Where your local law grants greater rights, we will honour them.

## 2. Data Controller and Sub-Processor Roles

2.1 **Controller.** Firmeza Consulting cc is the data controller for personal data processed
via the optional backend service (account credentials, session metadata) and analytics data.

2.2 **Local device data.** Financial and preference data stored exclusively on your device
within the App's local encrypted database is under your own control. Firmeza Consulting cc acts
as a software provider with respect to locally stored financial data, and does not routinely
access it.

2.3 **Sub-processors.** We engage the following key sub-processors who act on our instructions:

| Sub-Processor | Role | Data Location |
|---|---|---|
| **Autisync** | Database management, backend hosting, email delivery infrastructure | Hetzner servers, Germany (EU) |
| **Hetzner Online GmbH** | Physical server infrastructure | Germany (EU) |
| **[ANALYTICS_PROVIDER]** | App analytics | [ACTION REQUIRED: confirm data location] |

All sub-processors are bound by data processing agreements requiring GDPR-compliant processing.

## 3. What Data We Collect and Why

### 3.1 Backend Account Data (Optional - When Account is Created)

| Data Element | Purpose | Legal Basis (GDPR Art. 6) |
|---|---|---|
| Email address | Account creation, email verification, password reset, transactional comms | Art. 6(1)(b) - contract performance |
| First name, last name | Account identification | Art. 6(1)(b) - contract performance |
| Password (Argon2 hash only - never stored in plaintext) | Authentication security | Art. 6(1)(b); Art. 6(1)(c) - legal obligation (security) |
| Email verification status | Fraud prevention, account integrity | Art. 6(1)(f) - legitimate interest |

We do **not** collect payment card details, bank account numbers, national identity numbers, or
any government-issued document information.

### 3.2 Data Stored Locally on Your Device

The following data is stored in the App's local encrypted database on your device. It does not
leave your device unless you explicitly export or share it:

- **Transactions:** amount, currency, category, date, notes, recurrence metadata, account association, timestamps.
- **Accounts:** name, type, balance, currency.
- **Budgets:** category, limit amounts, alert thresholds, periods, date ranges.
- **Savings goals:** title, target and saved amounts, deadlines, priority, auto-allocation settings.
- **Subscriptions:** name, description, amount, billing cycle, payment method label, website (URL), importance, active status, timestamps.
- **Security settings:** session timeout preferences, biometric and PIN enable flags, lockout configuration.
- **Local auth logs:** device ID, authentication type and status, timestamps; IP address and user agent are optional fields populated only if technically available on the device.
- **In-app notifications:** title, body, category, read status, timestamp.

**Biometric data:** The App uses OS-level biometric APIs (e.g., Face ID, fingerprint) for local
unlock decisions only. **We do not store, access, or transmit biometric templates or biometric
data of any kind.** All matching is performed exclusively by your device's operating system.

### 3.3 Data in OS Secure Storage

Certain sensitive values are stored in your device's OS secure storage (iOS Keychain / Android
Keystore), isolated to the App's sandbox:

- Authentication tokens (access and refresh tokens, JSON format).
- Biometric preference flags and last authentication timestamp.
- Legal/onboarding acceptance flags.
- Theme, locale, currency, and other user preferences.
- Encryption key material for the local database encryption service.

### 3.4 Analytics Data

We use [ANALYTICS_PROVIDER] to collect aggregated usage analytics to understand how the App is
used and to improve it. Analytics data collected may include:

- App screens visited and feature interactions (without content of financial entries);
- Session duration and frequency;
- Device type and operating system version;
- App version and crash/error events;
- General geographic region (country level, not precise location).

**We do not pass financial data, transaction details, account balances, or any sensitive
financial content to any analytics provider.** Analytics data is collected under a pseudonymous
identifier and is not linked to your name or email address. You may opt out of analytics
collection at any time via Settings > Privacy > Analytics within the App.

**Legal basis:** Art. 6(1)(f) GDPR - legitimate interest in improving App quality. Where
consent is required by applicable law (e.g., ePrivacy Directive for tracking), consent will be
sought before analytics activation.

### 3.5 Exchange-Rate Lookups

When you use currency conversion features, the App contacts third-party exchange-rate APIs
(ExchangeRate-API, Open ER API, or Frankfurter/ECB). These requests include currency pair
identifiers and standard network metadata (IP address in transit). All exchange-rate data
displayed in the App is labelled "for reference only." See Third-Party Services Notice.

### 3.6 Automatically Collected Technical Data (Backend)

When you use the optional backend, we or our infrastructure providers may automatically log:

- IP address (for security and rate-limiting);
- Device name and platform (stored in session records for session management);
- Timestamps of authentication events;
- HTTP request metadata necessary for service operation.

### 3.7 Push Notifications (Firebase Cloud Messaging)

If you enable push notifications, the App registers with Google Firebase Cloud
Messaging (FCM) to deliver remote alerts (for example, security or billing
notices). For this purpose:

- A **device push token** (an opaque identifier issued by FCM/Apple Push
  Notification service) is generated and may be transmitted to our backend so
  we can address notifications to your device. The token does not contain your
  name, email, or any financial data.
- On Android 13+ and iOS, the operating system asks for your permission before
  any notification is shown; you can revoke this at any time in your device
  settings or in **Settings > Notifications** within the App.
- **Local (on-device) notifications** — budget alerts, savings nudges, and
  similar reminders — are generated entirely on your device and are **not**
  transmitted to us or to Google.

Google Firebase acts as a processor for push delivery. See the Third-Party
Services Notice. **Legal basis:** Art. 6(1)(a) GDPR — consent (you opt in by
enabling notifications).

### 3.8 Social Sign-In (Optional)

If you choose to sign in with Google or Apple, the respective provider returns a
signed identity token from which we read your **email address and, where
available, your first/last name** solely to create or match your account. We do
not receive your social-account password. Apple's "Hide My Email" relay
addresses are supported. **Legal basis:** Art. 6(1)(b) GDPR — contract
performance.

### 3.9 Data We Do Not Collect

We do not collect: raw biometric data; bank account or card numbers; Social Security, tax
identification, or national identity numbers; health or medical data; precise geolocation;
advertising identifiers; or financial transaction data from your bank or payment provider.

## 4. Legal Bases for Processing

For users in the EU/EEA, UK, and jurisdictions with equivalent requirements:

| Processing Activity | Legal Basis |
|---|---|
| Account creation and management | Art. 6(1)(b) - contract performance |
| Email verification and password reset | Art. 6(1)(b) - contract performance |
| Session management and security | Art. 6(1)(f) - legitimate interest in platform security |
| Exchange-rate API calls | Art. 6(1)(b) - necessary for requested feature |
| Analytics (pseudonymous) | Art. 6(1)(f) - legitimate interest in App improvement |
| Legal compliance obligations | Art. 6(1)(c) - legal obligation |

Where we rely on legitimate interests, you have the right to object at any time (see Section 9).

## 5. How We Use Personal Data

We use collected data strictly for:

- Providing and maintaining App functionality;
- Authenticating users and managing secure sessions;
- Sending transactional emails (verification, password reset, account deletion confirmation) - no marketing emails without separate explicit consent;
- Detecting and preventing fraudulent, abusive, or unauthorized use;
- Analytics and App improvement (pseudonymous, aggregated);
- Complying with legal obligations.

We do **not** sell, rent, or trade your personal data. We do not use your financial data for
targeted advertising.

## 6. Data Sharing and Disclosure

We share personal data only in the following circumstances:

6.1 **Sub-processors.** Data is shared with Autisync (database management, hosting, email
delivery) and Hetzner Online GmbH (server infrastructure) under binding data processing
agreements. All processing occurs on Hetzner servers located in Germany (EU). Analytics data
is shared with [ANALYTICS_PROVIDER] under a data processing agreement.

6.2 **Exchange-rate providers.** Currency lookup requests are sent to third-party APIs. See
Third-Party Services Notice.

6.3 **Legal compliance.** We may disclose data when required by applicable law, court order,
or governmental authority. We will notify you to the extent permitted by law.

6.4 **Business transfers.** In the event of a merger, acquisition, or asset sale, personal
data may transfer to a successor entity subject to equivalent protections. We will provide
advance notice.

6.5 **Your consent.** We may share data for other purposes only with your explicit prior
consent.

## 7. International Data Transfers

7.1 Firmeza Consulting cc is established in the Republic of Namibia. All backend data
processing occurs on Hetzner servers located in Germany, within the European Union.

7.2 **EU/EEA and UK users:** Data is processed within the EU (Germany). No transfer to a
third country occurs for backend data. This means EU/EEA users' data is processed within an
adequate-protection jurisdiction.

7.3 **Transfer from Namibia to EU servers:** Processing on EU-based infrastructure by a
Namibia-registered controller does not constitute a restricted transfer under GDPR; the EU
servers provide a higher protection standard.

7.4 **Analytics provider transfers:** Where [ANALYTICS_PROVIDER] processes data outside the
EU, we rely on Standard Contractual Clauses (SCCs - European Commission Decision 2021/914,
Module 1 Controller-to-Controller or Module 2 Controller-to-Processor as applicable) or
equivalent safeguards. [ACTION REQUIRED: confirm analytics provider data location and insert
applicable SCC module reference.]

7.5 You may request a copy of applicable transfer safeguards by contacting [PRIVACY_EMAIL].

## 8. Data Retention

Please refer to our Data Retention Policy for full schedules. In summary:

- **Backend account data:** Retained while your account is active and for 30 days following
  confirmed account deletion.
- **Auth sessions:** Active until expiry or revocation; revoked session records retained 90
  days for security audit, then purged.
- **Local device data:** Remains on your device under your control. Uninstalling the App
  removes this data (subject to OS backup behaviour outside our control).
- **Password reset / verification tokens:** Deleted on use or TTL expiry.
- **Analytics data:** Retained in pseudonymous/aggregated form per [ANALYTICS_PROVIDER]'s
  retention settings; raw event data deleted after [ACTION REQUIRED: confirm retention period
  with analytics provider].
- **Exchange-rate query data:** Not retained by us; third-party providers' own policies apply.

## 9. Your Rights

Depending on your jurisdiction, you may have the following rights. We will respond to verified
requests within timeframes required by applicable law (GDPR: 30 days, extendable by 60 days
for complex requests; LGPD: 15 days; CCPA: 45 days):

| Right | Description |
|---|---|
| **Access** | Request a copy of personal data we hold about you |
| **Rectification** | Request correction of inaccurate or incomplete data |
| **Erasure** | Request deletion, subject to legal retention obligations |
| **Restriction** | Request limited processing in certain circumstances |
| **Portability** | Receive your data in a structured, machine-readable format |
| **Objection** | Object to processing based on legitimate interests |
| **Withdraw consent** | Where processing is consent-based, withdraw at any time |
| **Opt out of analytics** | Opt out via App Settings > Privacy > Analytics |
| **Complaint** | File a complaint with your local supervisory authority |

9.1 **Identity verification.** We will verify your identity before processing rights requests
using email verification or account confirmation. We will not require disproportionate
information.

9.2 **Account deletion.** To delete your account and all associated backend data, email
[PRIVACY_EMAIL] with subject line "Account Deletion Request - [your registered email address]."
We will confirm receipt within 2 business days and complete deletion within 30 calendar days.
You will receive a confirmation email when deletion is complete. See Section 12 for what
happens to data after deletion.

9.3 **CCPA rights.** California residents may exercise rights to know, delete, correct, and
opt out of sale/sharing. We do not sell personal information.

9.4 **LGPD rights.** Brazilian residents may exercise rights under LGPD Art. 18.

To exercise any right: [PRIVACY_EMAIL] - subject line "Privacy Rights Request."

## 10. Security

We implement technical and organisational security measures appropriate to the nature and
sensitivity of the data, including:

- Argon2 password hashing;
- JWT access and refresh tokens with rotation, revocation, and configurable TTLs;
- OS secure storage (Keychain/Keystore) for sensitive client-side values;
- Local database encryption with key material in OS secure storage;
- Authentication endpoint rate-limiting;
- Email verification and single-use token flows with TTL enforcement;
- EU-based server infrastructure (Hetzner, Germany) with physical and logical security controls.

**We cannot guarantee absolute security.** Please refer to our Security Disclosure Policy.

## 11. Production Logging Controls

Dev-mode logging of email content (including password-reset or verification links) is disabled
in all production deployments. No password-reset tokens, verification links, or email content
are written to persistent application logs in production. [ACTION REQUIRED: Engineering to
confirm ENG-1 from checklist is complete before launch.]

## 12. No Minimum Age Policy

We do not impose a universal minimum age. You are responsible for ensuring your use of the App
complies with any age-related requirements in your country. Where local law requires parental
consent for minors to use digital services, the parent or guardian is responsible for providing
that consent and accepting these Terms on the minor's behalf. We do not knowingly collect
personal data from persons who lack legal capacity under applicable law; if we become aware of
such data, we will delete it promptly.

## 13. Changes to This Policy

We will notify you of material changes via in-app notification, email (if registered), or
notice at [APP_STORE_URL_OR_WEBSITE] at least 14 days before changes take effect.

## 14. Contact and Complaints

**Privacy inquiries / rights requests:** [PRIVACY_EMAIL]
**Data Protection contact:** [DPO_EMAIL_OR_CONTACT]
**Postal address:** [POSTAL_ADDRESS], Republic of Namibia

**Supervisory authority complaints:**
- EU/EEA users: your national data protection authority, or the Bundesbeauftragter fur den
  Datenschutz und die Informationsfreiheit (BfDI), Germany, given our server location.
- UK users: Information Commissioner's Office (ico.org.uk).
- Brazilian users: Autoridade Nacional de Protecao de Dados (ANPD).
- California users: California Privacy Protection Agency (CPPA).
- All other users: your applicable local authority.
