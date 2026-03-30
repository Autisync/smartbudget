import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/data/models/tables.dart'
    show TransactionType, TransactionRecurrence;
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isAppBarScrolled = false;

  TransactionType _type = TransactionType.expense;
  String _category = 'Food';
  DateTime _date = DateTime.now();
  TransactionRecurrence _recurrence = TransactionRecurrence.none;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;
    if (tx != null) {
      _type = tx.type;
      _category = tx.category;
      _date = tx.date;
      _recurrence = tx.recurrence;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';
    }
  }

  static const List<String> _defaultCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Health',
    'Education',
    'Salary',
    'Investment',
  ];

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  void _closeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (GoRouter.of(context).canPop()) {
        context.pop();
        return;
      }
      context.go('/transactions');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final budgetCategories = ref.watch(budgetListProvider).maybeWhen(
          data: (budgets) => budgets
              .map((budget) => budget.category.trim())
              .where((category) => category.isNotEmpty)
              .toList(),
          orElse: () => const <String>[],
        );

    final categories = <String>[];
    final seen = <String>{};
    void addCategory(String category) {
      final normalized = category.toLowerCase();
      if (seen.add(normalized)) {
        categories.add(category);
      }
    }

    for (final category in _defaultCategories) {
      addCategory(category);
    }
    for (final category in budgetCategories) {
      addCategory(category);
    }
    if (_category.trim().isNotEmpty) {
      addCategory(_category.trim());
    }

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
          child: Text(
            widget.existingTransaction != null
                ? l10n.transactionsUpdateTransaction
                : l10n.addTransaction,
          ),
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
                      key: const ValueKey('tx-form-appbar-blur-on'),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.08),
                        ),
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('tx-form-appbar-blur-off'),
                    ),
            ),
          ],
        ),
        leading: IconButton(
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: _isAppBarScrolled ? 0.9 : 0,
            ),
          ),
          icon: const Icon(Icons.close),
          onPressed: _closeScreen,
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _updateAppBarScrollState(notification.metrics.pixels);
          }
          return false;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type Selector
                SegmentedButton<TransactionType>(
                  segments: [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text(l10n.expense),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text(l10n.income),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (set) {
                    setState(() => _type = set.first);
                  },
                ),
                const SizedBox(height: 24),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _type == TransactionType.expense
                            ? Colors.redAccent
                            : Colors.greenAccent,
                      ),
                  decoration: InputDecoration(
                    prefixText: '${CurrencyUtils.symbol(appCurrency)} ',
                    hintText: '0.00',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.transactionsEnterAmount;
                    }
                    if (double.tryParse(value) == null) {
                      return l10n.transactionsInvalidNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Category
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: l10n.category,
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 16),

                // Date
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(l10n.date),
                  subtitle: Text(
                    MaterialLocalizations.of(context).formatFullDate(_date),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                const SizedBox(height: 16),

                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.transactionsNoteOptional,
                    prefixIcon: const Icon(Icons.edit),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Recurrence
                DropdownButtonFormField<TransactionRecurrence>(
                  initialValue: _recurrence,
                  decoration: InputDecoration(
                    labelText: l10n.transactionsRecurrence,
                    prefixIcon: const Icon(Icons.repeat),
                  ),
                  items: TransactionRecurrence.values
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              switch (r) {
                                TransactionRecurrence.none =>
                                  l10n.transactionsRecurrenceNone,
                                TransactionRecurrence.daily =>
                                  l10n.transactionsRecurrenceDaily,
                                TransactionRecurrence.weekly =>
                                  l10n.transactionsRecurrenceWeekly,
                                TransactionRecurrence.monthly =>
                                  l10n.transactionsRecurrenceMonthly,
                                TransactionRecurrence.yearly =>
                                  l10n.transactionsRecurrenceYearly,
                              },
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _recurrence = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Save Button
                FilledButton(
                  onPressed: _saveTransaction,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.existingTransaction != null
                        ? l10n.transactionsUpdateTransaction
                        : l10n.transactionsSaveTransaction,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final appCurrency = ref.read(appCurrencyControllerProvider);
    final transaction = Transaction(
      id: widget.existingTransaction?.id ?? const Uuid().v4(),
      accountId: widget.existingTransaction?.accountId ?? 'default',
      amount: amount,
      currency: appCurrency,
      type: _type,
      category: _category,
      date: _date,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      recurrence: _recurrence,
      isSynced: widget.existingTransaction?.isSynced ?? false,
    );

    final repo = ref.read(transactionListProvider().notifier);
    if (widget.existingTransaction != null) {
      await repo.updateTransaction(transaction);
    } else {
      await repo.addTransaction(transaction);
    }

    if (mounted) {
      _closeScreen();
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transactionsSaved)),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
