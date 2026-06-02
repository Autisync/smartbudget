import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/features/transactions/presentation/widgets/transaction_form_sheet.dart';
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
              title: buildFrostedAppBarTitle(
                context: context,
                title: l10n.transactionsEditTransaction,
                isScrolled: false,
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              flexibleSpace: buildFrostedFlexibleSpace(
                context: context,
                isScrolled: false,
                onKey: 'edit-tx-appbar-blur-on',
                offKey: 'edit-tx-appbar-blur-off',
              ),
              actions: buildPageHeaderActions(
                context: context,
                isScrolled: false,
              ),
            ),
            body: Center(child: Text(l10n.transactionsNotFound)),
          );
        }

        return TransactionFormSheet(
          mode: TransactionFormMode.update,
          initialData: snapshot.data,
          asModal: true,
        );
      },
    );
  }
}
