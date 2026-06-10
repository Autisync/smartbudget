# Data Retention Policy

**App:** SmartSpend
**Operator:** Firmeza Consulting cc
**Effective Date:** 05 April 2026
**Last Updated:** 10 June 2026

---

## 1. Purpose and Scope

This Policy describes how long Firmeza Consulting cc retains personal data collected via
SmartSpend, the rationale for each retention period, and deletion procedures. It covers:

1. Data retained by our optional backend authentication service (hosted by Autisync on Hetzner
   servers, Germany); and
2. Data stored on your device (under your primary control).

All backend data is stored within the European Union. This Policy should be read alongside the
Privacy Policy.

## 2. Principles

We retain personal data only as long as necessary for the purpose it was collected, to comply
with legal obligations, or to defend against legal claims. Retention periods are reviewed
annually.

## 3. Backend Service Data

### 3.1 Account Data

| Data | Retention Period | Basis | Deletion Method |
|---|---|---|---|
| Email address | Active account + 30 days post-confirmed deletion | Contract | Database purge; email delivery logs purged per log policy |
| First name, last name | Active account + 30 days | Contract | Database purge |
| Password hash (Argon2) | Active account + 30 days | Security | Database purge - hash is not reversible |
| Email verification / active flags | Active account | Contract | Purge with account |

The 30-day post-deletion window allows recovery of accidentally submitted deletion requests and
satisfies short-form legal audit requirements. No financial content is retained after deletion.

### 3.2 Authentication Sessions

| Data | Retention Period | Basis | Deletion Method |
|---|---|---|---|
| Active session records | Until session expiry or revocation + 90 days | Security audit | Automated purge after 90-day window |
| Revoked session records | 90 days from revocation | Security audit | Automated purge |
| Failed login attempt data | 90 days | Security; rate-limiting | Automated purge |

### 3.3 Email Transactional Tokens

| Token Type | Retention | Deletion Method |
|---|---|---|
| Password reset tokens | Per configured TTL (typically 1-24 hours) + immediate deletion on use | Automated - deleted on use or TTL expiry |
| Email verification tokens | Per configured TTL + immediate deletion on use | Automated - deleted on use or TTL expiry |

**Production logging controls:** Dev-mode logging of email content is disabled in production.
No token values or reset links are written to persistent logs.

### 3.4 Analytics Data

SmartSpend does not use any third-party analytics service and collects no usage, telemetry, or
pseudonymous event data. There is therefore no analytics data to retain.

### 3.5 Infrastructure and Application Logs (Autisync / Hetzner)

| Log Type | Retention | Notes |
|---|---|---|
| HTTP access logs (IP, endpoint, status) | 90 days | Security monitoring; shared only as required by law |
| Application error logs | 30 days | Request metadata; auto-purged |
| Rate-limit records | 24 hours after limit window | Aggregated only |

## 4. Client-Side (Device) Data

| Scenario | Effect |
|---|---|
| App in active use | Data persists on device under your control; deletable within the App |
| App uninstalled | Local database and secure storage deleted by OS (subject to backup caveat below) |
| OS cloud backup (iCloud, Google Backup) | Backed-up data may persist in OS backup until you clear it - outside our control |
| Export (PDF/CSV) | Exported files persist wherever you save or share them; retention is your responsibility |

We recommend managing OS backup settings to control whether App data is included in cloud
backups.

## 5. Account Deletion Workflow and SLA

### How to Request Account Deletion

Send an email to **admin@smaartspend.com** with:

- **Subject line:** `Account Deletion Request - [your registered email address]`
- **Body:** Confirmation that you wish to permanently delete your account and all associated
  backend data.

### Process and Timeline

| Step | Timeframe |
|---|---|
| **Acknowledgement:** We confirm receipt and identity of the request | Within **2 business days** |
| **Identity verification:** We send a verification prompt to your registered email | Within **2 business days** of your request |
| **Deletion executed:** Account and all backend personal data deleted | Within **30 calendar days** of verified request |
| **Confirmation:** We send a deletion confirmation email to your registered address | Within **30 calendar days** |

If we do not receive verification within 14 days of our prompt, the request will be put on hold
and re-confirmed before proceeding. This protects against unauthorized deletion requests.

### What Is Retained After Deletion

Following confirmed account deletion, we may retain:

- Anonymised, aggregated statistical data that cannot be re-linked to you;
- Security log entries (IP, timestamp, event type - no account content) for 90 days from
  deletion for fraud/security audit purposes;
- Data we are legally required to retain under applicable law;
- Data necessary to defend active legal claims.

Local device data is not affected by backend account deletion. Uninstall the App to remove
local data.

## 6. Deletion Methods

| Method | Application |
|---|---|
| Secure database purge | Account, session, token records - SQL DELETE with no soft-delete of content |
| Automated TTL expiry | Token and session data via scheduled jobs or TTL enforcement |
| Log rotation | Infrastructure logs via automated rotation |
| On-device OS deletion | App uninstall triggers OS container deletion (subject to backup) |

## 7. Retention Review

Retention periods are reviewed at least annually. Updates will be reflected in this Policy and
communicated per our Privacy Policy change notification process.

## 8. Contact

admin@smaartspend.com
