import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/components/financial/insight_portfolio_card.dart';
import 'package:smartbudget/components/dialogs/confirm_action_dialog.dart';
import 'package:smartbudget/components/forms/form_components.dart';
import 'package:smartbudget/components/shared/slidable_edge_clip.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/providers/quick_add_provider.dart';
import 'package:smartbudget/core/theme/app_colors.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/core/widgets/app_feedback.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_alerts_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/domain/entities/budget_alert.dart';
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/widgets/animated_list_item.dart';
import 'package:smartbudget/core/utils/money_utils.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  bool _isAppBarScrolled = false;
  bool _hasShownBudgetExceededWarning = false;

  void _maybeHandleQuickAdd(QuickAddTarget? target) {
    if (target != QuickAddTarget.budget) return;
    // Defer to after the current build/lifecycle: mutating a provider during
    // initState or build is disallowed by Riverpod.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pendingQuickAddProvider.notifier).state = null;
      _openBudgetForm(ref);
    });
  }

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  @override
  void initState() {
    super.initState();
    // Consume a quick-add request raised from the bottom-nav "+" menu before
    // navigating here (covers entering the screen fresh).
    _maybeHandleQuickAdd(ref.read(pendingQuickAddProvider));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final policy = await ref.read(rolloverPolicyServiceProvider).loadPolicy();
      if (!policy.autoRolloverEnabled || !mounted) return;
      await ref.read(budgetListProvider.notifier).rolloverExpiredBudgets(
            rolloverDay: policy.rolloverDay,
          );
    });
  }

  Future<void> _runManualRollover() async {
    final policy = await ref.read(rolloverPolicyServiceProvider).loadPolicy();
    await ref.read(budgetListProvider.notifier).rolloverExpiredBudgets(
          rolloverDay: policy.rolloverDay,
        );

    if (!mounted) {
      return;
    }

    AppFeedback.show(
      context,
      message: AppLocalizations.of(context)!.budgetsRolloverCompleted,
      type: AppFeedbackType.success,
    );
  }

  int _milestoneForProgress(double progress) {
    if (progress >= 1.0) return 100;
    if (progress >= 0.90) return 90;
    if (progress >= 0.75) return 75;
    if (progress >= 0.50) return 50;
    return 0;
  }

  // Budget fill ramp routed through the shared status tokens so "over / near /
  // on-track" reads in the exact same green-amber-red as every other meter.
  Color _budgetMilestoneColor(double progress, Brightness brightness) {
    if (progress >= 0.75) return AppColors.statusFor(brightness, AppStatus.danger);
    if (progress >= 0.50) {
      return AppColors.statusFor(brightness, AppStatus.warning);
    }
    return AppColors.statusFor(brightness, AppStatus.success);
  }

  void _trackBudgetMilestone(
    Budget budget,
    double progress, {
    required int recentCategoryUsageCount,
    required double remaining,
    required NumberFormat currencyFormat,
  }) {
    final reachedMilestone = _milestoneForProgress(progress);
    if (reachedMilestone <= 0) return;
    if (recentCategoryUsageCount <= 3) return;
  }

  @override
  Widget build(BuildContext context) {
    // Covers the case where the user triggers the quick-add while already on
    // this screen (provider changes null → budget without a fresh initState).
    ref.listen<QuickAddTarget?>(pendingQuickAddProvider, (_, next) {
      _maybeHandleQuickAdd(next);
    });
    final l10n = AppLocalizations.of(context)!;
    final budgetsAsync = ref.watch(budgetListProvider);
    final alertsAsync = ref.watch(budgetAlertsProvider);
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final currencyFormat = CurrencyUtils.getFormat(appCurrency);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.navBudgets,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: colorScheme.surface.withOpacity( _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'budget-appbar-blur-on',
          offKey: 'budget-appbar-blur-off',
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
        child: budgetsAsync.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return AppEmptyState(
                icon: Icons.pie_chart_outline_rounded,
                title: l10n.budgetEmptyTitle,
                message: l10n.budgetEmptySubtitle,
                lottieAsset: 'assets/animations/empty_budgets.json',
                action: SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 48)
                      .clamp(220.0, 320.0)
                      .toDouble(),
                  child: FilledButton.icon(
                    onPressed: () => _openBudgetForm(ref),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.budgetCreateButton),
                  ),
                ),
              );
            }

            final activeBudgets = budgets
                .where((budget) => budget.isActive)
                .toList(growable: false);
            final inactiveBudgets = budgets
                .where((budget) => !budget.isActive)
                .toList(growable: false);

            final alerts = alertsAsync.maybeWhen(
              data: (items) => items,
              orElse: () => const <BudgetAlert>[],
            );
            final exceededCount =
                alerts.where((alert) => alert.overLimit).length;
            if (exceededCount > 0 && !_hasShownBudgetExceededWarning) {
              _hasShownBudgetExceededWarning = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                AppFeedbackService.showWarning(
                  context,
                  '$exceededCount budget(s) exceeded their current limit.',
                );
              });
            }
            final totalLimit = activeBudgets.fold<double>(
              0.0,
              (sum, budget) => sum + budget.limitAmount,
            );
            final averageAlertThreshold = activeBudgets.isEmpty
                ? 0
                : (activeBudgets.fold<int>(
                          0,
                          (sum, budget) => sum + budget.alertThreshold,
                        ) /
                        activeBudgets.length)
                    .round();
            final riskCount = alertsAsync.maybeWhen(
              data: (alerts) => alerts.length,
              orElse: () => 0,
            );
            final spendingStates = activeBudgets
                .map(
                  (budget) => ref.watch(
                    budgetSpendingProvider(
                      category: budget.category,
                      start: budget.startDate,
                      end: budget.endDate ?? DateTime.now(),
                    ),
                  ),
                )
                .toList(growable: false);
            final spendingValues = spendingStates
                .where((state) => state.hasValue)
                .map((state) => state.requireValue)
                .toList(growable: false);
            final hasAggregateSpending = activeBudgets.isNotEmpty &&
                spendingValues.length == activeBudgets.length;
            final totalSpent = spendingValues.fold<double>(
              0.0,
              (sum, amount) => sum + amount,
            );
            final totalRemaining = totalLimit - totalSpent;
            final nextBudgetBoundary = activeBudgets.isEmpty
                ? null
                : activeBudgets.reduce(
                    (current, candidate) {
                      final currentEnd = current.endDate ?? DateTime.now();
                      final candidateEnd = candidate.endDate ?? DateTime.now();
                      return candidateEnd.isBefore(currentEnd)
                          ? candidate
                          : current;
                    },
                  );
            final nextBoundaryDate =
                nextBudgetBoundary?.endDate ?? DateTime.now();
            final daysLeft = nextBoundaryDate
                .difference(
                  DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                )
                .inDays
                .clamp(0, 365);
            final atRiskCategories = hasAggregateSpending
                ? _countAtRiskBudgets(activeBudgets, spendingValues)
                : riskCount;
            final projectedOverspend = hasAggregateSpending
                ? _calculateProjectedOverspend(activeBudgets, spendingValues)
                : 0.0;
            final portfolioStatus = hasAggregateSpending
                ? getBudgetPortfolioStatus(
                    budgets: activeBudgets,
                    spendingValues: spendingValues,
                    totalLimit: totalLimit,
                    totalSpent: totalSpent,
                  )
                : BudgetPortfolioStatus.watch;
            final decisionMessage = _buildBudgetPortfolioMessage(
              status: portfolioStatus,
              totalRemaining: totalRemaining,
              projectedOverspend: projectedOverspend,
              currencyFormat: currencyFormat,
            );

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  sliver: SliverToBoxAdapter(
                    child: BudgetPortfolioCard(
                      categoriesCount: activeBudgets.length,
                      atRiskCount: atRiskCategories,
                      totalLimit: totalLimit,
                      totalSpent: totalSpent,
                      totalRemaining: totalRemaining,
                      averageAlertThreshold: averageAlertThreshold,
                      projectedOverspend: projectedOverspend,
                      currencyFormat: currencyFormat,
                      description: decisionMessage,
                      daysLeftLabel: l10n.budgetDaysLeft(daysLeft),
                      rolloverLabel: l10n.budgetRolloverNow,
                      onRollover: _runManualRollover,
                    ),
                  ),
                ),
                if (alerts.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverToBoxAdapter(
                      child:
                          _BudgetInsightCards(alerts: alerts.take(4).toList()),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (activeBudgets.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    sliver: SliverToBoxAdapter(
                      child: SmartEmptyState(
                        icon: Icons.pause_circle_outline,
                        title: l10n.budgetsNoActive,
                        message:
                            'All budgets are paused or archived. Resume one below to continue tracking.',
                        lottieAsset: 'assets/animations/empty_budgets.json',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final budget = activeBudgets[index];
                          final endDate = budget.endDate ?? DateTime.now();
                          final now = DateTime.now();
                          final spentAsync = ref.watch(budgetSpendingProvider(
                            category: budget.category,
                            start: budget.startDate,
                            end: endDate,
                          ));
                          final categoryTxAsync = ref.watch(
                            transactionListProvider(
                              startDate: budget.startDate,
                              endDate: endDate,
                              category: budget.category,
                            ),
                          );

                          return AnimatedListItem(
                            index: index,
                            child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Slidable(
                              key: ValueKey('budget-${budget.id}'),
                              startActionPane: ActionPane(
                                motion: const BehindMotion(),
                                extentRatio: 0.30,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => _handleBudgetAction(
                                      action: 'increase10',
                                      budget: budget,
                                      transactions:
                                          categoryTxAsync.valueOrNull ??
                                              const [],
                                      currencyFormat: currencyFormat,
                                    ),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                    foregroundColor: Colors.white,
                                    icon: Icons.swipe_right_alt,
                                    label: l10n.commonIncrease,
                                    borderRadius: BorderRadius.circular(
                                      UiTokens.radiusXl,
                                    ),
                                  ),
                                ],
                              ),
                              endActionPane: ActionPane(
                                motion: const BehindMotion(),
                                extentRatio: 0.30,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => _handleBudgetAction(
                                      action: 'decrease10',
                                      budget: budget,
                                      transactions:
                                          categoryTxAsync.valueOrNull ??
                                              const [],
                                      currencyFormat: currencyFormat,
                                    ),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.tertiary,
                                    foregroundColor: Colors.white,
                                    icon: Icons.swipe_left_alt,
                                    label: l10n.commonDecrease,
                                    borderRadius: BorderRadius.circular(
                                      UiTokens.radiusXl,
                                    ),
                                  ),
                                ],
                              ),
                              child: SwipeableCard(
                                radius: UiTokens.radiusXl,
                                child: spentAsync.when(
                                  data: (spent) {
                                    final usage = budget.limitAmount > 0
                                        ? (spent / budget.limitAmount)
                                        : 0.0;
                                    final progress = usage.clamp(0.0, 1.0);
                                    final categoryTransactions =
                                        categoryTxAsync.valueOrNull ??
                                            const <Transaction>[];
                                    final recentWindowStart = DateTime.now()
                                        .subtract(const Duration(hours: 35));
                                    final recentCategoryUsageCount =
                                        categoryTransactions
                                            .where(
                                              (tx) =>
                                                  tx.type ==
                                                      TransactionType.expense &&
                                                  tx.date.isAfter(
                                                      recentWindowStart),
                                            )
                                            .length;
                                    final remaining =
                                        budget.limitAmount - spent;
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      _trackBudgetMilestone(
                                        budget,
                                        progress,
                                        recentCategoryUsageCount:
                                            recentCategoryUsageCount,
                                        remaining: remaining,
                                        currencyFormat: currencyFormat,
                                      );
                                    });
                                    final usagePercentage = usage * 100;
                                    final daysLeft = endDate
                                        .difference(DateTime(
                                            now.year, now.month, now.day))
                                        .inDays;
                                    final paceDailySpend = now
                                                .difference(budget.startDate)
                                                .inDays <=
                                            0
                                        ? spent
                                        : spent /
                                            now
                                                .difference(DateTime(
                                                  budget.startDate.year,
                                                  budget.startDate.month,
                                                  budget.startDate.day,
                                                ))
                                                .inDays;
                                    final projectedSpend = spent +
                                        (paceDailySpend *
                                            daysLeft.clamp(0, 365));
                                    final projectedOverrun =
                                        projectedSpend - budget.limitAmount;

                                    final statusColor = usagePercentage < 70
                                        ? Colors.green
                                        : usagePercentage < 90
                                            ? Colors.orange
                                            : Colors.red;

                                    final status = usagePercentage < 70
                                        ? l10n.budgetStatusOnTrack
                                        : usagePercentage < 90
                                            ? l10n.budgetStatusSoftWarning
                                            : usagePercentage < 100
                                                ? l10n.budgetStatusHighAlert
                                                : l10n.budgetStatusExceeded;

                                    return _BudgetCategoryCard(
                                      iconColor: statusColor,
                                      budget: budget,
                                      status: status,
                                      statusColor: statusColor,
                                      progressColor: _budgetMilestoneColor(
                                          progress, Theme.of(context).brightness),
                                      progress: progress,
                                      spent: spent,
                                      daysLeft: daysLeft,
                                      currencyFormat: currencyFormat,
                                      cycleLabel: l10n.budgetCycleAlert(
                                        _periodLabel(l10n, budget.period),
                                        '${budget.alertThreshold}',
                                      ),
                                      progressLabel:
                                          l10n.budgetSpendingProgress(
                                        currencyFormat.format(spent),
                                        currencyFormat.format(remaining),
                                        usagePercentage.toStringAsFixed(1),
                                      ),
                                      projectedOverrunLabel:
                                          projectedOverrun > 0 && daysLeft > 0
                                              ? l10n.budgetProjectedOverrun(
                                                  currencyFormat.format(
                                                    projectedOverrun,
                                                  ),
                                                )
                                              : null,
                                      l10n: l10n,
                                      onActionSelected: (action) =>
                                          _handleBudgetAction(
                                        action: action,
                                        budget: budget,
                                        transactions:
                                            categoryTxAsync.valueOrNull ??
                                                const [],
                                        currencyFormat: currencyFormat,
                                      ),
                                    );
                                  },
                                  loading: () => const AppSkeleton(height: 180),
                                  error: (err, st) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child:
                                        Text(l10n.budgetErrorLoadingProgress),
                                  ),
                                ),
                              ),
                            ),
                            ),
                            ); // AnimatedListItem
                        },
                        childCount: activeBudgets.length,
                      ),
                    ),
                  ),
                if (inactiveBudgets.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 4)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Paused or archived budgets',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Resume a budget to bring it back into active planning.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final budget = inactiveBudgets[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BudgetDormantCard(
                              budget: budget,
                              currencyFormat: currencyFormat,
                              onResume: () => _handleBudgetAction(
                                action: 'toggleActive',
                                budget: budget,
                                transactions: const [],
                                currencyFormat: currencyFormat,
                              ),
                              onDelete: () => _handleBudgetAction(
                                action: 'delete',
                                budget: budget,
                                transactions: const [],
                                currencyFormat: currencyFormat,
                              ),
                            ),
                          );
                        },
                        childCount: inactiveBudgets.length,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) => AppSkeleton(
              height: index == 0 ? 148 : 176,
            ),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: 4,
          ),
          error: (err, st) => Center(
            child: Text(l10n.transactionsError(err.toString())),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBudgetAction({
    required String action,
    required Budget budget,
    required List<Transaction> transactions,
    required NumberFormat currencyFormat,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    switch (action) {
      case 'viewTransactions':
        await _showOverspendTransactions(
          context,
          budget,
          transactions,
          currencyFormat,
        );
        return;
      case 'edit':
        await _openBudgetForm(ref, existingBudget: budget);
        return;
      case 'increase10':
        await _quickAdjustBudget(ref, budget, 1.1);
        break;
      case 'decrease10':
        await _quickAdjustBudget(ref, budget, 0.9);
        break;
      case 'duplicate':
        final duplicate = budget.copyWith(
          id: const Uuid().v4(),
          startDate: DateTime.now(),
          endDate: _calculateEndDate(DateTime.now(), budget.period),
        );
        await ref.read(budgetListProvider.notifier).addBudget(duplicate);
        break;
      case 'toggleActive':
        await ref.read(budgetListProvider.notifier).updateBudget(
              budget.copyWith(isActive: !budget.isActive),
            );
        break;
      case 'rollover':
        await _runManualRollover();
        return;
      case 'archive':
        final shouldArchive = await showDialog<bool>(
              context: context,
              builder: (context) => ConfirmActionDialog(
                title: l10n.budgetsArchiveTitle,
                message:
                    'This budget will be paused and hidden from active planning until you re-enable it.',
                confirmLabel: l10n.commonArchive,
              ),
            ) ??
            false;
        if (!shouldArchive) return;
        await ref.read(budgetListProvider.notifier).updateBudget(
              budget.copyWith(isActive: false),
            );
        break;
      case 'delete':
        final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (context) => ConfirmActionDialog(
                title: l10n.budgetsDeleteTitle,
                message:
                    'This permanently removes the budget. Transactions are not deleted.',
                confirmLabel: l10n.delete,
              ),
            ) ??
            false;
        if (!shouldDelete) return;
        await ref.read(budgetListProvider.notifier).deleteBudget(budget.id);
        break;
      default:
        return;
    }

    if (!mounted) return;
    AppFeedback.show(
      context,
      message: l10n.budgetsActionCompleted,
      type: AppFeedbackType.success,
    );
  }

  Future<void> _quickAdjustBudget(
    WidgetRef ref,
    Budget budget,
    double multiplier,
  ) async {
    final updated = budget.copyWith(
      limitAmount: (budget.limitAmount * multiplier).clamp(1.0, 9999999.0),
    );
    await ref.read(budgetListProvider.notifier).updateBudget(updated);
  }

  int _countAtRiskBudgets(List<Budget> budgets, List<double> spendingValues) {
    var count = 0;
    for (var index = 0; index < budgets.length; index++) {
      final budget = budgets[index];
      final spending = spendingValues[index];
      if (budget.limitAmount <= 0) continue;
      final usagePercent = (spending / budget.limitAmount) * 100;
      if (usagePercent >= budget.alertThreshold) {
        count += 1;
      }
    }
    return count;
  }

  double _calculateProjectedOverspend(
    List<Budget> budgets,
    List<double> spendingValues,
  ) {
    final now = DateTime.now();
    var projectedTotal = 0.0;
    for (var index = 0; index < budgets.length; index++) {
      final budget = budgets[index];
      final spending = spendingValues[index];
      final endDate = budget.endDate ?? now;
      final daysLeft =
          endDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      final elapsedDays = now.difference(budget.startDate).inDays;
      final paceDailySpend =
          elapsedDays <= 0 ? spending : spending / elapsedDays;
      final projectedSpend =
          spending + (paceDailySpend * daysLeft.clamp(0, 365));
      if (projectedSpend > budget.limitAmount) {
        projectedTotal += projectedSpend - budget.limitAmount;
      }
    }
    return projectedTotal;
  }

  String _buildBudgetPortfolioMessage({
    required BudgetPortfolioStatus status,
    required double totalRemaining,
    required double projectedOverspend,
    required NumberFormat currencyFormat,
  }) {
    switch (status) {
      case BudgetPortfolioStatus.exceeded:
        return 'You are projected to exceed your budget by ${currencyFormat.format(projectedOverspend > 0 ? projectedOverspend : totalRemaining.abs())} if current spending continues.';
      case BudgetPortfolioStatus.atRisk:
        return '${currencyFormat.format(totalRemaining)} remains available this month. Keep your highest-risk category under control.';
      case BudgetPortfolioStatus.watch:
        return 'Your budget setup needs attention. ${currencyFormat.format(totalRemaining)} is still available across active categories.';
      case BudgetPortfolioStatus.stable:
        return 'Your budget setup is stable. You still have ${currencyFormat.format(totalRemaining)} available across active categories.';
    }
  }

  Future<void> _openBudgetForm(
    WidgetRef ref, {
    Budget? existingBudget,
  }) async {
    final appCurrency = ref.read(appCurrencyControllerProvider);
    final result = await AppFormSheet.show<_BudgetFormResult>(
      context,
      builder: (_) => _BudgetFormSheet(
        existingBudget: existingBudget,
        currencySymbol: CurrencyUtils.symbol(appCurrency),
        currencyCode: appCurrency,
      ),
    );

    if (result == null) return;
    if (!mounted) return;

    final endDate = _calculateEndDate(result.startDate, result.period);
    final budget = Budget(
      id: existingBudget?.id ?? const Uuid().v4(),
      category: result.category,
      limitAmount: result.limitAmount,
      currency: appCurrency,
      period: result.period,
      startDate: result.startDate,
      endDate: endDate,
      alertThreshold: result.alertThreshold,
      isActive: existingBudget?.isActive ?? true,
    );

    AppFeedbackService.showLoading(
      context,
      existingBudget == null ? 'Saving budget...' : 'Updating budget...',
    );
    try {
      if (existingBudget == null) {
        await ref.read(budgetListProvider.notifier).addBudget(budget);
      } else {
        await ref.read(budgetListProvider.notifier).updateBudget(budget);
      }
      if (!mounted) return;
      AppFeedbackService.showSuccess(
        context,
        existingBudget == null
            ? 'Budget saved successfully.'
            : 'Budget updated successfully.',
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedbackService.showError(
        context,
        'Unable to save budget. Please try again.',
      );
    } finally {
      AppFeedbackService.dismissLoading();
    }
  }

  DateTime _calculateEndDate(DateTime startDate, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case BudgetPeriod.yearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
    }
  }

  String _periodLabel(AppLocalizations l10n, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return l10n.reportsBillingWeekly;
      case BudgetPeriod.monthly:
        return l10n.reportsBillingMonthly;
      case BudgetPeriod.yearly:
        return l10n.reportsBillingYearly;
    }
  }

  Future<void> _showOverspendTransactions(
    BuildContext context,
    Budget budget,
    List<Transaction> transactions,
    NumberFormat currencyFormat,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await AppFormSheet.show<void>(
      context,
      builder: (context) {
        if (transactions.isEmpty) {
          return AppFormSheet(
            maxHeightFactor: 0.28,
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n.budgetNoTransactionsForCategory),
            ),
          );
        }

        return AppFormSheet(
          maxHeightFactor: 0.72,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.budgetCategoryTransactions(budget.category),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              ...transactions.map(
                (tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity( 0.48),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        title: Text(
                          tx.note ?? tx.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          MaterialLocalizations.of(context)
                              .formatMediumDate(tx.date),
                        ),
                        trailing: Text(
                          currencyFormat.format(tx.amount),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum BudgetPortfolioStatus { stable, watch, atRisk, exceeded }

BudgetPortfolioStatus getBudgetPortfolioStatus({
  required List<Budget> budgets,
  required List<double> spendingValues,
  required double totalLimit,
  required double totalSpent,
}) {
  for (var index = 0; index < budgets.length; index++) {
    final budget = budgets[index];
    final spending = spendingValues[index];
    if (budget.limitAmount <= 0) continue;
    final usageRatio = spending / budget.limitAmount;
    final usagePercent = usageRatio * 100;
    if (usageRatio > 1.0) {
      return BudgetPortfolioStatus.exceeded;
    }
    if (usagePercent >= budget.alertThreshold) {
      return BudgetPortfolioStatus.atRisk;
    }
  }
  if (totalLimit > 0 && (totalSpent / totalLimit) > 0.7) {
    return BudgetPortfolioStatus.watch;
  }
  return BudgetPortfolioStatus.stable;
}

class _BudgetInsightCards extends StatelessWidget {
  const _BudgetInsightCards({required this.alerts});

  final List<BudgetAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 760;
        final cardWidth = twoColumns
            ? ((constraints.maxWidth - 12) / 2).clamp(280.0, 520.0)
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: alerts
              .map(
                (alert) => SizedBox(
                  width: cardWidth,
                  child: _BudgetInsightCard(alert: alert),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _BudgetInsightCard extends StatelessWidget {
  const _BudgetInsightCard({required this.alert});

  final BudgetAlert alert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final progressPercent = (alert.progress * 100).toStringAsFixed(0);
    final isCritical = alert.overLimit;
    final isWarning = !isCritical && alert.nearLimit;
    final tone = isCritical
        ? scheme.error
        : isWarning
            ? Colors.orange
            : scheme.primary;

    final statusLabel = isCritical
        ? 'Exceeded'
        : isWarning
            ? 'Near Limit'
            : 'On Track';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCritical
              ? (isDark
                  ? const [
                      Color(0xFF3B1A24),
                      Color(0xFF35141F),
                      Color(0xFF281016),
                    ]
                  : const [
                      Color(0xFFFFE4EA),
                      Color(0xFFFFEFF3),
                      Color(0xFFFFF7F9),
                    ])
              : isWarning
                  ? (isDark
                      ? const [
                          Color(0xFF3A2A18),
                          Color(0xFF332514),
                          Color(0xFF241A10),
                        ]
                      : const [
                          Color(0xFFFFEFD8),
                          Color(0xFFFFF5E8),
                          Color(0xFFFFFBF3),
                        ])
                  : (isDark
                      ? const [
                          Color(0xFF1E1A40),
                          Color(0xFF221540),
                          Color(0xFF1A1A2E),
                        ]
                      : const [
                          Color(0xFFECDDFF),
                          Color(0xFFF1EEFF),
                          Color(0xFFF7F9FF),
                        ]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.withOpacity( 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCritical
                      ? Icons.error_outline
                      : isWarning
                          ? Icons.warning_amber_outlined
                          : Icons.insights_outlined,
                  color: tone,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  alert.category,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Usage is at $progressPercent%. Current status: $statusLabel.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InsightMetric(label: l10n.budgetsMetricUsed, value: '$progressPercent%'),
                    const SizedBox(height: 12),
                    _InsightMetric(label: l10n.commonStatus, value: statusLabel),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InsightMetric(
                        label: l10n.budgetsMetricAlertAt, value: '${alert.threshold}%'),
                    const SizedBox(height: 12),
                    _InsightMetric(
                      label: l10n.budgetsMetricDelta,
                      value:
                          '${(alert.progress * 100 - alert.threshold).toStringAsFixed(0)}%',
                      tone: tone,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightMetric extends StatelessWidget {
  const _InsightMetric({
    required this.label,
    required this.value,
    this.tone,
  });

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: tone,
              ),
        ),
      ],
    );
  }
}

class _BudgetDormantCard extends StatelessWidget {
  const _BudgetDormantCard({
    required this.budget,
    required this.currencyFormat,
    required this.onResume,
    required this.onDelete,
  });

  final Budget budget;
  final NumberFormat currencyFormat;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.archive_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.category,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Limit ${currencyFormat.format(budget.limitAmount)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onResume,
            child: Text(l10n.commonResume),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  const _BudgetCategoryCard({
    required this.iconColor,
    required this.budget,
    required this.status,
    required this.statusColor,
    required this.progressColor,
    required this.progress,
    required this.spent,
    required this.daysLeft,
    required this.currencyFormat,
    required this.cycleLabel,
    required this.progressLabel,
    required this.projectedOverrunLabel,
    required this.l10n,
    required this.onActionSelected,
  });

  final Color iconColor;
  final Budget budget;
  final String status;
  final Color statusColor;
  final Color progressColor;
  final double progress;
  final double spent;
  final int daysLeft;
  final NumberFormat currencyFormat;
  final String cycleLabel;
  final String progressLabel;
  final String? projectedOverrunLabel;
  final AppLocalizations l10n;
  final ValueChanged<String> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity( 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(Icons.pie_chart_rounded, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity( 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              AppActionMenu(
                title: budget.category,
                tooltip: l10n.budgetsActions,
                onSelected: onActionSelected,
                items: [
                  AppActionItem(
                    value: 'viewTransactions',
                    label: l10n.budgetsViewTransactions,
                    icon: Icons.receipt_long_outlined,
                  ),
                  AppActionItem(
                    value: 'edit',
                    label: l10n.budgetEdit,
                    icon: Icons.edit_outlined,
                  ),
                  AppActionItem(
                    value: 'increase10',
                    label: l10n.budgetsIncrease10,
                    icon: Icons.trending_up,
                  ),
                  AppActionItem(
                    value: 'decrease10',
                    label: l10n.budgetsReduce10,
                    icon: Icons.trending_down,
                  ),
                  AppActionItem(
                    value: 'toggleActive',
                    label: budget.isActive ? l10n.budgetsPauseBudget : l10n.budgetsResumeBudget,
                    icon: budget.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                  AppActionItem(
                    value: 'rollover',
                    label: l10n.budgetRolloverNow,
                    icon: Icons.autorenew,
                  ),
                  AppActionItem(
                    value: 'duplicate',
                    label: l10n.commonDuplicate,
                    icon: Icons.copy_outlined,
                  ),
                  AppActionItem(
                    value: 'archive',
                    label: l10n.commonArchive,
                    icon: Icons.archive_outlined,
                  ),
                  AppActionItem(
                    value: 'delete',
                    label: l10n.budgetDelete,
                    icon: Icons.delete_outline,
                    destructive: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${currencyFormat.format(spent)} / ${currencyFormat.format(budget.limitAmount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            cycleLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => onActionSelected('viewTransactions'),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedFinanceProgressBar(
              value: progress,
              color: progressColor,
              height: 7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progressLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            daysLeft < 0
                ? l10n.budgetPeriodEnded
                : l10n.budgetDaysLeft(daysLeft),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (projectedOverrunLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              projectedOverrunLabel!,
              style: TextStyle(
                fontSize: 12,
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Tap the progress bar to review related transactions.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _BudgetFormResult {
  const _BudgetFormResult({
    required this.category,
    required this.limitAmount,
    required this.period,
    required this.alertThreshold,
    required this.startDate,
  });

  final String category;
  final double limitAmount;
  final BudgetPeriod period;
  final int alertThreshold;
  final DateTime startDate;
}

class _BudgetFormSheet extends StatefulWidget {
  const _BudgetFormSheet({
    this.existingBudget,
    required this.currencySymbol,
    required this.currencyCode,
  });

  final Budget? existingBudget;
  final String currencySymbol;
  final String currencyCode;

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _categoryController;
  late final TextEditingController _amountController;
  late BudgetPeriod _period;
  late int _alertThreshold;
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(
      text: widget.existingBudget?.category ?? 'Food',
    );
    _amountController = TextEditingController(
      text: widget.existingBudget?.limitAmount.toStringAsFixed(2) ?? '',
    );
    _period = widget.existingBudget?.period ?? BudgetPeriod.monthly;
    _alertThreshold = widget.existingBudget?.alertThreshold ?? 80;
    _startDate = widget.existingBudget?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2021),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() => _startDate = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppFeedbackService.showWarning(
        context,
        'Complete required budget fields to continue.',
      );
      return;
    }
    final parsedAmount =
        FormValidation.parseDecimal(_amountController.text.trim()) ?? 0;
    if (parsedAmount <= 0) {
      AppFeedbackService.showWarning(
        context,
        'Enter a valid budget amount greater than zero.',
      );
      return;
    }
    Navigator.of(context).pop(
      _BudgetFormResult(
        category: _categoryController.text.trim(),
        limitAmount: parsedAmount,
        period: _period,
        alertThreshold: _alertThreshold,
        startDate: _startDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEdit = widget.existingBudget != null;
    final liveAmount =
        FormValidation.parseDecimal(_amountController.text.trim()) ?? 0;
    final liveCategory = _categoryController.text.trim();

    final formFields = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card (matches transaction form style) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity( 0.10)
                    : Colors.black.withOpacity( 0.10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity( 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.pie_chart_rounded,
                      color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? l10n.budgetEdit : l10n.budgetCreate,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        liveAmount > 0
                            ? '${widget.currencySymbol} ${liveAmount.toStringAsFixed(2)}${liveCategory.isNotEmpty ? ' · $liveCategory' : ''}'
                            : 'Set a category and limit',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ModernInput(
            controller: _categoryController,
            label: l10n.category,
            hintText: l10n.budgetCategoryHint,
            helperText: 'Used for insights and category-based controls',
            onChanged: (_) => setState(() {}),
            validator: (value) =>
                FormValidation.requiredText(value, l10n.budgetEnterCategory),
          ),
          const SizedBox(height: 16),
          CurrencyInput(
            controller: _amountController,
            label: l10n.budgetAmount,
            currencySymbol: widget.currencySymbol,
            decimalDigits: MoneyUtils.decimalDigits(widget.currencyCode),
            onChanged: (_) => setState(() {}),
            validator: (value) => FormValidation.positiveAmount(
              value,
              l10n.budgetEnterValidAmount,
              l10n.budgetEnterValidAmount,
            ),
          ),
          const SizedBox(height: 16),
          ModernSelect<BudgetPeriod>(
            value: _period,
            label: l10n.budgetPeriod,
            prefixIcon: Icons.event_repeat_rounded,
            items: BudgetPeriod.values
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      switch (p) {
                        BudgetPeriod.weekly => l10n.reportsBillingWeekly,
                        BudgetPeriod.monthly => l10n.reportsBillingMonthly,
                        BudgetPeriod.yearly => l10n.reportsBillingYearly,
                      },
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _period = value);
            },
          ),
          const SizedBox(height: 16),
          AmountSlider(
            value: _alertThreshold.toDouble(),
            min: 60,
            max: 95,
            divisions: 7,
            labelBuilder: (value) => l10n.budgetAlertPercent(value.round()),
            onChanged: (value) {
              setState(() => _alertThreshold = value.round());
            },
          ),
          const SizedBox(height: 4),
          ModernDatePicker(
            label: l10n.budgetStartDate,
            value:
                MaterialLocalizations.of(context).formatMediumDate(_startDate),
            onTap: _pickStartDate,
          ),
        ],
      ),
    );

    return AppFormSheet(
      onClose: () => Navigator.of(context).pop(),
      maxHeightFactor: 0.85,
      body: formFields,
      actions: FilledButton.icon(
        onPressed: _submit,
        icon: Icon(
          isEdit ? Icons.edit_rounded : Icons.add_rounded,
        ),
        label: Text(isEdit ? l10n.budgetUpdate : l10n.budgetSave),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
        ),
      ),
    );
  }
}
