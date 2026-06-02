import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/data/datasources/local/app_database.dart'
    show SecuritySetting;
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/features/insights/presentation/providers/insight_provider.dart';
import 'package:smartbudget/features/insights/presentation/widgets/alert_banner.dart';
import 'package:smartbudget/intelligence/analyzers/spending_analyzer.dart';
import 'package:smartbudget/features/insights/presentation/widgets/forecast_chart_widget.dart';
import 'package:smartbudget/features/insights/presentation/widgets/insight_card.dart';
import 'package:smartbudget/features/insights/presentation/widgets/simulation_card.dart';
import 'package:smartbudget/intelligence/predictors/cashflow_predictor.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  bool _isAppBarScrolled = false;

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insightResultsAsync = ref.watch(insightResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.insightsFinancialCopilot,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(
              alpha: _isAppBarScrolled ? 0.88 : 0,
            ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'insights-appbar-blur-on',
          offKey: 'insights-appbar-blur-off',
        ),
        actions: buildPageHeaderActions(
          context: context,
          isScrolled: _isAppBarScrolled,
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _updateAppBarScrollState(notification.metrics.pixels);
          }
          return false;
        },
        child: insightResultsAsync.when(
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
                      const SmartSpendHeader(
                        title: 'Financial Copilot',
                        subtitle:
                            'AI-guided insights, risk detection, and proactive recommendations.',
                      ),
                      const SizedBox(height: 24),
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
                      SmartCard(
                        radius: 28,
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
                            const SizedBox(height: 12),
                            Text(
                              l10n.insightsRiskLevel(
                                _localizedRiskLevel(
                                    result.forecast.riskLevel, l10n),
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: UiTokens.chipSpacing,
                              runSpacing: UiTokens.chipRunSpacing,
                              children: [
                                _InsightMetricChip(
                                  icon: Icons.payments_outlined,
                                  label:
                                      l10n.insightsMetricSubscriptionPerMonth,
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
                        SmartEmptyState(
                          icon: Icons.pie_chart_outline_rounded,
                          title: l10n.insightsCategoryDistribution,
                          message: l10n.insightsNoCategoryData,
                          lottieAsset: 'assets/animations/empty_reports.json',
                        )
                      else
                        ...result.spendingProfile.categoryDistribution.entries
                            .map(
                          (entry) => SmartCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            radius: 22,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(entry.key)),
                                    Text(
                                      '${entry.value.toStringAsFixed(1)}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SmartProgressBar(
                                  value: (entry.value / 100).clamp(0.0, 1.0),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
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
                        SmartCard(
                          radius: 24,
                          color:
                              const Color(0xFF2E7D32).withValues(alpha: 0.08),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32)
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.verified_user_outlined,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.insightsNoUnusualSpending,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...result.spendingProfile.anomalies.map(
                          (anomaly) => SmartCard(
                            padding: const EdgeInsets.all(14),
                            radius: 22,
                            color: (anomaly.severity == AnomalySeverity.critical
                                    ? Colors.red
                                    : Colors.orange)
                                .withValues(alpha: 0.08),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        anomaly.reason,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${anomaly.transaction.category} ${currencyFormat.format(anomaly.transaction.amount)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                StatusPill(
                                  label: anomaly.severity.name.toUpperCase(),
                                  color: anomaly.severity ==
                                          AnomalySeverity.critical
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ],
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
                                  currencyFormat
                                      .format(subscriptionMonthlyCost),
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
                                  : l10n
                                      .insightsSecurityConfigurationUnavailable,
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
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.12),
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
