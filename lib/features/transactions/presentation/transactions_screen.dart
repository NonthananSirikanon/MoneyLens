import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_states.dart';
import '../../../l10n/app_localizations.dart';
import '../application/transaction_providers.dart';
import 'transaction_tile.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(transactionHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTransactions)),
      body: history.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorView(
          message: l10n.loadError,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(transactionHistoryProvider),
        ),
        data: (transactions) => transactions.isEmpty
            ? EmptyView(
                icon: Icons.receipt_long_outlined,
                message: l10n.transactionsEmpty,
              )
            : ListView.separated(
                itemCount: transactions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) =>
                    TransactionTile(transaction: transactions[i]),
              ),
      ),
    );
  }
}
