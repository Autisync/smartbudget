import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/data/models/tables.dart'
    show TransactionType, TransactionRecurrence;
import 'package:smartbudget/core/theme/input_styles.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/widgets/form_date_field.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:smartbudget/core/widgets/branded_title.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final amountFormat = CurrencyUtils.getFormat(appCurrency);
    final recurrenceLabel = _recurrenceLabel(l10n, _recurrence);
    final typeColor = _type == TransactionType.expense
        ? colorScheme.error
        : colorScheme.primary;
    final typeIcon = _type == TransactionType.expense
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

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
          child: BrandedTitle(
            label: widget.existingTransaction != null
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(typeIcon, color: typeColor, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              amount > 0
                                  ? amountFormat.format(amount)
                                  : '${CurrencyUtils.symbol(appCurrency)} 0.00',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _type == TransactionType.expense
                                  ? l10n.expense
                                  : l10n.income,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: typeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(_category),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(recurrenceLabel),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(
                              MaterialLocalizations.of(context)
                                  .formatMediumDate(_date),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: InputStyles.fieldSpacing),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: InputStyles.inputTextStyle(Theme.of(context)),
                  decoration: InputDecoration(
                    labelText: l10n.amount,
                    prefixText: '${CurrencyUtils.symbol(appCurrency)} ',
                    hintText: '0.00',
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
                const SizedBox(height: InputStyles.fieldSpacing),

                // Category
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  icon: InputStyles.dropdownIcon(context),
                  decoration: InputDecoration(
                    labelText: l10n.category,
                    prefixIcon: const Icon(Icons.category),
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
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: InputStyles.fieldSpacing),

                // Date
                FormDateField(
                  label: l10n.date,
                  value:
                      MaterialLocalizations.of(context).formatFullDate(_date),
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
                const SizedBox(height: InputStyles.fieldSpacing),

                // Note
                TextFormField(
                  controller: _noteController,
                  style: InputStyles.inputTextStyle(Theme.of(context)),
                  decoration: InputDecoration(
                    labelText: l10n.transactionsNoteOptional,
                    prefixIcon: const Icon(Icons.edit),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: InputStyles.fieldSpacing),

                // Recurrence
                DropdownButtonFormField<TransactionRecurrence>(
                  initialValue: _recurrence,
                  icon: InputStyles.dropdownIcon(context),
                  decoration: InputDecoration(
                    labelText: l10n.transactionsRecurrence,
                    prefixIcon: const Icon(Icons.repeat),
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
                const SizedBox(height: InputStyles.fieldSpacing),

                // Save Button
                FilledButton.icon(
                  onPressed: _saveTransaction,
                  icon: Icon(
                    widget.existingTransaction != null
                        ? Icons.check_rounded
                        : Icons.add_rounded,
                  ),
                  label: Text(
                    widget.existingTransaction != null
                        ? l10n.transactionsUpdateTransaction
                        : l10n.transactionsSaveTransaction,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

  String _recurrenceLabel(
    AppLocalizations l10n,
    TransactionRecurrence recurrence,
  ) {
    return switch (recurrence) {
      TransactionRecurrence.none => l10n.transactionsRecurrenceNone,
      TransactionRecurrence.daily => l10n.transactionsRecurrenceDaily,
      TransactionRecurrence.weekly => l10n.transactionsRecurrenceWeekly,
      TransactionRecurrence.monthly => l10n.transactionsRecurrenceMonthly,
      TransactionRecurrence.yearly => l10n.transactionsRecurrenceYearly,
    };
  }
}
