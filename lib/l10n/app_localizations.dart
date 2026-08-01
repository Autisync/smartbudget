import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SmartSpend'**
  String get appTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashboardTitle;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuth;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first income or expense to start tracking your money.'**
  String get noTransactionsSubtitle;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @monthlySpending.
  ///
  /// In en, this message translates to:
  /// **'Monthly Spending'**
  String get monthlySpending;

  /// No description provided for @remainingBudget.
  ///
  /// In en, this message translates to:
  /// **'Remaining Budget'**
  String get remainingBudget;

  /// No description provided for @anomalyDetected.
  ///
  /// In en, this message translates to:
  /// **'Unusual spending detected'**
  String get anomalyDetected;

  /// No description provided for @forecastWarning.
  ///
  /// In en, this message translates to:
  /// **'Budget forecast warning'**
  String get forecastWarning;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingAcceptLegal.
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms, Privacy Policy, and all legal documents.'**
  String get onboardingAcceptLegal;

  /// No description provided for @onboardingAcceptLegalError.
  ///
  /// In en, this message translates to:
  /// **'Please accept the legal documents to continue.'**
  String get onboardingAcceptLegalError;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Take control of your money'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Description.
  ///
  /// In en, this message translates to:
  /// **'Track spending, understand where your cash goes, and stay ahead of upcoming bills with one workspace.'**
  String get onboardingPage1Description;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Use your financial copilot'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Description.
  ///
  /// In en, this message translates to:
  /// **'Forecast risks, flag anomalies, review subscriptions, and simulate spending changes before they affect your balance.'**
  String get onboardingPage2Description;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Protect sensitive data'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Description.
  ///
  /// In en, this message translates to:
  /// **'Secure your financial information with biometric authentication, session controls, and clear security visibility.'**
  String get onboardingPage3Description;

  /// No description provided for @legalTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get legalTermsTitle;

  /// No description provided for @legalTermsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These terms govern your use of SmartSpend and its financial planning features.'**
  String get legalTermsSubtitle;

  /// No description provided for @legalTermsUseHeading.
  ///
  /// In en, this message translates to:
  /// **'Use of the App'**
  String get legalTermsUseHeading;

  /// No description provided for @legalTermsUseBody.
  ///
  /// In en, this message translates to:
  /// **'SmartSpend is provided for personal financial organization and insight generation. You are responsible for the accuracy of the information you enter and for any decisions you make based on the app output.'**
  String get legalTermsUseBody;

  /// No description provided for @legalTermsGuidanceHeading.
  ///
  /// In en, this message translates to:
  /// **'Financial Guidance'**
  String get legalTermsGuidanceHeading;

  /// No description provided for @legalTermsGuidanceBody.
  ///
  /// In en, this message translates to:
  /// **'Insights, forecasts, and recommendations are informational only. They do not constitute regulated financial, tax, legal, or investment advice.'**
  String get legalTermsGuidanceBody;

  /// No description provided for @legalTermsSecurityHeading.
  ///
  /// In en, this message translates to:
  /// **'Security Responsibilities'**
  String get legalTermsSecurityHeading;

  /// No description provided for @legalTermsSecurityBody.
  ///
  /// In en, this message translates to:
  /// **'You are responsible for maintaining access controls on your device, including passcodes, biometrics, and account protection settings. Do not share access to sensitive financial information with unauthorized users.'**
  String get legalTermsSecurityBody;

  /// No description provided for @legalTermsChangesHeading.
  ///
  /// In en, this message translates to:
  /// **'Service Changes'**
  String get legalTermsChangesHeading;

  /// No description provided for @legalTermsChangesBody.
  ///
  /// In en, this message translates to:
  /// **'Features may evolve over time. SmartSpend may update, improve, limit, or remove functionality as the product changes.'**
  String get legalTermsChangesBody;

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyTitle;

  /// No description provided for @legalPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'This policy explains what SmartSpend stores and how it handles your financial data locally.'**
  String get legalPrivacySubtitle;

  /// No description provided for @legalPrivacyDataHeading.
  ///
  /// In en, this message translates to:
  /// **'Data We Process'**
  String get legalPrivacyDataHeading;

  /// No description provided for @legalPrivacyDataBody.
  ///
  /// In en, this message translates to:
  /// **'SmartSpend processes the transactions, budgets, subscriptions, and security preferences you enter so it can show reports, forecasts, and insights.'**
  String get legalPrivacyDataBody;

  /// No description provided for @legalPrivacyStorageHeading.
  ///
  /// In en, this message translates to:
  /// **'Local Storage'**
  String get legalPrivacyStorageHeading;

  /// No description provided for @legalPrivacyStorageBody.
  ///
  /// In en, this message translates to:
  /// **'Sensitive settings and authentication metadata may be stored securely on your device using platform-provided secure storage and local databases.'**
  String get legalPrivacyStorageBody;

  /// No description provided for @legalPrivacyBiometricHeading.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get legalPrivacyBiometricHeading;

  /// No description provided for @legalPrivacyBiometricBody.
  ///
  /// In en, this message translates to:
  /// **'If you enable biometrics, SmartSpend uses the operating system authentication framework to verify your identity. Biometric templates are managed by the operating system and are not directly accessible to the app.'**
  String get legalPrivacyBiometricBody;

  /// No description provided for @legalPrivacyControlHeading.
  ///
  /// In en, this message translates to:
  /// **'Your Control'**
  String get legalPrivacyControlHeading;

  /// No description provided for @legalPrivacyControlBody.
  ///
  /// In en, this message translates to:
  /// **'You can review, edit, or delete app data from within the product where supported. You can also disable biometric authentication and related security features at any time.'**
  String get legalPrivacyControlBody;

  /// No description provided for @legalCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal Center'**
  String get legalCenterTitle;

  /// No description provided for @legalCenterIntro.
  ///
  /// In en, this message translates to:
  /// **'Review all legal documents that govern SmartSpend, including terms, privacy, security, and data handling policies.'**
  String get legalCenterIntro;

  /// No description provided for @legalAllDocuments.
  ///
  /// In en, this message translates to:
  /// **'All legal documents'**
  String get legalAllDocuments;

  /// No description provided for @legalAllDocumentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the complete legal center with all policies.'**
  String get legalAllDocumentsSubtitle;

  /// No description provided for @legalCookiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cookies & Tracking Notice'**
  String get legalCookiesTitle;

  /// No description provided for @legalCookiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How tracking technologies and analytics are used in the app.'**
  String get legalCookiesSubtitle;

  /// No description provided for @legalAupTitle.
  ///
  /// In en, this message translates to:
  /// **'Acceptable Use Policy'**
  String get legalAupTitle;

  /// No description provided for @legalAupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rules and prohibited behavior when using SmartSpend.'**
  String get legalAupSubtitle;

  /// No description provided for @legalDataRetentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Retention Policy'**
  String get legalDataRetentionTitle;

  /// No description provided for @legalDataRetentionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How long data is retained and when it is deleted.'**
  String get legalDataRetentionSubtitle;

  /// No description provided for @legalSecurityDisclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Disclosure Policy'**
  String get legalSecurityDisclosureTitle;

  /// No description provided for @legalSecurityDisclosureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How to report vulnerabilities and how we respond.'**
  String get legalSecurityDisclosureSubtitle;

  /// No description provided for @legalThirdPartyServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Third-Party Services Notice'**
  String get legalThirdPartyServicesTitle;

  /// No description provided for @legalThirdPartyServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Which external services process data for SmartSpend.'**
  String get legalThirdPartyServicesSubtitle;

  /// No description provided for @legalDisclaimersTitle.
  ///
  /// In en, this message translates to:
  /// **'Disclaimers'**
  String get legalDisclaimersTitle;

  /// No description provided for @legalDisclaimersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Important limitations and non-advice statements.'**
  String get legalDisclaimersSubtitle;

  /// No description provided for @legalLoadError.
  ///
  /// In en, this message translates to:
  /// **'We could not load this legal document.'**
  String get legalLoadError;

  /// No description provided for @legalTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get legalTryAgain;

  /// No description provided for @legalAndOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Legal & onboarding'**
  String get legalAndOnboarding;

  /// No description provided for @reviewTerms.
  ///
  /// In en, this message translates to:
  /// **'Review Terms & Conditions'**
  String get reviewTerms;

  /// No description provided for @reviewPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Review Privacy Policy'**
  String get reviewPrivacy;

  /// No description provided for @restartOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Restart onboarding'**
  String get restartOnboarding;

  /// No description provided for @restartOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the product introduction and legal acceptance flow again.'**
  String get restartOnboardingSubtitle;

  /// No description provided for @simulationSpendReductionTitle.
  ///
  /// In en, this message translates to:
  /// **'Spend reduction simulator'**
  String get simulationSpendReductionTitle;

  /// No description provided for @simulationSpendReductionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try preset reduction goals and compare the results.'**
  String get simulationSpendReductionSubtitle;

  /// No description provided for @simulationProjectedMonthlySpend.
  ///
  /// In en, this message translates to:
  /// **'Projected monthly spend: {amount}'**
  String simulationProjectedMonthlySpend(String amount);

  /// No description provided for @simulationProjectedEndBalance.
  ///
  /// In en, this message translates to:
  /// **'Projected end balance: {amount}'**
  String simulationProjectedEndBalance(String amount);

  /// No description provided for @simulationPotentialSavings.
  ///
  /// In en, this message translates to:
  /// **'Potential savings: {amount}'**
  String simulationPotentialSavings(String amount);

  /// No description provided for @simulationRecommendationPositive.
  ///
  /// In en, this message translates to:
  /// **'This goal helps preserve your buffer and reduces risk.'**
  String get simulationRecommendationPositive;

  /// No description provided for @simulationRecommendationNegative.
  ///
  /// In en, this message translates to:
  /// **'Even with this reduction, you may need deeper cuts to stay cash-positive.'**
  String get simulationRecommendationNegative;

  /// No description provided for @commonNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get commonNow;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsNotificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get settingsNotificationsEnabled;

  /// No description provided for @settingsNotificationsPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get settingsNotificationsPaused;

  /// No description provided for @settingsControlCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Control Center'**
  String get settingsControlCenterTitle;

  /// No description provided for @settingsControlCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personalize appearance, automation, and alerts from one place.'**
  String get settingsControlCenterSubtitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get settingsAlerts;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how SmartSpend should look.'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used across the app.'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsCurrencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used for monetary display across the app.'**
  String get settingsCurrencySubtitle;

  /// No description provided for @settingsBudgetRollover.
  ///
  /// In en, this message translates to:
  /// **'Budget Rollover'**
  String get settingsBudgetRollover;

  /// No description provided for @settingsAutoRolloverBudgets.
  ///
  /// In en, this message translates to:
  /// **'Auto-rollover budgets'**
  String get settingsAutoRolloverBudgets;

  /// No description provided for @settingsAutoRolloverBudgetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically start a new cycle when a budget period ends.'**
  String get settingsAutoRolloverBudgetsSubtitle;

  /// No description provided for @settingsRolloverDay.
  ///
  /// In en, this message translates to:
  /// **'Rollover day'**
  String get settingsRolloverDay;

  /// No description provided for @settingsRolloverDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used for monthly/yearly budget cycle boundaries.'**
  String get settingsRolloverDaySubtitle;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get settingsEnableNotifications;

  /// No description provided for @settingsEnableNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Master switch for all budget/savings alerts.'**
  String get settingsEnableNotificationsSubtitle;

  /// No description provided for @settingsNudgeFrequency.
  ///
  /// In en, this message translates to:
  /// **'Nudge frequency'**
  String get settingsNudgeFrequency;

  /// No description provided for @frequencyImmediate.
  ///
  /// In en, this message translates to:
  /// **'Immediate'**
  String get frequencyImmediate;

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @settingsQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get settingsQuietHours;

  /// No description provided for @settingsBudgetAlerts.
  ///
  /// In en, this message translates to:
  /// **'Budget alerts'**
  String get settingsBudgetAlerts;

  /// No description provided for @settingsSavingsNudges.
  ///
  /// In en, this message translates to:
  /// **'Savings nudges'**
  String get settingsSavingsNudges;

  /// No description provided for @settingsHealthInsights.
  ///
  /// In en, this message translates to:
  /// **'Health insights'**
  String get settingsHealthInsights;

  /// No description provided for @settingsNextEligibleSendTime.
  ///
  /// In en, this message translates to:
  /// **'Next eligible send time'**
  String get settingsNextEligibleSendTime;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsAuthenticationSettings.
  ///
  /// In en, this message translates to:
  /// **'Authentication settings'**
  String get settingsAuthenticationSettings;

  /// No description provided for @settingsAuthenticationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Biometrics, session timeout, lockout controls'**
  String get settingsAuthenticationSettingsSubtitle;

  /// No description provided for @settingsBlockedNotificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Blocked because notifications are disabled.'**
  String get settingsBlockedNotificationsDisabled;

  /// No description provided for @settingsBlockedCategoryDisabled.
  ///
  /// In en, this message translates to:
  /// **'Blocked because this category is disabled.'**
  String get settingsBlockedCategoryDisabled;

  /// No description provided for @settingsNotEligibleRightNow.
  ///
  /// In en, this message translates to:
  /// **'Not eligible right now'**
  String get settingsNotEligibleRightNow;

  /// No description provided for @settingsBlockedByQuietHoursUntil.
  ///
  /// In en, this message translates to:
  /// **'Blocked by quiet hours until {when} ({countdown}).'**
  String settingsBlockedByQuietHoursUntil(String when, String countdown);

  /// No description provided for @settingsBlockedByFrequencyCooldownUntil.
  ///
  /// In en, this message translates to:
  /// **'Blocked by frequency cooldown until {when} ({countdown}).'**
  String settingsBlockedByFrequencyCooldownUntil(String when, String countdown);

  /// No description provided for @settingsNotificationsAreDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled.'**
  String get settingsNotificationsAreDisabled;

  /// No description provided for @settingsThisCategoryIsDisabled.
  ///
  /// In en, this message translates to:
  /// **'This category is disabled.'**
  String get settingsThisCategoryIsDisabled;

  /// No description provided for @settingsReadyToSendNow.
  ///
  /// In en, this message translates to:
  /// **'Ready to send now.'**
  String get settingsReadyToSendNow;

  /// No description provided for @settingsNextEligible.
  ///
  /// In en, this message translates to:
  /// **'Next eligible: {when}'**
  String settingsNextEligible(String when);

  /// No description provided for @settingsCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get settingsCalculating;

  /// No description provided for @settingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get settingsUnavailable;

  /// No description provided for @insightsFinancialCopilot.
  ///
  /// In en, this message translates to:
  /// **'Financial Copilot'**
  String get insightsFinancialCopilot;

  /// No description provided for @insightsCriticalCashflowRisk.
  ///
  /// In en, this message translates to:
  /// **'Critical cashflow risk detected. Review spending immediately.'**
  String get insightsCriticalCashflowRisk;

  /// No description provided for @insightsElevatedCashflowRisk.
  ///
  /// In en, this message translates to:
  /// **'Elevated cashflow risk detected. Monitor spending closely.'**
  String get insightsElevatedCashflowRisk;

  /// No description provided for @insightsUpcomingRenewalsDueSoon.
  ///
  /// In en, this message translates to:
  /// **'{count} upcoming subscription renewal(s) due soon.'**
  String insightsUpcomingRenewalsDueSoon(int count);

  /// No description provided for @insightsWeakSecuritySettings.
  ///
  /// In en, this message translates to:
  /// **'Security settings are weak. Enable PIN or biometrics today.'**
  String get insightsWeakSecuritySettings;

  /// No description provided for @insightsDecisionSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Decision Snapshot'**
  String get insightsDecisionSnapshot;

  /// No description provided for @insightsRiskLevel.
  ///
  /// In en, this message translates to:
  /// **'Risk level: {level}'**
  String insightsRiskLevel(String level);

  /// No description provided for @insightsRiskLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get insightsRiskLow;

  /// No description provided for @insightsRiskMedium.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get insightsRiskMedium;

  /// No description provided for @insightsRiskHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get insightsRiskHigh;

  /// No description provided for @insightsRiskCritical.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL'**
  String get insightsRiskCritical;

  /// No description provided for @insightsMetricSubscriptionPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Subscription / mo'**
  String get insightsMetricSubscriptionPerMonth;

  /// No description provided for @insightsMetricAnomalies.
  ///
  /// In en, this message translates to:
  /// **'Anomalies'**
  String get insightsMetricAnomalies;

  /// No description provided for @insightsMetricRenewals14d.
  ///
  /// In en, this message translates to:
  /// **'Renewals (14d)'**
  String get insightsMetricRenewals14d;

  /// No description provided for @insightsMetricSecurityScore.
  ///
  /// In en, this message translates to:
  /// **'Security score'**
  String get insightsMetricSecurityScore;

  /// No description provided for @insightsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get insightsNotAvailable;

  /// No description provided for @insightsActionableInsights.
  ///
  /// In en, this message translates to:
  /// **'Actionable insights'**
  String get insightsActionableInsights;

  /// No description provided for @insightsCategoryDistribution.
  ///
  /// In en, this message translates to:
  /// **'Category distribution'**
  String get insightsCategoryDistribution;

  /// No description provided for @insightsNoCategoryData.
  ///
  /// In en, this message translates to:
  /// **'No category data available yet.'**
  String get insightsNoCategoryData;

  /// No description provided for @insightsAnomaliesAndImpact.
  ///
  /// In en, this message translates to:
  /// **'Anomalies & impact'**
  String get insightsAnomaliesAndImpact;

  /// No description provided for @insightsNoUnusualSpending.
  ///
  /// In en, this message translates to:
  /// **'No unusual spending detected.'**
  String get insightsNoUnusualSpending;

  /// No description provided for @insightsSubscriptionIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Subscription intelligence'**
  String get insightsSubscriptionIntelligence;

  /// No description provided for @insightsNoActiveSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No active subscriptions are being tracked yet.'**
  String get insightsNoActiveSubscriptions;

  /// No description provided for @insightsTotalMonthlySubscriptionSpend.
  ///
  /// In en, this message translates to:
  /// **'Total monthly subscription spend: {amount}'**
  String insightsTotalMonthlySubscriptionSpend(String amount);

  /// No description provided for @insightsRenewalsIn14d.
  ///
  /// In en, this message translates to:
  /// **'{count} subscription(s) renew within the next 14 days.'**
  String insightsRenewalsIn14d(int count);

  /// No description provided for @insightsNoRenewalsIn14d.
  ///
  /// In en, this message translates to:
  /// **'No subscription renewals due in the next 14 days.'**
  String get insightsNoRenewalsIn14d;

  /// No description provided for @insightsSecurityPosture.
  ///
  /// In en, this message translates to:
  /// **'Security posture'**
  String get insightsSecurityPosture;

  /// No description provided for @insightsSecurityConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Biometric: {biometric} • PIN: {pin}'**
  String insightsSecurityConfiguration(String biometric, String pin);

  /// No description provided for @insightsEnabled.
  ///
  /// In en, this message translates to:
  /// **'enabled'**
  String get insightsEnabled;

  /// No description provided for @insightsDisabled.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get insightsDisabled;

  /// No description provided for @insightsSecurityConfigurationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Security configuration not available.'**
  String get insightsSecurityConfigurationUnavailable;

  /// No description provided for @insightsLastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last update: {date}'**
  String insightsLastUpdate(String date);

  /// No description provided for @insightsConnectSecuritySettings.
  ///
  /// In en, this message translates to:
  /// **'Connect your security settings for tailored recommendations.'**
  String get insightsConnectSecuritySettings;

  /// No description provided for @insightsErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading insights: {error}'**
  String insightsErrorLoading(String error);

  /// No description provided for @insightsNoForecastData.
  ///
  /// In en, this message translates to:
  /// **'No forecast data available'**
  String get insightsNoForecastData;

  /// No description provided for @insightsForecastChart.
  ///
  /// In en, this message translates to:
  /// **'Forecast chart'**
  String get insightsForecastChart;

  /// No description provided for @insightsActual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get insightsActual;

  /// No description provided for @insightsPredicted.
  ///
  /// In en, this message translates to:
  /// **'Predicted'**
  String get insightsPredicted;

  /// No description provided for @insightsImpact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get insightsImpact;

  /// No description provided for @insightsAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get insightsAction;

  /// No description provided for @securitySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettingsTitle;

  /// No description provided for @securityAuthenticationAccess.
  ///
  /// In en, this message translates to:
  /// **'Authentication & access'**
  String get securityAuthenticationAccess;

  /// No description provided for @securityBiometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication'**
  String get securityBiometricAuth;

  /// No description provided for @securityBiometricAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID / Touch ID to unlock SmartSpend.'**
  String get securityBiometricAuthSubtitle;

  /// No description provided for @securitySessionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Session timeout'**
  String get securitySessionTimeout;

  /// No description provided for @securitySessionTimeoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before re-authentication'**
  String securitySessionTimeoutSubtitle(int minutes);

  /// No description provided for @securityMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String securityMinutesShort(int minutes);

  /// No description provided for @securityLockoutThreshold.
  ///
  /// In en, this message translates to:
  /// **'Lockout threshold'**
  String get securityLockoutThreshold;

  /// No description provided for @securityLockoutThresholdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock account after {attempts} failed attempts'**
  String securityLockoutThresholdSubtitle(int attempts);

  /// No description provided for @securityRecentAttempts.
  ///
  /// In en, this message translates to:
  /// **'Recent authentication attempts'**
  String get securityRecentAttempts;

  /// No description provided for @securityNoAttempts.
  ///
  /// In en, this message translates to:
  /// **'No attempts recorded yet.'**
  String get securityNoAttempts;

  /// No description provided for @securityErrorLoadingLogs.
  ///
  /// In en, this message translates to:
  /// **'Error loading logs: {error}'**
  String securityErrorLoadingLogs(String error);

  /// No description provided for @securityErrorLoadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error loading security settings: {error}'**
  String securityErrorLoadingSettings(String error);

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports & Export'**
  String get reportsTitle;

  /// No description provided for @reportsPeriod.
  ///
  /// In en, this message translates to:
  /// **'Report Period'**
  String get reportsPeriod;

  /// No description provided for @reportsFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get reportsFrom;

  /// No description provided for @reportsTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get reportsTo;

  /// No description provided for @reportsQuickSelect.
  ///
  /// In en, this message translates to:
  /// **'Quick Select'**
  String get reportsQuickSelect;

  /// No description provided for @reportsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get reportsThisWeek;

  /// No description provided for @reportsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get reportsThisMonth;

  /// No description provided for @reportsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get reportsLastMonth;

  /// No description provided for @reportsLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 Months'**
  String get reportsLast3Months;

  /// No description provided for @reportsThisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get reportsThisYear;

  /// No description provided for @reportsGenerateReports.
  ///
  /// In en, this message translates to:
  /// **'Generate Reports'**
  String get reportsGenerateReports;

  /// No description provided for @reportsFinancialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary ({currencyCode})'**
  String reportsFinancialSummary(String currencyCode);

  /// No description provided for @reportsFinancialSummaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete overview of income, expenses, and savings'**
  String get reportsFinancialSummaryDescription;

  /// No description provided for @reportsTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get reportsTransactionHistory;

  /// No description provided for @reportsTransactionHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Detailed list of all transactions in the period'**
  String get reportsTransactionHistoryDescription;

  /// No description provided for @reportsBudgetAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Budget Analysis'**
  String get reportsBudgetAnalysis;

  /// No description provided for @reportsBudgetAnalysisDescription.
  ///
  /// In en, this message translates to:
  /// **'Budget performance and spending patterns'**
  String get reportsBudgetAnalysisDescription;

  /// No description provided for @reportsSubscriptionCosts.
  ///
  /// In en, this message translates to:
  /// **'Subscription Costs'**
  String get reportsSubscriptionCosts;

  /// No description provided for @reportsSubscriptionCostsDescription.
  ///
  /// In en, this message translates to:
  /// **'Monthly breakdown of subscription expenses'**
  String get reportsSubscriptionCostsDescription;

  /// No description provided for @reportsActivity.
  ///
  /// In en, this message translates to:
  /// **'Report Activity'**
  String get reportsActivity;

  /// No description provided for @reportsGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get reportsGenerated;

  /// No description provided for @reportsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reportsToday;

  /// No description provided for @reportsTypesUsed.
  ///
  /// In en, this message translates to:
  /// **'Types Used'**
  String get reportsTypesUsed;

  /// No description provided for @reportsLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last Run'**
  String get reportsLastRun;

  /// No description provided for @reportsNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get reportsNone;

  /// No description provided for @reportsRuns.
  ///
  /// In en, this message translates to:
  /// **'{count} runs'**
  String reportsRuns(int count);

  /// No description provided for @reportsGeneratedReports.
  ///
  /// In en, this message translates to:
  /// **'Generated Reports'**
  String get reportsGeneratedReports;

  /// No description provided for @reportsNoGeneratedReports.
  ///
  /// In en, this message translates to:
  /// **'No reports generated yet. Run any report to see it listed here.'**
  String get reportsNoGeneratedReports;

  /// No description provided for @reportsExportAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get reportsExportAsPdf;

  /// No description provided for @reportsExportAsCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get reportsExportAsCsv;

  /// No description provided for @reportsShareFinancialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary Report'**
  String get reportsShareFinancialSummary;

  /// No description provided for @reportsPdfGeneratedShared.
  ///
  /// In en, this message translates to:
  /// **'PDF report generated and shared'**
  String get reportsPdfGeneratedShared;

  /// No description provided for @reportsErrorGenerating.
  ///
  /// In en, this message translates to:
  /// **'Error generating report: {error}'**
  String reportsErrorGenerating(String error);

  /// No description provided for @reportsShareTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History Export'**
  String get reportsShareTransactionHistory;

  /// No description provided for @reportsTransactionHistoryExported.
  ///
  /// In en, this message translates to:
  /// **'Transaction history exported'**
  String get reportsTransactionHistoryExported;

  /// No description provided for @reportsErrorExportingData.
  ///
  /// In en, this message translates to:
  /// **'Error exporting data: {error}'**
  String reportsErrorExportingData(String error);

  /// No description provided for @reportsShareBudgetAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Budget Analysis Report'**
  String get reportsShareBudgetAnalysis;

  /// No description provided for @reportsBudgetAnalysisGenerated.
  ///
  /// In en, this message translates to:
  /// **'Budget analysis report generated'**
  String get reportsBudgetAnalysisGenerated;

  /// No description provided for @reportsShareSubscriptionReport.
  ///
  /// In en, this message translates to:
  /// **'Subscription Report'**
  String get reportsShareSubscriptionReport;

  /// No description provided for @reportsSubscriptionReportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Subscription report generated'**
  String get reportsSubscriptionReportGenerated;

  /// No description provided for @reportsShareCompleteDataExport.
  ///
  /// In en, this message translates to:
  /// **'Complete Data Export'**
  String get reportsShareCompleteDataExport;

  /// No description provided for @reportsCompleteDataExportCreated.
  ///
  /// In en, this message translates to:
  /// **'Complete data export created'**
  String get reportsCompleteDataExportCreated;

  /// No description provided for @reportsTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get reportsTypeIncome;

  /// No description provided for @reportsTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get reportsTypeExpense;

  /// No description provided for @reportsTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get reportsTypeTransfer;

  /// No description provided for @reportsBillingWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get reportsBillingWeekly;

  /// No description provided for @reportsBillingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get reportsBillingMonthly;

  /// No description provided for @reportsBillingQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get reportsBillingQuarterly;

  /// No description provided for @reportsBillingYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get reportsBillingYearly;

  /// No description provided for @reportsPdfFinancialSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary Report'**
  String get reportsPdfFinancialSummaryTitle;

  /// No description provided for @reportsPdfBudgetAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Analysis Report'**
  String get reportsPdfBudgetAnalysisTitle;

  /// No description provided for @reportsPdfSubscriptionReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Report'**
  String get reportsPdfSubscriptionReportTitle;

  /// No description provided for @reportsPdfPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportsPdfPeriod;

  /// No description provided for @reportsPdfIncomeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Income & Expenses'**
  String get reportsPdfIncomeExpenses;

  /// No description provided for @reportsPdfTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get reportsPdfTotalIncome;

  /// No description provided for @reportsPdfTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get reportsPdfTotalExpenses;

  /// No description provided for @reportsPdfNetIncome.
  ///
  /// In en, this message translates to:
  /// **'Net Income'**
  String get reportsPdfNetIncome;

  /// No description provided for @reportsPdfMonthlySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Monthly Subscriptions'**
  String get reportsPdfMonthlySubscriptions;

  /// No description provided for @reportsPdfBudgetUtilization.
  ///
  /// In en, this message translates to:
  /// **'Budget Utilization'**
  String get reportsPdfBudgetUtilization;

  /// No description provided for @reportsPdfRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get reportsPdfRecentTransactions;

  /// No description provided for @reportsPdfBudgetPerformance.
  ///
  /// In en, this message translates to:
  /// **'Budget Performance'**
  String get reportsPdfBudgetPerformance;

  /// No description provided for @reportsPdfLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get reportsPdfLimit;

  /// No description provided for @reportsPdfSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get reportsPdfSpent;

  /// No description provided for @reportsPdfStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get reportsPdfStatus;

  /// No description provided for @reportsStatusOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over Budget'**
  String get reportsStatusOverBudget;

  /// No description provided for @reportsStatusNearLimit.
  ///
  /// In en, this message translates to:
  /// **'Near Limit'**
  String get reportsStatusNearLimit;

  /// No description provided for @reportsStatusOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get reportsStatusOnTrack;

  /// No description provided for @reportsPdfSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reportsPdfSummary;

  /// No description provided for @reportsPdfTotalBudgets.
  ///
  /// In en, this message translates to:
  /// **'Total Budgets'**
  String get reportsPdfTotalBudgets;

  /// No description provided for @reportsPdfOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over Budget'**
  String get reportsPdfOverBudget;

  /// No description provided for @reportsPdfNearLimit.
  ///
  /// In en, this message translates to:
  /// **'Near Limit'**
  String get reportsPdfNearLimit;

  /// No description provided for @reportsPdfOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get reportsPdfOnTrack;

  /// No description provided for @reportsPdfTotalActiveSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Total Active Subscriptions'**
  String get reportsPdfTotalActiveSubscriptions;

  /// No description provided for @reportsPdfMonthlyTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Monthly Total Cost'**
  String get reportsPdfMonthlyTotalCost;

  /// No description provided for @reportsPdfYearlyTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Yearly Total Cost'**
  String get reportsPdfYearlyTotalCost;

  /// No description provided for @reportsPdfActiveSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Active Subscriptions'**
  String get reportsPdfActiveSubscriptions;

  /// No description provided for @reportsPdfAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get reportsPdfAmount;

  /// No description provided for @reportsPdfMonthlyCost.
  ///
  /// In en, this message translates to:
  /// **'Monthly Cost'**
  String get reportsPdfMonthlyCost;

  /// No description provided for @reportsPdfNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next Due'**
  String get reportsPdfNextDue;

  /// No description provided for @reportsCsvHeaderDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportsCsvHeaderDate;

  /// No description provided for @reportsCsvHeaderCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reportsCsvHeaderCategory;

  /// No description provided for @reportsCsvHeaderAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get reportsCsvHeaderAmount;

  /// No description provided for @reportsCsvHeaderType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get reportsCsvHeaderType;

  /// No description provided for @reportsCsvHeaderNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get reportsCsvHeaderNote;

  /// No description provided for @reportsCsvHeaderDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reportsCsvHeaderDescription;

  /// No description provided for @reportsCsvRowTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get reportsCsvRowTransaction;

  /// No description provided for @reportsCsvRowSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get reportsCsvRowSubscription;

  /// No description provided for @reportsCompleteDataExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Data Export'**
  String get reportsCompleteDataExportTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get navBudgets;

  /// No description provided for @navSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get navSavings;

  /// No description provided for @navSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get navSubscriptions;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navTxns.
  ///
  /// In en, this message translates to:
  /// **'Txns'**
  String get navTxns;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navBalanceSheet.
  ///
  /// In en, this message translates to:
  /// **'Balance Sheet'**
  String get navBalanceSheet;

  /// No description provided for @navExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get navExchangeRates;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navAiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get navAiInsights;

  /// No description provided for @navScenarioLab.
  ///
  /// In en, this message translates to:
  /// **'Scenario Lab'**
  String get navScenarioLab;

  /// No description provided for @navLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get navLightMode;

  /// No description provided for @navDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get navDarkMode;

  /// No description provided for @navHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get navHelp;

  /// No description provided for @navUnableToOpenWebsite.
  ///
  /// In en, this message translates to:
  /// **'Unable to open website right now.'**
  String get navUnableToOpenWebsite;

  /// No description provided for @quickAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get quickAddTransaction;

  /// No description provided for @quickAddSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get quickAddSubscription;

  /// No description provided for @quickAddBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get quickAddBudget;

  /// No description provided for @authSecureFinancialManagement.
  ///
  /// In en, this message translates to:
  /// **'Secure Financial Management'**
  String get authSecureFinancialManagement;

  /// No description provided for @authBiometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this Mac. Verify Touch ID is enabled in System Settings.'**
  String get authBiometricNotAvailable;

  /// No description provided for @authNoBiometricsEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No biometrics enrolled. Add Touch ID in System Settings and try again.'**
  String get authNoBiometricsEnrolled;

  /// No description provided for @authBiometricLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is temporarily locked. Try again later.'**
  String get authBiometricLockedOut;

  /// No description provided for @authBiometricPermanentlyLocked.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is locked. Unlock with your device passcode first.'**
  String get authBiometricPermanentlyLocked;

  /// No description provided for @authDenied.
  ///
  /// In en, this message translates to:
  /// **'Authentication was canceled or denied. Please try again.'**
  String get authDenied;

  /// No description provided for @authSystemError.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed due to a system error. Please try again.'**
  String get authSystemError;

  /// No description provided for @authAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Authenticated'**
  String get authAuthenticated;

  /// No description provided for @authAuthenticate.
  ///
  /// In en, this message translates to:
  /// **'Authenticate'**
  String get authAuthenticate;

  /// No description provided for @transactionsDecisionOutpacingIncome.
  ///
  /// In en, this message translates to:
  /// **'Spending is outpacing income this month. Review your largest category first.'**
  String get transactionsDecisionOutpacingIncome;

  /// No description provided for @transactionsDecisionTopCategory.
  ///
  /// In en, this message translates to:
  /// **'Most spending is in {category}. That is the quickest place to tune this month.'**
  String transactionsDecisionTopCategory(String category);

  /// No description provided for @transactionsDecisionBalanced.
  ///
  /// In en, this message translates to:
  /// **'Your transaction flow is balanced. Keep an eye on recurring activity.'**
  String get transactionsDecisionBalanced;

  /// No description provided for @transactionsNoMatching.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get transactionsNoMatching;

  /// No description provided for @transactionsTryDifferentFilter.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or clear the current one.'**
  String get transactionsTryDifferentFilter;

  /// No description provided for @transactionsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get transactionsClear;

  /// No description provided for @transactionsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionsDeleted;

  /// No description provided for @transactionsNoNote.
  ///
  /// In en, this message translates to:
  /// **'No note'**
  String get transactionsNoNote;

  /// No description provided for @transactionsError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String transactionsError(String error);

  /// No description provided for @transactionsRecurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get transactionsRecurrenceDaily;

  /// No description provided for @transactionsRecurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get transactionsRecurrenceWeekly;

  /// No description provided for @transactionsRecurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get transactionsRecurrenceMonthly;

  /// No description provided for @transactionsRecurrenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get transactionsRecurrenceYearly;

  /// No description provided for @transactionsRecurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get transactionsRecurrenceNone;

  /// No description provided for @transactionsSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get transactionsSpent;

  /// No description provided for @transactionsRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get transactionsRecurring;

  /// No description provided for @transactionsNetFlow.
  ///
  /// In en, this message translates to:
  /// **'Net Flow'**
  String get transactionsNetFlow;

  /// No description provided for @transactionsTopCategory.
  ///
  /// In en, this message translates to:
  /// **'Top Category'**
  String get transactionsTopCategory;

  /// No description provided for @transactionsUpdateTransaction.
  ///
  /// In en, this message translates to:
  /// **'Update Transaction'**
  String get transactionsUpdateTransaction;

  /// No description provided for @transactionsEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get transactionsEnterAmount;

  /// No description provided for @transactionsInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get transactionsInvalidNumber;

  /// No description provided for @transactionsNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (Optional)'**
  String get transactionsNoteOptional;

  /// No description provided for @transactionsRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get transactionsRecurrence;

  /// No description provided for @transactionsSaveTransaction.
  ///
  /// In en, this message translates to:
  /// **'Save Transaction'**
  String get transactionsSaveTransaction;

  /// No description provided for @transactionsSaved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get transactionsSaved;

  /// No description provided for @transactionsEditTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get transactionsEditTransaction;

  /// No description provided for @transactionsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Transaction not found'**
  String get transactionsNotFound;

  /// No description provided for @exchangeUnableToFetch.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch exchange rate.'**
  String get exchangeUnableToFetch;

  /// No description provided for @exchangeLiveRateChecker.
  ///
  /// In en, this message translates to:
  /// **'Live Rate Checker'**
  String get exchangeLiveRateChecker;

  /// No description provided for @exchangeRateProviderInfo.
  ///
  /// In en, this message translates to:
  /// **'Rates provided by ExchangeRate-API / Frankfurter. For informational purposes only.'**
  String get exchangeRateProviderInfo;

  /// No description provided for @exchangeRatesFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get exchangeRatesFrom;

  /// No description provided for @exchangeRatesTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get exchangeRatesTo;

  /// No description provided for @exchangeRatesSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap currencies'**
  String get exchangeRatesSwap;

  /// No description provided for @exchangeRatesCheckRate.
  ///
  /// In en, this message translates to:
  /// **'Check Rate'**
  String get exchangeRatesCheckRate;

  /// No description provided for @exchangeRatesConversionResult.
  ///
  /// In en, this message translates to:
  /// **'Conversion Result'**
  String get exchangeRatesConversionResult;

  /// No description provided for @exchangeRatesTrend7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days trend'**
  String get exchangeRatesTrend7Days;

  /// No description provided for @exchangeRatesRateDate.
  ///
  /// In en, this message translates to:
  /// **'Rate date: {date}'**
  String exchangeRatesRateDate(String date);

  /// No description provided for @subscriptionsDecisionRenewingCritical.
  ///
  /// In en, this message translates to:
  /// **'You have {count} renewal(s) due within 7 days, including essential services. Review them first.'**
  String subscriptionsDecisionRenewingCritical(int count);

  /// No description provided for @subscriptionsDecisionRenewing.
  ///
  /// In en, this message translates to:
  /// **'{count} subscription(s) renew within 7 days. This is the best place to trim near-term spending.'**
  String subscriptionsDecisionRenewing(int count);

  /// No description provided for @subscriptionsDecisionLowPriorityCost.
  ///
  /// In en, this message translates to:
  /// **'Low-priority subscriptions are costing you {amount} per month. Consider pausing the least-used ones.'**
  String subscriptionsDecisionLowPriorityCost(String amount);

  /// No description provided for @subscriptionsDecisionCritical.
  ///
  /// In en, this message translates to:
  /// **'{count} critical subscription(s) are tracked. Keep payment methods and renewal dates current.'**
  String subscriptionsDecisionCritical(int count);

  /// No description provided for @subscriptionsDecisionStable.
  ///
  /// In en, this message translates to:
  /// **'Your subscription stack looks stable. Review monthly load and low-priority services to keep it that way.'**
  String get subscriptionsDecisionStable;

  /// No description provided for @subscriptionsFilterCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get subscriptionsFilterCritical;

  /// No description provided for @subscriptionsFilterRenewingSoon.
  ///
  /// In en, this message translates to:
  /// **'Renewing Soon'**
  String get subscriptionsFilterRenewingSoon;

  /// No description provided for @subscriptionsFilterHighPriority.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get subscriptionsFilterHighPriority;

  /// No description provided for @subscriptionsFilterLowPriority.
  ///
  /// In en, this message translates to:
  /// **'Low Priority'**
  String get subscriptionsFilterLowPriority;

  /// No description provided for @subscriptionsDueThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Due This Month'**
  String get subscriptionsDueThisMonth;

  /// No description provided for @subscriptionsFilteredTo.
  ///
  /// In en, this message translates to:
  /// **'Filtered to {filter} subscriptions'**
  String subscriptionsFilteredTo(String filter);

  /// No description provided for @subscriptionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get subscriptionsEmpty;

  /// No description provided for @subscriptionsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first subscription to start tracking'**
  String get subscriptionsEmptySubtitle;

  /// No description provided for @subscriptionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Subscription'**
  String get subscriptionsAdd;

  /// No description provided for @subscriptionsShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} {filter} subscription(s)'**
  String subscriptionsShowing(int count, String filter);

  /// No description provided for @subscriptionsDueLine.
  ///
  /// In en, this message translates to:
  /// **'{amount} - Due {date}'**
  String subscriptionsDueLine(String amount, String date);

  /// No description provided for @subscriptionsBillingWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get subscriptionsBillingWeekly;

  /// No description provided for @subscriptionsBillingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscriptionsBillingMonthly;

  /// No description provided for @subscriptionsBillingQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get subscriptionsBillingQuarterly;

  /// No description provided for @subscriptionsBillingYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subscriptionsBillingYearly;

  /// No description provided for @subscriptionsNext7Days.
  ///
  /// In en, this message translates to:
  /// **'Next 7 Days'**
  String get subscriptionsNext7Days;

  /// No description provided for @subscriptionsMonthlyLoad.
  ///
  /// In en, this message translates to:
  /// **'Monthly Load'**
  String get subscriptionsMonthlyLoad;

  /// No description provided for @subscriptionsOptionalSavings.
  ///
  /// In en, this message translates to:
  /// **'Optional Savings'**
  String get subscriptionsOptionalSavings;

  /// No description provided for @subscriptionsPerCycle.
  ///
  /// In en, this message translates to:
  /// **'{amount} per {cycle}'**
  String subscriptionsPerCycle(String amount, String cycle);

  /// No description provided for @subscriptionsNextBilling.
  ///
  /// In en, this message translates to:
  /// **'Next billing: {date}'**
  String subscriptionsNextBilling(String date);

  /// No description provided for @subscriptionsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get subscriptionsPerMonth;

  /// No description provided for @subscriptionsCycleWeek.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get subscriptionsCycleWeek;

  /// No description provided for @subscriptionsCycleMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get subscriptionsCycleMonth;

  /// No description provided for @subscriptionsCycleQuarter.
  ///
  /// In en, this message translates to:
  /// **'quarter'**
  String get subscriptionsCycleQuarter;

  /// No description provided for @subscriptionsCycleYear.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get subscriptionsCycleYear;

  /// No description provided for @subscriptionsCategoryStreaming.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get subscriptionsCategoryStreaming;

  /// No description provided for @subscriptionsCategorySoftware.
  ///
  /// In en, this message translates to:
  /// **'Software'**
  String get subscriptionsCategorySoftware;

  /// No description provided for @subscriptionsCategoryCloudStorage.
  ///
  /// In en, this message translates to:
  /// **'Cloud Storage'**
  String get subscriptionsCategoryCloudStorage;

  /// No description provided for @subscriptionsCategoryFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get subscriptionsCategoryFitness;

  /// No description provided for @subscriptionsCategoryMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get subscriptionsCategoryMusic;

  /// No description provided for @subscriptionsCategoryNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get subscriptionsCategoryNews;

  /// No description provided for @subscriptionsCategoryCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get subscriptionsCategoryCommunication;

  /// No description provided for @subscriptionsCategoryProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get subscriptionsCategoryProductivity;

  /// No description provided for @subscriptionsCategoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get subscriptionsCategoryEntertainment;

  /// No description provided for @subscriptionsCategoryInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get subscriptionsCategoryInsurance;

  /// No description provided for @subscriptionsCategoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get subscriptionsCategoryUtilities;

  /// No description provided for @subscriptionsCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get subscriptionsCategoryTransport;

  /// No description provided for @subscriptionsCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get subscriptionsCategoryHealth;

  /// No description provided for @subscriptionsCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get subscriptionsCategoryOther;

  /// No description provided for @subscriptionsImportanceLow.
  ///
  /// In en, this message translates to:
  /// **'Low - Optional/Nice-to-have'**
  String get subscriptionsImportanceLow;

  /// No description provided for @subscriptionsImportanceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium - Regular use'**
  String get subscriptionsImportanceMedium;

  /// No description provided for @subscriptionsImportanceHigh.
  ///
  /// In en, this message translates to:
  /// **'High - Important service'**
  String get subscriptionsImportanceHigh;

  /// No description provided for @subscriptionsImportanceCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical - Essential service'**
  String get subscriptionsImportanceCritical;

  /// No description provided for @subscriptionsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving subscription: {error}'**
  String subscriptionsSaveError(String error);

  /// No description provided for @subscriptionsEditSubscription.
  ///
  /// In en, this message translates to:
  /// **'Edit Subscription'**
  String get subscriptionsEditSubscription;

  /// No description provided for @subscriptionsAddSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add Subscription'**
  String get subscriptionsAddSubscription;

  /// No description provided for @subscriptionsName.
  ///
  /// In en, this message translates to:
  /// **'Subscription Name'**
  String get subscriptionsName;

  /// No description provided for @subscriptionsNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Netflix, Spotify'**
  String get subscriptionsNameHint;

  /// No description provided for @subscriptionsEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subscription name'**
  String get subscriptionsEnterName;

  /// No description provided for @subscriptionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get subscriptionsRequired;

  /// No description provided for @subscriptionsInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get subscriptionsInvalidAmount;

  /// No description provided for @subscriptionsBillingCycle.
  ///
  /// In en, this message translates to:
  /// **'Billing Cycle'**
  String get subscriptionsBillingCycle;

  /// No description provided for @subscriptionsImportance.
  ///
  /// In en, this message translates to:
  /// **'Importance'**
  String get subscriptionsImportance;

  /// No description provided for @subscriptionsCostSummary.
  ///
  /// In en, this message translates to:
  /// **'Cost Summary'**
  String get subscriptionsCostSummary;

  /// No description provided for @subscriptionsMonthlyCost.
  ///
  /// In en, this message translates to:
  /// **'Monthly Cost'**
  String get subscriptionsMonthlyCost;

  /// No description provided for @subscriptionsAnnualCost.
  ///
  /// In en, this message translates to:
  /// **'Annual Cost'**
  String get subscriptionsAnnualCost;

  /// No description provided for @subscriptionsStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get subscriptionsStartDate;

  /// No description provided for @subscriptionsNextBillingLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Billing'**
  String get subscriptionsNextBillingLabel;

  /// No description provided for @subscriptionsOptionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional Details'**
  String get subscriptionsOptionalDetails;

  /// No description provided for @subscriptionsPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get subscriptionsPaymentMethod;

  /// No description provided for @subscriptionsPaymentMethodHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Credit Card, PayPal'**
  String get subscriptionsPaymentMethodHint;

  /// No description provided for @subscriptionsWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get subscriptionsWebsite;

  /// No description provided for @subscriptionsWebsiteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., netflix.com'**
  String get subscriptionsWebsiteHint;

  /// No description provided for @subscriptionsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get subscriptionsNotes;

  /// No description provided for @subscriptionsNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add any notes about this subscription'**
  String get subscriptionsNotesHint;

  /// No description provided for @subscriptionsDecisionHelp.
  ///
  /// In en, this message translates to:
  /// **'Decision Help'**
  String get subscriptionsDecisionHelp;

  /// No description provided for @subscriptionsDecisionEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount to see suggestions'**
  String get subscriptionsDecisionEnterAmount;

  /// No description provided for @subscriptionsDecisionHighAnnualCost.
  ///
  /// In en, this message translates to:
  /// **'High annual cost ({amount}) - Consider if this is essential or could be replaced'**
  String subscriptionsDecisionHighAnnualCost(String amount);

  /// No description provided for @subscriptionsDecisionModerateAnnualCost.
  ///
  /// In en, this message translates to:
  /// **'Moderate annual cost ({amount}) - Make sure you actively use this'**
  String subscriptionsDecisionModerateAnnualCost(String amount);

  /// No description provided for @subscriptionsDecisionTrackRegularly.
  ///
  /// In en, this message translates to:
  /// **'Track regularly to avoid inactive subscriptions'**
  String get subscriptionsDecisionTrackRegularly;

  /// No description provided for @subscriptionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading subscription: {error}'**
  String subscriptionsLoadError(String error);

  /// No description provided for @subscriptionsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Subscription not found'**
  String get subscriptionsNotFound;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Budget alerts, savings nudges, and health insights will appear here.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications: {error}'**
  String notificationsLoadError(String error);

  /// No description provided for @financialHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Health'**
  String get financialHealthTitle;

  /// No description provided for @financialHealthStatusStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get financialHealthStatusStrong;

  /// No description provided for @financialHealthStatusNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get financialHealthStatusNeedsAttention;

  /// No description provided for @financialHealthStatusAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get financialHealthStatusAtRisk;

  /// No description provided for @financialHealthPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Health portfolio'**
  String get financialHealthPortfolio;

  /// No description provided for @financialHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get financialHealthScore;

  /// No description provided for @financialHealthGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get financialHealthGoals;

  /// No description provided for @financialHealthUpdateWeekly.
  ///
  /// In en, this message translates to:
  /// **'Update weekly'**
  String get financialHealthUpdateWeekly;

  /// No description provided for @financialHealthActiveCounts.
  ///
  /// In en, this message translates to:
  /// **'Active budgets: {budgets} • Active goals: {goals}'**
  String financialHealthActiveCounts(int budgets, int goals);

  /// No description provided for @financialHealthBudgetDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Budget discipline'**
  String get financialHealthBudgetDiscipline;

  /// No description provided for @financialHealthBudgetDisciplineDescription.
  ///
  /// In en, this message translates to:
  /// **'Measures pressure from near-limit and exceeded budgets.'**
  String get financialHealthBudgetDisciplineDescription;

  /// No description provided for @financialHealthSavingsMomentum.
  ///
  /// In en, this message translates to:
  /// **'Savings momentum'**
  String get financialHealthSavingsMomentum;

  /// No description provided for @financialHealthSavingsMomentumDescription.
  ///
  /// In en, this message translates to:
  /// **'Measures goal progress and schedule adherence.'**
  String get financialHealthSavingsMomentumDescription;

  /// No description provided for @financialHealthBudgetUtilization.
  ///
  /// In en, this message translates to:
  /// **'Budget utilization'**
  String get financialHealthBudgetUtilization;

  /// No description provided for @financialHealthBudgetUtilizationDescription.
  ///
  /// In en, this message translates to:
  /// **'Measures category-level spending efficiency across budget periods.'**
  String get financialHealthBudgetUtilizationDescription;

  /// No description provided for @financialHealthTrendWindow.
  ///
  /// In en, this message translates to:
  /// **'Trend window'**
  String get financialHealthTrendWindow;

  /// No description provided for @financialHealthWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks'**
  String financialHealthWeeks(int count);

  /// No description provided for @financialHealthRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get financialHealthRecommendations;

  /// No description provided for @financialHealthRecommendationExceeded.
  ///
  /// In en, this message translates to:
  /// **'Reduce discretionary spending in categories that already exceeded budget.'**
  String get financialHealthRecommendationExceeded;

  /// No description provided for @financialHealthRecommendationNearLimit.
  ///
  /// In en, this message translates to:
  /// **'Rebalance near-limit budgets before the period ends.'**
  String get financialHealthRecommendationNearLimit;

  /// No description provided for @financialHealthRecommendationBehindGoals.
  ///
  /// In en, this message translates to:
  /// **'Increase monthly contributions for {count} goal(s) behind schedule.'**
  String financialHealthRecommendationBehindGoals(int count);

  /// No description provided for @financialHealthRecommendationEnableAutoAllocation.
  ///
  /// In en, this message translates to:
  /// **'Enable auto-allocation for at least one savings goal to improve consistency.'**
  String get financialHealthRecommendationEnableAutoAllocation;

  /// No description provided for @financialHealthRecommendationStable.
  ///
  /// In en, this message translates to:
  /// **'Keep your current pace and review your health score weekly.'**
  String get financialHealthRecommendationStable;

  /// No description provided for @financialHealthWeeklyNoteNoIncome.
  ///
  /// In en, this message translates to:
  /// **'No income recorded this week; spending pressure increased.'**
  String get financialHealthWeeklyNoteNoIncome;

  /// No description provided for @financialHealthWeeklyNoteImproved.
  ///
  /// In en, this message translates to:
  /// **'Health improved with stronger weekly cashflow balance.'**
  String get financialHealthWeeklyNoteImproved;

  /// No description provided for @financialHealthWeeklyNoteDropped.
  ///
  /// In en, this message translates to:
  /// **'Health dropped this week due to higher spending pressure.'**
  String get financialHealthWeeklyNoteDropped;

  /// No description provided for @financialHealthWeeklyNoteStable.
  ///
  /// In en, this message translates to:
  /// **'Stable week with limited change in financial behavior.'**
  String get financialHealthWeeklyNoteStable;

  /// No description provided for @financialHealthWeeklyTrajectory.
  ///
  /// In en, this message translates to:
  /// **'Weekly health trajectory'**
  String get financialHealthWeeklyTrajectory;

  /// No description provided for @financialHealthOverallChange.
  ///
  /// In en, this message translates to:
  /// **'Overall change: {delta} points over {weeks} weeks.'**
  String financialHealthOverallChange(String delta, int weeks);

  /// No description provided for @financialHealthBiggestGain.
  ///
  /// In en, this message translates to:
  /// **'Biggest gain: {delta} on {date}.'**
  String financialHealthBiggestGain(String delta, String date);

  /// No description provided for @financialHealthBiggestDrop.
  ///
  /// In en, this message translates to:
  /// **'Biggest drop: {delta} on {date}.'**
  String financialHealthBiggestDrop(String delta, String date);

  /// No description provided for @savingsNudgeBehindTitle.
  ///
  /// In en, this message translates to:
  /// **'You are behind on {goal}'**
  String savingsNudgeBehindTitle(String goal);

  /// No description provided for @savingsNudgeBehindMessage.
  ///
  /// In en, this message translates to:
  /// **'You are about {amount} behind schedule. Consider increasing monthly savings.'**
  String savingsNudgeBehindMessage(String amount);

  /// No description provided for @savingsNudgeAutoAllocateTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable auto-allocation for {goal}'**
  String savingsNudgeAutoAllocateTitle(String goal);

  /// No description provided for @savingsNudgeAutoAllocateMessage.
  ///
  /// In en, this message translates to:
  /// **'Auto-allocation can help keep contributions consistent each month.'**
  String get savingsNudgeAutoAllocateMessage;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get commonSeeAll;

  /// No description provided for @commonViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get commonViewDetails;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @dashboardBudgetExceededTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Exceeded!'**
  String get dashboardBudgetExceededTitle;

  /// No description provided for @dashboardBudgetAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Alert'**
  String get dashboardBudgetAlertTitle;

  /// No description provided for @dashboardBudgetAlertBody.
  ///
  /// In en, this message translates to:
  /// **'{category} spending is at {percent}% of limit'**
  String dashboardBudgetAlertBody(String category, String percent);

  /// No description provided for @dashboardHealthNeedsAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial health needs attention'**
  String get dashboardHealthNeedsAttentionTitle;

  /// No description provided for @dashboardHealthNeedsAttentionBody.
  ///
  /// In en, this message translates to:
  /// **'Your score is {score}. Review the Health details for actions.'**
  String dashboardHealthNeedsAttentionBody(String score);

  /// No description provided for @dashboardMetricsTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get dashboardMetricsTransactions;

  /// No description provided for @dashboardMetricsBudgetAlerts.
  ///
  /// In en, this message translates to:
  /// **'Budget alerts'**
  String get dashboardMetricsBudgetAlerts;

  /// No description provided for @dashboardMetricsHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Money Health Index'**
  String get dashboardMetricsHealthScore;

  /// No description provided for @dashboardBalanceSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring Balance Sheet'**
  String get dashboardBalanceSheetTitle;

  /// No description provided for @dashboardBalanceSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See if recurring income covers recurring bills and subscriptions.'**
  String get dashboardBalanceSheetSubtitle;

  /// No description provided for @dashboardSectionThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get dashboardSectionThisMonth;

  /// No description provided for @dashboardSectionBudgetAlerts.
  ///
  /// In en, this message translates to:
  /// **'Budget Alerts'**
  String get dashboardSectionBudgetAlerts;

  /// No description provided for @dashboardNoActiveBudgetAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active budget alerts'**
  String get dashboardNoActiveBudgetAlerts;

  /// No description provided for @dashboardAlertExceeded.
  ///
  /// In en, this message translates to:
  /// **'{category} exceeded {threshold}% ({progress}%)'**
  String dashboardAlertExceeded(String category, String threshold, String progress);

  /// No description provided for @dashboardAlertNearing.
  ///
  /// In en, this message translates to:
  /// **'{category} nearing {threshold}% ({progress}%)'**
  String dashboardAlertNearing(String category, String threshold, String progress);

  /// No description provided for @dashboardCheckingAlerts.
  ///
  /// In en, this message translates to:
  /// **'Checking alerts...'**
  String get dashboardCheckingAlerts;

  /// No description provided for @dashboardAlertError.
  ///
  /// In en, this message translates to:
  /// **'Alert error: {error}'**
  String dashboardAlertError(String error);

  /// No description provided for @dashboardRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get dashboardRecentTransactions;

  /// No description provided for @dashboardErrorLoadingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Error loading transactions'**
  String get dashboardErrorLoadingTransactions;

  /// No description provided for @dashboardBurnRate.
  ///
  /// In en, this message translates to:
  /// **'Burn Rate'**
  String get dashboardBurnRate;

  /// No description provided for @dashboardUnusualTransactionsDetected.
  ///
  /// In en, this message translates to:
  /// **'{count} unusual transactions detected'**
  String dashboardUnusualTransactionsDetected(int count);

  /// No description provided for @dashboardTrendRising.
  ///
  /// In en, this message translates to:
  /// **'↑ Rising'**
  String get dashboardTrendRising;

  /// No description provided for @dashboardTrendFalling.
  ///
  /// In en, this message translates to:
  /// **'↓ Falling'**
  String get dashboardTrendFalling;

  /// No description provided for @dashboardTrendStable.
  ///
  /// In en, this message translates to:
  /// **'→ Stable'**
  String get dashboardTrendStable;

  /// No description provided for @dashboardHealthBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Budget discipline: {budget} • Savings momentum: {savings}'**
  String dashboardHealthBreakdown(String budget, String savings);

  /// No description provided for @dashboardFailedToLoadInsights.
  ///
  /// In en, this message translates to:
  /// **'Failed to load insights'**
  String get dashboardFailedToLoadInsights;

  /// No description provided for @dashboardLiveRateCheck.
  ///
  /// In en, this message translates to:
  /// **'Live Rate Check'**
  String get dashboardLiveRateCheck;

  /// No description provided for @dashboardRefreshRate.
  ///
  /// In en, this message translates to:
  /// **'Refresh rate'**
  String get dashboardRefreshRate;

  /// No description provided for @dashboardQuickQuoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick quote for your selected app currency.'**
  String get dashboardQuickQuoteSubtitle;

  /// No description provided for @dashboardRateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Rate unavailable right now. Try again or open the full tool.'**
  String get dashboardRateUnavailable;

  /// No description provided for @dashboardRateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String dashboardRateUpdated(String date);

  /// No description provided for @dashboardOpenFullTool.
  ///
  /// In en, this message translates to:
  /// **'Open full tool'**
  String get dashboardOpenFullTool;

  /// No description provided for @budgetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your first monthly budget'**
  String get budgetEmptyTitle;

  /// No description provided for @budgetEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create category budgets to track spending in real-time and avoid overspending.'**
  String get budgetEmptySubtitle;

  /// No description provided for @budgetCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Budget'**
  String get budgetCreateButton;

  /// No description provided for @budgetDecisionNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) need attention. Review the red and amber categories before adding new spend.'**
  String budgetDecisionNeedsAttention(int count);

  /// No description provided for @budgetDecisionStable.
  ///
  /// In en, this message translates to:
  /// **'Your current budget setup is stable. Use rollover only after confirming categories still fit this month.'**
  String get budgetDecisionStable;

  /// No description provided for @budgetPortfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Portfolio'**
  String get budgetPortfolioTitle;

  /// No description provided for @budgetCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get budgetCategories;

  /// No description provided for @budgetTotalLimit.
  ///
  /// In en, this message translates to:
  /// **'Total Limit'**
  String get budgetTotalLimit;

  /// No description provided for @budgetAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At Risk'**
  String get budgetAtRisk;

  /// No description provided for @budgetAverageAlert.
  ///
  /// In en, this message translates to:
  /// **'Avg Alert'**
  String get budgetAverageAlert;

  /// No description provided for @budgetRolloverNow.
  ///
  /// In en, this message translates to:
  /// **'Rollover now'**
  String get budgetRolloverNow;

  /// No description provided for @budgetSwipeRightHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe right: +10% budget'**
  String get budgetSwipeRightHint;

  /// No description provided for @budgetSwipeLeftHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe left: -10% budget'**
  String get budgetSwipeLeftHint;

  /// No description provided for @budgetIncreasedSnack.
  ///
  /// In en, this message translates to:
  /// **'{category} budget increased by 10%'**
  String budgetIncreasedSnack(String category);

  /// No description provided for @budgetReducedSnack.
  ///
  /// In en, this message translates to:
  /// **'{category} budget reduced by 10%'**
  String budgetReducedSnack(String category);

  /// No description provided for @budgetCycleAlert.
  ///
  /// In en, this message translates to:
  /// **'{period} cycle • Alert {threshold}%'**
  String budgetCycleAlert(String period, String threshold);

  /// No description provided for @budgetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get budgetEdit;

  /// No description provided for @budgetDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get budgetDelete;

  /// No description provided for @budgetLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit {amount}'**
  String budgetLimitLabel(String amount);

  /// No description provided for @budgetStatusOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get budgetStatusOnTrack;

  /// No description provided for @budgetStatusSoftWarning.
  ///
  /// In en, this message translates to:
  /// **'Soft warning'**
  String get budgetStatusSoftWarning;

  /// No description provided for @budgetStatusHighAlert.
  ///
  /// In en, this message translates to:
  /// **'High alert'**
  String get budgetStatusHighAlert;

  /// No description provided for @budgetStatusExceeded.
  ///
  /// In en, this message translates to:
  /// **'Exceeded'**
  String get budgetStatusExceeded;

  /// No description provided for @budgetPeriodEnded.
  ///
  /// In en, this message translates to:
  /// **'Period ended'**
  String get budgetPeriodEnded;

  /// No description provided for @budgetDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String budgetDaysLeft(int days);

  /// No description provided for @budgetSpendingProgress.
  ///
  /// In en, this message translates to:
  /// **'{spent} spent • {remaining} remaining • {percent}% used'**
  String budgetSpendingProgress(String spent, String remaining, String percent);

  /// No description provided for @budgetTapBarHint.
  ///
  /// In en, this message translates to:
  /// **'Tap bar to view transactions in this category'**
  String get budgetTapBarHint;

  /// No description provided for @budgetProjectedOverrun.
  ///
  /// In en, this message translates to:
  /// **'At this pace, you may exceed this budget by {amount}'**
  String budgetProjectedOverrun(String amount);

  /// No description provided for @budgetAdjustAmount.
  ///
  /// In en, this message translates to:
  /// **'Adjust amount'**
  String get budgetAdjustAmount;

  /// No description provided for @budgetErrorLoadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Error loading progress'**
  String get budgetErrorLoadingProgress;

  /// No description provided for @budgetRolloverComplete.
  ///
  /// In en, this message translates to:
  /// **'Budget rollover check complete.'**
  String get budgetRolloverComplete;

  /// No description provided for @budgetNoTransactionsForCategory.
  ///
  /// In en, this message translates to:
  /// **'No transactions found for this budget category yet.'**
  String get budgetNoTransactionsForCategory;

  /// No description provided for @budgetCategoryTransactions.
  ///
  /// In en, this message translates to:
  /// **'{category} transactions'**
  String budgetCategoryTransactions(String category);

  /// No description provided for @budgetCreate.
  ///
  /// In en, this message translates to:
  /// **'Create budget'**
  String get budgetCreate;

  /// No description provided for @budgetAmount.
  ///
  /// In en, this message translates to:
  /// **'Budget amount'**
  String get budgetAmount;

  /// No description provided for @budgetCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Food, Transport, Bills...'**
  String get budgetCategoryHint;

  /// No description provided for @budgetEnterCategory.
  ///
  /// In en, this message translates to:
  /// **'Enter a category'**
  String get budgetEnterCategory;

  /// No description provided for @budgetEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get budgetEnterValidAmount;

  /// No description provided for @budgetPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get budgetPeriod;

  /// No description provided for @budgetAlertAt.
  ///
  /// In en, this message translates to:
  /// **'Alert at {percent}%'**
  String budgetAlertAt(int percent);

  /// No description provided for @budgetAlertPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String budgetAlertPercent(int percent);

  /// No description provided for @budgetStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get budgetStartDate;

  /// No description provided for @budgetSave.
  ///
  /// In en, this message translates to:
  /// **'Save budget'**
  String get budgetSave;

  /// No description provided for @budgetUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update budget'**
  String get budgetUpdate;

  /// No description provided for @savingsGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get savingsGoalsTitle;

  /// No description provided for @savingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first savings goal'**
  String get savingsEmptyTitle;

  /// No description provided for @savingsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Define a target amount and optional deadline to build savings intentionally.'**
  String get savingsEmptySubtitle;

  /// No description provided for @savingsCreateGoal.
  ///
  /// In en, this message translates to:
  /// **'Create Goal'**
  String get savingsCreateGoal;

  /// No description provided for @savingsGoalsBehindPace.
  ///
  /// In en, this message translates to:
  /// **'{count} goal(s) are behind pace. Focus new contributions there first.'**
  String savingsGoalsBehindPace(int count);

  /// No description provided for @savingsMonthlySurplusMessage.
  ///
  /// In en, this message translates to:
  /// **'You have {amount} of monthly surplus available to accelerate your top priority goal.'**
  String savingsMonthlySurplusMessage(String amount);

  /// No description provided for @savingsSteadyProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress is steady. Keep contributions consistent to protect your deadlines.'**
  String get savingsSteadyProgress;

  /// No description provided for @savingsPortfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings Portfolio'**
  String get savingsPortfolioTitle;

  /// No description provided for @savingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savingsSaved;

  /// No description provided for @savingsTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get savingsTarget;

  /// No description provided for @savingsNudgesLabel.
  ///
  /// In en, this message translates to:
  /// **'Nudges'**
  String get savingsNudgesLabel;

  /// No description provided for @savingsSurplusDetected.
  ///
  /// In en, this message translates to:
  /// **'Surplus detected: {amount}'**
  String savingsSurplusDetected(String amount);

  /// No description provided for @savingsAllocateSurplusHint.
  ///
  /// In en, this message translates to:
  /// **'Allocate part of this surplus to accelerate your goals.'**
  String get savingsAllocateSurplusHint;

  /// No description provided for @savingsAllocateAmount.
  ///
  /// In en, this message translates to:
  /// **'Allocate \${amount}'**
  String savingsAllocateAmount(String amount);

  /// No description provided for @savingsEditGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get savingsEditGoal;

  /// No description provided for @savingsDeleteGoal.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get savingsDeleteGoal;

  /// No description provided for @savingsTimelineTracked.
  ///
  /// In en, this message translates to:
  /// **'Timeline tracked'**
  String get savingsTimelineTracked;

  /// No description provided for @savingsProgressLine.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete • {remaining} remaining'**
  String savingsProgressLine(String percent, String remaining);

  /// No description provided for @savingsDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline: {date}'**
  String savingsDeadlineLabel(String date);

  /// No description provided for @savingsSuggestionMonthly.
  ///
  /// In en, this message translates to:
  /// **'Suggestion: Save {amount}/month to stay on track.'**
  String savingsSuggestionMonthly(String amount);

  /// No description provided for @savingsProjectedLate.
  ///
  /// In en, this message translates to:
  /// **'At current pace, this goal may finish about {months} month(s) late.'**
  String savingsProjectedLate(int months);

  /// No description provided for @savingsAddFunds.
  ///
  /// In en, this message translates to:
  /// **'Add funds'**
  String get savingsAddFunds;

  /// No description provided for @savingsSimulatePlus50.
  ///
  /// In en, this message translates to:
  /// **'Simulate monthly boost'**
  String get savingsSimulatePlus50;

  /// No description provided for @savingsGoalAchieved.
  ///
  /// In en, this message translates to:
  /// **'Goal achieved! Archive it or create a new one to keep momentum.'**
  String get savingsGoalAchieved;

  /// No description provided for @savingsScenarioSimulationTitle.
  ///
  /// In en, this message translates to:
  /// **'Scenario simulation'**
  String get savingsScenarioSimulationTitle;

  /// No description provided for @savingsUnableEstimateCompletion.
  ///
  /// In en, this message translates to:
  /// **'Unable to estimate completion date with current data.'**
  String get savingsUnableEstimateCompletion;

  /// No description provided for @savingsScenarioEstimate.
  ///
  /// In en, this message translates to:
  /// **'If you increase savings by {amount}/month, you could complete this goal in about {months} month(s).'**
  String savingsScenarioEstimate(String amount, int months);

  /// No description provided for @savingsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get savingsStatusCompleted;

  /// No description provided for @savingsStatusBehindSchedule.
  ///
  /// In en, this message translates to:
  /// **'Behind schedule'**
  String get savingsStatusBehindSchedule;

  /// No description provided for @savingsStatusOnPace.
  ///
  /// In en, this message translates to:
  /// **'On pace'**
  String get savingsStatusOnPace;

  /// No description provided for @savingsStatusBuildingMomentum.
  ///
  /// In en, this message translates to:
  /// **'Building momentum'**
  String get savingsStatusBuildingMomentum;

  /// No description provided for @savingsTimeProgressLine.
  ///
  /// In en, this message translates to:
  /// **'Time progress {time}% • Savings progress {savings}%'**
  String savingsTimeProgressLine(String time, String savings);

  /// No description provided for @savingsGoalName.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get savingsGoalName;

  /// No description provided for @savingsEnterGoalName.
  ///
  /// In en, this message translates to:
  /// **'Enter a goal name'**
  String get savingsEnterGoalName;

  /// No description provided for @savingsTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get savingsTargetAmount;

  /// No description provided for @savingsEnterValidTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid target amount'**
  String get savingsEnterValidTargetAmount;

  /// No description provided for @savingsCurrentSavedAmount.
  ///
  /// In en, this message translates to:
  /// **'Current saved amount'**
  String get savingsCurrentSavedAmount;

  /// No description provided for @savingsEnterValidSavedAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid saved amount'**
  String get savingsEnterValidSavedAmount;

  /// No description provided for @savingsPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get savingsPriority;

  /// No description provided for @savingsEnableAutoAllocation.
  ///
  /// In en, this message translates to:
  /// **'Enable auto-allocation'**
  String get savingsEnableAutoAllocation;

  /// No description provided for @savingsDeadlineOptional.
  ///
  /// In en, this message translates to:
  /// **'Deadline (optional)'**
  String get savingsDeadlineOptional;

  /// No description provided for @savingsNoDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get savingsNoDeadline;

  /// No description provided for @savingsSaveGoal.
  ///
  /// In en, this message translates to:
  /// **'Save goal'**
  String get savingsSaveGoal;

  /// No description provided for @savingsUpdateGoal.
  ///
  /// In en, this message translates to:
  /// **'Update goal'**
  String get savingsUpdateGoal;

  /// No description provided for @savingsAddToGoal.
  ///
  /// In en, this message translates to:
  /// **'Add to {goal}'**
  String savingsAddToGoal(String goal);

  /// No description provided for @balanceSheetRecurringType.
  ///
  /// In en, this message translates to:
  /// **'Recurring {type}'**
  String balanceSheetRecurringType(String type);

  /// No description provided for @balanceSheetInsightEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recurring plan available yet'**
  String get balanceSheetInsightEmptyTitle;

  /// No description provided for @balanceSheetInsightEmptyExplanation.
  ///
  /// In en, this message translates to:
  /// **'Add recurring transactions or subscriptions to generate a balance sheet.'**
  String get balanceSheetInsightEmptyExplanation;

  /// No description provided for @balanceSheetInsightEmptyImpact.
  ///
  /// In en, this message translates to:
  /// **'Without recurring entries, the app cannot estimate fixed monthly commitments.'**
  String get balanceSheetInsightEmptyImpact;

  /// No description provided for @balanceSheetInsightEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Mark salary, rent, loan payments, and subscriptions as recurring to unlock planning.'**
  String get balanceSheetInsightEmptyAction;

  /// No description provided for @balanceSheetInsightShortfallTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring plan is running a deficit'**
  String get balanceSheetInsightShortfallTitle;

  /// No description provided for @balanceSheetInsightShortfallExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your recurring income misses monthly obligations by {amount}.'**
  String balanceSheetInsightShortfallExplanation(String amount);

  /// No description provided for @balanceSheetInsightShortfallImpact.
  ///
  /// In en, this message translates to:
  /// **'If nothing changes, fixed commitments alone can force you to borrow or cut essentials.'**
  String get balanceSheetInsightShortfallImpact;

  /// No description provided for @balanceSheetInsightShortfallActionOptional.
  ///
  /// In en, this message translates to:
  /// **'Reduce at least {amount} from optional subscriptions, then review large recurring bills.'**
  String balanceSheetInsightShortfallActionOptional(String amount);

  /// No description provided for @balanceSheetInsightShortfallAction.
  ///
  /// In en, this message translates to:
  /// **'Increase recurring income or reduce fixed expenses by at least {amount}.'**
  String balanceSheetInsightShortfallAction(String amount);

  /// No description provided for @balanceSheetInsightThinBufferTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring coverage is positive but thin'**
  String get balanceSheetInsightThinBufferTitle;

  /// No description provided for @balanceSheetInsightThinBufferExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your fixed-income plan covers obligations with only {amount} left each month.'**
  String balanceSheetInsightThinBufferExplanation(String amount);

  /// No description provided for @balanceSheetInsightThinBufferImpact.
  ///
  /// In en, this message translates to:
  /// **'A small change in income or a missed payment could remove your margin quickly.'**
  String get balanceSheetInsightThinBufferImpact;

  /// No description provided for @balanceSheetInsightThinBufferAction.
  ///
  /// In en, this message translates to:
  /// **'Build an extra buffer by trimming one recurring expense or redirecting new income into essentials first.'**
  String get balanceSheetInsightThinBufferAction;

  /// No description provided for @balanceSheetInsightCoveredTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring obligations are currently covered'**
  String get balanceSheetInsightCoveredTitle;

  /// No description provided for @balanceSheetInsightCoveredExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your monthly recurring plan leaves an estimated {amount} after fixed commitments.'**
  String balanceSheetInsightCoveredExplanation(String amount);

  /// No description provided for @balanceSheetInsightCoveredImpact.
  ///
  /// In en, this message translates to:
  /// **'You have room to absorb smaller fluctuations without falling behind on recurring bills.'**
  String get balanceSheetInsightCoveredImpact;

  /// No description provided for @balanceSheetInsightCoveredAction.
  ///
  /// In en, this message translates to:
  /// **'Protect that margin by keeping discretionary recurring charges under review.'**
  String get balanceSheetInsightCoveredAction;

  /// No description provided for @balanceSheetInsightNearTermTitle.
  ///
  /// In en, this message translates to:
  /// **'Next 14 days look cashflow-heavy'**
  String get balanceSheetInsightNearTermTitle;

  /// No description provided for @balanceSheetInsightNearTermExplanation.
  ///
  /// In en, this message translates to:
  /// **'Near-term recurring commitments total {commitments} against {income} in recurring income.'**
  String balanceSheetInsightNearTermExplanation(String commitments, String income);

  /// No description provided for @balanceSheetInsightNearTermImpact.
  ///
  /// In en, this message translates to:
  /// **'You may feel payment pressure before month-end even if the monthly picture is acceptable.'**
  String get balanceSheetInsightNearTermImpact;

  /// No description provided for @balanceSheetInsightNearTermAction.
  ///
  /// In en, this message translates to:
  /// **'Prioritize due-soon essentials first and reschedule optional payments where possible.'**
  String get balanceSheetInsightNearTermAction;

  /// No description provided for @balanceSheetInsightSubscriptionShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions take a large share of fixed outflow'**
  String get balanceSheetInsightSubscriptionShareTitle;

  /// No description provided for @balanceSheetInsightSubscriptionShareExplanation.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions account for {percent}% of your recurring obligations.'**
  String balanceSheetInsightSubscriptionShareExplanation(String percent);

  /// No description provided for @balanceSheetInsightSubscriptionShareImpact.
  ///
  /// In en, this message translates to:
  /// **'Smaller digital charges can quietly crowd out money needed for core bills.'**
  String get balanceSheetInsightSubscriptionShareImpact;

  /// No description provided for @balanceSheetInsightSubscriptionShareActionOptional.
  ///
  /// In en, this message translates to:
  /// **'Review optional subscriptions first. You could free up about {amount} per month.'**
  String balanceSheetInsightSubscriptionShareActionOptional(String amount);

  /// No description provided for @balanceSheetInsightSubscriptionShareAction.
  ///
  /// In en, this message translates to:
  /// **'Review annual and quarterly subscriptions for services you can pause or consolidate.'**
  String get balanceSheetInsightSubscriptionShareAction;

  /// No description provided for @balanceSheetInsightLargestBillTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with the largest recurring bill'**
  String get balanceSheetInsightLargestBillTitle;

  /// No description provided for @balanceSheetInsightLargestBillExplanation.
  ///
  /// In en, this message translates to:
  /// **'{title} is your largest recurring commitment at about {amount} per month.'**
  String balanceSheetInsightLargestBillExplanation(String title, String amount);

  /// No description provided for @balanceSheetInsightLargestBillImpact.
  ///
  /// In en, this message translates to:
  /// **'Any reduction here has more impact than cutting multiple smaller charges.'**
  String get balanceSheetInsightLargestBillImpact;

  /// No description provided for @balanceSheetInsightLargestBillAction.
  ///
  /// In en, this message translates to:
  /// **'Review whether {title} can be renegotiated, downgraded, or offset with a matching recurring income increase.'**
  String balanceSheetInsightLargestBillAction(String title);

  /// No description provided for @balanceSheetBuildError.
  ///
  /// In en, this message translates to:
  /// **'Unable to build recurring balance sheet: {error}'**
  String balanceSheetBuildError(String error);

  /// No description provided for @balanceSheetCurrencyFallback.
  ///
  /// In en, this message translates to:
  /// **'Live exchange rates are unavailable for {requested}. This view is shown in {fallback} for now.'**
  String balanceSheetCurrencyFallback(String requested, String fallback);

  /// No description provided for @balanceSheetCoveredTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring income currently covers your obligations'**
  String get balanceSheetCoveredTitle;

  /// No description provided for @balanceSheetDeficitTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring obligations currently outpace recurring income'**
  String get balanceSheetDeficitTitle;

  /// No description provided for @balanceSheetCoveredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estimated monthly room left after recurring commitments.'**
  String get balanceSheetCoveredSubtitle;

  /// No description provided for @balanceSheetDeficitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estimated monthly shortfall before variable spending begins.'**
  String get balanceSheetDeficitSubtitle;

  /// No description provided for @balanceSheetIncomePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Income / mo'**
  String get balanceSheetIncomePerMonth;

  /// No description provided for @balanceSheetExpensesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Expenses / mo'**
  String get balanceSheetExpensesPerMonth;

  /// No description provided for @balanceSheetSubscriptionsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions / mo'**
  String get balanceSheetSubscriptionsPerMonth;

  /// No description provided for @balanceSheetDueIn14Days.
  ///
  /// In en, this message translates to:
  /// **'Due in 14 days'**
  String get balanceSheetDueIn14Days;

  /// No description provided for @balanceSheetCoverageOutlook.
  ///
  /// In en, this message translates to:
  /// **'Coverage outlook'**
  String get balanceSheetCoverageOutlook;

  /// No description provided for @balanceSheetCoveragePercent.
  ///
  /// In en, this message translates to:
  /// **'Recurring income covers {percent}% of recurring obligations.'**
  String balanceSheetCoveragePercent(String percent);

  /// No description provided for @balanceSheetCoverageFootnote.
  ///
  /// In en, this message translates to:
  /// **'The sheet uses monthly equivalents for active recurring transactions and subscriptions in {currency}.'**
  String balanceSheetCoverageFootnote(String currency);

  /// No description provided for @balanceSheetScenarioLab.
  ///
  /// In en, this message translates to:
  /// **'Scenario Lab'**
  String get balanceSheetScenarioLab;

  /// No description provided for @balanceSheetScenarioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Test small changes before you make them. Increase recurring income, cut recurring expenses, or pause optional subscriptions.'**
  String get balanceSheetScenarioSubtitle;

  /// No description provided for @balanceSheetAddRecurringIncome.
  ///
  /// In en, this message translates to:
  /// **'Add recurring income'**
  String get balanceSheetAddRecurringIncome;

  /// No description provided for @balanceSheetReduceRecurringExpenses.
  ///
  /// In en, this message translates to:
  /// **'Reduce recurring expenses'**
  String get balanceSheetReduceRecurringExpenses;

  /// No description provided for @balanceSheetPauseOptionalSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Pause optional subscriptions'**
  String get balanceSheetPauseOptionalSubscriptions;

  /// No description provided for @balanceSheetSubscriptionChip.
  ///
  /// In en, this message translates to:
  /// **'{title} · {amount}/mo'**
  String balanceSheetSubscriptionChip(String title, String amount);

  /// No description provided for @balanceSheetSimulatedMonthlyBalance.
  ///
  /// In en, this message translates to:
  /// **'Simulated monthly balance'**
  String get balanceSheetSimulatedMonthlyBalance;

  /// No description provided for @balanceSheetSimulatedIncomeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Income {income} · Expenses {expenses}'**
  String balanceSheetSimulatedIncomeExpenses(String income, String expenses);

  /// No description provided for @balanceSheetResetScenario.
  ///
  /// In en, this message translates to:
  /// **'Reset scenario'**
  String get balanceSheetResetScenario;

  /// No description provided for @balanceSheetWaysToMakeEndsMeet.
  ///
  /// In en, this message translates to:
  /// **'Ways to make ends meet'**
  String get balanceSheetWaysToMakeEndsMeet;

  /// No description provided for @balanceSheetRecurringIncome.
  ///
  /// In en, this message translates to:
  /// **'Recurring income'**
  String get balanceSheetRecurringIncome;

  /// No description provided for @balanceSheetNoRecurringIncome.
  ///
  /// In en, this message translates to:
  /// **'No recurring income has been configured yet.'**
  String get balanceSheetNoRecurringIncome;

  /// No description provided for @balanceSheetRecurringExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recurring expenses'**
  String get balanceSheetRecurringExpenses;

  /// No description provided for @balanceSheetNoRecurringExpenses.
  ///
  /// In en, this message translates to:
  /// **'No recurring expenses have been configured yet.'**
  String get balanceSheetNoRecurringExpenses;

  /// No description provided for @balanceSheetSubscriptionsIncluded.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions included'**
  String get balanceSheetSubscriptionsIncluded;

  /// No description provided for @balanceSheetNextDate.
  ///
  /// In en, this message translates to:
  /// **'Next {date}'**
  String balanceSheetNextDate(String date);

  /// No description provided for @balanceSheetOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get balanceSheetOptional;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashboardGreetingMorning;

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashboardGreetingAfternoon;

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get dashboardGreetingEvening;

  /// No description provided for @dashboardDefaultUserName.
  ///
  /// In en, this message translates to:
  /// **'SmartSpend User'**
  String get dashboardDefaultUserName;

  /// No description provided for @dashboardOverallScore.
  ///
  /// In en, this message translates to:
  /// **'Overall score'**
  String get dashboardOverallScore;

  /// No description provided for @dashboardSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing dashboard data…'**
  String get dashboardSyncing;

  /// No description provided for @dashboardBurnRateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load burn rate'**
  String get dashboardBurnRateErrorTitle;

  /// No description provided for @dashboardBurnRateErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment to view spending pace insights.'**
  String get dashboardBurnRateErrorMessage;

  /// No description provided for @dashboardHealthCardErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load financial health'**
  String get dashboardHealthCardErrorTitle;

  /// No description provided for @dashboardHealthCardErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment to view your health score.'**
  String get dashboardHealthCardErrorMessage;

  /// No description provided for @dashboardRecentTransactionsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent transactions'**
  String get dashboardRecentTransactionsErrorTitle;

  /// No description provided for @burnRateStatusCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get burnRateStatusCritical;

  /// No description provided for @burnRateStatusHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get burnRateStatusHigh;

  /// No description provided for @burnRateStatusWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get burnRateStatusWatch;

  /// No description provided for @burnRateStatusHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get burnRateStatusHealthy;

  /// No description provided for @subscriptionEssential.
  ///
  /// In en, this message translates to:
  /// **'Essential Subscription'**
  String get subscriptionEssential;

  /// No description provided for @scenarioLabTitle.
  ///
  /// In en, this message translates to:
  /// **'Scenario Lab'**
  String get scenarioLabTitle;

  /// No description provided for @scenarioRunError.
  ///
  /// In en, this message translates to:
  /// **'Unable to run this scenario'**
  String get scenarioRunError;

  /// No description provided for @scenarioRunErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while simulating. Please try again in a moment.'**
  String get scenarioRunErrorMessage;

  /// No description provided for @scenarioMetricMonthlyCashflow.
  ///
  /// In en, this message translates to:
  /// **'Monthly cashflow'**
  String get scenarioMetricMonthlyCashflow;

  /// No description provided for @scenarioMetricSavingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings rate'**
  String get scenarioMetricSavingsRate;

  /// No description provided for @scenarioMetricSubscriptionBurden.
  ///
  /// In en, this message translates to:
  /// **'Subscription burden'**
  String get scenarioMetricSubscriptionBurden;

  /// No description provided for @scenarioMetricEmergencyRunway.
  ///
  /// In en, this message translates to:
  /// **'Emergency runway'**
  String get scenarioMetricEmergencyRunway;

  /// No description provided for @transactionsPreparingInsights.
  ///
  /// In en, this message translates to:
  /// **'Preparing insights…'**
  String get transactionsPreparingInsights;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @transactionsFilterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get transactionsFilterThisMonth;

  /// No description provided for @commonRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get commonRecurring;

  /// No description provided for @commonClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get commonClearSearch;

  /// No description provided for @subscriptionsActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription actions'**
  String get subscriptionsActionsTitle;

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @accountsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get accountsEmptyTitle;

  /// No description provided for @accountsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountsNameLabel;

  /// No description provided for @accountsOpeningBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get accountsOpeningBalanceLabel;

  /// No description provided for @insightsFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get insightsFocus;

  /// No description provided for @insightsNoRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations yet'**
  String get insightsNoRecommendations;

  /// No description provided for @insightsConfidenceModel.
  ///
  /// In en, this message translates to:
  /// **'Confidence model'**
  String get insightsConfidenceModel;

  /// No description provided for @insightsNoForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'No forecast data yet'**
  String get insightsNoForecastTitle;

  /// No description provided for @insightsNoForecastMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep using SmartSpend to unlock prediction trends.'**
  String get insightsNoForecastMessage;

  /// No description provided for @insightsNoCopilotTitle.
  ///
  /// In en, this message translates to:
  /// **'No Copilot activity yet'**
  String get insightsNoCopilotTitle;

  /// No description provided for @insightsNoCopilotMessage.
  ///
  /// In en, this message translates to:
  /// **'Smart insights will appear here as you use the app.'**
  String get insightsNoCopilotMessage;

  /// No description provided for @insightsActivityActions.
  ///
  /// In en, this message translates to:
  /// **'Insight activity actions'**
  String get insightsActivityActions;

  /// No description provided for @insightsOpenDetails.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get insightsOpenDetails;

  /// No description provided for @subscriptionsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get subscriptionsPause;

  /// No description provided for @subscriptionsResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get subscriptionsResume;

  /// No description provided for @settingsNotifBudgetAlerts.
  ///
  /// In en, this message translates to:
  /// **'Budget alerts'**
  String get settingsNotifBudgetAlerts;

  /// No description provided for @settingsNotifSubscriptionReminders.
  ///
  /// In en, this message translates to:
  /// **'Subscription reminders'**
  String get settingsNotifSubscriptionReminders;

  /// No description provided for @settingsNotifSavingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Savings reminders'**
  String get settingsNotifSavingsReminders;

  /// No description provided for @settingsNotifReportCompletion.
  ///
  /// In en, this message translates to:
  /// **'Report completion'**
  String get settingsNotifReportCompletion;

  /// No description provided for @settingsNotifSecurityAlerts.
  ///
  /// In en, this message translates to:
  /// **'Security alerts'**
  String get settingsNotifSecurityAlerts;

  /// No description provided for @settingsNotifMonthlySummaries.
  ///
  /// In en, this message translates to:
  /// **'Monthly summaries'**
  String get settingsNotifMonthlySummaries;

  /// No description provided for @settingsNotifPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in your device settings to receive alerts.'**
  String get settingsNotifPermissionHint;

  /// No description provided for @settingsNotifEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled.'**
  String get settingsNotifEnabled;

  /// No description provided for @settingsNotifDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled.'**
  String get settingsNotifDisabled;

  /// No description provided for @budgetsRolloverCompleted.
  ///
  /// In en, this message translates to:
  /// **'Budget rollover completed.'**
  String get budgetsRolloverCompleted;

  /// No description provided for @budgetsNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active budgets'**
  String get budgetsNoActive;

  /// No description provided for @commonIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get commonIncrease;

  /// No description provided for @commonDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get commonDecrease;

  /// No description provided for @budgetsArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive budget?'**
  String get budgetsArchiveTitle;

  /// No description provided for @budgetsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete budget?'**
  String get budgetsDeleteTitle;

  /// No description provided for @budgetsActionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Budget action completed.'**
  String get budgetsActionCompleted;

  /// No description provided for @budgetsMetricUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get budgetsMetricUsed;

  /// No description provided for @commonStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get commonStatus;

  /// No description provided for @budgetsMetricAlertAt.
  ///
  /// In en, this message translates to:
  /// **'Alert at'**
  String get budgetsMetricAlertAt;

  /// No description provided for @budgetsMetricDelta.
  ///
  /// In en, this message translates to:
  /// **'Delta'**
  String get budgetsMetricDelta;

  /// No description provided for @budgetsActions.
  ///
  /// In en, this message translates to:
  /// **'Budget actions'**
  String get budgetsActions;

  /// No description provided for @budgetsViewTransactions.
  ///
  /// In en, this message translates to:
  /// **'View transactions'**
  String get budgetsViewTransactions;

  /// No description provided for @budgetsIncrease10.
  ///
  /// In en, this message translates to:
  /// **'Increase 10%'**
  String get budgetsIncrease10;

  /// No description provided for @budgetsReduce10.
  ///
  /// In en, this message translates to:
  /// **'Reduce 10%'**
  String get budgetsReduce10;

  /// No description provided for @commonDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get commonDuplicate;

  /// No description provided for @commonArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get commonArchive;

  /// No description provided for @savingsMilestoneReached.
  ///
  /// In en, this message translates to:
  /// **'Savings milestone reached'**
  String get savingsMilestoneReached;

  /// No description provided for @savingsNoActiveGoals.
  ///
  /// In en, this message translates to:
  /// **'No active savings goals'**
  String get savingsNoActiveGoals;

  /// No description provided for @commonPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get commonPause;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @savingsSurplusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Surplus allocation cancelled.'**
  String get savingsSurplusCancelled;

  /// No description provided for @savingsSimulationSavedNoApply.
  ///
  /// In en, this message translates to:
  /// **'Simulation saved without applying changes.'**
  String get savingsSimulationSavedNoApply;

  /// No description provided for @savingsEnterAmountAboveZero.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above 0 to allocate.'**
  String get savingsEnterAmountAboveZero;

  /// No description provided for @savingsArchiveGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive goal?'**
  String get savingsArchiveGoalTitle;

  /// No description provided for @savingsDeleteGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete goal?'**
  String get savingsDeleteGoalTitle;

  /// No description provided for @savingsGoalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Savings goal updated.'**
  String get savingsGoalUpdated;

  /// No description provided for @savingsSetPriorityTitle.
  ///
  /// In en, this message translates to:
  /// **'Set goal priority'**
  String get savingsSetPriorityTitle;

  /// No description provided for @savingsPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High priority'**
  String get savingsPriorityHigh;

  /// No description provided for @savingsPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium priority'**
  String get savingsPriorityMedium;

  /// No description provided for @savingsPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low priority'**
  String get savingsPriorityLow;

  /// No description provided for @savingsPriorityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Goal priority updated.'**
  String get savingsPriorityUpdated;

  /// No description provided for @savingsGoalActions.
  ///
  /// In en, this message translates to:
  /// **'Savings goal actions'**
  String get savingsGoalActions;

  /// No description provided for @savingsSimulateContribution.
  ///
  /// In en, this message translates to:
  /// **'Simulate contribution'**
  String get savingsSimulateContribution;

  /// No description provided for @savingsSetPriority.
  ///
  /// In en, this message translates to:
  /// **'Set priority'**
  String get savingsSetPriority;

  /// No description provided for @savingsPauseAutoAllocation.
  ///
  /// In en, this message translates to:
  /// **'Pause auto-allocation'**
  String get savingsPauseAutoAllocation;

  /// No description provided for @savingsMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get savingsMarkComplete;

  /// No description provided for @savingsUseMoreThanSurplusTitle.
  ///
  /// In en, this message translates to:
  /// **'Use more than monthly surplus?'**
  String get savingsUseMoreThanSurplusTitle;

  /// No description provided for @savingsCustomMonthlyAllocation.
  ///
  /// In en, this message translates to:
  /// **'Custom monthly allocation'**
  String get savingsCustomMonthlyAllocation;

  /// No description provided for @reportsTitleExport.
  ///
  /// In en, this message translates to:
  /// **'Reports & Export'**
  String get reportsTitleExport;

  /// No description provided for @reportsOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Reporting Overview'**
  String get reportsOverviewTitle;

  /// No description provided for @reportsLastExport.
  ///
  /// In en, this message translates to:
  /// **'Last export'**
  String get reportsLastExport;

  /// No description provided for @reportsAvailableTypes.
  ///
  /// In en, this message translates to:
  /// **'Available types'**
  String get reportsAvailableTypes;

  /// No description provided for @commonGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get commonGenerate;

  /// No description provided for @reportsActions.
  ///
  /// In en, this message translates to:
  /// **'Report actions'**
  String get reportsActions;

  /// No description provided for @reportsScheduleRun.
  ///
  /// In en, this message translates to:
  /// **'Schedule run'**
  String get reportsScheduleRun;

  /// No description provided for @reportsNoActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'No report activity yet'**
  String get reportsNoActivityTitle;

  /// No description provided for @reportsNoActivityMessage.
  ///
  /// In en, this message translates to:
  /// **'Generated and exported reports will appear here.'**
  String get reportsNoActivityMessage;

  /// No description provided for @reportsGenerateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate report'**
  String get reportsGenerateReport;

  /// No description provided for @reportsNoGeneratedTitle.
  ///
  /// In en, this message translates to:
  /// **'No generated reports yet'**
  String get reportsNoGeneratedTitle;

  /// No description provided for @commonDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get commonDownload;

  /// No description provided for @reportsActivityActions.
  ///
  /// In en, this message translates to:
  /// **'Report activity actions'**
  String get reportsActivityActions;

  /// No description provided for @reportsShareExport.
  ///
  /// In en, this message translates to:
  /// **'Share / Export'**
  String get reportsShareExport;

  /// No description provided for @commonFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get commonFormat;

  /// No description provided for @reportTypeFinancialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get reportTypeFinancialSummary;

  /// No description provided for @reportTypeTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get reportTypeTransactionHistory;

  /// No description provided for @reportTypeBudgetAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Budget Analysis'**
  String get reportTypeBudgetAnalysis;

  /// No description provided for @reportTypeSubscriptionCosts.
  ///
  /// In en, this message translates to:
  /// **'Subscription Costs'**
  String get reportTypeSubscriptionCosts;

  /// No description provided for @reportTypeSavingsProgress.
  ///
  /// In en, this message translates to:
  /// **'Savings Progress'**
  String get reportTypeSavingsProgress;

  /// No description provided for @reportTypeCashflowForecast.
  ///
  /// In en, this message translates to:
  /// **'Cashflow Forecast'**
  String get reportTypeCashflowForecast;

  /// No description provided for @reportTypeCategoryInsights.
  ///
  /// In en, this message translates to:
  /// **'Category Insights'**
  String get reportTypeCategoryInsights;

  /// No description provided for @reportTypeTaxReady.
  ///
  /// In en, this message translates to:
  /// **'Tax-ready Export'**
  String get reportTypeTaxReady;

  /// No description provided for @reportTypeCompleteExport.
  ///
  /// In en, this message translates to:
  /// **'Complete Export'**
  String get reportTypeCompleteExport;

  /// No description provided for @reportShared.
  ///
  /// In en, this message translates to:
  /// **'{name} shared'**
  String reportShared(String name);

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your finances with confidence.'**
  String get authLoginSubtitle;

  /// No description provided for @authNewHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get authNewHere;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get authEnterPassword;

  /// No description provided for @authContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueApple;

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @authUnlockSession.
  ///
  /// In en, this message translates to:
  /// **'Unlock your session'**
  String get authUnlockSession;

  /// No description provided for @authUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to continue securely.'**
  String get authUnlockSubtitle;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start building healthier financial habits.'**
  String get authSignupSubtitle;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get authFirstName;

  /// No description provided for @authFirstNameHint.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get authFirstNameHint;

  /// No description provided for @authLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get authLastName;

  /// No description provided for @authLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get authLastNameHint;

  /// No description provided for @authCreatePassword.
  ///
  /// In en, this message translates to:
  /// **'Create password'**
  String get authCreatePassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authRepeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get authRepeatPassword;

  /// No description provided for @signupHeading.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signupHeading;

  /// No description provided for @signupHeadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your secure SmartSpend account.'**
  String get signupHeadingSubtitle;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get authEmailHint;

  /// No description provided for @signupCreatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get signupCreatingAccount;

  /// No description provided for @authTermsAgreement.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms and Privacy Policy.'**
  String get authTermsAgreement;

  /// No description provided for @authFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String authFieldRequired(String field);

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get authConfirmPasswordRequired;

  /// No description provided for @authPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDoNotMatch;

  /// No description provided for @signupCompleteFieldsAndLegal.
  ///
  /// In en, this message translates to:
  /// **'Complete the required fields and accept the legal terms.'**
  String get signupCompleteFieldsAndLegal;

  /// No description provided for @signupCompleteHighlightedFields.
  ///
  /// In en, this message translates to:
  /// **'Complete the highlighted fields to create your account.'**
  String get signupCompleteHighlightedFields;

  /// No description provided for @signupUnableToCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Unable to create account.'**
  String get signupUnableToCreateAccount;

  /// No description provided for @loginHeading.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginHeading;

  /// No description provided for @loginHeadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your account credentials to continue.'**
  String get loginHeadingSubtitle;

  /// No description provided for @loginSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loginSigningIn;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

  /// No description provided for @authBiometricAvailableHint.
  ///
  /// In en, this message translates to:
  /// **'Face ID / biometrics remain available after first sign in.'**
  String get authBiometricAvailableHint;

  /// No description provided for @authGoogleNoIdToken.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in did not return an ID token.'**
  String get authGoogleNoIdToken;

  /// No description provided for @authSignedInSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully.'**
  String get authSignedInSuccessfully;

  /// No description provided for @authGoogleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed.'**
  String get authGoogleSignInFailed;

  /// No description provided for @authGoogleSignInFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get authGoogleSignInFailedRetry;

  /// No description provided for @authAppleNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in is not available on this device.'**
  String get authAppleNotAvailable;

  /// No description provided for @authAppleNoIdToken.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in did not return an ID token.'**
  String get authAppleNoIdToken;

  /// No description provided for @authAppleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed.'**
  String get authAppleSignInFailed;

  /// No description provided for @authAppleSignInFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed. Please try again.'**
  String get authAppleSignInFailedRetry;

  /// No description provided for @authEnterValidEmailPasswordContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email and password to continue.'**
  String get authEnterValidEmailPasswordContinue;

  /// No description provided for @authEnterValidEmailPasswordSignIn.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email and password to sign in.'**
  String get authEnterValidEmailPasswordSignIn;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed.'**
  String get authLoginFailed;

  /// No description provided for @authSessionExpiredSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get authSessionExpiredSignInAgain;

  /// No description provided for @authBiometricUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get authBiometricUnlockTitle;

  /// No description provided for @authBiometricUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID or fingerprint to restore local access.'**
  String get authBiometricUnlockSubtitle;

  /// No description provided for @authBiometricAnimationLabel.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication animation'**
  String get authBiometricAnimationLabel;

  /// No description provided for @authBiometricInstructions.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID, fingerprint, or another enrolled biometric method to continue.'**
  String get authBiometricInstructions;

  /// No description provided for @authVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get authVerifying;

  /// No description provided for @authUnlockWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get authUnlockWithBiometrics;

  /// No description provided for @authUsePasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Use password instead'**
  String get authUsePasswordInstead;

  /// No description provided for @authUseDifferentAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get authUseDifferentAccount;

  /// No description provided for @budgetAlertStatusNearLimit.
  ///
  /// In en, this message translates to:
  /// **'Near Limit'**
  String get budgetAlertStatusNearLimit;

  /// No description provided for @budgetAlertStatusOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get budgetAlertStatusOnTrack;

  /// No description provided for @budgetsTapProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the progress bar to review related transactions.'**
  String get budgetsTapProgressHint;

  /// No description provided for @budgetsCompleteRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Complete required budget fields to continue.'**
  String get budgetsCompleteRequiredFields;

  /// No description provided for @budgetsEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid budget amount greater than zero.'**
  String get budgetsEnterValidAmount;

  /// No description provided for @budgetsSetCategoryAndLimit.
  ///
  /// In en, this message translates to:
  /// **'Set a category and limit'**
  String get budgetsSetCategoryAndLimit;

  /// No description provided for @budgetsUsedForInsights.
  ///
  /// In en, this message translates to:
  /// **'Used for insights and category-based controls'**
  String get budgetsUsedForInsights;

  /// No description provided for @budgetsAllPausedOrArchived.
  ///
  /// In en, this message translates to:
  /// **'All budgets are paused or archived. Resume one below to continue tracking.'**
  String get budgetsAllPausedOrArchived;

  /// No description provided for @budgetsPausedOrArchivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused or archived budgets'**
  String get budgetsPausedOrArchivedTitle;

  /// No description provided for @budgetsResumeHint.
  ///
  /// In en, this message translates to:
  /// **'Resume a budget to bring it back into active planning.'**
  String get budgetsResumeHint;

  /// No description provided for @budgetsPauseConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This budget will be paused and hidden from active planning until you re-enable it.'**
  String get budgetsPauseConfirmation;

  /// No description provided for @budgetsDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the budget. Transactions are not deleted.'**
  String get budgetsDeleteConfirmation;

  /// No description provided for @budgetsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving budget...'**
  String get budgetsSaving;

  /// No description provided for @budgetsUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating budget...'**
  String get budgetsUpdating;

  /// No description provided for @budgetsSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Budget saved successfully.'**
  String get budgetsSavedSuccessfully;

  /// No description provided for @budgetsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Budget updated successfully.'**
  String get budgetsUpdatedSuccessfully;

  /// No description provided for @budgetsUnableToSave.
  ///
  /// In en, this message translates to:
  /// **'Unable to save budget. Please try again.'**
  String get budgetsUnableToSave;

  /// No description provided for @savingsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving goal...'**
  String get savingsSaving;

  /// No description provided for @savingsUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating goal...'**
  String get savingsUpdating;

  /// No description provided for @savingsSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Savings goal saved successfully.'**
  String get savingsSavedSuccessfully;

  /// No description provided for @savingsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Savings goal updated successfully.'**
  String get savingsUpdatedSuccessfully;

  /// No description provided for @savingsUnableToSave.
  ///
  /// In en, this message translates to:
  /// **'Unable to save savings goal. Please try again.'**
  String get savingsUnableToSave;

  /// No description provided for @savingsInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get savingsInsightsTitle;

  /// No description provided for @savingsMonthlySurplusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Monthly Surplus Available'**
  String get savingsMonthlySurplusAvailable;

  /// No description provided for @savingsAllocateToHighestPriority.
  ///
  /// In en, this message translates to:
  /// **'Allocate to your highest priority goal'**
  String get savingsAllocateToHighestPriority;

  /// No description provided for @savingsProjectedLateBy.
  ///
  /// In en, this message translates to:
  /// **'Projected late by {months} months'**
  String savingsProjectedLateBy(int months);

  /// No description provided for @savingsOverflowMenuHint.
  ///
  /// In en, this message translates to:
  /// **'Use the overflow menu to add funds, simulate scenarios, or update this goal.'**
  String get savingsOverflowMenuHint;

  /// No description provided for @savingsEnterAmountGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get savingsEnterAmountGreaterThanZero;

  /// No description provided for @savingsAmountAboveSurplusWarning.
  ///
  /// In en, this message translates to:
  /// **'This amount is above the available monthly surplus. Continue with simulation?'**
  String get savingsAmountAboveSurplusWarning;

  /// No description provided for @savingsRunSimulationFirst.
  ///
  /// In en, this message translates to:
  /// **'Run a simulation before applying.'**
  String get savingsRunSimulationFirst;

  /// No description provided for @savingsMonthlySurplusSimulation.
  ///
  /// In en, this message translates to:
  /// **'Monthly surplus simulation'**
  String get savingsMonthlySurplusSimulation;

  /// No description provided for @savingsCompleteRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Complete required savings goal fields to continue.'**
  String get savingsCompleteRequiredFields;

  /// No description provided for @savingsTargetAmountMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid target amount greater than zero.'**
  String get savingsTargetAmountMustBeGreaterThanZero;

  /// No description provided for @savingsNameGoalAndSetTarget.
  ///
  /// In en, this message translates to:
  /// **'Name your goal and set a target'**
  String get savingsNameGoalAndSetTarget;

  /// No description provided for @savingsChooseSpecificTarget.
  ///
  /// In en, this message translates to:
  /// **'Choose a specific target such as Emergency Fund'**
  String get savingsChooseSpecificTarget;

  /// No description provided for @savingsFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get savingsFromAccount;

  /// No description provided for @savingsMilestoneGreatStart.
  ///
  /// In en, this message translates to:
  /// **'Great start. You are building momentum one step at a time.'**
  String get savingsMilestoneGreatStart;

  /// No description provided for @savingsMilestoneHalfway.
  ///
  /// In en, this message translates to:
  /// **'Halfway there. Your consistency is paying off.'**
  String get savingsMilestoneHalfway;

  /// No description provided for @savingsMilestoneAmazing.
  ///
  /// In en, this message translates to:
  /// **'Amazing progress. The finish line is close.'**
  String get savingsMilestoneAmazing;

  /// No description provided for @savingsMilestoneAchieved.
  ///
  /// In en, this message translates to:
  /// **'Goal achieved. Excellent discipline and focus.'**
  String get savingsMilestoneAchieved;

  /// No description provided for @savingsMilestoneNiceProgress.
  ///
  /// In en, this message translates to:
  /// **'Nice progress. Keep going.'**
  String get savingsMilestoneNiceProgress;

  /// No description provided for @savingsAllPausedOrArchived.
  ///
  /// In en, this message translates to:
  /// **'All savings plans are paused or archived. Resume one below to continue.'**
  String get savingsAllPausedOrArchived;

  /// No description provided for @savingsPausedPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused plans'**
  String get savingsPausedPlansTitle;

  /// No description provided for @savingsPausedLabel.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get savingsPausedLabel;

  /// No description provided for @savingsArchivedPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived plans'**
  String get savingsArchivedPlansTitle;

  /// No description provided for @savingsArchivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get savingsArchivedLabel;

  /// No description provided for @savingsArchiveConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This goal will move to Archived plans until you restore it.'**
  String get savingsArchiveConfirmation;

  /// No description provided for @savingsDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the goal and cannot be undone.'**
  String get savingsDeleteConfirmation;

  /// No description provided for @savingsPriorityShortLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get savingsPriorityShortLow;

  /// No description provided for @savingsPriorityShortMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get savingsPriorityShortMedium;

  /// No description provided for @savingsPriorityShortHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get savingsPriorityShortHigh;

  /// No description provided for @savingsPriorityShortCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get savingsPriorityShortCritical;

  /// No description provided for @a11yShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get a11yShowPassword;

  /// No description provided for @a11yHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get a11yHidePassword;

  /// No description provided for @a11yClearDeadline.
  ///
  /// In en, this message translates to:
  /// **'Clear deadline'**
  String get a11yClearDeadline;

  /// No description provided for @a11yCloseForm.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get a11yCloseForm;

  /// No description provided for @a11yMarkAllNotificationsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get a11yMarkAllNotificationsRead;

  /// No description provided for @a11yClearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications'**
  String get a11yClearAllNotifications;

  /// No description provided for @a11yExportReport.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get a11yExportReport;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get authForgotPassword;

  /// No description provided for @authForgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recover account access in a few quick steps.'**
  String get authForgotSubtitle;

  /// No description provided for @authBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// No description provided for @authSetNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get authSetNewPassword;

  /// No description provided for @authResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect your account with a strong replacement password.'**
  String get authResetSubtitle;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get authNewPasswordHint;

  /// No description provided for @authReEnterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter the password'**
  String get authReEnterPasswordHint;

  /// No description provided for @authConfirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get authConfirmEmail;

  /// No description provided for @securityTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get securityTimeout;

  /// No description provided for @securityAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get securityAttempts;

  /// No description provided for @settingsItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get settingsItems;

  /// No description provided for @settingsMainFeatures.
  ///
  /// In en, this message translates to:
  /// **'Main features'**
  String get settingsMainFeatures;

  /// No description provided for @settingsMainFeaturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Essential tools to manage spending, plan ahead, and improve financial health.'**
  String get settingsMainFeaturesSubtitle;

  /// No description provided for @settingsIncludedTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions and recurring entries'**
  String get settingsIncludedTransactions;

  /// No description provided for @settingsIncludedBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets, savings goals, and subscriptions'**
  String get settingsIncludedBudgets;

  /// No description provided for @settingsIncludedInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights, forecasts, and anomaly alerts'**
  String get settingsIncludedInsights;

  /// No description provided for @settingsExploreFeatures.
  ///
  /// In en, this message translates to:
  /// **'Explore features'**
  String get settingsExploreFeatures;

  /// No description provided for @settingsFeatureDebtManagement.
  ///
  /// In en, this message translates to:
  /// **'Debt Management'**
  String get settingsFeatureDebtManagement;

  /// No description provided for @settingsFeatureDebtManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Track loans and pay down debt faster with a payoff plan.'**
  String get settingsFeatureDebtManagementDesc;

  /// No description provided for @settingsFeatureAiCoach.
  ///
  /// In en, this message translates to:
  /// **'AI Budget Coach'**
  String get settingsFeatureAiCoach;

  /// No description provided for @settingsFeatureAiCoachDesc.
  ///
  /// In en, this message translates to:
  /// **'Get weekly personalized spending and savings guidance.'**
  String get settingsFeatureAiCoachDesc;

  /// No description provided for @commonComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get commonComingSoon;

  /// No description provided for @settingsOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get settingsOthers;

  /// No description provided for @settingsAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage cash, transfer, and credit sources'**
  String get settingsAccountsSubtitle;

  /// No description provided for @settingsTellFriend.
  ///
  /// In en, this message translates to:
  /// **'Tell a friend'**
  String get settingsTellFriend;

  /// No description provided for @settingsSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get settingsSendFeedback;

  /// No description provided for @settingsSendFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Email tech and general feedback'**
  String get settingsSendFeedbackSubtitle;

  /// No description provided for @settingsHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelpSupport;

  /// No description provided for @settingsHelpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visit smaartspend.com'**
  String get settingsHelpSupportSubtitle;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsLegalOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Legal & Onboarding'**
  String get settingsLegalOnboarding;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get settingsProfileUpdated;

  /// No description provided for @settingsOnboardingRestarted.
  ///
  /// In en, this message translates to:
  /// **'Onboarding restarted.'**
  String get settingsOnboardingRestarted;

  /// No description provided for @settingsReferralComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Referral sharing coming soon.'**
  String get settingsReferralComingSoon;

  /// No description provided for @settingsNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get settingsNotSignedIn;

  /// No description provided for @settingsNoTimestamp.
  ///
  /// In en, this message translates to:
  /// **'No timestamp recorded yet.'**
  String get settingsNoTimestamp;

  /// No description provided for @insightsCopilotTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Copilot'**
  String get insightsCopilotTitle;

  /// No description provided for @insightsTimeframeFocus.
  ///
  /// In en, this message translates to:
  /// **'Timeframe & Focus'**
  String get insightsTimeframeFocus;

  /// No description provided for @insightsRecommendedActions.
  ///
  /// In en, this message translates to:
  /// **'Recommended actions'**
  String get insightsRecommendedActions;

  /// No description provided for @insightsForecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get insightsForecast;

  /// No description provided for @insightsActualVsPredicted.
  ///
  /// In en, this message translates to:
  /// **'Actual vs predicted spending'**
  String get insightsActualVsPredicted;

  /// No description provided for @insightsRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Copilot Activity'**
  String get insightsRecentActivity;

  /// No description provided for @insightsQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get insightsQuickActions;

  /// No description provided for @insightsAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing financial patterns…'**
  String get insightsAnalyzing;

  /// No description provided for @insightsAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed'**
  String get insightsAnalysisFailed;

  /// No description provided for @accountsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountsAdd;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @accountsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load accounts.'**
  String get accountsLoadError;

  /// No description provided for @accountsLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load accounts'**
  String get accountsLoadErrorTitle;

  /// No description provided for @budgetsListErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load budgets'**
  String get budgetsListErrorTitle;

  /// No description provided for @budgetsListErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment to view your budgets.'**
  String get budgetsListErrorMessage;

  /// No description provided for @savingsListErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load savings goals'**
  String get savingsListErrorTitle;

  /// No description provided for @savingsListErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment to view your savings goals.'**
  String get savingsListErrorMessage;

  /// No description provided for @notificationsListErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications'**
  String get notificationsListErrorTitle;

  /// No description provided for @notificationsListErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment to view your notifications.'**
  String get notificationsListErrorMessage;

  /// No description provided for @accountsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String accountsRemoveTitle(String name);

  /// No description provided for @accountsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first account to start tracking your money across wallets and banks.'**
  String get accountsEmptyMessage;

  /// No description provided for @accountsRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'The account will be hidden. Existing transactions are kept.'**
  String get accountsRemoveMessage;

  /// No description provided for @accountsTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get accountsTotalBalance;

  /// No description provided for @accountsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} account} other{{count} accounts}}'**
  String accountsCount(num count);

  /// No description provided for @accountsEditAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get accountsEditAccount;

  /// No description provided for @accountsNewAccount.
  ///
  /// In en, this message translates to:
  /// **'New Account'**
  String get accountsNewAccount;

  /// No description provided for @accountsNameYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Name your account'**
  String get accountsNameYourAccount;

  /// No description provided for @accountsNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Main Wallet, HSBC Savings'**
  String get accountsNameHint;

  /// No description provided for @accountsEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get accountsEnterName;

  /// No description provided for @accountsNegativeBalanceHelper.
  ///
  /// In en, this message translates to:
  /// **'Use a negative value for an outstanding balance owed'**
  String get accountsNegativeBalanceHelper;

  /// No description provided for @accountsStartingBalanceHelper.
  ///
  /// In en, this message translates to:
  /// **'Starting balance for this account'**
  String get accountsStartingBalanceHelper;

  /// No description provided for @accountsEnterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get accountsEnterNumber;

  /// No description provided for @accountsAmountTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Amount too large'**
  String get accountsAmountTooLarge;

  /// No description provided for @accountsSaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Save Account'**
  String get accountsSaveAccount;

  /// No description provided for @accountsCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get accountsCreateAccount;

  /// No description provided for @accountsType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountsType;

  /// No description provided for @subscriptionsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get subscriptionsClearFilters;

  /// No description provided for @subscriptionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or category'**
  String get subscriptionsSearchHint;

  /// No description provided for @notificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationsMarkRead;

  /// No description provided for @scenarioOpenFull.
  ///
  /// In en, this message translates to:
  /// **'Open full Scenario Lab'**
  String get scenarioOpenFull;

  /// No description provided for @balanceSheetImpact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get balanceSheetImpact;

  /// No description provided for @balanceSheetAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get balanceSheetAction;

  /// No description provided for @commonMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get commonMonthly;

  /// No description provided for @legalTermsDocSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your rights and responsibilities when using SmartSpend.'**
  String get legalTermsDocSubtitle;

  /// No description provided for @simLabelProjectedMonthlySpend.
  ///
  /// In en, this message translates to:
  /// **'Projected Monthly Spend'**
  String get simLabelProjectedMonthlySpend;

  /// No description provided for @simLabelProjectedEndBalance.
  ///
  /// In en, this message translates to:
  /// **'Projected End Balance'**
  String get simLabelProjectedEndBalance;

  /// No description provided for @simLabelPotentialSavings.
  ///
  /// In en, this message translates to:
  /// **'Potential Savings'**
  String get simLabelPotentialSavings;

  /// No description provided for @scenarioNoSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'No active savings goals found.'**
  String get scenarioNoSavingsGoals;

  /// No description provided for @scenarioNoBehavioralRisks.
  ///
  /// In en, this message translates to:
  /// **'No behavioral risks detected for this scenario.'**
  String get scenarioNoBehavioralRisks;

  /// No description provided for @scenarioNoRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations for this scenario yet.'**
  String get scenarioNoRecommendations;

  /// No description provided for @scenarioActionAdjustBudget.
  ///
  /// In en, this message translates to:
  /// **'Adjust Budget'**
  String get scenarioActionAdjustBudget;

  /// No description provided for @scenarioActionSavingsRule.
  ///
  /// In en, this message translates to:
  /// **'Savings Rule'**
  String get scenarioActionSavingsRule;

  /// No description provided for @scenarioActionReviewSubs.
  ///
  /// In en, this message translates to:
  /// **'Review Subs'**
  String get scenarioActionReviewSubs;

  /// No description provided for @scenarioActionOpenBalanceSheet.
  ///
  /// In en, this message translates to:
  /// **'Open Balance Sheet'**
  String get scenarioActionOpenBalanceSheet;

  /// No description provided for @scenarioActionTxByCategory.
  ///
  /// In en, this message translates to:
  /// **'Transactions by Category'**
  String get scenarioActionTxByCategory;

  /// No description provided for @scenarioActionOpenSavingsGoal.
  ///
  /// In en, this message translates to:
  /// **'Open Savings Goal'**
  String get scenarioActionOpenSavingsGoal;

  /// No description provided for @scenarioSim.
  ///
  /// In en, this message translates to:
  /// **'Sim: {value}'**
  String scenarioSim(String value);

  /// No description provided for @scenarioEmergencyRunway.
  ///
  /// In en, this message translates to:
  /// **'Emergency runway: {days} days'**
  String scenarioEmergencyRunway(String days);

  /// No description provided for @scenarioStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String scenarioStatus(String status);

  /// No description provided for @scenarioScore.
  ///
  /// In en, this message translates to:
  /// **'Score {score}/100'**
  String scenarioScore(String score);

  /// No description provided for @scenarioPressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure {value}'**
  String scenarioPressure(String value);

  /// No description provided for @scenarioBurnRateRisk.
  ///
  /// In en, this message translates to:
  /// **'Burn-rate risk {value}'**
  String scenarioBurnRateRisk(String value);

  /// No description provided for @scenarioResilience.
  ///
  /// In en, this message translates to:
  /// **'Resilience {value}'**
  String scenarioResilience(String value);

  /// No description provided for @tourWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SmartSpend'**
  String get tourWelcomeTitle;

  /// No description provided for @tourWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your all-in-one personal finance app. Track spending, build budgets, and grow savings — all in one place.'**
  String get tourWelcomeSubtitle;

  /// No description provided for @tourTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track every transaction'**
  String get tourTrackTitle;

  /// No description provided for @tourTrackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log cash, bank transfers and credit card payments. See exactly where your money goes in real time.'**
  String get tourTrackSubtitle;

  /// No description provided for @tourBudgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Set budgets & goals'**
  String get tourBudgetsTitle;

  /// No description provided for @tourBudgetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create category budgets and savings goals. SmartSpend tracks your progress and warns you before you overspend.'**
  String get tourBudgetsSubtitle;

  /// No description provided for @tourAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add anything in one tap'**
  String get tourAddTitle;

  /// No description provided for @tourAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The \"+\" button launches a quick-add menu. The grid icon opens navigation — reports, accounts, AI insights and more.'**
  String get tourAddSubtitle;

  /// No description provided for @commonResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get commonResume;

  /// No description provided for @commonAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get commonAccount;

  /// No description provided for @budgetsPauseBudget.
  ///
  /// In en, this message translates to:
  /// **'Pause budget'**
  String get budgetsPauseBudget;

  /// No description provided for @budgetsResumeBudget.
  ///
  /// In en, this message translates to:
  /// **'Resume budget'**
  String get budgetsResumeBudget;

  /// No description provided for @legalPrivacyDocSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How personal and financial data is handled in SmartSpend.'**
  String get legalPrivacyDocSubtitle;

  /// No description provided for @reportsIncludeCharts.
  ///
  /// In en, this message translates to:
  /// **'Include charts'**
  String get reportsIncludeCharts;

  /// No description provided for @reportsIncludeTransactions.
  ///
  /// In en, this message translates to:
  /// **'Include detailed transactions'**
  String get reportsIncludeTransactions;

  /// No description provided for @reportsIncludeBudgets.
  ///
  /// In en, this message translates to:
  /// **'Include budgets'**
  String get reportsIncludeBudgets;

  /// No description provided for @reportsIncludeSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Include subscriptions'**
  String get reportsIncludeSubscriptions;

  /// No description provided for @reportsIncludeSavings.
  ///
  /// In en, this message translates to:
  /// **'Include savings goals'**
  String get reportsIncludeSavings;

  /// No description provided for @reportsExportFinancialSummaryPdf.
  ///
  /// In en, this message translates to:
  /// **'Export Financial Summary (PDF)'**
  String get reportsExportFinancialSummaryPdf;

  /// No description provided for @reportsExportCompleteCsv.
  ///
  /// In en, this message translates to:
  /// **'Export Complete Data (CSV)'**
  String get reportsExportCompleteCsv;

  /// No description provided for @reportsShareDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Financial Data?'**
  String get reportsShareDataTitle;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @transactionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions, notes, or dates'**
  String get transactionsSearchHint;

  /// No description provided for @authForgotPasswordQ.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPasswordQ;

  /// No description provided for @commonTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get commonTerms;

  /// No description provided for @commonPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get commonPrivacy;

  /// No description provided for @addSubscriptionOptionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional Details'**
  String get addSubscriptionOptionalDetails;

  /// No description provided for @settingsLegalReviewConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Legal review confirmation'**
  String get settingsLegalReviewConfirmation;

  /// No description provided for @commonSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get commonSaveChanges;

  /// No description provided for @savingsKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get savingsKeepGoing;

  /// No description provided for @savingsSimulateCustomAllocation.
  ///
  /// In en, this message translates to:
  /// **'Simulate custom allocation'**
  String get savingsSimulateCustomAllocation;

  /// No description provided for @savingsSimulationOutput.
  ///
  /// In en, this message translates to:
  /// **'Simulation output'**
  String get savingsSimulationOutput;

  /// No description provided for @savingsSimulate.
  ///
  /// In en, this message translates to:
  /// **'Simulate'**
  String get savingsSimulate;

  /// No description provided for @savingsConfirmAndApply.
  ///
  /// In en, this message translates to:
  /// **'Confirm and apply'**
  String get savingsConfirmAndApply;

  /// No description provided for @scenarioCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current: {value}'**
  String scenarioCurrent(String value);

  /// No description provided for @portfolioSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get portfolioSpent;

  /// No description provided for @portfolioNetFlow.
  ///
  /// In en, this message translates to:
  /// **'Net Flow'**
  String get portfolioNetFlow;

  /// No description provided for @portfolioTopCategory.
  ///
  /// In en, this message translates to:
  /// **'Top Category'**
  String get portfolioTopCategory;

  /// No description provided for @portfolioDecisionSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Decision Snapshot'**
  String get portfolioDecisionSnapshot;

  /// No description provided for @portfolioCaptionSpent.
  ///
  /// In en, this message translates to:
  /// **'spent'**
  String get portfolioCaptionSpent;

  /// No description provided for @portfolioOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get portfolioOnTrack;

  /// No description provided for @portfolioAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At Risk'**
  String get portfolioAtRisk;

  /// No description provided for @portfolioDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Days Left'**
  String get portfolioDaysLeft;

  /// No description provided for @portfolioCaptionUsed.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get portfolioCaptionUsed;

  /// No description provided for @portfolioHealthyPace.
  ///
  /// In en, this message translates to:
  /// **'Healthy pace'**
  String get portfolioHealthyPace;

  /// No description provided for @portfolioSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get portfolioSaved;

  /// No description provided for @portfolioTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get portfolioTarget;

  /// No description provided for @portfolioMonthlySurplus.
  ///
  /// In en, this message translates to:
  /// **'Monthly Surplus'**
  String get portfolioMonthlySurplus;

  /// No description provided for @portfolioCaptionSaved.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get portfolioCaptionSaved;

  /// No description provided for @portfolioStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get portfolioStable;

  /// No description provided for @portfolioMonthlyLoad.
  ///
  /// In en, this message translates to:
  /// **'Monthly Load'**
  String get portfolioMonthlyLoad;

  /// No description provided for @portfolioActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get portfolioActive;

  /// No description provided for @portfolioNextRenewal.
  ///
  /// In en, this message translates to:
  /// **'Next Renewal'**
  String get portfolioNextRenewal;

  /// No description provided for @portfolioOptionalSavings.
  ///
  /// In en, this message translates to:
  /// **'Optional Savings'**
  String get portfolioOptionalSavings;

  /// No description provided for @subscriptionPortfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Portfolio'**
  String get subscriptionPortfolioTitle;

  /// No description provided for @portfolioCaptionOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get portfolioCaptionOptional;

  /// No description provided for @portfolioAtRiskCount.
  ///
  /// In en, this message translates to:
  /// **'{count} at risk'**
  String portfolioAtRiskCount(String count);

  /// No description provided for @portfolioCriticalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} critical'**
  String portfolioCriticalCount(String count);

  /// No description provided for @authReq8Chars.
  ///
  /// In en, this message translates to:
  /// **'8+ chars'**
  String get authReq8Chars;

  /// No description provided for @authReqUppercase.
  ///
  /// In en, this message translates to:
  /// **'Uppercase'**
  String get authReqUppercase;

  /// No description provided for @authReqLowercase.
  ///
  /// In en, this message translates to:
  /// **'Lowercase'**
  String get authReqLowercase;

  /// No description provided for @authReqNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get authReqNumber;

  /// No description provided for @authReqPasswordsMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords match'**
  String get authReqPasswordsMatch;

  /// No description provided for @bioMsgOpeningPrompt.
  ///
  /// In en, this message translates to:
  /// **'Opening biometric prompt…'**
  String get bioMsgOpeningPrompt;

  /// No description provided for @bioMsgWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for biometric verification…'**
  String get bioMsgWaiting;

  /// No description provided for @bioMsgUsePassword.
  ///
  /// In en, this message translates to:
  /// **'Use your password to continue.'**
  String get bioMsgUsePassword;

  /// No description provided for @bioMsgVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified. Unlocking your session…'**
  String get bioMsgVerified;

  /// No description provided for @bioMsgCancelled.
  ///
  /// In en, this message translates to:
  /// **'Biometric verification was cancelled or denied.'**
  String get bioMsgCancelled;

  /// No description provided for @bioMsgNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are not available on this device.'**
  String get bioMsgNotAvailable;

  /// No description provided for @bioMsgNoneEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No biometrics are enrolled. Use password instead.'**
  String get bioMsgNoneEnrolled;

  /// No description provided for @bioMsgLocked.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are locked. Unlock your device and try again.'**
  String get bioMsgLocked;

  /// No description provided for @bioMsgError.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify biometrics right now. Try again.'**
  String get bioMsgError;

  /// No description provided for @scenarioRecSubBurdenTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription burden is high'**
  String get scenarioRecSubBurdenTitle;

  /// No description provided for @scenarioRecSubBurdenReason.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions consume {pct}% of recurring obligations.'**
  String scenarioRecSubBurdenReason(String pct);

  /// No description provided for @scenarioRecSubBurdenAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel or pause low-priority subscriptions.'**
  String get scenarioRecSubBurdenAction;

  /// No description provided for @scenarioRecFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Optimize food spending'**
  String get scenarioRecFoodTitle;

  /// No description provided for @scenarioRecFoodReason.
  ///
  /// In en, this message translates to:
  /// **'Reducing food spend by 15% can recover {amount} per month.'**
  String scenarioRecFoodReason(String amount);

  /// No description provided for @scenarioRecFoodAction.
  ///
  /// In en, this message translates to:
  /// **'Set a food budget cap and track weekly variance.'**
  String get scenarioRecFoodAction;

  /// No description provided for @scenarioRecBreakEvenTitle.
  ///
  /// In en, this message translates to:
  /// **'Break-even income gap detected'**
  String get scenarioRecBreakEvenTitle;

  /// No description provided for @scenarioRecBreakEvenReason.
  ///
  /// In en, this message translates to:
  /// **'Increase recurring income by {amount} to avoid a monthly deficit.'**
  String scenarioRecBreakEvenReason(String amount);

  /// No description provided for @scenarioRecBreakEvenAction.
  ///
  /// In en, this message translates to:
  /// **'Create a recurring income goal or reduce variable spending.'**
  String get scenarioRecBreakEvenAction;

  /// No description provided for @scenarioRecRunwayTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency runway is low'**
  String get scenarioRecRunwayTitle;

  /// No description provided for @scenarioRecRunwayReason.
  ///
  /// In en, this message translates to:
  /// **'Current emergency runway is below 30 days.'**
  String get scenarioRecRunwayReason;

  /// No description provided for @scenarioRecRunwayAction.
  ///
  /// In en, this message translates to:
  /// **'Increase emergency allocation and reduce optional spend.'**
  String get scenarioRecRunwayAction;

  /// No description provided for @scenarioRecDebtTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt repayment acceleration available'**
  String get scenarioRecDebtTitle;

  /// No description provided for @scenarioRecDebtReason.
  ///
  /// In en, this message translates to:
  /// **'Debt obligations are taking a significant share of cashflow.'**
  String get scenarioRecDebtReason;

  /// No description provided for @scenarioRecDebtAction.
  ///
  /// In en, this message translates to:
  /// **'Route {amount} extra monthly to debt repayment.'**
  String scenarioRecDebtAction(String amount);

  /// No description provided for @scenarioRecDeficitTitle.
  ///
  /// In en, this message translates to:
  /// **'High next-month deficit probability'**
  String get scenarioRecDeficitTitle;

  /// No description provided for @scenarioRecDeficitReason.
  ///
  /// In en, this message translates to:
  /// **'Deficit likelihood is {pct}%.'**
  String scenarioRecDeficitReason(String pct);

  /// No description provided for @scenarioRecDeficitAction.
  ///
  /// In en, this message translates to:
  /// **'Review transactions by category and apply targeted reductions.'**
  String get scenarioRecDeficitAction;

  /// No description provided for @scenarioEstimatedImpact.
  ///
  /// In en, this message translates to:
  /// **'Estimated impact: {amount}'**
  String scenarioEstimatedImpact(String amount);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
