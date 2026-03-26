// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SmartBudget';

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
}
