import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/features/slip_import/data/reference_duplicate_detector.dart';
import 'package:moneylens/features/slip_import/domain/extracted_fields.dart';
import 'package:moneylens/features/slip_import/domain/scan_record.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';
import 'package:moneylens/features/transactions/domain/transaction.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';

import '../support/test_support.dart';

/// The matching rules of [ReferenceDuplicateDetector], one dimension at a
/// time. Every "not flagged" case matches the saved transaction exactly
/// except for the single thing named, so dropping any one rule turns
/// exactly its test red. All values are invented.
void main() {
  const ref = 'REF00012345';
  final time = DateTime.utc(2026, 2, 12, 2, 5);

  MoneyTransaction saved({
    String? reference = ref,
    String? scanRecordId = 'scan-old',
    String? merchant = 'นาย ตัวอย่าง หนึ่ง',
    int minor = 125050,
    DateTime? at,
    String id = 'tx-1',
    DateTime? createdAt,
  }) => MoneyTransaction(
    id: id,
    type: TransactionType.expense,
    amount: thb(minor),
    accountId: 'acc-1',
    merchant: merchant,
    occurredAt: at ?? time,
    source: TransactionSource.ocr,
    scanRecordId: scanRecordId,
    providerReference: reference,
    createdAt: createdAt ?? time,
    updatedAt: time,
  );

  ExtractedFields reading({
    String? reference = ref,
    int? minor = 125050,
    DateTime? at,
    String? merchant = 'นาย ตัวอย่าง หนึ่ง',
    String? currency = 'THB',
  }) => ExtractedFields(
    amountMinor: minor == null ? null : ExtractedField(minor),
    currencyCode: currency,
    occurredAt: ExtractedField(at ?? time),
    type: const ExtractedField(TransactionType.expense),
    merchant: merchant == null ? null : ExtractedField(merchant),
    providerReference: reference == null ? null : ExtractedField(reference),
  );

  final incoming = ScanRecord(
    id: 'scan-new',
    source: ImportSource.gallery,
    status: ScanStatus.processing,
    createdAt: time,
    updatedAt: time,
  );

  Future<String?> check(
    ExtractedFields fields, {
    List<MoneyTransaction>? txs,
  }) async {
    final detector = ReferenceDuplicateDetector(
      FakeTransactionRepository(txs ?? [saved()]),
    );
    return (await detector.check(incoming, fields)).duplicateOfScanId;
  }

  group('matcher', () {
    test(
      'everything equal: points at the scan that made the transaction',
      () async {
        expect(await check(reading()), 'scan-old');
      },
    );

    test('reference written differently still matches', () async {
      expect(await check(reading(reference: 'ref-0001 2345')), 'scan-old');
    });

    test('amount differs alone: not flagged', () async {
      expect(await check(reading(minor: 125051)), isNull);
    });

    test('time differs by one minute alone: not flagged', () async {
      expect(
        await check(reading(at: time.add(const Duration(minutes: 1)))),
        isNull,
      );
    });

    test(
      'same time of day on another day (monthly bill): not flagged',
      () async {
        expect(
          await check(reading(at: time.add(const Duration(days: 30)))),
          isNull,
        );
      },
    );

    test('counterparty differs alone: not flagged', () async {
      expect(await check(reading(merchant: 'นาย ตัวอย่าง สอง')), isNull);
    });

    test('currency differs alone: not flagged', () async {
      expect(await check(reading(currency: 'USD')), isNull);
    });

    test(
      'a missing counterparty on either side does not block a match',
      () async {
        expect(await check(reading(merchant: null)), 'scan-old');
        expect(
          await check(reading(), txs: [saved(merchant: null)]),
          'scan-old',
        );
      },
    );

    test(
      'a reference that merely contains the saved one: not flagged',
      () async {
        // Everything else equal; only the references differ, one containing
        // the other. Equality, not substring, decides.
        expect(await check(reading(reference: 'X$ref')), isNull);
        expect(
          await check(reading(), txs: [saved(reference: 'X$ref')]),
          isNull,
        );
      },
    );

    test('a 7-character reference is too weak, even if identical', () async {
      expect(
        await check(
          reading(reference: 'ABC1234'),
          txs: [saved(reference: 'ABC1234')],
        ),
        isNull,
      );
    });

    test('an 8-character reference is enough', () async {
      expect(
        await check(
          reading(reference: 'ABC12345'),
          txs: [saved(reference: 'ABC12345')],
        ),
        'scan-old',
      );
    });

    test('no reference, or no amount, on the slip: never flagged', () async {
      expect(await check(reading(reference: null)), isNull);
      expect(await check(reading(minor: null)), isNull);
    });

    test('a transaction without a scan link cannot be pointed at', () async {
      expect(await check(reading(), txs: [saved(scanRecordId: null)]), isNull);
    });

    test('the scan being checked is never its own duplicate', () async {
      expect(
        await check(reading(), txs: [saved(scanRecordId: 'scan-new')]),
        isNull,
      );
    });

    test('with two matches the older transaction wins', () async {
      final newer = saved(
        id: 'tx-2',
        scanRecordId: 'scan-newer',
        createdAt: time.add(const Duration(days: 1)),
      );
      expect(await check(reading(), txs: [newer, saved()]), 'scan-old');
    });
  });

  group('normalizeReference', () {
    String? n(String? s) => ReferenceDuplicateDetector.normalizeReference(s);

    test('ignores case, spaces, dashes and punctuation', () {
      expect(n(' ab-12 cd.34 ef '), 'AB12CD34EF');
    });

    test('Thai digits become Arabic digits', () {
      expect(n('REF๐๐๐๑๒๓๔๕'), 'REF00012345');
    });

    test('too short or empty becomes null', () {
      expect(n('ABC1234'), isNull);
      expect(n('---- ----'), isNull);
      expect(n(null), isNull);
    });
  });
}
