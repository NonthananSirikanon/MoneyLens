import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/features/slip_import/domain/extracted_fields.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';

void main() {
  group('ScanStatus transitions', () {
    test('only needs_review can become confirmed', () {
      final canConfirm = ScanStatus.values.where(
        (s) => s.canTransitionTo(ScanStatus.confirmed),
      );
      expect(canConfirm, [ScanStatus.needsReview]);
    });

    test('processing cannot jump straight to confirmed', () {
      expect(
        ScanStatus.processing.canTransitionTo(ScanStatus.confirmed),
        isFalse,
      );
    });

    test('confirmed and discarded are terminal', () {
      for (final next in ScanStatus.values) {
        expect(ScanStatus.confirmed.canTransitionTo(next), isFalse);
        expect(ScanStatus.discarded.canTransitionTo(next), isFalse);
      }
    });

    test('failed scans can be retried or discarded', () {
      expect(ScanStatus.failed.canTransitionTo(ScanStatus.queued), isTrue);
      expect(ScanStatus.failed.canTransitionTo(ScanStatus.discarded), isTrue);
    });

    test('db values round-trip', () {
      for (final status in ScanStatus.values) {
        expect(ScanStatus.fromDb(status.dbValue), status);
      }
      expect(ScanStatus.needsReview.dbValue, 'needs_review');
      expect(ImportSource.shareSheet.dbValue, 'share_sheet');
    });
  });

  group('ExtractedFields', () {
    test('reports missing required fields for review', () {
      expect(const ExtractedFields().missingRequiredFields, [
        ReviewField.amount,
        ReviewField.occurredAt,
        ReviewField.type,
      ]);
    });

    test('round-trips through the versioned JSON payload', () {
      final fields = ExtractedFields(
        amountMinor: const ExtractedField(12345, confidence: 0.92),
        currencyCode: 'THB',
        occurredAt: ExtractedField(DateTime.utc(2026, 10, 14, 3)),
        type: const ExtractedField(TransactionType.expense, confidence: 0.6),
      );
      final decoded = ExtractedFields.fromJson(fields.toJson());

      expect(decoded.amountMinor!.value, 12345);
      expect(decoded.amountMinor!.confidence, 0.92);
      expect(decoded.occurredAt!.value, DateTime.utc(2026, 10, 14, 3));
      expect(decoded.type!.value, TransactionType.expense);
      expect(decoded.merchant, isNull);
      expect(decoded.missingRequiredFields, isEmpty);
    });

    test('rejects unknown payload versions', () {
      expect(() => ExtractedFields.fromJson({'v': 99}), throwsFormatException);
    });
  });
}
