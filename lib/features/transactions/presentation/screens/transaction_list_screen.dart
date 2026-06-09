import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/components/financial/insight_portfolio_card.dart';
import 'package:smartbudget/components/shared/slidable_edge_clip.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/core/widgets/app_feedback.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/features/transactions/presentation/widgets/transaction_form_sheet.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/data/models/tables.dart'
    show TransactionType, TransactionRecurrence;
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

enum _TransactionFilter {
  thisMonth,
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
  String _searchQuery = '';
  bool _isAppBarScrolled = false;

  Future<void> _openEditTransactionModal(Transaction transaction) async {
    await AppFormSheet.show<void>(
      context,
      builder: (_) => TransactionFormSheet(
        mode: TransactionFormMode.update,
        initialData: transaction,
        asModal: true,
      ),
    );
  }

  Future<void> _openAddTransactionModal() async {
    await AppFormSheet.show<void>(
      context,
      builder: (_) => const TransactionFormSheet(
        mode: TransactionFormMode.create,
        asModal: true,
      ),
    );
  }

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final query = _searchQuery.trim().toLowerCase();
    final searched = query.isEmpty
        ? transactions
        : transactions.where((tx) {
            return tx.category.toLowerCase().contains(query) ||
                (tx.note ?? '').toLowerCase().contains(query) ||
                DateFormat('MMM dd yyyy')
                    .format(tx.date)
                    .toLowerCase()
                    .contains(query);
          }).toList();

    switch (_activeFilter) {
      case _TransactionFilter.thisMonth:
        final now = DateTime.now();
        return searched
            .where(
                (tx) => tx.date.year == now.year && tx.date.month == now.month)
            .toList();
      case _TransactionFilter.income:
        return searched
            .where((tx) => tx.type == TransactionType.income)
            .toList();
      case _TransactionFilter.spent:
        return searched
            .where((tx) => tx.type == TransactionType.expense)
            .toList();
      case _TransactionFilter.recurring:
        return searched
            .where((tx) => tx.recurrence != TransactionRecurrence.none)
            .toList();
      case null:
        return searched;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final currencyFormat = CurrencyUtils.getFormat(appCurrency);
    final transactionsAsync = ref.watch(transactionListProvider());
    final decisionSnapshotAsync =
        ref.watch(transactionDecisionSnapshotProvider);

    return AppScaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.transactionsTitle,
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
          onKey: 'transactions-appbar-blur-on',
          offKey: 'transactions-appbar-blur-off',
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
        child: transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: l10n.noTransactions,
                message: l10n.noTransactionsSubtitle,
                lottieAsset: 'assets/animations/empty_transactions.json',
                action: SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 48)
                      .clamp(220.0, 320.0)
                      .toDouble(),
                  child: FilledButton.icon(
                    onPressed: _openAddTransactionModal,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addTransaction),
                  ),
                ),
              );
            }
            final filteredTransactions = _filterTransactions(transactions);
            final displayedTransactions =
                filteredTransactions.isEmpty ? const [] : filteredTransactions;

            return CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TransactionSearchHeaderDelegate(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _TransactionSearchField(
                        value: _searchQuery,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: decisionSnapshotAsync.when(
                      data: (snapshot) => TransactionInsightCard(
                        message: snapshot.message,
                        monthIncome: snapshot.monthIncome,
                        monthExpense: snapshot.monthExpense,
                        recurringCount: snapshot.recurringCount,
                        netFlow: snapshot.netFlow,
                        topCategory: snapshot.topCategory,
                        currencyCode: appCurrency,
                        isIncomeSelected:
                            _activeFilter == _TransactionFilter.income,
                        isSpentSelected:
                            _activeFilter == _TransactionFilter.spent,
                        isRecurringSelected:
                            _activeFilter == _TransactionFilter.recurring,
                        onIncomeTap: () => setState(() {
                          _activeFilter =
                              _activeFilter == _TransactionFilter.income
                                  ? null
                                  : _TransactionFilter.income;
                        }),
                        onSpentTap: () => setState(() {
                          _activeFilter =
                              _activeFilter == _TransactionFilter.spent
                                  ? null
                                  : _TransactionFilter.spent;
                        }),
                        onRecurringTap: () => setState(() {
                          _activeFilter =
                              _activeFilter == _TransactionFilter.recurring
                                  ? null
                                  : _TransactionFilter.recurring;
                        }),
                        emptyFallback: l10n.transactionsRecurrenceNone,
                      ),
                      loading: () => AppSkeletonLoader(
                        child: TransactionInsightCard(
                          message: 'Preparing insights...',
                          monthIncome: 0,
                          monthExpense: 0,
                          recurringCount: 0,
                          netFlow: 0,
                          topCategory: null,
                          currencyCode: appCurrency,
                          isIncomeSelected: false,
                          isSpentSelected: false,
                          isRecurringSelected: false,
                          onIncomeTap: () {},
                          onSpentTap: () {},
                          onRecurringTap: () {},
                          emptyFallback: l10n.transactionsRecurrenceNone,
                        ),
                      ),
                      error: (_, __) => TransactionInsightCard(
                        message: l10n.transactionsDecisionBalanced,
                        monthIncome: 0,
                        monthExpense: 0,
                        recurringCount: 0,
                        netFlow: 0,
                        topCategory: null,
                        currencyCode: appCurrency,
                        isIncomeSelected: false,
                        isSpentSelected: false,
                        isRecurringSelected: false,
                        onIncomeTap: () {},
                        onSpentTap: () {},
                        onRecurringTap: () {},
                        emptyFallback: l10n.transactionsRecurrenceNone,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _activeFilter == null,
                          onTap: () => setState(() => _activeFilter = null),
                        ),
                        _FilterChip(
                          label: 'This Month',
                          selected:
                              _activeFilter == _TransactionFilter.thisMonth,
                          onTap: () => setState(() {
                            _activeFilter =
                                _activeFilter == _TransactionFilter.thisMonth
                                    ? null
                                    : _TransactionFilter.thisMonth;
                          }),
                        ),
                        _FilterChip(
                          label: 'Income',
                          selected: _activeFilter == _TransactionFilter.income,
                          onTap: () => setState(() {
                            _activeFilter =
                                _activeFilter == _TransactionFilter.income
                                    ? null
                                    : _TransactionFilter.income;
                          }),
                        ),
                        _FilterChip(
                          label: 'Expense',
                          selected: _activeFilter == _TransactionFilter.spent,
                          onTap: () => setState(() {
                            _activeFilter =
                                _activeFilter == _TransactionFilter.spent
                                    ? null
                                    : _TransactionFilter.spent;
                          }),
                        ),
                        _FilterChip(
                          label: 'Recurring',
                          selected:
                              _activeFilter == _TransactionFilter.recurring,
                          onTap: () => setState(() {
                            _activeFilter =
                                _activeFilter == _TransactionFilter.recurring
                                    ? null
                                    : _TransactionFilter.recurring;
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filteredTransactions.isEmpty && _activeFilter != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
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
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: displayedTransactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tx = displayedTransactions[index];
                        final isExpense = tx.type == TransactionType.expense;
                        final amountColor = isExpense
                            ? Theme.of(context).colorScheme.error
                            : const Color(0xFF059669);
                        return Slidable(
                          key: ValueKey(tx.id),
                          endActionPane: ActionPane(
                            motion: const BehindMotion(),
                            extentRatio: 0.28,
                            children: [
                              SlidableAction(
                                onPressed: (_) async {
                                  await ref
                                      .read(transactionListProvider().notifier)
                                      .deleteTransaction(tx.id);
                                  if (!context.mounted) return;
                                  AppFeedback.show(
                                    context,
                                    message: l10n.transactionsDeleted,
                                    type: AppFeedbackType.success,
                                  );
                                },
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                foregroundColor: Colors.white,
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                                borderRadius:
                                    BorderRadius.circular(UiTokens.radiusXl),
                              ),
                            ],
                          ),
                          child: SwipeableCard(
                            radius: UiTokens.radiusXl,
                            child: PremiumCard(
                              padding: const EdgeInsets.all(16),
                              onTap: () {
                                _openEditTransactionModal(tx);
                              },
                              child: Row(
                                children: [
                                  _MerchantAvatar(
                                    label: tx.category,
                                    isExpense: isExpense,
                                    color: amountColor,
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
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                                      BorderRadius.circular(
                                                          999),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        FinanceAmount(
                                          value:
                                              '${isExpense ? '-' : '+'}${currencyFormat.format(tx.amount)}',
                                          color: amountColor,
                                          compact: true,
                                          textAlign: TextAlign.end,
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
                        );
                      },
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) =>
              Center(child: Text(l10n.transactionsError(err.toString()))),
        ),
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

class _TransactionSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TransactionSearchHeaderDelegate({
    required this.child,
    required this.backgroundColor,
  });

  final Widget child;
  final Color backgroundColor;

  static const double _extent = 64;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _TransactionSearchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _TransactionSearchField extends StatefulWidget {
  const _TransactionSearchField({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_TransactionSearchField> createState() =>
      _TransactionSearchFieldState();
}

class _TransactionSearchFieldState extends State<_TransactionSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TransactionSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        hintText: 'Search transactions, notes, or dates',
        prefixIcon: Icon(
          Icons.search_rounded,
          color: scheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.16),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.16),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        suffixIcon: widget.value.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _MerchantAvatar extends StatelessWidget {
  const _MerchantAvatar({
    required this.label,
    required this.isExpense,
    required this.color,
  });

  final String label;
  final bool isExpense;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return Semantics(
      label: '$label ${isExpense ? 'expense' : 'income'}',
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.20),
              color.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              initial,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            Positioned(
              right: 5,
              bottom: 5,
              child: Icon(
                isExpense
                    ? Icons.arrow_outward_rounded
                    : Icons.arrow_downward_rounded,
                color: color,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.14)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
