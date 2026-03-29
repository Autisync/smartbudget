import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_alerts_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/domain/entities/budget.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final policy = await ref.read(rolloverPolicyServiceProvider).loadPolicy();
      if (!policy.autoRolloverEnabled || !mounted) return;
      await ref.read(budgetListProvider.notifier).rolloverExpiredBudgets(
            rolloverDay: policy.rolloverDay,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetListProvider);
    final alertsAsync = ref.watch(budgetAlertsProvider);
    final currencyFormat = NumberFormat.currency(symbol: r'$');
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
          child: const Text('Budgets'),
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
                      key: const ValueKey('budget-appbar-blur-on'),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.08),
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('budget-appbar-blur-off')),
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
        child: budgetsAsync.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        size: 52,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Set your first monthly budget',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create category budgets to track spending in real-time and avoid overspending.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _openBudgetForm(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Budget'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final totalLimit = budgets.fold<double>(
              0.0,
              (sum, budget) => sum + budget.limitAmount,
            );
            final riskCount = alertsAsync.maybeWhen(
              data: (alerts) => alerts.length,
              orElse: () => 0,
            );

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
                        Text(
                          'Budget portfolio',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryMetric(
                                label: 'Categories',
                                value: '${budgets.length}',
                              ),
                            ),
                            Expanded(
                              child: _SummaryMetric(
                                label: 'Total limit',
                                value: currencyFormat.format(totalLimit),
                              ),
                            ),
                            Expanded(
                              child: _SummaryMetric(
                                label: 'At risk',
                                value: '$riskCount',
                                valueColor: riskCount > 0
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Chip(label: Text('Green <70%')),
                            Chip(label: Text('Yellow 70-90%')),
                            Chip(label: Text('Red >90%')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _runManualRollover,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Rollover now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ...budgets.map((budget) {
                  final endDate = budget.endDate ?? DateTime.now();
                  final now = DateTime.now();
                  final spentAsync = ref.watch(budgetSpendingProvider(
                    category: budget.category,
                    start: budget.startDate,
                    end: endDate,
                  ));
                  final categoryTxAsync = ref.watch(transactionListProvider(
                    startDate: budget.startDate,
                    endDate: endDate,
                    category: budget.category,
                  ));

                  return Dismissible(
                    key: ValueKey('budget-${budget.id}'),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Row(
                        children: [
                          Icon(Icons.swipe_right_alt, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Swipe right: +10% budget'),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Swipe left: -10% budget'),
                          SizedBox(width: 8),
                          Icon(Icons.swipe_left_alt, color: Colors.orange),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      final increase = direction == DismissDirection.startToEnd;
                      await _quickAdjustBudget(
                          ref, budget, increase ? 1.1 : 0.9);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              increase
                                  ? '${budget.category} budget increased by 10%'
                                  : '${budget.category} budget reduced by 10%',
                            ),
                          ),
                        );
                      }
                      return false;
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        budget.category,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_periodLabel(budget.period)} cycle • Alert ${budget.alertThreshold}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await _openBudgetForm(
                                        context,
                                        ref,
                                        existingBudget: budget,
                                      );
                                    } else if (value == 'delete') {
                                      await ref
                                          .read(budgetListProvider.notifier)
                                          .deleteBudget(budget.id);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit budget'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete budget'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Limit ${currencyFormat.format(budget.limitAmount)}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            spentAsync.when(
                              data: (spent) {
                                final usage = budget.limitAmount > 0
                                    ? (spent / budget.limitAmount)
                                    : 0.0;
                                final progress = usage.clamp(0.0, 1.0);
                                final remaining = budget.limitAmount - spent;
                                final usagePercentage = usage * 100;
                                final daysLeft = endDate
                                    .difference(
                                        DateTime(now.year, now.month, now.day))
                                    .inDays;
                                final paceDailySpend =
                                    now.difference(budget.startDate).inDays <= 0
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
                                    (paceDailySpend * daysLeft.clamp(0, 365));
                                final projectedOverrun =
                                    projectedSpend - budget.limitAmount;

                                final statusColor = usagePercentage < 70
                                    ? Colors.green
                                    : usagePercentage < 90
                                        ? Colors.orange
                                        : Colors.red;

                                final status = usagePercentage < 70
                                    ? 'On track'
                                    : usagePercentage < 90
                                        ? 'Soft warning'
                                        : usagePercentage < 100
                                            ? 'High alert'
                                            : 'Exceeded';

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _StatusChip(
                                            label: status, color: statusColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          daysLeft < 0
                                              ? 'Period ended'
                                              : '$daysLeft days left',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () {
                                        _showOverspendTransactions(
                                          context,
                                          budget,
                                          categoryTxAsync.valueOrNull ??
                                              const [],
                                          currencyFormat,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          LinearProgressIndicator(
                                            value: progress,
                                            color: statusColor,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            minHeight: 8,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${currencyFormat.format(spent)} spent • ${currencyFormat.format(remaining)} remaining • ${usagePercentage.toStringAsFixed(1)}% used',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                          Text(
                                            'Tap bar to view transactions in this category',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (projectedOverrun > 0 && daysLeft > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'At this pace, you may exceed this budget by ${currencyFormat.format(projectedOverrun)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        ActionChip(
                                          label: const Text('+10%'),
                                          onPressed: () => _quickAdjustBudget(
                                            ref,
                                            budget,
                                            1.1,
                                          ),
                                        ),
                                        ActionChip(
                                          label: const Text('-10%'),
                                          onPressed: () => _quickAdjustBudget(
                                            ref,
                                            budget,
                                            0.9,
                                          ),
                                        ),
                                        ActionChip(
                                          label: const Text('Adjust amount'),
                                          onPressed: () => _openBudgetForm(
                                            context,
                                            ref,
                                            existingBudget: budget,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (err, st) =>
                                  const Text('Error loading progress'),
                            ),
                          ],
                        ),
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
        onPressed: () => _openBudgetForm(context, ref),
        child: const Icon(Icons.add),
      ),
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

  Future<void> _runManualRollover() async {
    final policy = await ref.read(rolloverPolicyServiceProvider).loadPolicy();
    await ref.read(budgetListProvider.notifier).rolloverExpiredBudgets(
          rolloverDay: policy.rolloverDay,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget rollover check complete.')),
    );
  }

  Future<void> _openBudgetForm(
    BuildContext context,
    WidgetRef ref, {
    Budget? existingBudget,
  }) async {
    final result = await showModalBottomSheet<_BudgetFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      builder: (_) => _BudgetFormSheet(existingBudget: existingBudget),
    );

    if (result != null) {
      final endDate = _calculateEndDate(result.startDate, result.period);
      final budget = Budget(
        id: existingBudget?.id ?? const Uuid().v4(),
        category: result.category,
        limitAmount: result.limitAmount,
        currency: 'USD',
        period: result.period,
        startDate: result.startDate,
        endDate: endDate,
        alertThreshold: result.alertThreshold,
        isActive: existingBudget?.isActive ?? true,
      );

      if (existingBudget == null) {
        await ref.read(budgetListProvider.notifier).addBudget(budget);
      } else {
        await ref.read(budgetListProvider.notifier).updateBudget(budget);
      }
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

  String _periodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }

  void _showOverspendTransactions(
    BuildContext context,
    Budget budget,
    List<Transaction> transactions,
    NumberFormat currencyFormat,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        if (transactions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No transactions found for this budget category yet.'),
          );
        }

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                '${budget.category} transactions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...transactions.map(
                (tx) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(tx.note ?? tx.category),
                  subtitle: Text(
                    MaterialLocalizations.of(context).formatMediumDate(tx.date),
                  ),
                  trailing: Text(currencyFormat.format(tx.amount)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

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
  const _BudgetFormSheet({this.existingBudget});

  final Budget? existingBudget;

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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final parsedAmount = double.parse(_amountController.text.trim());
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
                  widget.existingBudget == null
                      ? 'Create budget'
                      : 'Edit budget',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'Food, Transport, Bills...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Budget amount',
                    prefixText: r'$',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<BudgetPeriod>(
                  initialValue: _period,
                  decoration: const InputDecoration(labelText: 'Period'),
                  items: BudgetPeriod.values
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
                    setState(() => _period = value);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Alert at $_alertThreshold%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Slider(
                  value: _alertThreshold.toDouble(),
                  min: 60,
                  max: 95,
                  divisions: 7,
                  label: '$_alertThreshold%',
                  onChanged: (value) {
                    setState(() => _alertThreshold = value.round());
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Start date'),
                  subtitle: Text(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(_startDate),
                  ),
                  onTap: _pickStartDate,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submit,
                  child: Text(
                    widget.existingBudget == null
                        ? 'Save budget'
                        : 'Update budget',
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
