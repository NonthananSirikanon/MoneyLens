import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/features/slip_import/application/slip_queue.dart';
import 'package:moneylens/features/slip_import/domain/scan_record.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';

import '../support/test_support.dart';

/// The simulated slip queue of sample mode (`lib/demo`), driven through the
/// same `slipQueueProvider` the UI uses.
void main() {
  final now = ReportingTimeZone.bangkok.toUtc(2026, 10, 24, 10, 45);

  Future<ProviderContainer> container() => sampleContainer(now);

  group('simulated slip queue', () {
    test('a capture is read, then needs review', () async {
      final c = await container();
      final queue = c.read(slipQueueProvider.notifier);
      fakeAsync((async) {
        ScanRecord? scan;
        queue.importFrom(ImportSource.camera).then((s) => scan = s);
        async.flushMicrotasks();
        final id = scan!.id;
        expect(
          c.read(slipQueueProvider).scan(id)!.status,
          ScanStatus.processing,
        );
        async.elapse(const Duration(seconds: 3));
        final s = c.read(slipQueueProvider);
        expect(s.scan(id)!.status, ScanStatus.needsReview);
        expect(s.scanDetails[id]!.reading!.merchant, 'Café Amazon สาขาสามย่าน');
      });
    });

    test('picking from the gallery adds two slips that are read', () async {
      final c = await container();
      final queue = c.read(slipQueueProvider.notifier);
      final before = c.read(slipQueueProvider).scans.length;
      fakeAsync((async) {
        queue.importFrom(ImportSource.gallery);
        async.flushMicrotasks();
        expect(c.read(slipQueueProvider).scans.length, before + 2);
        async.elapse(const Duration(seconds: 4));
        expect(
          c.read(slipQueueProvider).scans.take(2).map((s) => s.status),
          everyElement(ScanStatus.needsReview),
        );
      });
    });

    test('retrying a failed read uses its prepared result', () async {
      final c = await container();
      final queue = c.read(slipQueueProvider.notifier);
      fakeAsync((async) {
        queue.retry('s3');
        expect(
          c.read(slipQueueProvider).scan('s3')!.status,
          ScanStatus.processing,
        );
        async.elapse(const Duration(seconds: 3));
        expect(
          c.read(slipQueueProvider).scan('s3')!.status,
          ScanStatus.needsReview,
        );
      });
    });

    test('discarding a duplicate leaves one pending slip', () async {
      final c = await container();
      c.read(slipQueueProvider.notifier).discard('s2');
      final s = c.read(slipQueueProvider);
      expect(s.scan('s2')!.status, ScanStatus.discarded);
      expect(s.pending.map((s) => s.id), ['s1']);
    });
  });
}
