import 'package:flutter/material.dart';

/// Centralized icon set. Uses Material icons (outlined for unselected, rounded
/// for selected/filled) so there's no third-party icon dependency to break on
/// Flutter SDK upgrades.
class AppIcons {
  const AppIcons._();

  static const IconData home = Icons.home_rounded;
  static const IconData homeOutline = Icons.home_outlined;
  static const IconData reports = Icons.bar_chart_outlined;
  static const IconData reportsFilled = Icons.bar_chart_rounded;
  static const IconData savings = Icons.savings_outlined;
  static const IconData savingsFilled = Icons.savings_rounded;
  static const IconData subscriptions = Icons.layers_outlined;
  static const IconData subscriptionsFilled = Icons.layers_rounded;
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsFilled = Icons.settings_rounded;
  static const IconData moreGrid = Icons.grid_view_outlined;
  static const IconData moreGridFilled = Icons.grid_view_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData transactions = Icons.receipt_long_outlined;
  static const IconData transactionsFilled = Icons.receipt_long_rounded;
  static const IconData budgets = Icons.account_balance_wallet_outlined;
  static const IconData budgetsFilled = Icons.account_balance_wallet_rounded;
  static const IconData insights = Icons.insights_outlined;
  static const IconData insightsFilled = Icons.insights_rounded;
  static const IconData balanceSheet = Icons.account_balance_outlined;
  static const IconData exchangeRates = Icons.swap_horiz_rounded;
}
