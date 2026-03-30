## SmartBudget product brief

### Overview

SmartBudget is a privacy-first budgeting app built in Flutter, designed to help users track finances, manage subscriptions, and get clear spending insights. It combines transaction management, reporting, security controls, and predictive forecasting in one local-first experience.

---

### Core value proposition

- Enables users to monitor daily spending and recurring costs
- Helps identify unusual expenses and cashflow risks
- Protects financial data with biometric authentication
- Produces exportable reports for review or sharing

---

### Key capabilities

- **Dashboard**
  - Recent activity summary
  - Quick access to transactions, insights, and security

- **Transactions**
  - Add, edit, delete expense/income records
  - Supports recurring payments
  - Local persistence with SQLite

- **Budgets**
  - Track spending targets
  - Monitor progress against goals

- **Savings**
  - Define savings goals
  - Track progress over time

- **Subscriptions**
  - Manage recurring services
  - Show upcoming payment due dates
  - Normalize costs by billing cycles

- **Reports**
  - Generate PDF financial reports
  - Export CSV data
  - Share reports via OS share sheet

- **Security**
  - Biometric unlock
  - Session timeout setting
  - Authentication event logging

- **Insights**
  - Spending profile: burn rate, daily spend, category mix
  - Trend analysis vs prior month
  - Anomaly detection for unusual expenses
  - Forecasting: projected spend, predicted end balance, confidence, risk, recommendation

---

### Technical foundation

- **Flutter + Riverpod** for UI and state management
- **GoRouter** for app navigation
- **Drift** for local database and persistence
- **local_auth + secure storage** for authentication
- **PDF / CSV generation** for report exports

---

### Current status

- Fully implemented local budgeting flow
- AI-style insights and forecasting available in the `Insights` section
- Secure app access via biometric checks
- Report generation and sharing working
- Responsive navigation for mobile and larger screens

---

### Exchange-rate provider setup

SmartBudget supports two exchange-rate sources:

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
