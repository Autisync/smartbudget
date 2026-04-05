# Security Disclosure Policy

**App:** SmartSpend
**Operator:** Firmeza Consulting cc
**Effective Date:** 05 April 2026
**Last Updated:** 05 April 2026

---

## 1. Purpose

Firmeza Consulting cc is committed to the security of SmartSpend and its users worldwide. This
Policy explains how we handle vulnerability reports and how we respond to confirmed security
incidents.

## 2. Scope

This Policy applies to:

- The SmartSpend mobile application (Flutter client);
- The backend authentication service (FastAPI/PostgreSQL/Redis) hosted by Autisync on Hetzner
  infrastructure in Germany;
- Public-facing API endpoints (`/api/v1/auth/*`);
- Exchange-rate integration points.

**Out of scope:**
- Third-party service vulnerabilities (exchange-rate APIs, OS platforms) - report to vendors
  directly;
- Theoretical vulnerabilities without a demonstrable proof-of-concept;
- Social engineering of personnel;
- Physical access attacks against user devices;
- Denial-of-service or load testing without prior written authorization.

## 3. Reporting a Vulnerability

3.1 If you believe you have discovered a security vulnerability in an in-scope component,
report it to us **before any public disclosure** at:

**[SUPPORT_EMAIL]** - Subject: `[SECURITY DISCLOSURE] <brief description>`

3.2 Please include where possible:

- A description of the vulnerability and affected component;
- Steps to reproduce (proof-of-concept only - do not exploit production data);
- Potential impact assessment;
- Any suggested remediation.

3.3 Please **do not**:

- Access, modify, delete, or exfiltrate data beyond what is minimally necessary to confirm the
  vulnerability;
- Degrade service availability or harm other users;
- Publicly disclose before coordinated disclosure is agreed;
- Exploit the vulnerability against live user data.

## 4. Our Commitments to Reporters

When you submit a good-faith report complying with this Policy:

4.1 **Acknowledgement:** Within **5 business days**.

4.2 **Initial assessment:** Within **20 business days**, including an estimated remediation
timeline. Complex issues may take longer; we will keep you informed.

4.3 **Safe harbor:** We will not pursue civil or criminal legal action against researchers who
act in good faith under this Policy. This safe harbor does not extend to conduct that accesses
real user data beyond what is minimally necessary, introduces malicious code, or constitutes an
independent criminal act under applicable law.

4.4 **Coordinated disclosure:** We request a remediation window before public disclosure
(typically up to 90 days for critical issues). We will agree a disclosure date with you.

4.5 **Attribution:** With your consent, we will acknowledge contributions in our security
acknowledgements. We do not operate a formal bug bounty program at this time.

## 5. Severity and Response Targets

| Severity | Description | Target Remediation |
|---|---|---|
| **Critical** | Unauthenticated RCE, mass data exposure, authentication bypass | 14 days |
| **High** | Authenticated RCE, significant data leakage, JWT forgery | 30 days |
| **Medium** | Limited data exposure, CSRF, rate-limit bypass | 60 days |
| **Low** | Minor information disclosure, UX-level security issues | 90 days |

These are targets. We will communicate promptly if timelines cannot be met.

## 6. Incident Notification to Users

6.1 If we confirm a security incident affecting personal data, we will assess notification
obligations under applicable data protection law, including GDPR Art. 33/34 (72-hour
supervisory authority notification; user notification without undue delay where high risk),
UK GDPR, LGPD, CCPA, and applicable breach notification statutes in users' jurisdictions.

6.2 Given our server infrastructure is located in Germany (EU), our primary supervisory
authority for GDPR breach notification is the Bundesbeauftragter fur den Datenschutz und die
Informationsfreiheit (BfDI). We will also notify other relevant authorities as required by
applicable law.

6.3 **Security commitment disclaimer.** Despite implementing reasonable and industry-
appropriate security measures, **we cannot guarantee the absolute security of any software or
networked system.** Security measures described in this Policy reflect practices as of the
stated date and are subject to continuous improvement. We do not warrant the App is free from
all vulnerabilities.

## 7. Implemented Security Controls

The following controls are currently in place (not an exhaustive list):

- Argon2 password hashing (memory-hard, OWASP-recommended parameters);
- JWT access and refresh tokens with rotation, revocation, and configurable TTLs;
- Session records storing device name and platform for session management;
- Authentication endpoint rate-limiting;
- Local database encryption with key material in OS secure storage;
- OS-level biometric unlock; no biometric data stored or transmitted by the App;
- Email verification and single-use password-reset token flows with TTL enforcement;
- EU-based server infrastructure (Hetzner, Germany) managed by Autisync;
- Production logging controls preventing token or credential logging.

## 8. Contact

**Security reports:** [SUPPORT_EMAIL] - subject `[SECURITY DISCLOSURE]`
**General security enquiries:** [SUPPORT_EMAIL]
**Postal:** [POSTAL_ADDRESS], Republic of Namibia
