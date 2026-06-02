import 'package:flutter/material.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/screens/add_transaction_screen.dart';

enum TransactionFormMode { create, update }

class TransactionFormSheet extends StatelessWidget {
  const TransactionFormSheet({
    super.key,
    required this.mode,
    this.initialData,
    this.asModal = true,
  });

  final TransactionFormMode mode;
  final Transaction? initialData;
  final bool asModal;

  @override
  Widget build(BuildContext context) {
    final existingTransaction =
        mode == TransactionFormMode.update ? initialData : null;
    return AddTransactionScreen(
      existingTransaction: existingTransaction,
      asModal: asModal,
    );
  }
}
