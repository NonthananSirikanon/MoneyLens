import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_formatter.dart';
import '../../../core/widgets/async_states.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/presentation/transaction_tile.dart';
import '../application/dashboard_providers.dart';
import '../application/summary_calculator.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(dashboardSummaryProvider);
    final recent = ref.watch(recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navDashboard)),
      body: summary.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorView(
          message: l10n.loadError,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
        ),
        data: (summary) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SummaryCard(summary: summary),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.recentTransactions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...switch (recent) {
              AsyncData(:final value) when value.isEmpty => [
                EmptyView(
                  icon: Icons.receipt_long_outlined,
                  message: l10n.transactionsEmpty,
                ),
              ],
              AsyncData(:final value) => [
                for (final tx in value) TransactionTile(transaction: tx),
              ],
              AsyncError() => [ErrorView(message: l10n.loadError)],
              _ => [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: LoadingView(),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final formatter = MoneyFormatter(
      Localizations.localeOf(context).toLanguageTag(),
    );
    String fmt(Money m) => formatter.format(m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dashboardThisMonth, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(fmt(summary.net), style: theme.textTheme.headlineMedium),
            Text(l10n.summaryNet, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Figure(
                    label: l10n.summaryIncome,
                    value: fmt(summary.income),
                    color: theme.colorScheme.incomeColor,
                  ),
                ),
                Expanded(
                  child: _Figure(
                    label: l10n.summaryExpense,
                    value: fmt(summary.expense),
                    color: theme.colorScheme.expenseColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.summaryTransfers(summary.transferCount),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(color: color)),
      ],
    );
  }
}
