import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/components/forms/form_components.dart';
import 'package:smartbudget/components/sheets/app_sheet_container.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/domain/entities/account.dart';
import 'package:smartbudget/data/models/tables.dart'
    show TransactionType, TransactionRecurrence;
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/features/accounts/presentation/providers/account_provider.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/core/utils/money_utils.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? existingTransaction;
  final bool asModal;

  const AddTransactionScreen({
    super.key,
    this.existingTransaction,
    this.asModal = false,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isAppBarScrolled = false;
  bool _saving = false;

  TransactionType _type = TransactionType.expense;
  String _category = 'Food';
  DateTime _date = DateTime.now();
  TransactionRecurrence _recurrence = TransactionRecurrence.none;
  // Selected money source (account id). Defaults to Cash; preselected from the
  // existing transaction when editing. Resolved against the accounts list.
  String? _accountId;

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
      _accountId = tx.accountId;
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
    if (widget.asModal) {
      Navigator.of(context).pop();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (GoRouter.of(context).canPop()) {
        context.pop();
        return;
      }
      context.go('/transactions');
    });
  }

  /// Real money-source picker backed by the accounts table. Lets the user
  /// choose how money came in / went out (Cash, Bank Transfer, Credit Card, or
  /// any custom account). Persisted to the transaction's accountId.
  Widget _buildAccountPicker() {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(accountsListProvider);
    return accountsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (accounts) {
        if (accounts.isEmpty) return const SizedBox.shrink();
        // Default to Cash (or the first account) when nothing is selected, and
        // recover gracefully if a previously-selected account was removed.
        final ids = accounts.map((a) => a.id).toSet();
        final selected = (_accountId != null && ids.contains(_accountId))
            ? _accountId
            : (ids.contains(DefaultAccountIds.cash)
                ? DefaultAccountIds.cash
                : accounts.first.id);
        if (selected != _accountId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _accountId = selected);
          });
        }
        return ModernSelect<String>(
          value: selected!,
          label: l10n.commonAccount,
          prefixIcon: Icons.account_balance_wallet_rounded,
          items: accounts
              .map(
                (a) => DropdownMenuItem(
                  value: a.id,
                  child: Text(a.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _accountId = value);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final budgetCategories = ref.watch(activeBudgetsProvider).maybeWhen(
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
    final typeColor = _type == TransactionType.expense
        ? colorScheme.error
        : colorScheme.primary;
    final typeIcon = _type == TransactionType.expense
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    final formFields = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    color: typeColor.withOpacity( 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.existingTransaction != null
                            ? l10n.transactionsUpdateTransaction
                            : l10n.addTransaction,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amount > 0
                            ? amountFormat.format(amount)
                            : '${CurrencyUtils.symbol(appCurrency)} 0.00',
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
          const SizedBox(height: 16),
          CurrencyInput(
            controller: _amountController,
            label: l10n.amount,
            currencySymbol: CurrencyUtils.symbol(appCurrency),
            helperText: 'Use amount with decimals, e.g. 1,250.75',
            decimalDigits: MoneyUtils.decimalDigits(appCurrency),
            validator: (value) => FormValidation.positiveAmount(
              value,
              l10n.transactionsEnterAmount,
              l10n.transactionsInvalidNumber,
            ),
          ),
          const SizedBox(height: 16),
          ModernSelect<String>(
            value: _category,
            label: l10n.category,
            helperText: 'Assign the transaction to a budget category',
            prefixIcon: Icons.category_rounded,
            items: categories.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 16),
          ModernDatePicker(
            label: l10n.date,
            value: MaterialLocalizations.of(context).formatFullDate(_date),
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
          ModernSelect<TransactionRecurrence>(
            value: _recurrence,
            label: l10n.transactionsRecurrence,
            prefixIcon: Icons.repeat_rounded,
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
          _buildAccountPicker(),
          const SizedBox(height: 16),
          ModernInput(
            controller: _noteController,
            label: l10n.transactionsNoteOptional,
            helperText: 'Optional context for categorization and insights',
            prefixIcon: Icons.edit_note_rounded,
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );

    final formBody = AppSheetContainer(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 108),
        child: formFields,
      ),
    );

    if (widget.asModal) {
      return AppFormSheet(
        onClose: _closeScreen,
        maxHeightFactor: 0.78,
        body: formFields,
        actions: FilledButton.icon(
          onPressed: _saving ? null : _saveTransaction,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  widget.existingTransaction != null
                      ? Icons.edit_rounded
                      : Icons.add_rounded,
                ),
          label: Text(
            widget.existingTransaction != null
                ? l10n.transactionsUpdateTransaction
                : l10n.transactionsSaveTransaction,
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      );
    }

    return AppScaffold(
      appBar: widget.asModal
          ? null
          : AppBar(
              title: buildFrostedAppBarTitle(
                context: context,
                title: widget.existingTransaction != null
                    ? l10n.transactionsUpdateTransaction
                    : l10n.addTransaction,
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
                onKey: 'tx-form-appbar-blur-on',
                offKey: 'tx-form-appbar-blur-off',
              ),
              leading: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor:
                      colorScheme.surfaceContainerHighest.withOpacity( _isAppBarScrolled ? 0.9 : 0,
                  ),
                ),
                icon: const Icon(Icons.close),
                onPressed: _closeScreen,
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
        child: formBody,
      ),
      bottomNavigationBar: widget.asModal
          ? null
          : AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveTransaction,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            widget.existingTransaction != null
                                ? Icons.edit_rounded
                                : Icons.add_rounded,
                          ),
                    label: Text(
                      widget.existingTransaction != null
                          ? l10n.transactionsUpdateTransaction
                          : l10n.transactionsSaveTransaction,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = FormValidation.parseDecimal(_amountController.text) ?? 0;
    if (amount <= 0) {
      AppFeedbackService.showWarning(
        context,
        'Please enter a valid amount.',
      );
      return;
    }

    setState(() => _saving = true);
    AppFeedbackService.showLoading(
      context,
      widget.existingTransaction != null
          ? 'Updating transaction...'
          : 'Saving transaction...',
    );

    final appCurrency = ref.read(appCurrencyControllerProvider);
    final transaction = Transaction(
      id: widget.existingTransaction?.id ?? const Uuid().v4(),
      accountId: _accountId ??
          widget.existingTransaction?.accountId ??
          DefaultAccountIds.cash,
      amount: amount,
      currency: appCurrency,
      type: _type,
      category: _category,
      date: _date,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      recurrence: _recurrence,
      isSynced: widget.existingTransaction?.isSynced ?? false,
    );

    try {
      final repo = ref.read(transactionListProvider().notifier);
      if (widget.existingTransaction != null) {
        await repo.updateTransaction(transaction);
      } else {
        await repo.addTransaction(transaction);
      }

      if (!mounted) return;
      AppFeedbackService.dismissLoading();
      AppFeedbackService.showSuccess(
        context,
        widget.existingTransaction != null
            ? 'Transaction updated successfully.'
            : 'Transaction added successfully.',
      );
      _closeScreen();
    } catch (_) {
      if (!mounted) return;
      AppFeedbackService.dismissLoading();
      AppFeedbackService.showError(
        context,
        'Failed to save transaction. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
