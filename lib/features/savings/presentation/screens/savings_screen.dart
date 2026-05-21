import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/input_styles.dart';
import 'package:smartbudget/core/widgets/app_feedback.dart';
import 'package:smartbudget/core/widgets/branded_title.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/core/widgets/form_date_field.dart';
import 'package:smartbudget/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:smartbudget/features/savings/presentation/providers/savings_provider.dart';
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/data/models/tables.dart' show GoalPriority;
import 'package:smartbudget/data/models/tables.dart' show TransactionType;
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  ProviderSubscription<AsyncValue<List<SavingsNudge>>>? _nudgeSubscription;
  final Set<String> _notifiedNudgeKeys = <String>{};
  bool _isAppBarScrolled = false;

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
    _nudgeSubscription = ref.listenManual<AsyncValue<List<SavingsNudge>>>(
      savingsNudgesProvider,
      (previous, next) {
        next.whenData((nudges) async {
          final notificationService = ref.read(notificationServiceProvider);
          final preferencesService =
              ref.read(notificationPreferencesServiceProvider);
          for (final nudge in nudges.take(2)) {
            final key = '${nudge.goalId}-${nudge.title}';
            if (_notifiedNudgeKeys.contains(key)) continue;

            final canSend =
                await preferencesService.shouldDispatch('savingsNudges');
            if (!canSend) break;

            _notifiedNudgeKeys.add(key);
            await notificationService.showSavingsNudge(
              title: nudge.title,
              body: nudge.message,
              payload: nudge.goalId,
            );
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _nudgeSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final savingsAsync = ref.watch(savingsGoalListProvider);
    final nudgesAsync = ref.watch(savingsNudgesProvider);
    final monthlyTransactionsAsync = ref.watch(recentTransactionsProvider);
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final currencyFormat = CurrencyUtils.getFormat(appCurrency);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : const Color(0xFFF8F8FA),
      appBar: AppBar(
        title: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: _isAppBarScrolled ? 0.9 : 0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: BrandedTitle(label: l10n.savingsGoalsTitle),
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isAppBarScrolled
                  ? ClipRect(
                      key: const ValueKey('savings-appbar-blur-on'),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.08),
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('savings-appbar-blur-off')),
            ),
          ],
        ),
        actions: [
          NotificationBellButton(
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: _isAppBarScrolled ? 0.9 : 0,
            ),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: AppFloatingActionButton(
        onPressed: () => _openGoalForm(context, ref),
        icon: Icons.add_rounded,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _updateAppBarScrollState(notification.metrics.pixels);
          }
          return false;
        },
        child: savingsAsync.when(
          data: (goals) {
            final now = DateTime.now();
            final monthlySurplus = monthlyTransactionsAsync.maybeWhen(
              data: (transactions) {
                final income = transactions
                    .where((tx) => tx.type == TransactionType.income)
                    .fold<double>(0.0, (sum, tx) => sum + tx.amount);
                final expense = transactions
                    .where((tx) => tx.type == TransactionType.expense)
                    .fold<double>(0.0, (sum, tx) => sum + tx.amount);
                return income - expense;
              },
              orElse: () => 0.0,
            );
            final totalTarget = goals.fold<double>(
              0.0,
              (sum, goal) => sum + goal.targetAmount,
            );
            final totalSaved = goals.fold<double>(
              0.0,
              (sum, goal) => sum + goal.savedAmount,
            );
            final atRiskGoals = goals.where((goal) {
              if (goal.deadline == null || goal.targetAmount <= 0) return false;
              final createdAt = goal.createdAt ?? now;
              final totalDays = goal.deadline!.difference(createdAt).inDays;
              if (totalDays <= 0) return false;
              final elapsedDays = now.difference(createdAt).inDays;
              final expectedProgress =
                  (elapsedDays / totalDays).clamp(0.0, 1.0);
              final actualProgress =
                  (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
              return actualProgress + 0.05 < expectedProgress;
            }).length;

            if (goals.isEmpty) {
              return AppEmptyState(
                icon: Icons.savings_outlined,
                title: l10n.savingsEmptyTitle,
                message: l10n.savingsEmptySubtitle,
                action: SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 48)
                      .clamp(220.0, 320.0)
                      .toDouble(),
                  child: FilledButton.icon(
                    onPressed: () => _openGoalForm(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.savingsCreateGoal),
                  ),
                ),
              );
            }

            final decisionMessage = atRiskGoals > 0
                ? l10n.savingsGoalsBehindPace(atRiskGoals)
                : monthlySurplus > 0
                    ? l10n.savingsMonthlySurplusMessage(
                        currencyFormat.format(monthlySurplus),
                      )
                    : l10n.savingsSteadyProgress;

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              children: [
                // Savings Portfolio Card
                _SavingsPortfolioCard(
                  totalTarget: totalTarget,
                  totalSaved: totalSaved,
                  atRiskGoals: atRiskGoals,
                  goalsCount: goals.length,
                  decisionMessage: decisionMessage,
                  colorScheme: colorScheme,
                  currencyFormat: currencyFormat,
                ),
                const SizedBox(height: 16),

                // Nudges Section
                nudgesAsync.when(
                  data: (nudges) {
                    if (nudges.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        _SavingsNudgeCard(nudges: nudges.take(2).toList()),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Surplus Allocation Section
                if (monthlySurplus > 0)
                  Column(
                    children: [
                      _SavingsSurplusCard(
                        monthlySurplus: monthlySurplus,
                        currencyFormat: currencyFormat,
                        onAllocate50: () =>
                            _allocateSurplusToTopGoal(ref, goals, 50),
                        onAllocate100: () =>
                            _allocateSurplusToTopGoal(ref, goals, 100),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Savings Goals
                ...goals.map((goal) {
                  final progress = goal.targetAmount > 0
                      ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
                      : 0.0;
                  final remaining =
                      (goal.targetAmount - goal.savedAmount).clamp(
                    0.0,
                    double.infinity,
                  );
                  final hasDeadline = goal.deadline != null;
                  final monthsRemaining = hasDeadline
                      ? (((goal.deadline!.difference(now).inDays) / 30).ceil())
                          .clamp(1, 120)
                      : 0;
                  final suggestedMonthly =
                      hasDeadline ? remaining / monthsRemaining : remaining / 6;
                  final projectedLate = hasDeadline && suggestedMonthly > 0
                      ? _calculateProjectedDelayMonths(
                          goal,
                          now,
                        )
                      : 0;

                  final statusColor = _goalStatusColor(progress, projectedLate);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SavingsGoalCard(
                      goal: goal,
                      progress: progress,
                      remaining: remaining,
                      statusColor: statusColor,
                      statusLabel:
                          _goalStatusLabel(l10n, progress, projectedLate),
                      suggestedMonthly: suggestedMonthly,
                      projectedLate: projectedLate,
                      monthsRemaining: monthsRemaining,
                      hasDeadline: hasDeadline,
                      currencyFormat: currencyFormat,
                      l10n: l10n,
                      onEdit: () =>
                          _openGoalForm(context, ref, existingGoal: goal),
                      onDelete: () => ref
                          .read(savingsGoalListProvider.notifier)
                          .deleteSavingsGoal(goal.id),
                      onAddFunds: () =>
                          _openContributionDialog(context, ref, goal),
                      onSimulate: () => _showSimulation(
                        context,
                        goal,
                        50,
                        currencyFormat,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) => AppSkeleton(
              height: index == 0 ? 148 : 190,
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

  int _calculateProjectedDelayMonths(SavingsGoal goal, DateTime now) {
    final elapsedMonths =
        (((now.difference(goal.createdAt ?? now).inDays) / 30).clamp(1, 120))
            .toDouble();
    final currentRate = goal.savedAmount / elapsedMonths;
    if (currentRate <= 0 || goal.deadline == null) return 0;

    final remaining = (goal.targetAmount - goal.savedAmount).clamp(
      0,
      double.infinity,
    );
    final neededMonths = (remaining / currentRate).ceil();
    final monthsUntilDeadline =
        ((goal.deadline!.difference(now).inDays) / 30).ceil();
    return (neededMonths - monthsUntilDeadline).clamp(0, 120);
  }

  Future<void> _allocateSurplusToTopGoal(
    WidgetRef ref,
    List<SavingsGoal> goals,
    double amount,
  ) async {
    if (goals.isEmpty) return;

    final sorted = [...goals]..sort((a, b) {
        final aRemaining = a.targetAmount - a.savedAmount;
        final bRemaining = b.targetAmount - b.savedAmount;
        return aRemaining.compareTo(bRemaining);
      });
    final target = sorted.first;
    final updated = target.copyWith(
      savedAmount: (target.savedAmount + amount).clamp(0, target.targetAmount),
    );
    await ref.read(savingsGoalListProvider.notifier).updateSavingsGoal(updated);
  }

  Future<void> _openGoalForm(
    BuildContext context,
    WidgetRef ref, {
    SavingsGoal? existingGoal,
  }) async {
    final appCurrency = ref.read(appCurrencyControllerProvider);
    final result = await showModalBottomSheet<_SavingsGoalFormResult>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SavingsGoalFormSheet(
        existingGoal: existingGoal,
        currencySymbol: CurrencyUtils.symbol(appCurrency),
      ),
    );

    if (result != null) {
      final goal = SavingsGoal(
        id: existingGoal?.id ?? const Uuid().v4(),
        title: result.title,
        targetAmount: result.targetAmount,
        savedAmount: result.savedAmount,
        deadline: result.deadline,
        priority: result.priority,
        color: existingGoal?.color,
        autoAllocate: result.autoAllocate,
        createdAt: existingGoal?.createdAt ?? DateTime.now(),
      );

      if (existingGoal == null) {
        await ref.read(savingsGoalListProvider.notifier).addSavingsGoal(goal);
      } else {
        await ref
            .read(savingsGoalListProvider.notifier)
            .updateSavingsGoal(goal);
      }
    }
  }

  Future<void> _openContributionDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final appCurrency = ref.read(appCurrencyControllerProvider);
    final currencyFormat = CurrencyUtils.getFormat(appCurrency);
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _ContributionDialog(
        goalTitle: goal.title,
        currencySymbol: CurrencyUtils.symbol(appCurrency),
      ),
    );

    if (amount != null && amount > 0 && mounted) {
      final updated = goal.copyWith(
        savedAmount: (goal.savedAmount + amount).clamp(0, goal.targetAmount),
      );
      await ref
          .read(savingsGoalListProvider.notifier)
          .updateSavingsGoal(updated);
      if (!context.mounted) return;
      AppFeedback.show(
        context,
        message: l10n.savingsProgressLine(
          ((updated.savedAmount / updated.targetAmount) * 100)
              .clamp(0, 100)
              .toStringAsFixed(1),
          currencyFormat.format(
            (updated.targetAmount - updated.savedAmount).clamp(
              0,
              double.infinity,
            ),
          ),
        ),
        type: AppFeedbackType.success,
      );
    }
  }

  void _showSimulation(
    BuildContext context,
    SavingsGoal goal,
    double monthlyIncrease,
    NumberFormat currencyFormat,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final elapsedMonths =
        (((now.difference(goal.createdAt ?? now).inDays) / 30).clamp(1, 120))
            .toDouble();
    final currentRate =
        goal.savedAmount > 0 ? goal.savedAmount / elapsedMonths : 0;
    final newRate = currentRate + monthlyIncrease;
    final remaining = (goal.targetAmount - goal.savedAmount).clamp(
      0,
      double.infinity,
    );
    final monthsToComplete = newRate > 0 ? (remaining / newRate).ceil() : null;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.savingsScenarioSimulationTitle),
        content: Text(
          monthsToComplete == null
              ? l10n.savingsUnableEstimateCompletion
              : l10n.savingsScenarioEstimate(
                  currencyFormat.format(monthlyIncrease),
                  monthsToComplete,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  String _goalStatusLabel(
    AppLocalizations l10n,
    double progress,
    int projectedLate,
  ) {
    if (progress >= 1.0) return l10n.savingsStatusCompleted;
    if (projectedLate > 0) return l10n.savingsStatusBehindSchedule;
    if (progress >= 0.6) return l10n.savingsStatusOnPace;
    return l10n.savingsStatusBuildingMomentum;
  }

  Color _goalStatusColor(double progress, int projectedLate) {
    if (progress >= 1.0) return Colors.green;
    if (projectedLate > 0) return Colors.red;
    if (progress >= 0.6) return Colors.orange;
    return Colors.blue;
  }
}

// ============================================================================
// NEW MODERN SAVINGS COMPONENTS
// ============================================================================

/// Redesigned Savings Portfolio Card with gradient background and 2x2 grid
class _SavingsPortfolioCard extends StatelessWidget {
  const _SavingsPortfolioCard({
    required this.totalTarget,
    required this.totalSaved,
    required this.atRiskGoals,
    required this.goalsCount,
    required this.decisionMessage,
    required this.colorScheme,
    required this.currencyFormat,
  });

  final double totalTarget;
  final double totalSaved;
  final int atRiskGoals;
  final int goalsCount;
  final String decisionMessage;
  final ColorScheme colorScheme;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? const Color(0xFF1E1A40) : const Color(0xFFECDDFF),
            isDark ? const Color(0xFF221540) : const Color(0xFFF1EEFF),
            isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF7F9FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.savings_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Savings Portfolio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            decisionMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          // 2x2 Metric Grid
          Row(
            children: [
              // Left column (smaller metrics)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PortfolioMetric(
                      label: 'Goals',
                      value: goalsCount.toString(),
                      isLarge: false,
                    ),
                    const SizedBox(height: 12),
                    _PortfolioMetric(
                      label: 'At Risk',
                      value: atRiskGoals.toString(),
                      isLarge: false,
                      tone: atRiskGoals > 0 ? Colors.orange : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right column (larger metrics)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PortfolioMetric(
                      label: 'Saved',
                      value: currencyFormat.format(totalSaved),
                      isLarge: true,
                    ),
                    const SizedBox(height: 12),
                    _PortfolioMetric(
                      label: 'Target',
                      value: currencyFormat.format(totalTarget),
                      isLarge: true,
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

/// Portfolio metric display widget
class _PortfolioMetric extends StatelessWidget {
  const _PortfolioMetric({
    required this.label,
    required this.value,
    required this.isLarge,
    this.tone,
  });

  final String label;
  final String value;
  final bool isLarge;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: isLarge ? 24 : 18,
                color: tone,
              ),
        ),
      ],
    );
  }
}

/// Redesigned Savings Nudge Card
class _SavingsNudgeCard extends StatelessWidget {
  const _SavingsNudgeCard({required this.nudges});

  final List<SavingsNudge> nudges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...nudges.map((nudge) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getSeverityIcon(nudge.severity),
                    size: 16,
                    color: _getSeverityColor(nudge.severity),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nudge.message,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getSeverityIcon(SavingsNudgeSeverity severity) {
    return switch (severity) {
      SavingsNudgeSeverity.critical => Icons.error_outline,
      SavingsNudgeSeverity.warning => Icons.warning_amber_outlined,
      SavingsNudgeSeverity.info => Icons.info_outline,
    };
  }

  Color _getSeverityColor(SavingsNudgeSeverity severity) {
    return switch (severity) {
      SavingsNudgeSeverity.critical => Colors.red,
      SavingsNudgeSeverity.warning => Colors.orange,
      SavingsNudgeSeverity.info => Colors.blue,
    };
  }
}

/// Surplus allocation card
class _SavingsSurplusCard extends StatelessWidget {
  const _SavingsSurplusCard({
    required this.monthlySurplus,
    required this.currencyFormat,
    required this.onAllocate50,
    required this.onAllocate100,
  });

  final double monthlySurplus;
  final NumberFormat currencyFormat;
  final VoidCallback onAllocate50;
  final VoidCallback onAllocate100;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Surplus Available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(monthlySurplus),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: Colors.green,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Allocate to your highest priority goal',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAllocate50,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Allocate 50',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onAllocate100,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Allocate 100',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Redesigned Savings Goal Card
class _SavingsGoalCard extends StatelessWidget {
  const _SavingsGoalCard({
    required this.goal,
    required this.progress,
    required this.remaining,
    required this.statusColor,
    required this.statusLabel,
    required this.suggestedMonthly,
    required this.projectedLate,
    required this.monthsRemaining,
    required this.hasDeadline,
    required this.currencyFormat,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
    required this.onAddFunds,
    required this.onSimulate,
  });

  final SavingsGoal goal;
  final double progress;
  final double remaining;
  final Color statusColor;
  final String statusLabel;
  final double suggestedMonthly;
  final int projectedLate;
  final int monthsRemaining;
  final bool hasDeadline;
  final NumberFormat currencyFormat;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddFunds;
  final VoidCallback onSimulate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Goal title, status badge, and menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.flag_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.savingsEditGoal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 10,
                color: Theme.of(context).colorScheme.surface,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                surfaceTintColor: Colors.transparent,
                position: PopupMenuPosition.under,
                icon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    )
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 10),
                        Text(l10n.savingsEditGoal),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.savingsDeleteGoal,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount row: Saved / Target
          Text(
            '${currencyFormat.format(goal.savedAmount)} / ${currencyFormat.format(goal.targetAmount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),

          // Progress text
          Text(
            '${(progress * 100).toStringAsFixed(1)}% complete • ${currencyFormat.format(remaining)} remaining',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),

          // Deadline info
          if (hasDeadline) ...[
            const SizedBox(height: 12),
            Text(
              'Deadline: ${MaterialLocalizations.of(context).formatMediumDate(goal.deadline!)} • $monthsRemaining months',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],

          const SizedBox(height: 12),

          // Quick percentage chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['25%', '50%', '75%', '100%']
                .map((percent) => _SavingsQuickPercentageChip(label: percent))
                .toList(),
          ),

          const SizedBox(height: 12),

          // Suggestion text
          Text(
            'Suggested: ${currencyFormat.format(suggestedMonthly)}/month',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),

          if (projectedLate > 0)
            Text(
              'Projected late by $projectedLate months',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAddFunds,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    l10n.savingsAddFunds,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSimulate,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Simulate',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),

          // Achieved badge
          if (goal.savedAmount >= goal.targetAmount) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.savingsGoalAchieved,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Quick percentage chip
class _SavingsQuickPercentageChip extends StatelessWidget {
  const _SavingsQuickPercentageChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ============================================================================
// FORM AND HELPER DATA STRUCTURES
// ============================================================================

class _SavingsGoalFormResult {
  const _SavingsGoalFormResult({
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.priority,
    required this.autoAllocate,
    required this.deadline,
  });

  final String title;
  final double targetAmount;
  final double savedAmount;
  final GoalPriority priority;
  final bool autoAllocate;
  final DateTime? deadline;
}

class _SavingsGoalFormSheet extends StatefulWidget {
  const _SavingsGoalFormSheet({
    this.existingGoal,
    required this.currencySymbol,
  });

  final SavingsGoal? existingGoal;
  final String currencySymbol;

  @override
  State<_SavingsGoalFormSheet> createState() => _SavingsGoalFormSheetState();
}

class _SavingsGoalFormSheetState extends State<_SavingsGoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late final TextEditingController _savedController;
  late GoalPriority _priority;
  late bool _autoAllocate;
  late DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingGoal?.title ?? '',
    );
    _targetController = TextEditingController(
      text: widget.existingGoal?.targetAmount.toStringAsFixed(2) ?? '',
    );
    _savedController = TextEditingController(
      text: widget.existingGoal?.savedAmount.toStringAsFixed(2) ?? '0',
    );
    _priority = widget.existingGoal?.priority ?? GoalPriority.medium;
    _autoAllocate = widget.existingGoal?.autoAllocate ?? false;
    _deadline = widget.existingGoal?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (!mounted || picked == null) return;
    setState(() => _deadline = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final targetAmount = double.parse(_targetController.text.trim());
    final savedAmount =
        double.parse(_savedController.text.trim()).clamp(0.0, targetAmount);
    Navigator.of(context).pop(
      _SavingsGoalFormResult(
        title: _titleController.text.trim(),
        targetAmount: targetAmount,
        savedAmount: savedAmount,
        priority: _priority,
        autoAllocate: _autoAllocate,
        deadline: _deadline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final baseTheme = Theme.of(context);
    final modalBackgroundColor = baseTheme.brightness == Brightness.dark
        ? baseTheme.colorScheme.surfaceContainerHigh
        : baseTheme.colorScheme.surface;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: modalBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: baseTheme.colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      color: baseTheme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.existingGoal == null
                                ? l10n.savingsCreateGoal
                                : l10n.savingsEditGoal,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  style: InputStyles.inputTextStyle(baseTheme),
                  decoration: InputDecoration(labelText: l10n.savingsGoalName),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.savingsEnterGoalName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: InputStyles.fieldSpacing),
                TextFormField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: InputStyles.inputTextStyle(baseTheme),
                  decoration: InputDecoration(
                    labelText: l10n.savingsTargetAmount,
                    prefixText: '${widget.currencySymbol} ',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return l10n.savingsEnterValidTargetAmount;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: InputStyles.fieldSpacing),
                TextFormField(
                  controller: _savedController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: InputStyles.inputTextStyle(baseTheme),
                  decoration: InputDecoration(
                    labelText: l10n.savingsCurrentSavedAmount,
                    prefixText: '${widget.currencySymbol} ',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed < 0) {
                      return l10n.savingsEnterValidSavedAmount;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: InputStyles.fieldSpacing),
                DropdownButtonFormField<GoalPriority>(
                  initialValue: _priority,
                  icon: InputStyles.dropdownIcon(context),
                  decoration: InputDecoration(
                    labelText: l10n.savingsPriority,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  items: GoalPriority.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            switch (p) {
                              GoalPriority.low =>
                                l10n.subscriptionsFilterLowPriority,
                              GoalPriority.medium =>
                                l10n.subscriptionsImportanceMedium,
                              GoalPriority.high =>
                                l10n.subscriptionsFilterHighPriority,
                              GoalPriority.critical =>
                                l10n.subscriptionsFilterCritical,
                            },
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _priority = value);
                  },
                ),
                const SizedBox(height: InputStyles.fieldSpacing),
                SwitchListTile.adaptive(
                  value: _autoAllocate,
                  title: Text(l10n.savingsEnableAutoAllocation),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) => setState(() => _autoAllocate = value),
                ),
                const SizedBox(height: InputStyles.fieldSpacing),
                FormDateField(
                  label: l10n.savingsDeadlineOptional,
                  value: _deadline == null
                      ? l10n.savingsNoDeadline
                      : MaterialLocalizations.of(context)
                          .formatMediumDate(_deadline!),
                  trailing: _deadline == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _deadline = null),
                        ),
                  onTap: _pickDeadline,
                ),
                const SizedBox(height: InputStyles.fieldSpacing),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: Icon(
                    widget.existingGoal == null
                        ? Icons.add_rounded
                        : Icons.edit_rounded,
                  ),
                  label: Text(
                    widget.existingGoal == null
                        ? l10n.savingsSaveGoal
                        : l10n.savingsUpdateGoal,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContributionDialog extends StatefulWidget {
  const _ContributionDialog({
    required this.goalTitle,
    required this.currencySymbol,
  });

  final String goalTitle;
  final String currencySymbol;

  @override
  State<_ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends State<_ContributionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim()) ?? 0;
    Navigator.of(context).pop(value > 0 ? value : null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.savingsAddToGoal(widget.goalTitle)),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: InputStyles.inputTextStyle(Theme.of(context)),
        decoration: InputDecoration(
          labelText: l10n.amount,
          prefixText: '${widget.currencySymbol} ',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.commonAdd),
        ),
      ],
    );
  }
}
