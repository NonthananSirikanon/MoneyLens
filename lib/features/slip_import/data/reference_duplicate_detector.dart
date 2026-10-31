import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_repository.dart';
import '../domain/extracted_fields.dart';
import '../domain/import_ports.dart';
import '../domain/scan_record.dart';

/// Flags a slip that matches a transaction already saved from another scan,
/// even when the image file is different (a screenshot, a second photo).
/// This is the bank-reference layer of DATABASE.md section 6. It runs
/// entirely on the device.
///
/// A saved transaction counts as the same payment only when ALL of these
/// agree:
///
/// - the bank reference, ignoring case, spaces and dashes;
/// - the amount (and currency, when both sides state one);
/// - the time, to the minute (slips show no seconds);
/// - the counterparty name, when both sides have one.
///
/// The reference alone is not enough. A reference can repeat (a bill
/// reference paid every month) or be misread, so a slip with the same
/// reference but another amount or time is treated as a different payment.
/// Amount and date alone never match either: a slip with no readable
/// reference is never flagged here. Whoever reviews it still sees both
/// entries on the list.
///
/// Known limits, all of which let the slip through to review rather than
/// hide it:
///
/// - The saved transaction holds what the user confirmed. If they edited
///   the amount, time or payee in review, it no longer matches.
/// - Only transactions saved from a scan can be pointed at, because a
///   duplicate scan links to another scan (`duplicate_of_scan_id`).
///   Manual entries are skipped.
/// - Earlier scans still waiting for review are not compared.
class ReferenceDuplicateDetector implements ReadingDuplicateDetector {
  const ReferenceDuplicateDetector(this._transactions);

  final TransactionRepository _transactions;

  /// Shorter references are too weak to identify a payment.
  static const _minReferenceLength = 8;

  @override
  Future<DuplicateCheck> check(ScanRecord scan, ExtractedFields fields) async {
    final reference = normalizeReference(fields.providerReference?.value);
    final amount = fields.amountMinor?.value;
    final time = fields.occurredAt?.value;
    if (reference == null || amount == null || time == null) {
      return DuplicateCheck.none;
    }

    final candidates = await _transactions.findWithProviderReference();
    // Oldest first, so the answer does not depend on query order.
    candidates.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final tx in candidates) {
      final scanId = tx.scanRecordId;
      if (scanId == null || scanId == scan.id) continue;
      if (normalizeReference(tx.providerReference) != reference) continue;
      if (tx.amount.minor != amount) continue;
      final currency = fields.currencyCode;
      if (currency != null && tx.amount.currency.code != currency) continue;
      if (_minute(tx.occurredAt) != _minute(time)) continue;
      if (!_sameCounterparty(tx, fields)) continue;
      return DuplicateCheck(duplicateOfScanId: scanId);
    }
    return DuplicateCheck.none;
  }

  /// Upper-cased letters and digits only, or null when too short to trust.
  /// Thai digits become Arabic ones first, as the extraction service does
  /// (slips print Arabic digits), so a reference edited with a Thai keyboard
  /// still matches. Without that they would be stripped, which could make
  /// two different references look equal.
  static String? normalizeReference(String? raw) {
    if (raw == null) return null;
    final key = raw
        .replaceAllMapped(
          RegExp('[\u0E50-\u0E59]'),
          (m) => '${m.group(0)!.codeUnitAt(0) - 0x0E50}',
        )
        .toUpperCase()
        .replaceAll(RegExp('[^A-Z0-9]'), '');
    return key.length < _minReferenceLength ? null : key;
  }

  static int _minute(DateTime t) =>
      t.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute;

  static bool _sameCounterparty(MoneyTransaction tx, ExtractedFields f) {
    final a = _nameKey(tx.merchant);
    final b = _nameKey(f.merchant?.value);
    return a.isEmpty || b.isEmpty || a == b;
  }

  static String _nameKey(String? name) =>
      (name ?? '').replaceAll(RegExp(r'\s+'), '').toLowerCase();
}
