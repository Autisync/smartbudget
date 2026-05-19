import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart'
    show SecuritySetting;
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/core/widgets/branded_title.dart';
import 'package:smartbudget/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:smartbudget/features/insights/presentation/providers/insight_provider.dart';
import 'package:smartbudget/features/insights/presentation/widgets/alert_banner.dart';
import 'package:smartbudget/intelligence/analyzers/spending_analyzer.dart';
import 'package:smartbudget/features/insights/presentation/widgets/forecast_chart_widget.dart';
import 'package:smartbudget/features/insights/presentation/widgets/insight_card.dart';
import 'package:smartbudget/features/insights/presentation/widgets/simulation_card.dart';
import 'package:smartbudget/intelligence/predictors/cashflow_predictor.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final insightResultsAsync = ref.watch(insightResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: BrandedTitle(label: l10n.insightsFinancialCopilot),
        actions: [
          NotificationBellButton(
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: insightResultsAsync.when(
        data: (result) {
          final appCurrency = ref.watch(appCurrencyControllerProvider);
          final currencyFormat = CurrencyUtils.getFormat(appCurrency);
          final activeSubscriptions =
              result.subscriptions.where((sub) => sub.isActive).toList();
          final subscriptionMonthlyCost = activeSubscriptions.fold<double>(
              0, (sum, sub) => sum + sub.monthlyCost);
          final upcomingSubscriptions = activeSubscriptions
              .where((sub) => sub.nextDueDate
                  .isBefore(DateTime.now().add(const Duration(days: 14))))
              .toList();

          return SingleChildScrollView(
            padding: UiTokens.adaptiveScreenPadding(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result.forecast.riskLevel == RiskLevel.critical)
                      AlertBanner(
                        message: l10n.insightsCriticalCashflowRisk,
                        color: Colors.red.shade700,
                      )
                    else if (result.forecast.riskLevel == RiskLevel.high)
                      AlertBanner(
                        message: l10n.insightsElevatedCashflowRisk,
                        color: Colors.orange.shade700,
                      )
                    else if (upcomingSubscriptions.isNotEmpty)
                      AlertBanner(
                        message: l10n.insightsUpcomingRenewalsDueSoon(
                          upcomingSubscriptions.length,
                        ),
                        color: Colors.orange.shade700,
                      )
                    else if (result.securitySetting != null &&
                        _computeSecurityScore(result.securitySetting!) < 60)
                      AlertBanner(
                        message: l10n.insightsWeakSecuritySettings,
                        color: Colors.orange.shade700,
                      ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: AppSurfaces.elevated(
                        context,
                        radius: UiTokens.radiusXl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.insights_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.insightsDecisionSnapshot,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.insightsRiskLevel(
                              _localizedRiskLevel(
                                  result.forecast.riskLevel, l10n),
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: UiTokens.chipSpacing,
                            runSpacing: UiTokens.chipRunSpacing,
                            children: [
                              _InsightMetricChip(
                                icon: Icons.payments_outlined,
                                label: l10n.insightsMetricSubscriptionPerMonth,
                                value: currencyFormat
                                    .format(subscriptionMonthlyCost),
                              ),
                              _InsightMetricChip(
                                icon: Icons.warning_amber_rounded,
                                label: l10n.insightsMetricAnomalies,
                                value:
                                    '${result.spendingProfile.anomalies.length}',
                              ),
                              _InsightMetricChip(
                                icon: Icons.event_repeat_rounded,
                                label: l10n.insightsMetricRenewals14d,
                                value: '${upcomingSubscriptions.length}',
                              ),
                              _InsightMetricChip(
                                icon: Icons.security_rounded,
                                label: l10n.insightsMetricSecurityScore,
                                value: result.securitySetting != null
                                    ? '${_computeSecurityScore(result.securitySetting!)}%'
                                    : l10n.insightsNotAvailable,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: UiTokens.sectionGapMd),
                    ForecastChartWidget(dataPoints: result.forecastSeries),
                    const SizedBox(height: UiTokens.sectionGapMd),
                    SimulationCard(
                      forecast: result.forecast,
                      profile: result.spendingProfile,
                      currency: appCurrency,
                    ),
                    const SizedBox(height: UiTokens.sectionGapMd),
                    _InsightSectionHeader(
                      icon: Icons.lightbulb_outline_rounded,
                      title: l10n.insightsActionableInsights,
                    ),
                    const SizedBox(height: 12),
                    ...result.insights
                        .map((insight) => InsightCard(insight: insight)),
                    const SizedBox(height: UiTokens.sectionGapMd),
                    _InsightSectionHeader(
                      icon: Icons.pie_chart_outline_rounded,
                      title: l10n.insightsCategoryDistribution,
                    ),
                    const SizedBox(height: 12),
                    if (result.spendingProfile.categoryDistribution.isEmpty)
                      Text(l10n.insightsNoCategoryData)
                    else
                      ...result.spendingProfile.categoryDistribution.entries
                          .map(
                        (entry) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: AppSurfaces.elevated(context, radius: 16),
                          child: ListTile(
                            title: Text(entry.key),
                            trailing:
                                Text('${entry.value.toStringAsFixed(1)}%'),
                          ),
                        ),
                      ),
                    const SizedBox(height: UiTokens.sectionGapMd),
                    _InsightSectionHeader(
                      icon: Icons.trending_up_rounded,
                      title: l10n.insightsAnomaliesAndImpact,
                    ),
                    const SizedBox(height: 12),
                    if (result.spendingProfile.anomalies.isEmpty)
                      Text(l10n.insightsNoUnusualSpending)
                    else
                      ...result.spendingProfile.anomalies.map(
                        (anomaly) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: AppSurfaces.elevated(context, radius: 16),
                          child: ListTile(
                            title: Text(anomaly.reason),
                            subtitle: Text(
                              '${anomaly.transaction.category} ${currencyFormat.format(anomaly.transaction.amount)}',
                            ),
                            trailing: Text(
                              anomaly.severity.name.toUpperCase(),
                              style: TextStyle(
                                color:
                                    anomaly.severity == AnomalySeverity.critical
                                        ? Colors.red
                                        : Colors.orange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: UiTokens.sectionGapMd),
                    _InsightSectionHeader(
                      icon: Icons.subscriptions_outlined,
                      title: l10n.insightsSubscriptionIntelligence,
                    ),
                    const SizedBox(height: 12),
                    if (activeSubscriptions.isEmpty)
                      Text(l10n.insightsNoActiveSubscriptions)
                    else
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: AppSurfaces.elevated(context, radius: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.insightsTotalMonthlySubscriptionSpend(
                                currencyFormat.format(subscriptionMonthlyCost),
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              upcomingSubscriptions.isNotEmpty
                                  ? l10n.insightsRenewalsIn14d(
                                      upcomingSubscriptions.length,
                                    )
                                  : l10n.insightsNoRenewalsIn14d,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    _InsightSectionHeader(
                      icon: Icons.shield_outlined,
                      title: l10n.insightsSecurityPosture,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: AppSurfaces.elevated(context, radius: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.securitySetting != null
                                ? l10n.insightsSecurityConfiguration(
                                    result.securitySetting!.biometricEnabled
                                        ? l10n.insightsEnabled
                                        : l10n.insightsDisabled,
                                    result.securitySetting!.pinEnabled
                                        ? l10n.insightsEnabled
                                        : l10n.insightsDisabled,
                                  )
                                : l10n.insightsSecurityConfigurationUnavailable,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.securitySetting != null
                                ? l10n.insightsLastUpdate(
                                    result.securitySetting!.lastSecurityUpdate
                                        .toLocal()
                                        .toString()
                                        .split(' ')
                                        .first,
                                  )
                                : l10n.insightsConnectSecuritySettings,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: UiTokens.sectionGapLg),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) =>
            Center(child: Text(l10n.insightsErrorLoading(err.toString()))),
      ),
    );
  }

  String _localizedRiskLevel(RiskLevel riskLevel, AppLocalizations l10n) {
    return switch (riskLevel) {
      RiskLevel.low => l10n.insightsRiskLow,
      RiskLevel.medium => l10n.insightsRiskMedium,
      RiskLevel.high => l10n.insightsRiskHigh,
      RiskLevel.critical => l10n.insightsRiskCritical,
    };
  }

  int _computeSecurityScore(SecuritySetting securitySetting) {
    var score = 50;
    if (securitySetting.biometricEnabled) score += 20;
    if (securitySetting.pinEnabled) score += 15;
    if (securitySetting.maxFailedAttempts <= 5) score += 10;
    if (securitySetting.lockoutDuration >= 300) score += 5;
    if (securitySetting.sessionTimeout <= 600) score += 5;
    return score.clamp(0, 100);
  }
}

class _InsightSectionHeader extends StatelessWidget {
  const _InsightSectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _InsightMetricChip extends StatelessWidget {
  const _InsightMetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




