# Cookies and Tracking Notice

**App:** SmartSpend
**Operator:** Firmeza Consulting cc
**Effective Date:** 05 April 2026
**Last Updated:** 05 April 2026

---

## 1. Overview

SmartSpend is a native mobile application. It does not use browser cookies. This Notice
describes the equivalent tracking technologies used on mobile platforms, including the analytics
SDK we have implemented to improve the App experience.

## 2. Technologies We Use

### 2.1 Local Device Storage (SQLite / Drift) - Essential

Your financial data and application state are stored in an encrypted local database on your
device. This is functionally equivalent to "strictly necessary" local storage: it is essential
to App operation and does not track you across apps or websites.

**Consent required:** No - necessary for service operation.

### 2.2 OS Secure Storage (Keychain / Keystore) - Essential

Authentication tokens, encryption keys, and preference flags are stored in OS-isolated secure
storage. Inaccessible to other apps.

**Consent required:** No - essential to App security.

### 2.3 JWT Session Tokens (Backend Mode) - Essential

Access and refresh tokens issued by the optional backend are stored in secure storage. These
manage your authenticated session and expire per configured TTLs. Token rotation and revocation
are implemented.

**Consent required:** No - necessary for authenticated service.

### 2.4 In-App Notification Storage - Functional

Notification entries (title, body, category, read status, timestamp) are stored locally for
the in-app inbox. No cross-device or cross-app tracking occurs.

**Consent required:** No - functional to the App feature.

### 2.5 Analytics SDK - [ANALYTICS_PROVIDER]

We use [ANALYTICS_PROVIDER] to collect pseudonymous usage analytics. Data collected includes
app screens visited, feature interactions (excluding any financial content), session information,
device type, OS version, app version, error events, and country-level location.

**Financial data, transaction details, and account balances are never sent to the analytics
provider.**

Analytics events are associated with a pseudonymous device identifier, not your name or email.

**Consent:** Where required by applicable law (e.g., EU ePrivacy Directive, national
implementations), we will request your consent before activating analytics. You may opt out
at any time via **Settings > Privacy > Analytics** within the App. Opt-out prevents further
event collection; previously collected pseudonymous data is handled per [ANALYTICS_PROVIDER]'s
retention policy.

**Provider privacy policy:** [ANALYTICS_PRIVACY_URL]

### 2.6 Exchange-Rate API Calls - Functional (Feature-Dependent)

Currency conversion requests send currency pair codes and standard network metadata (IP address
in transit) to third-party exchange-rate APIs. We do not control whether those providers log
this data. See Third-Party Services Notice. All returned data is displayed with a "for
reference only" label in the App.

**Consent required:** No - incidental to a user-initiated feature request.

### 2.7 Technologies Not Used

As of 05 April 2026, SmartSpend does not use:

- Browser cookies of any kind;
- Advertising identifiers (IDFA / GAID) or ad networks;
- Cross-app or cross-site behavioural tracking beyond the analytics SDK described above;
- Fingerprinting techniques;
- Third-party social media trackers or pixels.

## 3. Local Notifications

Notifications for budgets, savings alerts, and health checks are generated entirely on-device
using the OS local notification system. No data is transmitted to remote servers for local
notification delivery. Notification permission can be revoked at any time in device Settings.

## 4. Your Choices

| Technology | How to Control |
|---|---|
| Local database / secure storage | Uninstall the App |
| Session tokens | Log out (tokens are revoked on the backend) |
| Analytics | Settings > Privacy > Analytics - toggle off at any time |
| Local notifications | Device OS Settings > Notifications |
| Exchange-rate API calls | Do not use currency conversion features |

## 5. Changes to This Notice

We will update this Notice when we introduce new tracking technologies or material changes to
existing ones. Material changes will be communicated as described in our Privacy Policy.

## 6. Contact

[PRIVACY_EMAIL]
