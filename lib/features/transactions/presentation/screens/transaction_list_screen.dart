import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/data/models/tables.dart'
    show TransactionType, TransactionRecurrence;

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final transactionsAsync = ref.watch(transactionListProvider());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            onPressed: () => context.push('/transactions/add'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions yet'));
          }
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return Dismissible(
                key: ValueKey(tx.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
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
                    const SnackBar(content: Text('Transaction deleted')),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tx.type == TransactionType.expense
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    child: Icon(
                      tx.type == TransactionType.expense
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(tx.category),
                      if (tx.recurrence != TransactionRecurrence.none) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tx.recurrence.name,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.blue),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(tx.note ?? 'No note'),
                  trailing: Text(
                    '${tx.type == TransactionType.expense ? '-' : '+'}${currencyFormat.format(tx.amount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    context.push('/transactions/edit/${tx.id}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
