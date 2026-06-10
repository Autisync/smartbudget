# Third-Party Services Notice

**App:** SmartSpend
**Operator:** Firmeza Consulting cc
**Effective Date:** 05 April 2026
**Last Updated:** 10 June 2026

---

## 1. Purpose

This Notice identifies third-party services and infrastructure providers that SmartSpend
integrates with or relies upon, explains what data is shared with them, and clarifies the
boundary of Firmeza Consulting cc's responsibility. SmartSpend is available worldwide; this
Notice applies to all users regardless of country of residence.

## 2. Responsibility Boundaries

Firmeza Consulting cc is responsible for our own systems and the data flows we control. We are
**not responsible** for the data practices, availability, accuracy, or security of third-party
services. Each third party operates under its own terms of service and privacy policy. We
maintain data processing agreements with sub-processors for any personal data shared.

## 3. Infrastructure and Managed Services

### 3.1 Autisync - Database, Backend, Hosting, and Email Management

| Item | Detail |
|---|---|
| **Provider** | Autisync |
| **Role** | Management of backend database (PostgreSQL), application hosting (FastAPI), Redis cache, and email delivery infrastructure |
| **Data processed** | Account data (email, name, password hash), session records, authentication tokens, transactional email content (verification/reset links) |
| **Data location** | Hetzner Online GmbH servers, Germany (EU) |
| **Sub-processor status** | Data Processing Agreement in place; processes data only on Firmeza Consulting cc's instructions |
| **GDPR role** | Data Processor |

### 3.2 Hetzner Online GmbH - Server Infrastructure

| Item | Detail |
|---|---|
| **Provider** | Hetzner Online GmbH, Industriestr. 25, 91710 Gunzenhausen, Germany |
| **Role** | Physical and virtual server infrastructure on which the backend is hosted via Autisync |
| **Data processed** | Backend data at rest on server storage; network traffic |
| **Data location** | Germany (EU) - within GDPR jurisdiction |
| **Privacy policy** | https://www.hetzner.com/legal/privacy-policy |
| **GDPR role** | Sub-processor under Autisync's arrangements; Hetzner operates under its own DPA with Autisync |

All backend personal data of SmartSpend users is processed exclusively within the European
Union on Hetzner infrastructure.

## 4. Analytics

SmartSpend uses **no third-party analytics provider**. No analytics SDK is embedded in the App,
and no usage, telemetry, session, device, crash, or pseudonymous event data is collected or sent
to any third party. In-app reports and insights are computed locally on your device.

## 4a. Push Notifications - Google Firebase Cloud Messaging (FCM)

| Item | Detail |
|---|---|
| **Provider** | Google Firebase Cloud Messaging |
| **Purpose** | Delivery of remote push notifications (only if you enable notifications) |
| **Data sent** | An opaque device push token; the notification payload we send |
| **Financial data sent** | **None** |
| **Opt-out** | Disable notifications in device Settings or in-app Settings > Notifications |

## 5. Exchange-Rate Data Providers

All exchange-rate data displayed in the App is labelled **"for reference only"** and is
retrieved via a fallback chain - primary provider first, falling to secondary and tertiary
providers on failure. This chain is designed to minimise disruption from individual provider
outages; however, data accuracy and availability are not guaranteed. **Do not rely on App
exchange-rate data for commercial transactions or financial instruments.**

### 5.1 ExchangeRate-API (Primary - when API key configured)

| Item | Detail |
|---|---|
| **Provider** | ExchangeRate-API Ltd |
| **Purpose** | Currency exchange rate lookups |
| **Data sent** | Currency pair codes; standard HTTP metadata (IP address in transit) |
| **Privacy policy** | https://www.exchangerate-api.com/privacy |

### 5.2 Open ER API (Secondary fallback)

| Item | Detail |
|---|---|
| **Provider** | Open ER API |
| **Purpose** | Fallback exchange rate data |
| **Data sent** | Currency pair codes; standard HTTP metadata |
| **Notes** | Review current terms and privacy policy at provider's website |

### 5.3 Frankfurter / European Central Bank (Tertiary fallback)

| Item | Detail |
|---|---|
| **Provider** | Frankfurter API (frankfurter.app) - ECB reference rate proxy |
| **Purpose** | Tertiary fallback for exchange rate data |
| **Data sent** | Currency pair codes; standard HTTP metadata |
| **Notes** | ECB data reflects end-of-business reference rates; not real-time market rates |

## 6. Operating System APIs

### 6.1 Biometric Authentication

| Item | Detail |
|---|---|
| **Providers** | Apple Inc. (iOS Face ID / Touch ID); Google LLC / device manufacturers (Android Biometric API) |
| **Data shared** | **None.** App receives only a pass/fail result from the OS. No biometric data is transmitted or stored by the App. |

### 6.2 OS Secure Storage

| Item | Detail |
|---|---|
| **Providers** | Apple Inc. (iOS Keychain); Google LLC / device manufacturers (Android Keystore) |
| **Notes** | App data in secure storage is isolated to the App sandbox. OS cloud backup settings may cause secure storage data to be included in cloud backups - manage via device settings. |

### 6.3 Local Notifications

| Item | Detail |
|---|---|
| **Providers** | Apple Inc. (iOS); Android OS |
| **Data shared** | None - notifications are generated on-device; no data sent to Apple or Google for local notification delivery |

### 6.4 OS Share Sheet

| Item | Detail |
|---|---|
| **Providers** | Device OS and user-selected receiving app |
| **Notes** | Exported PDF/CSV files passed to the receiving app are outside our control from point of share |

## 7. Changes to Third-Party Integrations

This Notice will be updated when we add, remove, or materially change third-party integrations.
Material changes communicated per Privacy Policy §13.

## 8. Contact

admin@smaartspend.com
