import 'dart:convert';

import '../../../core/dates/reporting_time_zone.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';

/// Words used in the file, in the language of the app.
class CsvLabels {
  const CsvLabels({
    required this.date,
    required this.time,
    required this.type,
    required this.amount,
    required this.currency,
    required this.account,
    required this.toAccount,
    required this.category,
    required this.merchant,
    required this.note,
    required this.source,
    required this.income,
    required this.expense,
    required this.transfer,
  });

  final String date;
  final String time;
  final String type;
  final String amount;
  final String currency;
  final String account;
  final String toAccount;
  final String category;
  final String merchant;
  final String note;
  final String source;
  final String income;
  final String expense;
  final String transfer;

  String typeLabel(TransactionType t) => switch (t) {
    TransactionType.income => income,
    TransactionType.expense => expense,
    TransactionType.transfer => transfer,
  };
}

/// Builds the CSV text for a list of transactions.
///
/// * UTF-8 with a byte order mark, so Excel reads Thai correctly.
/// * CRLF line ends and RFC 4180 quoting.
/// * Dates are Gregorian ISO in Asia/Bangkok (not Buddhist years), so other
///   tools can read them; the amount is a plain decimal, always positive, and
///   the type column says the direction.
/// * Text a spreadsheet would run as a formula (`=`, `+`, `-`, `@`, tab, CR)
///   gets a leading `'`.
/// * The provider reference and slip image paths are never exported.
abstract final class TransactionCsv {
  static const bom = '﻿';

  /// The file as bytes, ready to write.
  static List<int> encode(String csv) => utf8.encode(csv);

  static String build({
    required Iterable<MoneyTransaction> transactions,
    required CsvLabels labels,
    required String Function(String id) accountName,
    required String Function(String id) categoryName,
  }) {
    final sorted = transactions.toList()
      ..sort((a, b) {
        final byTime = a.occurredAt.compareTo(b.occurredAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    final out = StringBuffer(bom)
      ..write(
        _row([
          labels.date,
          labels.time,
          labels.type,
          labels.amount,
          labels.currency,
          labels.account,
          labels.toAccount,
          labels.category,
          labels.merchant,
          labels.note,
          labels.source,
        ]),
      );
    for (final t in sorted) {
      final local = ReportingTimeZone.bangkok.wallClock(t.occurredAt);
      final destination = t.destinationAccountId;
      final category = t.categoryId;
      out.write(
        _row(
          [
            '${_pad(local.year, 4)}-${_pad(local.month)}-${_pad(local.day)}',
            '${_pad(local.hour)}:${_pad(local.minute)}',
            labels.typeLabel(t.type),
            t.amount.toDecimalString(),
            t.amount.currency.code,
            accountName(t.accountId),
            destination == null ? '' : accountName(destination),
            category == null ? '' : categoryName(category),
            t.merchant ?? '',
            t.note ?? '',
            t.source.dbValue,
          ],
          plain: const {0, 1, 3, 4, 10},
        ),
      );
    }
    return out.toString();
  }

  static String _pad(int n, [int width = 2]) =>
      n.toString().padLeft(width, '0');

  /// One record. Columns in [plain] are values this code produced (dates,
  /// the amount, codes) and are never treated as formulas; every other cell
  /// is user text.
  static String _row(List<String> cells, {Set<int> plain = const {}}) =>
      '${[for (var i = 0; i < cells.length; i++) _cell(cells[i], guard: !plain.contains(i))].join(',')}\r\n';

  static String _cell(String value, {required bool guard}) {
    var v = value;
    if (guard && v.isNotEmpty && '=+-@\t\r'.contains(v[0])) v = "'$v";
    if (v.contains(',') ||
        v.contains('"') ||
        v.contains('\n') ||
        v.contains('\r')) {
      v = '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
