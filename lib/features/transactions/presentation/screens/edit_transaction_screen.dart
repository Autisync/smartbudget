import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';

class EditTransactionScreen extends ConsumerWidget {
  final String transactionId;
  const EditTransactionScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(transactionRepositoryProvider);

    return FutureBuilder<Transaction?>(
      future: repo.getTransactionById(transactionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Transaction')),
            body: const Center(child: Text('Transaction not found')),
          );
        }

        return AddTransactionScreen(existingTransaction: snapshot.data);
      },
    );
  }
}
