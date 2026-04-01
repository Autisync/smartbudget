## SmartSpend product brief

### Overview

SmartSpend is a privacy-first, local-first personal finance app built in Flutter. It helps users manage day-to-day money operations across transactions, budgets, savings goals, subscriptions, and recurring cashflow while surfacing forecasting, anomaly detection, and financial health signals in a single experience.

---

### Core value proposition

- Gives users one control center for spending, budgeting, savings, subscriptions, and recurring obligations
- Converts complex financial data into practical insights (risk levels, anomalies, forecasts, recommendations)
- Protects sensitive data through biometric-gated access and secure local storage
- Provides portable outputs through built-in PDF/CSV report generation and sharing

---

### Key capabilities

- **Onboarding + legal readiness**
  - Guided first-run onboarding flow
  - In-app Terms and Privacy document access

- **Dashboard**
  - Recent activity summary and spending highlights
  - Quick actions to key money workflows
  - Dedicated Financial Health view with trend scoring

- **Transactions**
  - Add, edit, delete expense/income records
  - Supports recurring payments (daily/weekly/monthly/yearly)
  - Local persistence with SQLite

- **Budgets**
  - Track spending targets
  - Monitor progress against limits
  - Budget alert thresholds and in-app alert surfacing

- **Savings**
  - Define savings goals
  - Track progress over time
  - Goal nudges and quick-adjust workflow support

- **Subscriptions**
  - Manage recurring services
  - Importance levels (low to critical) for prioritization
  - Show upcoming payment due dates
  - Normalize costs by billing cycles
  - Convert subscription totals into selected app currency when rates are available

- **Recurring balance sheet**
  - Combine recurring income, recurring expenses, and subscriptions
  - Estimate near-term commitments and monthly coverage ratio
  - Generate actionable recommendations from recurring cashflow signals

- **Exchange rates**
  - Live currency conversion and 7-day trend visualization
  - Dual-provider strategy: ExchangeRate-API with Frankfurter/ECB fallback

- **Reports**
  - Generate multiple report types (summary, transactions, budgets, subscriptions)
  - Export PDF and CSV outputs
  - Share reports via OS share sheet

- **Notifications**
  - In-app inbox for budget, savings, and financial health events
  - Mark-all-read and inbox clear actions

- **Security**
  - Biometric-gated unlock
  - Session timeout setting
  - Secure local storage for sensitive keys/settings

- **Settings + personalization**
  - Theme mode (system, light, dark)
  - Language selection (English, Portuguese, Spanish)
  - App currency selection with data migration support
  - Notification preferences and rollover policy controls

- **Insights**
  - Spending profile: burn rate, daily spend, category mix
  - Trend analysis vs prior month
  - Anomaly detection for unusual expenses
  - Forecasting: projected spend, predicted end balance, confidence, risk, recommendation
  - Subscription intelligence + security posture signals in one analysis view

---

### Technical foundation

- **Flutter + Riverpod** for UI and state management
- **GoRouter** for app navigation
- **Drift** for local database and persistence
- **local_auth + secure storage** for authentication
- **PDF / CSV generation** for report exports

---

### Current status

- Implemented end-to-end local-first finance workflow (transactions, budgets, savings, subscriptions)
- Insights stack includes anomalies, forecast modeling, and recommendation cards
- Recurring balance sheet and financial health scoring are available for recurring-cashflow analysis
- Reports support PDF/CSV generation with sharing
- Security uses biometric-gated access with secure local storage integration
- App-level localization (EN/PT/ES), theming, and currency controls are available in settings
- Responsive navigation is implemented for compact and large-screen layouts

---

### Exchange-rate provider setup

SmartSpend supports two exchange-rate sources:

- Primary: ExchangeRate-API (when `EXCHANGE_RATE_API_KEY` is provided)
- Fallback: Frankfurter/ECB (no API key required)

To enable ExchangeRate-API, inject the key at runtime/build time using `dart-define`:

```bash
flutter run --dart-define=EXCHANGE_RATE_API_KEY=YOUR_KEY_HERE
```

```bash
flutter build apk --dart-define=EXCHANGE_RATE_API_KEY=YOUR_KEY_HERE
```

You can also use a define file to avoid placing keys directly in shell history:

```bash
flutter run --dart-define-from-file=.env.json
```

Create your local `.env.json` from the committed template:

```bash
cp .env.example .env.json
```

Example `.env.json`:

```json
{
  "EXCHANGE_RATE_API_KEY": ""
}
```

Do not hardcode production API keys in source files.

---

### Suggested next priorities

- Add visual charts for spending and forecast trends
- Expand anomaly explanations and alert notifications
- Improve report filters and customizable export ranges
- Consider cloud sync or multi-device account support

---

## Local development setup (full app)

This section explains how to run SmartSpend locally with the Flutter app and the auth backend.

### Prerequisites

- Flutter SDK installed and on PATH
- Dart (bundled with Flutter)
- Python 3.11+ (for backend local non-Docker mode)
- Docker Desktop (optional, for backend Docker mode)
- Android device/emulator (or iOS simulator/device)

### 1) Clone and open project

```bash
git clone <your-repo-url>
cd smartbudget
```

### 2) Backend setup

Go to backend folder:

```bash
cd backend
```

Create env file from template:

```bash
cp .env.example .env
```

Windows PowerShell alternative:

```powershell
Copy-Item .env.example .env -Force
```

#### Option A: Run backend with Docker (recommended)

```bash
docker compose up --build
```

To stop:

```bash
docker compose down
```

#### Option B: Run backend without Docker

Install dependencies:

```bash
pip install -r requirements.txt
```

Run migrations:

```bash
alembic upgrade head
```

Start API:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend health check URL:

```text
http://localhost:8000/api/v1/health
```

### 3) Flutter app setup

Return to project root:

```bash
cd ..
```

Fetch Flutter packages:

```bash
flutter pub get
```

List connected devices:

```bash
flutter devices
```

### 4) Run app with backend URL

#### Android emulator

Use host loopback bridge:

```bash
flutter run --dart-define=AUTH_API_BASE_URL=http://10.0.2.2:8000
```

#### Physical Android device

Use your machine LAN IP (example shown):

```bash
flutter run -d <device_id> --dart-define=AUTH_API_BASE_URL=http://192.168.0.175:8000
```

### 5) Verify auth flow manually

- Sign up with a new email/password
- Log out and log back in
- Trigger forgot password flow
- Open deep link for reset/verify using device commands below

### 6) Deep-link tests

Android:

```bash
adb shell am start -a android.intent.action.VIEW -d "smartbudget://reset-password?token=test-token"
adb shell am start -a android.intent.action.VIEW -d "smartbudget://verify-email?token=test-token"
```

iOS simulator:

```bash
xcrun simctl openurl booted "smartbudget://reset-password?token=test-token"
xcrun simctl openurl booted "smartbudget://verify-email?token=test-token"
```

### 7) Email templates and SMTP

- HTML templates live in `backend/app/templates/emails/`
- SMTP is configured via `backend/.env`
- For local testing without sending emails, keep `SMTP_ENABLED=false`

### 8) Common issues

- Docker engine not running:
  - Start Docker Desktop, then rerun `docker compose up --build`
- Android app cannot reach backend:
  - Verify device and PC are on same network
  - Check firewall allows port 8000
  - Confirm `AUTH_API_BASE_URL` uses reachable IP
- Migration issues:
  - Ensure database URL in `.env` is correct
  - Rerun `alembic upgrade head`
