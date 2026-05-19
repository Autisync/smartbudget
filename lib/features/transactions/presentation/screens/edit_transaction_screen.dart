import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/core/widgets/branded_title.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class EditTransactionScreen extends ConsumerWidget {
  final String transactionId;
  const EditTransactionScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
            appBar: AppBar(
                title: BrandedTitle(label: l10n.transactionsEditTransaction)),
            body: Center(child: Text(l10n.transactionsNotFound)),
          );
        }

        return AddTransactionScreen(existingTransaction: snapshot.data);
      },
    );
  }
}




