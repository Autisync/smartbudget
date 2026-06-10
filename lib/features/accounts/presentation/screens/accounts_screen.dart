import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/components/forms/form_components.dart';
import 'package:smartbudget/core/providers/quick_add_provider.dart';
import 'package:smartbudget/core/widgets/animated_list_item.dart';
import 'package:smartbudget/core/widgets/app_shimmer.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/domain/entities/account.dart';
import 'package:smartbudget/features/accounts/presentation/providers/account_provider.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';

/// Lists money-source accounts (Cash, Bank Transfer, Credit Card and any custom
/// accounts) with their live derived balances, and supports adding / editing /
/// removing custom accounts.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _isAppBarScrolled = false;

  @override
  void initState() {
    super.initState();
    // Handle quick-add request from the nav + menu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeHandleQuickAdd(ref.read(pendingQuickAddProvider));
    });
  }

  void _maybeHandleQuickAdd(QuickAddTarget? target) {
    if (target != QuickAddTarget.account) return;
    ref.read(pendingQuickAddProvider.notifier).state = null;
    _openEditor(context, ref, null);
  }

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled || !mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QuickAddTarget?>(pendingQuickAddProvider, (_, next) {
      _maybeHandleQuickAdd(next);
    });

    final accountsAsync = ref.watch(accountsProvider);
    final totalAsync = ref.watch(totalAccountBalanceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : const Color(0xFFF8F8FA),
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: 'Accounts',
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'accounts-appbar-blur-on',
          offKey: 'accounts-appbar-blur-off',
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
        child: accountsAsync.when(
          loading: () => const AppShimmerSkeleton(
              variant: AppShimmerVariant.cards, itemCount: 4),
          error: (e, _) => Center(child: Text('Failed to load accounts: $e')),
          data: (accounts) {
            if (accounts.isEmpty) {
              return AppEmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No accounts yet',
                message:
                    'Add your first account to start tracking your money '
                    'across wallets and banks.',
                action: SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 48)
                      .clamp(220.0, 320.0)
                      .toDouble(),
                  child: FilledButton.icon(
                    onPressed: () => _openEditor(context, ref, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add account'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: accounts.length + 1, // +1 for total card
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AnimatedListItem(
                    index: 0,
                    child: Column(
                      children: [
                        totalAsync.maybeWhen(
                          data: (total) => _TotalCard(
                              total: total,
                              currency: accounts.first.currency,
                              count: accounts.length),
                          orElse: () => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                }
                final a = accounts[index - 1];
                return AnimatedListItem(
                  index: index,
                  child: _AccountTile(
                    account: a,
                    onEdit: () => _openEditor(context, ref, a),
                    onDelete: a.isDefault
                        ? null
                        : () => _confirmDelete(context, ref, a),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    Account? existing,
  ) async {
    await AppFormSheet.show<void>(
      context,
      builder: (_) => _AccountEditorSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${account.name}?'),
        content: const Text(
          'The account will be hidden. Existing transactions are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(accountRepositoryProvider).deactivateAccount(account.id);
    }
  }
}

IconData _accountIcon(AccountType type) => switch (type) {
      AccountType.cash => Icons.payments_rounded,
      AccountType.bank => Icons.account_balance_rounded,
      AccountType.mobileMoney => Icons.smartphone_rounded,
      AccountType.creditCard => Icons.credit_card_rounded,
      AccountType.investment => Icons.trending_up_rounded,
    };

Color _accountColor(AccountType type) => switch (type) {
      AccountType.cash => const Color(0xFF198754),
      AccountType.bank => const Color(0xFF4F5FA7),
      AccountType.mobileMoney => const Color(0xFF0E7490),
      AccountType.creditCard => const Color(0xFFB36A10),
      AccountType.investment => const Color(0xFF7C3AED),
    };

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.currency,
    required this.count,
  });
  final double total;
  final String currency;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fmt = CurrencyUtils.getFormat(currency);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.colorScheme.surfaceContainerHigh,
                  theme.colorScheme.surfaceContainer,
                ]
              : const [Color(0xFF2D3561), Color(0xFF4F5FA7)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F5FA7).withValues(alpha: isDark ? 0.0 : 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Total balance',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fmt.format(total),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'account' : 'accounts'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.onEdit,
    this.onDelete,
  });

  final Account account;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = CurrencyUtils.getFormat(account.currency);
    final color = _accountColor(account.type);
    final negative = account.currentBalance < 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SmartCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onEdit,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_accountIcon(account.type), color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.type.label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              fmt.format(account.currentBalance),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: negative ? const Color(0xFFC94B2A) : null,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Text('Remove')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountEditorSheet extends ConsumerStatefulWidget {
  const _AccountEditorSheet({this.existing});
  final Account? existing;

  @override
  ConsumerState<_AccountEditorSheet> createState() =>
      _AccountEditorSheetState();
}

class _AccountEditorSheetState extends ConsumerState<_AccountEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _opening;
  late AccountType _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _opening =
        TextEditingController(text: e == null ? '0' : e.openingBalance.toString());
    _type = e?.type ?? AccountType.cash;
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(accountRepositoryProvider);
    final opening = double.tryParse(_opening.text.trim()) ?? 0;
    final existing = widget.existing;
    if (existing == null) {
      // New custom accounts use the app's default currency of the first account.
      final accounts = await repo.getAccounts(includeInactive: true);
      final currency = accounts.isNotEmpty ? accounts.first.currency : 'USD';
      await repo.createAccount(
        name: _name.text.trim(),
        type: _type,
        currency: currency,
        openingBalance: opening,
      );
    } else {
      await repo.updateAccount(
        existing.copyWith(
          name: _name.text.trim(),
          type: _type,
          openingBalance: opening,
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final liveName = _name.text.trim();
    final liveBalance = double.tryParse(_opening.text.trim()) ?? 0.0;

    final typeIcon = switch (_type) {
      AccountType.cash => Icons.payments_outlined,
      AccountType.bank => Icons.account_balance_outlined,
      AccountType.mobileMoney => Icons.smartphone_outlined,
      AccountType.creditCard => Icons.credit_card_outlined,
      AccountType.investment => Icons.trending_up_outlined,
    };

    final formFields = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(typeIcon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Account' : 'New Account',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        liveName.isNotEmpty
                            ? liveBalance != 0
                                ? '$liveName · ${liveBalance.toStringAsFixed(2)}'
                                : liveName
                            : 'Name your account',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ModernInput(
            controller: _name,
            label: 'Account name',
            hintText: 'e.g. Main Wallet, HSBC Savings',
            prefixIcon: Icons.label_rounded,
            onChanged: (_) => setState(() {}),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
          ),
          const SizedBox(height: 16),
          // Account type chip row
          _AccountTypeChipSelector(
            value: _type,
            onChanged: (t) => setState(() => _type = t),
          ),
          const SizedBox(height: 16),
          CurrencyInput(
            controller: _opening,
            label: 'Opening balance',
            currencySymbol: '',
            helperText: 'Starting balance for this account',
            onChanged: (_) => setState(() {}),
            validator: (v) =>
                double.tryParse((v ?? '').trim()) == null
                    ? 'Enter a number'
                    : null,
          ),
        ],
      ),
    );

    return AppFormSheet(
      onClose: () => Navigator.of(context).pop(),
      maxHeightFactor: 0.78,
      body: formFields,
      actions: FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isEdit ? Icons.edit_rounded : Icons.add_rounded),
        label: Text(isEdit ? 'Save Account' : 'Create Account'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
        ),
      ),
    );
  }
}

// ─── Account type chip selector ──────────────────────────────────────────────

class _AccountTypeChipSelector extends StatelessWidget {
  const _AccountTypeChipSelector({
    required this.value,
    required this.onChanged,
  });

  final AccountType value;
  final ValueChanged<AccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account type',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AccountType.values.map((t) {
            final selected = value == t;
            return GestureDetector(
              onTap: () => onChanged(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  t.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
