// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SmartSpend';

  @override
  String get dashboardTitle => 'Overview';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get balance => 'Balance';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get category => 'Category';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get note => 'Note';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get biometricAuth => 'Biometric Authentication';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get currency => 'Currency';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Logout';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get monthlySpending => 'Monthly Spending';

  @override
  String get remainingBudget => 'Remaining Budget';

  @override
  String get anomalyDetected => 'Unusual spending detected';

  @override
  String get forecastWarning => 'Budget forecast warning';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingAcceptLegal => 'I accept the Terms & Conditions and Privacy Policy.';

  @override
  String get onboardingAcceptLegalError => 'Please accept the Terms and Privacy Policy to continue.';

  @override
  String get onboardingPage1Title => 'Take control of your money';

  @override
  String get onboardingPage1Description => 'Track spending, understand where your cash goes, and stay ahead of upcoming bills with one workspace.';

  @override
  String get onboardingPage2Title => 'Use your financial copilot';

  @override
  String get onboardingPage2Description => 'Forecast risks, flag anomalies, review subscriptions, and simulate spending changes before they affect your balance.';

  @override
  String get onboardingPage3Title => 'Protect sensitive data';

  @override
  String get onboardingPage3Description => 'Secure your financial information with biometric authentication, session controls, and clear security visibility.';

  @override
  String get legalTermsTitle => 'Terms & Conditions';

  @override
  String get legalTermsSubtitle => 'These terms govern your use of SmartSpend and its financial planning features.';

  @override
  String get legalTermsUseHeading => 'Use of the App';

  @override
  String get legalTermsUseBody => 'SmartSpend is provided for personal financial organization and insight generation. You are responsible for the accuracy of the information you enter and for any decisions you make based on the app output.';

  @override
  String get legalTermsGuidanceHeading => 'Financial Guidance';

  @override
  String get legalTermsGuidanceBody => 'Insights, forecasts, and recommendations are informational only. They do not constitute regulated financial, tax, legal, or investment advice.';

  @override
  String get legalTermsSecurityHeading => 'Security Responsibilities';

  @override
  String get legalTermsSecurityBody => 'You are responsible for maintaining access controls on your device, including passcodes, biometrics, and account protection settings. Do not share access to sensitive financial information with unauthorized users.';

  @override
  String get legalTermsChangesHeading => 'Service Changes';

  @override
  String get legalTermsChangesBody => 'Features may evolve over time. SmartSpend may update, improve, limit, or remove functionality as the product changes.';

  @override
  String get legalPrivacyTitle => 'Privacy Policy';

  @override
  String get legalPrivacySubtitle => 'This policy explains what SmartSpend stores and how it handles your financial data locally.';

  @override
  String get legalPrivacyDataHeading => 'Data We Process';

  @override
  String get legalPrivacyDataBody => 'SmartSpend processes the transactions, budgets, subscriptions, and security preferences you enter so it can show reports, forecasts, and insights.';

  @override
  String get legalPrivacyStorageHeading => 'Local Storage';

  @override
  String get legalPrivacyStorageBody => 'Sensitive settings and authentication metadata may be stored securely on your device using platform-provided secure storage and local databases.';

  @override
  String get legalPrivacyBiometricHeading => 'Biometric Authentication';

  @override
  String get legalPrivacyBiometricBody => 'If you enable biometrics, SmartSpend uses the operating system authentication framework to verify your identity. Biometric templates are managed by the operating system and are not directly accessible to the app.';

  @override
  String get legalPrivacyControlHeading => 'Your Control';

  @override
  String get legalPrivacyControlBody => 'You can review, edit, or delete app data from within the product where supported. You can also disable biometric authentication and related security features at any time.';

  @override
  String get legalAndOnboarding => 'Legal & onboarding';

  @override
  String get reviewTerms => 'Review Terms & Conditions';

  @override
  String get reviewPrivacy => 'Review Privacy Policy';

  @override
  String get restartOnboarding => 'Restart onboarding';

  @override
  String get restartOnboardingSubtitle => 'Show the product introduction and legal acceptance flow again.';

  @override
  String get simulationSpendReductionTitle => 'Spend reduction simulator';

  @override
  String get simulationSpendReductionSubtitle => 'Try preset reduction goals and compare the results.';

  @override
  String simulationProjectedMonthlySpend(String amount) {
    return 'Projected monthly spend: $amount';
  }

  @override
  String simulationProjectedEndBalance(String amount) {
    return 'Projected end balance: $amount';
  }

  @override
  String simulationPotentialSavings(String amount) {
    return 'Potential savings: $amount';
  }

  @override
  String get simulationRecommendationPositive => 'This goal helps preserve your buffer and reduces risk.';

  @override
  String get simulationRecommendationNegative => 'Even with this reduction, you may need deeper cuts to stay cash-positive.';

  @override
  String get commonNow => 'now';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsNotificationsEnabled => 'Enabled';

  @override
  String get settingsNotificationsPaused => 'Paused';

  @override
  String get settingsControlCenterTitle => 'Control Center';

  @override
  String get settingsControlCenterSubtitle => 'Personalize appearance, automation, and alerts from one place.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsAlerts => 'Alerts';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceSubtitle => 'Choose how SmartSpend should look.';

  @override
  String get settingsLanguageSubtitle => 'Choose the language used across the app.';

  @override
  String get settingsCurrencySubtitle => 'Used for monetary display across the app.';

  @override
  String get settingsBudgetRollover => 'Budget Rollover';

  @override
  String get settingsAutoRolloverBudgets => 'Auto-rollover budgets';

  @override
  String get settingsAutoRolloverBudgetsSubtitle => 'Automatically start a new cycle when a budget period ends.';

  @override
  String get settingsRolloverDay => 'Rollover day';

  @override
  String get settingsRolloverDaySubtitle => 'Used for monthly/yearly budget cycle boundaries.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsEnableNotifications => 'Enable notifications';

  @override
  String get settingsEnableNotificationsSubtitle => 'Master switch for all budget/savings alerts.';

  @override
  String get settingsNudgeFrequency => 'Nudge frequency';

  @override
  String get frequencyImmediate => 'Immediate';

  @override
  String get frequencyDaily => 'Daily';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get settingsQuietHours => 'Quiet hours';

  @override
  String get settingsBudgetAlerts => 'Budget alerts';

  @override
  String get settingsSavingsNudges => 'Savings nudges';

  @override
  String get settingsHealthInsights => 'Health insights';

  @override
  String get settingsNextEligibleSendTime => 'Next eligible send time';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsAuthenticationSettings => 'Authentication settings';

  @override
  String get settingsAuthenticationSettingsSubtitle => 'Biometrics, session timeout, lockout controls';

  @override
  String get settingsBlockedNotificationsDisabled => 'Blocked because notifications are disabled.';

  @override
  String get settingsBlockedCategoryDisabled => 'Blocked because this category is disabled.';

  @override
  String get settingsNotEligibleRightNow => 'Not eligible right now';

  @override
  String settingsBlockedByQuietHoursUntil(String when, String countdown) {
    return 'Blocked by quiet hours until $when ($countdown).';
  }

  @override
  String settingsBlockedByFrequencyCooldownUntil(String when, String countdown) {
    return 'Blocked by frequency cooldown until $when ($countdown).';
  }

  @override
  String get settingsNotificationsAreDisabled => 'Notifications are disabled.';

  @override
  String get settingsThisCategoryIsDisabled => 'This category is disabled.';

  @override
  String get settingsReadyToSendNow => 'Ready to send now.';

  @override
  String settingsNextEligible(String when) {
    return 'Next eligible: $when';
  }

  @override
  String get settingsCalculating => 'Calculating...';

  @override
  String get settingsUnavailable => 'Unavailable';

  @override
  String get insightsFinancialCopilot => 'Financial Copilot';

  @override
  String get insightsCriticalCashflowRisk => 'Critical cashflow risk detected. Review spending immediately.';

  @override
  String get insightsElevatedCashflowRisk => 'Elevated cashflow risk detected. Monitor spending closely.';

  @override
  String insightsUpcomingRenewalsDueSoon(int count) {
    return '$count upcoming subscription renewal(s) due soon.';
  }

  @override
  String get insightsWeakSecuritySettings => 'Security settings are weak. Enable PIN or biometrics today.';

  @override
  String get insightsDecisionSnapshot => 'Decision Snapshot';

  @override
  String insightsRiskLevel(String level) {
    return 'Risk level: $level';
  }

  @override
  String get insightsRiskLow => 'LOW';

  @override
  String get insightsRiskMedium => 'MEDIUM';

  @override
  String get insightsRiskHigh => 'HIGH';

  @override
  String get insightsRiskCritical => 'CRITICAL';

  @override
  String get insightsMetricSubscriptionPerMonth => 'Subscription / mo';

  @override
  String get insightsMetricAnomalies => 'Anomalies';

  @override
  String get insightsMetricRenewals14d => 'Renewals (14d)';

  @override
  String get insightsMetricSecurityScore => 'Security score';

  @override
  String get insightsNotAvailable => 'N/A';

  @override
  String get insightsActionableInsights => 'Actionable insights';

  @override
  String get insightsCategoryDistribution => 'Category distribution';

  @override
  String get insightsNoCategoryData => 'No category data available yet.';

  @override
  String get insightsAnomaliesAndImpact => 'Anomalies & impact';

  @override
  String get insightsNoUnusualSpending => 'No unusual spending detected.';

  @override
  String get insightsSubscriptionIntelligence => 'Subscription intelligence';

  @override
  String get insightsNoActiveSubscriptions => 'No active subscriptions are being tracked yet.';

  @override
  String insightsTotalMonthlySubscriptionSpend(String amount) {
    return 'Total monthly subscription spend: $amount';
  }

  @override
  String insightsRenewalsIn14d(int count) {
    return '$count subscription(s) renew within the next 14 days.';
  }

  @override
  String get insightsNoRenewalsIn14d => 'No subscription renewals due in the next 14 days.';

  @override
  String get insightsSecurityPosture => 'Security posture';

  @override
  String insightsSecurityConfiguration(String biometric, String pin) {
    return 'Biometric: $biometric • PIN: $pin';
  }

  @override
  String get insightsEnabled => 'enabled';

  @override
  String get insightsDisabled => 'disabled';

  @override
  String get insightsSecurityConfigurationUnavailable => 'Security configuration not available.';

  @override
  String insightsLastUpdate(String date) {
    return 'Last update: $date';
  }

  @override
  String get insightsConnectSecuritySettings => 'Connect your security settings for tailored recommendations.';

  @override
  String insightsErrorLoading(String error) {
    return 'Error loading insights: $error';
  }

  @override
  String get insightsNoForecastData => 'No forecast data available';

  @override
  String get insightsForecastChart => 'Forecast chart';

  @override
  String get insightsActual => 'Actual';

  @override
  String get insightsPredicted => 'Predicted';

  @override
  String get insightsImpact => 'Impact';

  @override
  String get insightsAction => 'Action';

  @override
  String get securitySettingsTitle => 'Security Settings';

  @override
  String get securityAuthenticationAccess => 'Authentication & access';

  @override
  String get securityBiometricAuth => 'Biometric authentication';

  @override
  String get securityBiometricAuthSubtitle => 'Use Face ID / Touch ID to unlock SmartSpend.';

  @override
  String get securitySessionTimeout => 'Session timeout';

  @override
  String securitySessionTimeoutSubtitle(int minutes) {
    return '$minutes minutes before re-authentication';
  }

  @override
  String securityMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get securityLockoutThreshold => 'Lockout threshold';

  @override
  String securityLockoutThresholdSubtitle(int attempts) {
    return 'Lock account after $attempts failed attempts';
  }

  @override
  String get securityRecentAttempts => 'Recent authentication attempts';

  @override
  String get securityNoAttempts => 'No attempts recorded yet.';

  @override
  String securityErrorLoadingLogs(String error) {
    return 'Error loading logs: $error';
  }

  @override
  String securityErrorLoadingSettings(String error) {
    return 'Error loading security settings: $error';
  }

  @override
  String get reportsTitle => 'Reports & Export';

  @override
  String get reportsPeriod => 'Report Period';

  @override
  String get reportsFrom => 'From';

  @override
  String get reportsTo => 'To';

  @override
  String get reportsQuickSelect => 'Quick Select';

  @override
  String get reportsThisWeek => 'This Week';

  @override
  String get reportsThisMonth => 'This Month';

  @override
  String get reportsLastMonth => 'Last Month';

  @override
  String get reportsLast3Months => 'Last 3 Months';

  @override
  String get reportsThisYear => 'This Year';

  @override
  String get reportsGenerateReports => 'Generate Reports';

  @override
  String reportsFinancialSummary(String currencyCode) {
    return 'Financial Summary ($currencyCode)';
  }

  @override
  String get reportsFinancialSummaryDescription => 'Complete overview of income, expenses, and savings';

  @override
  String get reportsTransactionHistory => 'Transaction History';

  @override
  String get reportsTransactionHistoryDescription => 'Detailed list of all transactions in the period';

  @override
  String get reportsBudgetAnalysis => 'Budget Analysis';

  @override
  String get reportsBudgetAnalysisDescription => 'Budget performance and spending patterns';

  @override
  String get reportsSubscriptionCosts => 'Subscription Costs';

  @override
  String get reportsSubscriptionCostsDescription => 'Monthly breakdown of subscription expenses';

  @override
  String get reportsActivity => 'Report Activity';

  @override
  String get reportsGenerated => 'Generated';

  @override
  String get reportsToday => 'Today';

  @override
  String get reportsTypesUsed => 'Types Used';

  @override
  String get reportsLastRun => 'Last Run';

  @override
  String get reportsNone => 'None';

  @override
  String reportsRuns(int count) {
    return '$count runs';
  }

  @override
  String get reportsGeneratedReports => 'Generated Reports';

  @override
  String get reportsNoGeneratedReports => 'No reports generated yet. Run any report to see it listed here.';

  @override
  String get reportsExportAsPdf => 'Export as PDF';

  @override
  String get reportsExportAsCsv => 'Export as CSV';

  @override
  String get reportsShareFinancialSummary => 'Financial Summary Report';

  @override
  String get reportsPdfGeneratedShared => 'PDF report generated and shared';

  @override
  String reportsErrorGenerating(String error) {
    return 'Error generating report: $error';
  }

  @override
  String get reportsShareTransactionHistory => 'Transaction History Export';

  @override
  String get reportsTransactionHistoryExported => 'Transaction history exported';

  @override
  String reportsErrorExportingData(String error) {
    return 'Error exporting data: $error';
  }

  @override
  String get reportsShareBudgetAnalysis => 'Budget Analysis Report';

  @override
  String get reportsBudgetAnalysisGenerated => 'Budget analysis report generated';

  @override
  String get reportsShareSubscriptionReport => 'Subscription Report';

  @override
  String get reportsSubscriptionReportGenerated => 'Subscription report generated';

  @override
  String get reportsShareCompleteDataExport => 'Complete Data Export';

  @override
  String get reportsCompleteDataExportCreated => 'Complete data export created';

  @override
  String get reportsTypeIncome => 'Income';

  @override
  String get reportsTypeExpense => 'Expense';

  @override
  String get reportsTypeTransfer => 'Transfer';

  @override
  String get reportsBillingWeekly => 'Weekly';

  @override
  String get reportsBillingMonthly => 'Monthly';

  @override
  String get reportsBillingQuarterly => 'Quarterly';

  @override
  String get reportsBillingYearly => 'Yearly';

  @override
  String get reportsPdfFinancialSummaryTitle => 'Financial Summary Report';

  @override
  String get reportsPdfBudgetAnalysisTitle => 'Budget Analysis Report';

  @override
  String get reportsPdfSubscriptionReportTitle => 'Subscription Report';

  @override
  String get reportsPdfPeriod => 'Period';

  @override
  String get reportsPdfIncomeExpenses => 'Income & Expenses';

  @override
  String get reportsPdfTotalIncome => 'Total Income';

  @override
  String get reportsPdfTotalExpenses => 'Total Expenses';

  @override
  String get reportsPdfNetIncome => 'Net Income';

  @override
  String get reportsPdfMonthlySubscriptions => 'Monthly Subscriptions';

  @override
  String get reportsPdfBudgetUtilization => 'Budget Utilization';

  @override
  String get reportsPdfRecentTransactions => 'Recent Transactions';

  @override
  String get reportsPdfBudgetPerformance => 'Budget Performance';

  @override
  String get reportsPdfLimit => 'Limit';

  @override
  String get reportsPdfSpent => 'Spent';

  @override
  String get reportsPdfStatus => 'Status';

  @override
  String get reportsStatusOverBudget => 'Over Budget';

  @override
  String get reportsStatusNearLimit => 'Near Limit';

  @override
  String get reportsStatusOnTrack => 'On Track';

  @override
  String get reportsPdfSummary => 'Summary';

  @override
  String get reportsPdfTotalBudgets => 'Total Budgets';

  @override
  String get reportsPdfOverBudget => 'Over Budget';

  @override
  String get reportsPdfNearLimit => 'Near Limit';

  @override
  String get reportsPdfOnTrack => 'On Track';

  @override
  String get reportsPdfTotalActiveSubscriptions => 'Total Active Subscriptions';

  @override
  String get reportsPdfMonthlyTotalCost => 'Monthly Total Cost';

  @override
  String get reportsPdfYearlyTotalCost => 'Yearly Total Cost';

  @override
  String get reportsPdfActiveSubscriptions => 'Active Subscriptions';

  @override
  String get reportsPdfAmount => 'Amount';

  @override
  String get reportsPdfMonthlyCost => 'Monthly Cost';

  @override
  String get reportsPdfNextDue => 'Next Due';

  @override
  String get reportsCsvHeaderDate => 'Date';

  @override
  String get reportsCsvHeaderCategory => 'Category';

  @override
  String get reportsCsvHeaderAmount => 'Amount';

  @override
  String get reportsCsvHeaderType => 'Type';

  @override
  String get reportsCsvHeaderNote => 'Note';

  @override
  String get reportsCsvHeaderDescription => 'Description';

  @override
  String get reportsCsvRowTransaction => 'Transaction';

  @override
  String get reportsCsvRowSubscription => 'Subscription';

  @override
  String get reportsCompleteDataExportTitle => 'Complete Data Export';

  @override
  String get navHome => 'Home';

  @override
  String get navBudgets => 'Budgets';

  @override
  String get navSavings => 'Savings';

  @override
  String get navSubscriptions => 'Subscriptions';

  @override
  String get navInsights => 'Insights';

  @override
  String get navTxns => 'Txns';

  @override
  String get navMore => 'More';

  @override
  String get navBalanceSheet => 'Balance Sheet';

  @override
  String get navExchangeRates => 'Exchange Rates';

  @override
  String get authSecureFinancialManagement => 'Secure Financial Management';

  @override
  String get authBiometricNotAvailable => 'Biometric authentication is not available on this Mac. Verify Touch ID is enabled in System Settings.';

  @override
  String get authNoBiometricsEnrolled => 'No biometrics enrolled. Add Touch ID in System Settings and try again.';

  @override
  String get authBiometricLockedOut => 'Biometric authentication is temporarily locked. Try again later.';

  @override
  String get authBiometricPermanentlyLocked => 'Biometric authentication is locked. Unlock with your device passcode first.';

  @override
  String get authDenied => 'Authentication was canceled or denied. Please try again.';

  @override
  String get authSystemError => 'Authentication failed due to a system error. Please try again.';

  @override
  String get authAuthenticated => 'Authenticated';

  @override
  String get authAuthenticate => 'Authenticate';

  @override
  String get transactionsDecisionOutpacingIncome => 'Spending is outpacing income this month. Review your largest category first.';

  @override
  String transactionsDecisionTopCategory(String category) {
    return 'Most spending is in $category. That is the quickest place to tune this month.';
  }

  @override
  String get transactionsDecisionBalanced => 'Your transaction flow is balanced. Keep an eye on recurring activity.';

  @override
  String get transactionsNoMatching => 'No matching transactions';

  @override
  String get transactionsTryDifferentFilter => 'Try a different filter or clear the current one.';

  @override
  String get transactionsClear => 'Clear';

  @override
  String get transactionsDeleted => 'Transaction deleted';

  @override
  String get transactionsNoNote => 'No note';

  @override
  String transactionsError(String error) {
    return 'Error: $error';
  }

  @override
  String get transactionsRecurrenceDaily => 'Daily';

  @override
  String get transactionsRecurrenceWeekly => 'Weekly';

  @override
  String get transactionsRecurrenceMonthly => 'Monthly';

  @override
  String get transactionsRecurrenceYearly => 'Yearly';

  @override
  String get transactionsRecurrenceNone => 'None';

  @override
  String get transactionsSpent => 'Spent';

  @override
  String get transactionsRecurring => 'Recurring';

  @override
  String get transactionsNetFlow => 'Net Flow';

  @override
  String get transactionsTopCategory => 'Top Category';

  @override
  String get transactionsUpdateTransaction => 'Update Transaction';

  @override
  String get transactionsEnterAmount => 'Enter amount';

  @override
  String get transactionsInvalidNumber => 'Invalid number';

  @override
  String get transactionsNoteOptional => 'Note (Optional)';

  @override
  String get transactionsRecurrence => 'Recurrence';

  @override
  String get transactionsSaveTransaction => 'Save Transaction';

  @override
  String get transactionsSaved => 'Transaction saved';

  @override
  String get transactionsEditTransaction => 'Edit Transaction';

  @override
  String get transactionsNotFound => 'Transaction not found';

  @override
  String get exchangeUnableToFetch => 'Unable to fetch exchange rate.';

  @override
  String get exchangeLiveRateChecker => 'Live Rate Checker';

  @override
  String get exchangeRateProviderInfo => 'Rates provided by ExchangeRate-API / Frankfurter. For informational purposes only.';

  @override
  String get exchangeRatesFrom => 'From';

  @override
  String get exchangeRatesTo => 'To';

  @override
  String get exchangeRatesSwap => 'Swap currencies';

  @override
  String get exchangeRatesCheckRate => 'Check Rate';

  @override
  String get exchangeRatesConversionResult => 'Conversion Result';

  @override
  String get exchangeRatesTrend7Days => 'Last 7 days trend';

  @override
  String exchangeRatesRateDate(String date) {
    return 'Rate date: $date';
  }

  @override
  String subscriptionsDecisionRenewingCritical(int count) {
    return 'You have $count renewal(s) due within 7 days, including essential services. Review them first.';
  }

  @override
  String subscriptionsDecisionRenewing(int count) {
    return '$count subscription(s) renew within 7 days. This is the best place to trim near-term spending.';
  }

  @override
  String subscriptionsDecisionLowPriorityCost(String amount) {
    return 'Low-priority subscriptions are costing you $amount per month. Consider pausing the least-used ones.';
  }

  @override
  String subscriptionsDecisionCritical(int count) {
    return '$count critical subscription(s) are tracked. Keep payment methods and renewal dates current.';
  }

  @override
  String get subscriptionsDecisionStable => 'Your subscription stack looks stable. Review monthly load and low-priority services to keep it that way.';

  @override
  String get subscriptionsFilterCritical => 'Critical';

  @override
  String get subscriptionsFilterRenewingSoon => 'Renewing Soon';

  @override
  String get subscriptionsFilterHighPriority => 'High Priority';

  @override
  String get subscriptionsFilterLowPriority => 'Low Priority';

  @override
  String get subscriptionsDueThisMonth => 'Due This Month';

  @override
  String subscriptionsFilteredTo(String filter) {
    return 'Filtered to $filter subscriptions';
  }

  @override
  String get subscriptionsEmpty => 'No subscriptions yet';

  @override
  String get subscriptionsEmptySubtitle => 'Add your first subscription to start tracking';

  @override
  String get subscriptionsAdd => 'Add Subscription';

  @override
  String subscriptionsShowing(int count, String filter) {
    return 'Showing $count $filter subscription(s)';
  }

  @override
  String subscriptionsDueLine(String amount, String date) {
    return '$amount - Due $date';
  }

  @override
  String get subscriptionsBillingWeekly => 'Weekly';

  @override
  String get subscriptionsBillingMonthly => 'Monthly';

  @override
  String get subscriptionsBillingQuarterly => 'Quarterly';

  @override
  String get subscriptionsBillingYearly => 'Yearly';

  @override
  String get subscriptionsNext7Days => 'Next 7 Days';

  @override
  String get subscriptionsMonthlyLoad => 'Monthly Load';

  @override
  String get subscriptionsOptionalSavings => 'Optional Savings';

  @override
  String subscriptionsPerCycle(String amount, String cycle) {
    return '$amount per $cycle';
  }

  @override
  String subscriptionsNextBilling(String date) {
    return 'Next billing: $date';
  }

  @override
  String get subscriptionsPerMonth => 'per month';

  @override
  String get subscriptionsCycleWeek => 'week';

  @override
  String get subscriptionsCycleMonth => 'month';

  @override
  String get subscriptionsCycleQuarter => 'quarter';

  @override
  String get subscriptionsCycleYear => 'year';

  @override
  String get subscriptionsCategoryStreaming => 'Streaming';

  @override
  String get subscriptionsCategorySoftware => 'Software';

  @override
  String get subscriptionsCategoryCloudStorage => 'Cloud Storage';

  @override
  String get subscriptionsCategoryFitness => 'Fitness';

  @override
  String get subscriptionsCategoryMusic => 'Music';

  @override
  String get subscriptionsCategoryNews => 'News';

  @override
  String get subscriptionsCategoryCommunication => 'Communication';

  @override
  String get subscriptionsCategoryProductivity => 'Productivity';

  @override
  String get subscriptionsCategoryEntertainment => 'Entertainment';

  @override
  String get subscriptionsCategoryInsurance => 'Insurance';

  @override
  String get subscriptionsCategoryUtilities => 'Utilities';

  @override
  String get subscriptionsCategoryTransport => 'Transport';

  @override
  String get subscriptionsCategoryHealth => 'Health';

  @override
  String get subscriptionsCategoryOther => 'Other';

  @override
  String get subscriptionsImportanceLow => 'Low - Optional/Nice-to-have';

  @override
  String get subscriptionsImportanceMedium => 'Medium - Regular use';

  @override
  String get subscriptionsImportanceHigh => 'High - Important service';

  @override
  String get subscriptionsImportanceCritical => 'Critical - Essential service';

  @override
  String subscriptionsSaveError(String error) {
    return 'Error saving subscription: $error';
  }

  @override
  String get subscriptionsEditSubscription => 'Edit Subscription';

  @override
  String get subscriptionsAddSubscription => 'Add Subscription';

  @override
  String get subscriptionsName => 'Subscription Name';

  @override
  String get subscriptionsNameHint => 'e.g., Netflix, Spotify';

  @override
  String get subscriptionsEnterName => 'Please enter a subscription name';

  @override
  String get subscriptionsRequired => 'Required';

  @override
  String get subscriptionsInvalidAmount => 'Invalid amount';

  @override
  String get subscriptionsBillingCycle => 'Billing Cycle';

  @override
  String get subscriptionsImportance => 'Importance';

  @override
  String get subscriptionsCostSummary => 'Cost Summary';

  @override
  String get subscriptionsMonthlyCost => 'Monthly Cost';

  @override
  String get subscriptionsAnnualCost => 'Annual Cost';

  @override
  String get subscriptionsStartDate => 'Start Date';

  @override
  String get subscriptionsNextBillingLabel => 'Next Billing';

  @override
  String get subscriptionsOptionalDetails => 'Optional Details';

  @override
  String get subscriptionsPaymentMethod => 'Payment Method';

  @override
  String get subscriptionsPaymentMethodHint => 'e.g., Credit Card, PayPal';

  @override
  String get subscriptionsWebsite => 'Website';

  @override
  String get subscriptionsWebsiteHint => 'e.g., netflix.com';

  @override
  String get subscriptionsNotes => 'Notes';

  @override
  String get subscriptionsNotesHint => 'Add any notes about this subscription';

  @override
  String get subscriptionsDecisionHelp => 'Decision Help';

  @override
  String get subscriptionsDecisionEnterAmount => 'Enter an amount to see suggestions';

  @override
  String subscriptionsDecisionHighAnnualCost(String amount) {
    return 'High annual cost ($amount) - Consider if this is essential or could be replaced';
  }

  @override
  String subscriptionsDecisionModerateAnnualCost(String amount) {
    return 'Moderate annual cost ($amount) - Make sure you actively use this';
  }

  @override
  String get subscriptionsDecisionTrackRegularly => 'Track regularly to avoid inactive subscriptions';

  @override
  String subscriptionsLoadError(String error) {
    return 'Error loading subscription: $error';
  }

  @override
  String get subscriptionsNotFound => 'Subscription not found';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsEmptySubtitle => 'Budget alerts, savings nudges, and health insights will appear here.';

  @override
  String notificationsLoadError(String error) {
    return 'Error loading notifications: $error';
  }

  @override
  String get financialHealthTitle => 'Financial Health';

  @override
  String get financialHealthStatusStrong => 'Strong';

  @override
  String get financialHealthStatusNeedsAttention => 'Needs attention';

  @override
  String get financialHealthStatusAtRisk => 'At risk';

  @override
  String get financialHealthPortfolio => 'Health portfolio';

  @override
  String get financialHealthScore => 'Score';

  @override
  String get financialHealthGoals => 'Goals';

  @override
  String get financialHealthUpdateWeekly => 'Update weekly';

  @override
  String financialHealthActiveCounts(int budgets, int goals) {
    return 'Active budgets: $budgets • Active goals: $goals';
  }

  @override
  String get financialHealthBudgetDiscipline => 'Budget discipline';

  @override
  String get financialHealthBudgetDisciplineDescription => 'Measures pressure from near-limit and exceeded budgets.';

  @override
  String get financialHealthSavingsMomentum => 'Savings momentum';

  @override
  String get financialHealthSavingsMomentumDescription => 'Measures goal progress and schedule adherence.';

  @override
  String get financialHealthBudgetUtilization => 'Budget utilization';

  @override
  String get financialHealthBudgetUtilizationDescription => 'Measures category-level spending efficiency across budget periods.';

  @override
  String get financialHealthTrendWindow => 'Trend window';

  @override
  String financialHealthWeeks(int count) {
    return '$count weeks';
  }

  @override
  String get financialHealthRecommendations => 'Recommendations';

  @override
  String get financialHealthRecommendationExceeded => 'Reduce discretionary spending in categories that already exceeded budget.';

  @override
  String get financialHealthRecommendationNearLimit => 'Rebalance near-limit budgets before the period ends.';

  @override
  String financialHealthRecommendationBehindGoals(int count) {
    return 'Increase monthly contributions for $count goal(s) behind schedule.';
  }

  @override
  String get financialHealthRecommendationEnableAutoAllocation => 'Enable auto-allocation for at least one savings goal to improve consistency.';

  @override
  String get financialHealthRecommendationStable => 'Keep your current pace and review your health score weekly.';

  @override
  String get financialHealthWeeklyNoteNoIncome => 'No income recorded this week; spending pressure increased.';

  @override
  String get financialHealthWeeklyNoteImproved => 'Health improved with stronger weekly cashflow balance.';

  @override
  String get financialHealthWeeklyNoteDropped => 'Health dropped this week due to higher spending pressure.';

  @override
  String get financialHealthWeeklyNoteStable => 'Stable week with limited change in financial behavior.';

  @override
  String get financialHealthWeeklyTrajectory => 'Weekly health trajectory';

  @override
  String financialHealthOverallChange(String delta, int weeks) {
    return 'Overall change: $delta points over $weeks weeks.';
  }

  @override
  String financialHealthBiggestGain(String delta, String date) {
    return 'Biggest gain: $delta on $date.';
  }

  @override
  String financialHealthBiggestDrop(String delta, String date) {
    return 'Biggest drop: $delta on $date.';
  }

  @override
  String savingsNudgeBehindTitle(String goal) {
    return 'You are behind on $goal';
  }

  @override
  String savingsNudgeBehindMessage(String amount) {
    return 'You are about $amount behind schedule. Consider increasing monthly savings.';
  }

  @override
  String savingsNudgeAutoAllocateTitle(String goal) {
    return 'Enable auto-allocation for $goal';
  }

  @override
  String get savingsNudgeAutoAllocateMessage => 'Auto-allocation can help keep contributions consistent each month.';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonSeeAll => 'See All';

  @override
  String get commonViewDetails => 'View details';

  @override
  String get commonClose => 'Close';

  @override
  String get commonAdd => 'Add';

  @override
  String get dashboardBudgetExceededTitle => 'Budget Exceeded!';

  @override
  String get dashboardBudgetAlertTitle => 'Budget Alert';

  @override
  String dashboardBudgetAlertBody(String category, String percent) {
    return '$category spending is at $percent% of limit';
  }

  @override
  String get dashboardHealthNeedsAttentionTitle => 'Financial health needs attention';

  @override
  String dashboardHealthNeedsAttentionBody(String score) {
    return 'Your score is $score. Review the Health details for actions.';
  }

  @override
  String get dashboardMetricsTransactions => 'Transactions';

  @override
  String get dashboardMetricsBudgetAlerts => 'Budget alerts';

  @override
  String get dashboardMetricsHealthScore => 'Money Health Index';

  @override
  String get dashboardBalanceSheetTitle => 'Recurring Balance Sheet';

  @override
  String get dashboardBalanceSheetSubtitle => 'See if recurring income covers recurring bills and subscriptions.';

  @override
  String get dashboardSectionThisMonth => 'This Month';

  @override
  String get dashboardSectionBudgetAlerts => 'Budget Alerts';

  @override
  String get dashboardNoActiveBudgetAlerts => 'No active budget alerts';

  @override
  String dashboardAlertExceeded(String category, String threshold, String progress) {
    return '$category exceeded $threshold% ($progress%)';
  }

  @override
  String dashboardAlertNearing(String category, String threshold, String progress) {
    return '$category nearing $threshold% ($progress%)';
  }

  @override
  String get dashboardCheckingAlerts => 'Checking alerts...';

  @override
  String dashboardAlertError(String error) {
    return 'Alert error: $error';
  }

  @override
  String get dashboardRecentTransactions => 'Recent Transactions';

  @override
  String get dashboardErrorLoadingTransactions => 'Error loading transactions';

  @override
  String get dashboardBurnRate => 'Burn Rate';

  @override
  String dashboardUnusualTransactionsDetected(int count) {
    return '$count unusual transactions detected';
  }

  @override
  String get dashboardTrendRising => '↑ Rising';

  @override
  String get dashboardTrendFalling => '↓ Falling';

  @override
  String get dashboardTrendStable => '→ Stable';

  @override
  String dashboardHealthBreakdown(String budget, String savings) {
    return 'Budget discipline: $budget • Savings momentum: $savings';
  }

  @override
  String get dashboardFailedToLoadInsights => 'Failed to load insights';

  @override
  String get dashboardLiveRateCheck => 'Live Rate Check';

  @override
  String get dashboardRefreshRate => 'Refresh rate';

  @override
  String get dashboardQuickQuoteSubtitle => 'Quick quote for your selected app currency.';

  @override
  String get dashboardRateUnavailable => 'Rate unavailable right now. Try again or open the full tool.';

  @override
  String dashboardRateUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get dashboardOpenFullTool => 'Open full tool';

  @override
  String get budgetEmptyTitle => 'Set your first monthly budget';

  @override
  String get budgetEmptySubtitle => 'Create category budgets to track spending in real-time and avoid overspending.';

  @override
  String get budgetCreateButton => 'Create Budget';

  @override
  String budgetDecisionNeedsAttention(int count) {
    return '$count budget(s) need attention. Review the red and amber categories before adding new spend.';
  }

  @override
  String get budgetDecisionStable => 'Your current budget setup is stable. Use rollover only after confirming categories still fit this month.';

  @override
  String get budgetPortfolioTitle => 'Budget portfolio';

  @override
  String get budgetCategories => 'Categories';

  @override
  String get budgetTotalLimit => 'Total Limit';

  @override
  String get budgetAtRisk => 'At Risk';

  @override
  String get budgetAverageAlert => 'Avg Alert';

  @override
  String get budgetRolloverNow => 'Rollover now';

  @override
  String get budgetSwipeRightHint => 'Swipe right: +10% budget';

  @override
  String get budgetSwipeLeftHint => 'Swipe left: -10% budget';

  @override
  String budgetIncreasedSnack(String category) {
    return '$category budget increased by 10%';
  }

  @override
  String budgetReducedSnack(String category) {
    return '$category budget reduced by 10%';
  }

  @override
  String budgetCycleAlert(String period, String threshold) {
    return '$period cycle • Alert $threshold%';
  }

  @override
  String get budgetEdit => 'Edit budget';

  @override
  String get budgetDelete => 'Delete budget';

  @override
  String budgetLimitLabel(String amount) {
    return 'Limit $amount';
  }

  @override
  String get budgetStatusOnTrack => 'On track';

  @override
  String get budgetStatusSoftWarning => 'Soft warning';

  @override
  String get budgetStatusHighAlert => 'High alert';

  @override
  String get budgetStatusExceeded => 'Exceeded';

  @override
  String get budgetPeriodEnded => 'Period ended';

  @override
  String budgetDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String budgetSpendingProgress(String spent, String remaining, String percent) {
    return '$spent spent • $remaining remaining • $percent% used';
  }

  @override
  String get budgetTapBarHint => 'Tap bar to view transactions in this category';

  @override
  String budgetProjectedOverrun(String amount) {
    return 'At this pace, you may exceed this budget by $amount';
  }

  @override
  String get budgetAdjustAmount => 'Adjust amount';

  @override
  String get budgetErrorLoadingProgress => 'Error loading progress';

  @override
  String get budgetRolloverComplete => 'Budget rollover check complete.';

  @override
  String get budgetNoTransactionsForCategory => 'No transactions found for this budget category yet.';

  @override
  String budgetCategoryTransactions(String category) {
    return '$category transactions';
  }

  @override
  String get budgetCreate => 'Create budget';

  @override
  String get budgetAmount => 'Budget amount';

  @override
  String get budgetCategoryHint => 'Food, Transport, Bills...';

  @override
  String get budgetEnterCategory => 'Enter a category';

  @override
  String get budgetEnterValidAmount => 'Enter a valid amount';

  @override
  String get budgetPeriod => 'Period';

  @override
  String budgetAlertAt(int percent) {
    return 'Alert at $percent%';
  }

  @override
  String budgetAlertPercent(int percent) {
    return '$percent%';
  }

  @override
  String get budgetStartDate => 'Start date';

  @override
  String get budgetSave => 'Save budget';

  @override
  String get budgetUpdate => 'Update budget';

  @override
  String get savingsGoalsTitle => 'Savings Goals';

  @override
  String get savingsEmptyTitle => 'Create your first savings goal';

  @override
  String get savingsEmptySubtitle => 'Define a target amount and optional deadline to build savings intentionally.';

  @override
  String get savingsCreateGoal => 'Create Goal';

  @override
  String savingsGoalsBehindPace(int count) {
    return '$count goal(s) are behind pace. Focus new contributions there first.';
  }

  @override
  String savingsMonthlySurplusMessage(String amount) {
    return 'You have $amount of monthly surplus available to accelerate your top priority goal.';
  }

  @override
  String get savingsSteadyProgress => 'Progress is steady. Keep contributions consistent to protect your deadlines.';

  @override
  String get savingsPortfolioTitle => 'Savings portfolio';

  @override
  String get savingsSaved => 'Saved';

  @override
  String get savingsTarget => 'Target';

  @override
  String get savingsNudgesLabel => 'Nudges';

  @override
  String savingsSurplusDetected(String amount) {
    return 'Surplus detected: $amount';
  }

  @override
  String get savingsAllocateSurplusHint => 'Allocate part of this surplus to accelerate your goals.';

  @override
  String savingsAllocateAmount(String amount) {
    return 'Allocate \$$amount';
  }

  @override
  String get savingsEditGoal => 'Edit goal';

  @override
  String get savingsDeleteGoal => 'Delete goal';

  @override
  String get savingsTimelineTracked => 'Timeline tracked';

  @override
  String savingsProgressLine(String percent, String remaining) {
    return '$percent% complete • $remaining remaining';
  }

  @override
  String savingsDeadlineLabel(String date) {
    return 'Deadline: $date';
  }

  @override
  String savingsSuggestionMonthly(String amount) {
    return 'Suggestion: Save $amount/month to stay on track.';
  }

  @override
  String savingsProjectedLate(int months) {
    return 'At current pace, this goal may finish about $months month(s) late.';
  }

  @override
  String get savingsAddFunds => 'Add funds';

  @override
  String get savingsSimulatePlus50 => 'Simulate +\$50/mo';

  @override
  String get savingsGoalAchieved => 'Goal achieved! Archive it or create a new one to keep momentum.';

  @override
  String get savingsScenarioSimulationTitle => 'Scenario simulation';

  @override
  String get savingsUnableEstimateCompletion => 'Unable to estimate completion date with current data.';

  @override
  String savingsScenarioEstimate(String amount, int months) {
    return 'If you increase savings by $amount/month, you could complete this goal in about $months month(s).';
  }

  @override
  String get savingsStatusCompleted => 'Completed';

  @override
  String get savingsStatusBehindSchedule => 'Behind schedule';

  @override
  String get savingsStatusOnPace => 'On pace';

  @override
  String get savingsStatusBuildingMomentum => 'Building momentum';

  @override
  String savingsTimeProgressLine(String time, String savings) {
    return 'Time progress $time% • Savings progress $savings%';
  }

  @override
  String get savingsGoalName => 'Goal name';

  @override
  String get savingsEnterGoalName => 'Enter a goal name';

  @override
  String get savingsTargetAmount => 'Target amount';

  @override
  String get savingsEnterValidTargetAmount => 'Enter a valid target amount';

  @override
  String get savingsCurrentSavedAmount => 'Current saved amount';

  @override
  String get savingsEnterValidSavedAmount => 'Enter a valid saved amount';

  @override
  String get savingsPriority => 'Priority';

  @override
  String get savingsEnableAutoAllocation => 'Enable auto-allocation';

  @override
  String get savingsDeadlineOptional => 'Deadline (optional)';

  @override
  String get savingsNoDeadline => 'No deadline';

  @override
  String get savingsSaveGoal => 'Save goal';

  @override
  String get savingsUpdateGoal => 'Update goal';

  @override
  String savingsAddToGoal(String goal) {
    return 'Add to $goal';
  }

  @override
  String balanceSheetRecurringType(String type) {
    return 'Recurring $type';
  }

  @override
  String get balanceSheetInsightEmptyTitle => 'No recurring plan available yet';

  @override
  String get balanceSheetInsightEmptyExplanation => 'Add recurring transactions or subscriptions to generate a balance sheet.';

  @override
  String get balanceSheetInsightEmptyImpact => 'Without recurring entries, the app cannot estimate fixed monthly commitments.';

  @override
  String get balanceSheetInsightEmptyAction => 'Mark salary, rent, loan payments, and subscriptions as recurring to unlock planning.';

  @override
  String get balanceSheetInsightShortfallTitle => 'Recurring plan is running a deficit';

  @override
  String balanceSheetInsightShortfallExplanation(String amount) {
    return 'Your recurring income misses monthly obligations by $amount.';
  }

  @override
  String get balanceSheetInsightShortfallImpact => 'If nothing changes, fixed commitments alone can force you to borrow or cut essentials.';

  @override
  String balanceSheetInsightShortfallActionOptional(String amount) {
    return 'Reduce at least $amount from optional subscriptions, then review large recurring bills.';
  }

  @override
  String balanceSheetInsightShortfallAction(String amount) {
    return 'Increase recurring income or reduce fixed expenses by at least $amount.';
  }

  @override
  String get balanceSheetInsightThinBufferTitle => 'Recurring coverage is positive but thin';

  @override
  String balanceSheetInsightThinBufferExplanation(String amount) {
    return 'Your fixed-income plan covers obligations with only $amount left each month.';
  }

  @override
  String get balanceSheetInsightThinBufferImpact => 'A small change in income or a missed payment could remove your margin quickly.';

  @override
  String get balanceSheetInsightThinBufferAction => 'Build an extra buffer by trimming one recurring expense or redirecting new income into essentials first.';

  @override
  String get balanceSheetInsightCoveredTitle => 'Recurring obligations are currently covered';

  @override
  String balanceSheetInsightCoveredExplanation(String amount) {
    return 'Your monthly recurring plan leaves an estimated $amount after fixed commitments.';
  }

  @override
  String get balanceSheetInsightCoveredImpact => 'You have room to absorb smaller fluctuations without falling behind on recurring bills.';

  @override
  String get balanceSheetInsightCoveredAction => 'Protect that margin by keeping discretionary recurring charges under review.';

  @override
  String get balanceSheetInsightNearTermTitle => 'Next 14 days look cashflow-heavy';

  @override
  String balanceSheetInsightNearTermExplanation(String commitments, String income) {
    return 'Near-term recurring commitments total $commitments against $income in recurring income.';
  }

  @override
  String get balanceSheetInsightNearTermImpact => 'You may feel payment pressure before month-end even if the monthly picture is acceptable.';

  @override
  String get balanceSheetInsightNearTermAction => 'Prioritize due-soon essentials first and reschedule optional payments where possible.';

  @override
  String get balanceSheetInsightSubscriptionShareTitle => 'Subscriptions take a large share of fixed outflow';

  @override
  String balanceSheetInsightSubscriptionShareExplanation(String percent) {
    return 'Subscriptions account for $percent% of your recurring obligations.';
  }

  @override
  String get balanceSheetInsightSubscriptionShareImpact => 'Smaller digital charges can quietly crowd out money needed for core bills.';

  @override
  String balanceSheetInsightSubscriptionShareActionOptional(String amount) {
    return 'Review optional subscriptions first. You could free up about $amount per month.';
  }

  @override
  String get balanceSheetInsightSubscriptionShareAction => 'Review annual and quarterly subscriptions for services you can pause or consolidate.';

  @override
  String get balanceSheetInsightLargestBillTitle => 'Start with the largest recurring bill';

  @override
  String balanceSheetInsightLargestBillExplanation(String title, String amount) {
    return '$title is your largest recurring commitment at about $amount per month.';
  }

  @override
  String get balanceSheetInsightLargestBillImpact => 'Any reduction here has more impact than cutting multiple smaller charges.';

  @override
  String balanceSheetInsightLargestBillAction(String title) {
    return 'Review whether $title can be renegotiated, downgraded, or offset with a matching recurring income increase.';
  }

  @override
  String balanceSheetBuildError(String error) {
    return 'Unable to build recurring balance sheet: $error';
  }

  @override
  String balanceSheetCurrencyFallback(String requested, String fallback) {
    return 'Live exchange rates are unavailable for $requested. This view is shown in $fallback for now.';
  }

  @override
  String get balanceSheetCoveredTitle => 'Recurring income currently covers your obligations';

  @override
  String get balanceSheetDeficitTitle => 'Recurring obligations currently outpace recurring income';

  @override
  String get balanceSheetCoveredSubtitle => 'Estimated monthly room left after recurring commitments.';

  @override
  String get balanceSheetDeficitSubtitle => 'Estimated monthly shortfall before variable spending begins.';

  @override
  String get balanceSheetIncomePerMonth => 'Income / mo';

  @override
  String get balanceSheetExpensesPerMonth => 'Expenses / mo';

  @override
  String get balanceSheetSubscriptionsPerMonth => 'Subscriptions / mo';

  @override
  String get balanceSheetDueIn14Days => 'Due in 14 days';

  @override
  String get balanceSheetCoverageOutlook => 'Coverage outlook';

  @override
  String balanceSheetCoveragePercent(String percent) {
    return 'Recurring income covers $percent% of recurring obligations.';
  }

  @override
  String balanceSheetCoverageFootnote(String currency) {
    return 'The sheet uses monthly equivalents for active recurring transactions and subscriptions in $currency.';
  }

  @override
  String get balanceSheetScenarioLab => 'Scenario Lab';

  @override
  String get balanceSheetScenarioSubtitle => 'Test small changes before you make them. Increase recurring income, cut recurring expenses, or pause optional subscriptions.';

  @override
  String get balanceSheetAddRecurringIncome => 'Add recurring income';

  @override
  String get balanceSheetReduceRecurringExpenses => 'Reduce recurring expenses';

  @override
  String get balanceSheetPauseOptionalSubscriptions => 'Pause optional subscriptions';

  @override
  String balanceSheetSubscriptionChip(String title, String amount) {
    return '$title · $amount/mo';
  }

  @override
  String get balanceSheetSimulatedMonthlyBalance => 'Simulated monthly balance';

  @override
  String balanceSheetSimulatedIncomeExpenses(String income, String expenses) {
    return 'Income $income · Expenses $expenses';
  }

  @override
  String get balanceSheetResetScenario => 'Reset scenario';

  @override
  String get balanceSheetWaysToMakeEndsMeet => 'Ways to make ends meet';

  @override
  String get balanceSheetRecurringIncome => 'Recurring income';

  @override
  String get balanceSheetNoRecurringIncome => 'No recurring income has been configured yet.';

  @override
  String get balanceSheetRecurringExpenses => 'Recurring expenses';

  @override
  String get balanceSheetNoRecurringExpenses => 'No recurring expenses have been configured yet.';

  @override
  String get balanceSheetSubscriptionsIncluded => 'Subscriptions included';

  @override
  String balanceSheetNextDate(String date) {
    return 'Next $date';
  }

  @override
  String get balanceSheetOptional => 'Optional';
}
