import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../accounts/application/account_providers.dart';
import '../../accounts/domain/account_repository.dart';
import '../../categories/application/category_providers.dart';
import '../../categories/domain/category_repository.dart';
import '../../transactions/application/transaction_providers.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_repository.dart';
import '../data/share_plus_file_sharer.dart';
import '../domain/export_period.dart';
import '../domain/file_sharer.dart';
import 'transaction_csv.dart';

/// What an export did.
class ExportResult {
  const ExportResult({
    required this.count,
    required this.fileName,
    this.outcome,
  });

  /// Transactions in the period. When 0 nothing was written or shared.
  final int count;
  final String fileName;
  final ShareOutcome? outcome;
}

/// Builds the CSV for a period from the local database and shares it.
class CsvExportService {
  const CsvExportService({
    required this._transactions,
    required this._accounts,
    required this._categories,
    required this._sharer,
    required this._clock,
  });

  final TransactionRepository _transactions;
  final AccountRepository _accounts;
  final CategoryRepository _categories;
  final FileSharer _sharer;
  final Clock _clock;

  /// `moneylens-2026-10.csv` for the current month, `moneylens-2026.csv`
  /// for the year, `moneylens-last-3-months-2026-10.csv`, `moneylens-all.csv`.
  /// Gregorian years: a file name is for people and tools, not a Thai date.
  String fileName(ExportPeriod period) {
    final now = ReportingTimeZone.bangkok.wallClock(_clock.nowUtc());
    final month = now.month.toString().padLeft(2, '0');
    return switch (period) {
      ExportPeriod.thisMonth => 'moneylens-${now.year}-$month.csv',
      ExportPeriod.last3Months =>
        'moneylens-last-3-months-${now.year}-$month.csv',
      ExportPeriod.thisYear => 'moneylens-${now.year}.csv',
      ExportPeriod.all => 'moneylens-all.csv',
    };
  }

  Future<List<MoneyTransaction>> transactionsIn(ExportPeriod period) async {
    final now = _clock.nowUtc();
    return [
      for (final t in await _transactions.findAll())
        if (period.includes(t.occurredAt, now)) t,
    ];
  }

  Future<ExportResult> export(ExportPeriod period, CsvLabels labels) async {
    final name = fileName(period);
    final list = await transactionsIn(period);
    if (list.isEmpty) return ExportResult(count: 0, fileName: name);

    // Names include archived accounts and categories, which the "active"
    // lists leave out. A deleted one falls back to its id.
    final accountNames = <String, String>{};
    final categoryNames = <String, String>{};
    for (final t in list) {
      for (final id in [t.accountId, t.destinationAccountId]) {
        if (id != null && !accountNames.containsKey(id)) {
          accountNames[id] = (await _accounts.findById(id))?.name ?? id;
        }
      }
      final c = t.categoryId;
      if (c != null && !categoryNames.containsKey(c)) {
        categoryNames[c] = (await _categories.findById(c))?.name ?? c;
      }
    }
    final csv = TransactionCsv.build(
      transactions: list,
      labels: labels,
      accountName: (id) => accountNames[id] ?? id,
      categoryName: (id) => categoryNames[id] ?? id,
    );
    final outcome = await _sharer.shareFile(
      fileName: name,
      bytes: Uint8List.fromList(TransactionCsv.encode(csv)),
      mimeType: 'text/csv',
    );
    return ExportResult(count: list.length, fileName: name, outcome: outcome);
  }
}

/// Overridden in tests.
final fileSharerProvider = Provider<FileSharer>(
  (ref) => const SharePlusFileSharer(),
);

final csvExportServiceProvider = Provider<CsvExportService>(
  (ref) => CsvExportService(
    transactions: ref.watch(transactionRepositoryProvider),
    accounts: ref.watch(accountRepositoryProvider),
    categories: ref.watch(categoryRepositoryProvider),
    sharer: ref.watch(fileSharerProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// The period chosen on the Data & export screen.
class ExportPeriodController extends Notifier<ExportPeriod> {
  @override
  ExportPeriod build() => ExportPeriod.thisMonth;

  void choose(ExportPeriod period) => state = period;
}

final exportPeriodProvider =
    NotifierProvider<ExportPeriodController, ExportPeriod>(
      ExportPeriodController.new,
    );
