import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/widgets/branded_title.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/data/models/tables.dart'
    show TransactionType, TransactionRecurrence;
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

enum _TransactionFilter {
  income,
  spent,
  recurring,
}

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  _TransactionFilter? _activeFilter;

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    switch (_activeFilter) {
      case _TransactionFilter.income:
        return transactions
            .where((tx) => tx.type == TransactionType.income)
            .toList();
      case _TransactionFilter.spent:
        return transactions
            .where((tx) => tx.type == TransactionType.expense)
            .toList();
      case _TransactionFilter.recurring:
        return transactions
            .where((tx) => tx.recurrence != TransactionRecurrence.none)
            .toList();
      case null:
        return transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final currencyFormat = CurrencyUtils.getFormat(appCurrency);
    final transactionsAsync = ref.watch(transactionListProvider());

    return Scaffold(
      appBar: AppBar(
        title: BrandedTitle(label: l10n.transactionsTitle),
        actions: [
          NotificationBellButton(
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 52,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noTransactions,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noTransactionsSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: (MediaQuery.sizeOf(context).width - 48)
                          .clamp(220.0, 320.0)
                          .toDouble(),
                      child: FilledButton.icon(
                        onPressed: () => context.push('/transactions/add'),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addTransaction),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);
          final monthTransactions = transactions
              .where((tx) => !tx.date.isBefore(monthStart))
              .toList();
          final monthIncome = monthTransactions
              .where((tx) => tx.type == TransactionType.income)
              .fold<double>(0, (sum, tx) => sum + tx.amount);
          final monthExpense = monthTransactions
              .where((tx) => tx.type == TransactionType.expense)
              .fold<double>(0, (sum, tx) => sum + tx.amount);
          final recurringCount = transactions
              .where((tx) => tx.recurrence != TransactionRecurrence.none)
              .length;
          final categoryTotals = <String, double>{};
          for (final tx in monthTransactions.where(
            (tx) => tx.type == TransactionType.expense,
          )) {
            categoryTotals.update(
              tx.category,
              (value) => value + tx.amount,
              ifAbsent: () => tx.amount,
            );
          }
          final topCategory = categoryTotals.entries.isEmpty
              ? null
              : (categoryTotals.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .first;
          final decisionMessage = monthExpense > monthIncome
              ? l10n.transactionsDecisionOutpacingIncome
              : topCategory != null
                  ? l10n.transactionsDecisionTopCategory(topCategory.key)
                  : l10n.transactionsDecisionBalanced;

          final filteredTransactions = _filterTransactions(transactions);
          final displayedTransactions =
              filteredTransactions.isEmpty ? const [] : filteredTransactions;

          return filteredTransactions.isEmpty && _activeFilter != null
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _TransactionDecisionSummary(
                        message: decisionMessage,
                        monthIncome: monthIncome,
                        monthExpense: monthExpense,
                        recurringCount: recurringCount,
                        netFlow: monthIncome - monthExpense,
                        topCategory: topCategory?.key,
                        currencyCode: appCurrency,
                        activeFilter: _activeFilter,
                        onFilterSelected: (filter) {
                          setState(() {
                            _activeFilter =
                                _activeFilter == filter ? null : filter;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_off,
                                size: 40,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.transactionsNoMatching,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.transactionsTryDifferentFilter,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () => setState(() {
                                  _activeFilter = null;
                                }),
                                child: Text(l10n.transactionsClear),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: displayedTransactions.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _TransactionDecisionSummary(
                        message: decisionMessage,
                        monthIncome: monthIncome,
                        monthExpense: monthExpense,
                        recurringCount: recurringCount,
                        netFlow: monthIncome - monthExpense,
                        topCategory: topCategory?.key,
                        currencyCode: appCurrency,
                        activeFilter: _activeFilter,
                        onFilterSelected: (filter) {
                          setState(() {
                            _activeFilter =
                                _activeFilter == filter ? null : filter;
                          });
                        },
                      );
                    }
                    final tx = displayedTransactions[index - 1];
                    final isExpense = tx.type == TransactionType.expense;
                    final amountColor = isExpense
                        ? Theme.of(context).colorScheme.error
                        : const Color(0xFF059669);
                    return Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ref
                            .read(transactionListProvider().notifier)
                            .deleteTransaction(tx.id);
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.transactionsDeleted)),
                        );
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            context.push('/transactions/edit/${tx.id}');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppSurfaces.elevated(
                              context,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: amountColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    isExpense
                                        ? Icons.arrow_outward_rounded
                                        : Icons.arrow_downward_rounded,
                                    color: amountColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              tx.category,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                          if (tx.recurrence !=
                                              TransactionRecurrence.none) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                _getRecurrenceLabel(
                                                  tx.recurrence,
                                                  l10n,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        tx.note?.isNotEmpty == true
                                            ? tx.note!
                                            : l10n.transactionsNoNote,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isExpense ? '-' : '+'}${currencyFormat.format(tx.amount)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: amountColor,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM dd').format(tx.date),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) =>
            Center(child: Text(l10n.transactionsError(err.toString()))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getRecurrenceLabel(
    TransactionRecurrence recurrence,
    AppLocalizations l10n,
  ) {
    switch (recurrence) {
      case TransactionRecurrence.daily:
        return l10n.transactionsRecurrenceDaily;
      case TransactionRecurrence.weekly:
        return l10n.transactionsRecurrenceWeekly;
      case TransactionRecurrence.monthly:
        return l10n.transactionsRecurrenceMonthly;
      case TransactionRecurrence.yearly:
        return l10n.transactionsRecurrenceYearly;
      case TransactionRecurrence.none:
        return l10n.transactionsRecurrenceNone;
    }
  }
}

class _TransactionDecisionSummary extends StatelessWidget {
  const _TransactionDecisionSummary({
    required this.message,
    required this.monthIncome,
    required this.monthExpense,
    required this.recurringCount,
    required this.netFlow,
    required this.topCategory,
    required this.currencyCode,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  final String message;
  final double monthIncome;
  final double monthExpense;
  final int recurringCount;
  final double netFlow;
  final String? topCategory;
  final String currencyCode;
  final _TransactionFilter? activeFilter;
  final ValueChanged<_TransactionFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = CurrencyUtils.getFormat(currencyCode);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppSurfaces.elevated(
        context,
        radius: 22,
        color: colorScheme.surfaceContainerHigh,
        opacity: 0.06,
      ),
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
                  AppLocalizations.of(context)!.insightsDecisionSnapshot,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TransactionFilterChip(
                label: AppLocalizations.of(context)!.income,
                value: currencyFormat.format(monthIncome),
                tone: const Color(0xFF059669),
                isSelected: activeFilter == _TransactionFilter.income,
                onTap: () => onFilterSelected(_TransactionFilter.income),
              ),
              _TransactionFilterChip(
                label: AppLocalizations.of(context)!.transactionsSpent,
                value: currencyFormat.format(monthExpense),
                tone: colorScheme.error,
                isSelected: activeFilter == _TransactionFilter.spent,
                onTap: () => onFilterSelected(_TransactionFilter.spent),
              ),
              _TransactionFilterChip(
                label: AppLocalizations.of(context)!.transactionsRecurring,
                value: '$recurringCount',
                tone: colorScheme.secondary,
                isSelected: activeFilter == _TransactionFilter.recurring,
                onTap: () => onFilterSelected(_TransactionFilter.recurring),
              ),
              _CompactDecisionChip(
                label: AppLocalizations.of(context)!.transactionsNetFlow,
                value: currencyFormat.format(netFlow),
                valueColor:
                    netFlow >= 0 ? const Color(0xFF059669) : colorScheme.error,
              ),
              _CompactDecisionChip(
                label: AppLocalizations.of(context)!.transactionsTopCategory,
                value: topCategory ??
                    AppLocalizations.of(context)!.transactionsRecurrenceNone,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;
  final bool isSelected;
  final VoidCallback onTap;

  const _TransactionFilterChip({
    required this.label,
    required this.value,
    required this.tone,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundAlpha = isSelected ? 0.18 : 0.08;
    final borderAlpha = isSelected ? 0.42 : 0.14;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 110),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: backgroundAlpha),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: tone.withValues(alpha: borderAlpha),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
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
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _CompactDecisionChip extends StatelessWidget {
  const _CompactDecisionChip({
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
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHigh
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                  color: valueColor,
                ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
