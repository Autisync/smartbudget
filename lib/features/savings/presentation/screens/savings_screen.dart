import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/features/savings/presentation/providers/savings_provider.dart';
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/data/models/tables.dart' show GoalPriority;
import 'package:smartbudget/data/models/tables.dart' show TransactionType;
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
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
    final savingsAsync = ref.watch(savingsGoalListProvider);
    final nudgesAsync = ref.watch(savingsNudgesProvider);
    final monthlyTransactionsAsync = ref.watch(recentTransactionsProvider);
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final currencyFormat = CurrencyUtils.getFormat(appCurrency);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
          child: const Text('Savings Goals'),
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
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        size: 52,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Create your first savings goal',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Define a target amount and optional deadline to build savings intentionally.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _openGoalForm(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Goal'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final nudgesCount = nudgesAsync.maybeWhen(
              data: (nudges) => nudges.length,
              orElse: () => 0,
            );
            final decisionMessage = atRiskGoals > 0
                ? '$atRiskGoals goal${atRiskGoals == 1 ? '' : 's'} are behind pace. Focus new contributions there first.'
                : monthlySurplus > 0
                    ? 'You have ${currencyFormat.format(monthlySurplus)} of monthly surplus available to accelerate your top priority goal.'
                    : 'Progress is steady. Keep contributions consistent to protect your deadlines.';

            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tips_and_updates_outlined,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Savings portfolio',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          decisionMessage,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SavingsSummaryMetric(
                              label: 'Goals',
                              value: '${goals.length}',
                            ),
                            _SavingsSummaryMetric(
                              label: 'Saved',
                              value: currencyFormat.format(totalSaved),
                            ),
                            _SavingsSummaryMetric(
                              label: 'At Risk',
                              value: '$atRiskGoals',
                              valueColor: atRiskGoals > 0
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            _SavingsSummaryMetric(
                              label: 'Target',
                              value: currencyFormat.format(totalTarget),
                            ),
                            _SavingsSummaryMetric(
                              label: 'Nudges',
                              value: '$nudgesCount',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                nudgesAsync.when(
                  data: (nudges) {
                    if (nudges.isEmpty) return const SizedBox.shrink();
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Savings nudges',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            ...nudges.take(3).map(
                                  (n) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          n.severity ==
                                                  SavingsNudgeSeverity.critical
                                              ? Icons.error_outline
                                              : n.severity ==
                                                      SavingsNudgeSeverity
                                                          .warning
                                                  ? Icons.warning_amber_outlined
                                                  : Icons.info_outline,
                                          size: 18,
                                          color: n.severity ==
                                                  SavingsNudgeSeverity.critical
                                              ? Colors.red
                                              : n.severity ==
                                                      SavingsNudgeSeverity
                                                          .warning
                                                  ? Colors.orange
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            n.message,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                if (monthlySurplus > 0)
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Surplus detected: ${currencyFormat.format(monthlySurplus)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Allocate part of this surplus to accelerate your goals.',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ActionChip(
                                label: const Text('Allocate \$50'),
                                onPressed: () => _allocateSurplusToTopGoal(
                                  ref,
                                  goals,
                                  50,
                                ),
                              ),
                              ActionChip(
                                label: const Text('Allocate \$100'),
                                onPressed: () => _allocateSurplusToTopGoal(
                                  ref,
                                  goals,
                                  100,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ...goals.map((goal) {
                  final progress = goal.targetAmount > 0
                      ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
                      : 0.0;
                  final remaining =
                      (goal.targetAmount - goal.savedAmount).clamp(
                    0,
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

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  goal.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openGoalForm(context, ref,
                                        existingGoal: goal);
                                  } else if (value == 'delete') {
                                    ref
                                        .read(savingsGoalListProvider.notifier)
                                        .deleteSavingsGoal(goal.id);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit goal'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete goal'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _SavingsStatusChip(
                                label:
                                    _goalStatusLabel(progress, projectedLate),
                                color:
                                    _goalStatusColor(progress, projectedLate),
                              ),
                              const SizedBox(width: 8),
                              if (hasDeadline)
                                Text(
                                  'Timeline tracked',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${currencyFormat.format(goal.savedAmount)} / ${currencyFormat.format(goal.targetAmount)}',
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 6),
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}% complete • ${currencyFormat.format(remaining)} remaining',
                          ),
                          if (hasDeadline) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Deadline: ${MaterialLocalizations.of(context).formatMediumDate(goal.deadline!)}',
                            ),
                            _GoalTimeline(
                              createdAt: goal.createdAt ?? now,
                              deadline: goal.deadline!,
                              progress: progress,
                            ),
                          ],
                          const SizedBox(height: 6),
                          const Wrap(
                            spacing: 6,
                            children: [
                              Chip(label: Text('25%')),
                              Chip(label: Text('50%')),
                              Chip(label: Text('75%')),
                              Chip(label: Text('100%')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Suggestion: Save ${currencyFormat.format(suggestedMonthly)}/month to stay on track.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (projectedLate > 0)
                            Text(
                              'At current pace, this goal may finish about $projectedLate month(s) late.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ActionChip(
                                label: const Text('Add funds'),
                                onPressed: () =>
                                    _openContributionDialog(context, ref, goal),
                              ),
                              ActionChip(
                                label: const Text('Simulate +\$50/mo'),
                                onPressed: () => _showSimulation(
                                  context,
                                  goal,
                                  50,
                                  currencyFormat,
                                ),
                              ),
                            ],
                          ),
                          if (goal.savedAmount >= goal.targetAmount)
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Goal achieved! Archive it or create a new one to keep momentum.',
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error: $err')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openGoalForm(context, ref),
        child: const Icon(Icons.add),
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
    final result = await showModalBottomSheet<_SavingsGoalFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      builder: (_) => _SavingsGoalFormSheet(existingGoal: existingGoal),
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
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _ContributionDialog(goalTitle: goal.title),
    );

    if (amount != null && amount > 0 && mounted) {
      final updated = goal.copyWith(
        savedAmount: (goal.savedAmount + amount).clamp(0, goal.targetAmount),
      );
      await ref
          .read(savingsGoalListProvider.notifier)
          .updateSavingsGoal(updated);
    }
  }

  void _showSimulation(
    BuildContext context,
    SavingsGoal goal,
    double monthlyIncrease,
    NumberFormat currencyFormat,
  ) {
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
        title: const Text('Scenario simulation'),
        content: Text(
          monthsToComplete == null
              ? 'Unable to estimate completion date with current data.'
              : 'If you increase savings by ${currencyFormat.format(monthlyIncrease)}/month, you could complete this goal in about $monthsToComplete month(s).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _goalStatusLabel(double progress, int projectedLate) {
    if (progress >= 1.0) return 'Completed';
    if (projectedLate > 0) return 'Behind schedule';
    if (progress >= 0.6) return 'On pace';
    return 'Building momentum';
  }

  Color _goalStatusColor(double progress, int projectedLate) {
    if (progress >= 1.0) return Colors.green;
    if (projectedLate > 0) return Colors.red;
    if (progress >= 0.6) return Colors.orange;
    return Colors.blue;
  }
}

class _GoalTimeline extends StatelessWidget {
  const _GoalTimeline({
    required this.createdAt,
    required this.deadline,
    required this.progress,
  });

  final DateTime createdAt;
  final DateTime deadline;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final total = deadline.difference(createdAt).inDays;
    final elapsed = DateTime.now().difference(createdAt).inDays;
    final timeProgress = total <= 0 ? 1.0 : (elapsed / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        LinearProgressIndicator(value: timeProgress),
        const SizedBox(height: 4),
        Text(
          'Time progress ${(timeProgress * 100).toStringAsFixed(0)}% • Savings progress ${(progress * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SavingsSummaryMetric extends StatelessWidget {
  const _SavingsSummaryMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _SavingsStatusChip extends StatelessWidget {
  const _SavingsStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

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
  const _SavingsGoalFormSheet({this.existingGoal});

  final SavingsGoal? existingGoal;

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
    final baseTheme = Theme.of(context);
    final modalBackgroundColor = baseTheme.brightness == Brightness.dark
        ? baseTheme.colorScheme.surfaceContainerHigh
        : baseTheme.colorScheme.surfaceContainerHigh;
    final inputFillColor = baseTheme.brightness == Brightness.dark
        ? baseTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.95);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Theme(
        data: baseTheme.copyWith(
          inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
            filled: true,
            fillColor: inputFillColor,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: modalBackgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingGoal == null ? 'Create goal' : 'Edit goal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Goal name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a goal name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Target amount',
                    prefixText: r'$',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid target amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _savedController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Current saved amount',
                    prefixText: r'$',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed < 0) {
                      return 'Enter a valid saved amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<GoalPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: GoalPriority.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name[0].toUpperCase()}${p.name.substring(1)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _priority = value);
                  },
                ),
                SwitchListTile.adaptive(
                  value: _autoAllocate,
                  title: const Text('Enable auto-allocation'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) => setState(() => _autoAllocate = value),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('Deadline (optional)'),
                  subtitle: Text(
                    _deadline == null
                        ? 'No deadline'
                        : MaterialLocalizations.of(context)
                            .formatMediumDate(_deadline!),
                  ),
                  trailing: _deadline == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _deadline = null),
                        ),
                  onTap: _pickDeadline,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submit,
                  child: Text(
                    widget.existingGoal == null ? 'Save goal' : 'Update goal',
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
  const _ContributionDialog({required this.goalTitle});

  final String goalTitle;

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
    return AlertDialog(
      title: Text('Add to ${widget.goalTitle}'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Amount',
          prefixText: r'$',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
