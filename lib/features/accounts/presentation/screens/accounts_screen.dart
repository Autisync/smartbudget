import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/domain/entities/account.dart';
import 'package:smartbudget/features/accounts/presentation/providers/account_provider.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';

/// Lists money-source accounts (Cash, Bank Transfer, Credit Card and any custom
/// accounts) with their live derived balances, and supports adding / editing /
/// removing custom accounts.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final totalAsync = ref.watch(totalAccountBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add account'),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load accounts: $e')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts yet.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              totalAsync.maybeWhen(
                data: (total) => _TotalCard(total: total,
                    currency: accounts.first.currency),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              for (final a in accounts)
                _AccountTile(
                  account: a,
                  onEdit: () => _openEditor(context, ref, a),
                  onDelete: a.isDefault
                      ? null
                      : () => _confirmDelete(context, ref, a),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    Account? existing,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.currency});
  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final fmt = CurrencyUtils.getFormat(currency);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total balance',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(
              fmt.format(total),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
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

  IconData get _icon => switch (account.type) {
        AccountType.cash => Icons.payments_outlined,
        AccountType.bank => Icons.account_balance_outlined,
        AccountType.mobileMoney => Icons.smartphone_outlined,
        AccountType.creditCard => Icons.credit_card_outlined,
        AccountType.investment => Icons.trending_up_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final fmt = CurrencyUtils.getFormat(account.currency);
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(_icon)),
        title: Text(account.name),
        subtitle: Text(account.type.label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fmt.format(account.currentBalance),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            PopupMenuButton<String>(
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
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit account' : 'New account',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: AccountType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _opening,
              decoration: const InputDecoration(labelText: 'Opening balance'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  double.tryParse((v ?? '').trim()) == null
                      ? 'Enter a number'
                      : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
