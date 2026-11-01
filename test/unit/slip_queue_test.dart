import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/errors/app_failure.dart';
import 'package:moneylens/features/slip_import/application/slip_import_providers.dart';
import 'package:moneylens/features/slip_import/application/slip_queue.dart';
import 'package:moneylens/features/slip_import/domain/extracted_fields.dart';
import 'package:moneylens/features/slip_import/domain/scan_record.dart';
import 'package:moneylens/features/slip_import/domain/scan_repository.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';

/// Reads of the visible scans that finish when the test says so.
class _SlowScans implements ScanRepository {
  final reads = <Completer<List<ScanRecord>>>[];

  @override
  Future<List<ScanRecord>> findVisible() {
    final read = Completer<List<ScanRecord>>();
    reads.add(read);
    return read.future;
  }

  @override
  Future<ScanRecord?> findById(String id) async => null;

  @override
  Future<ScanRecord> create({
    required String id,
    required ImportSource source,
    required String attachmentPath,
    required String imageFingerprint,
  }) => throw UnimplementedError();

  @override
  Future<List<ScanRecord>> findByFingerprint(String fingerprint) =>
      throw UnimplementedError();

  @override
  Stream<List<ScanRecord>> watchVisible() => throw UnimplementedError();

  @override
  Future<ScanRecord> transition(
    String id,
    ScanStatus next, {
    ExtractedFields? extracted,
    FailureCode? failureCode,
    String? duplicateOfScanId,
    String? processorVersion,
    bool clearAttachment = false,
  }) => throw UnimplementedError();

  @override
  Future<int> requeueInterrupted() => throw UnimplementedError();
}

void main() {
  final at = DateTime.utc(2026, 10, 30);
  ScanRecord scan(String id) => ScanRecord(
    id: id,
    source: ImportSource.gallery,
    attachmentPath: 'p',
    status: ScanStatus.needsReview,
    createdAt: at,
    updatedAt: at,
  );

  test(
    'a slower, older read of the queue never overwrites a newer one',
    () async {
      final scans = _SlowScans();
      final c = ProviderContainer(
        overrides: [scanRepositoryProvider.overrideWithValue(scans)],
      );
      addTearDown(c.dispose);
      final queue = c.read(slipQueueProvider.notifier);

      final older = queue.refresh();
      final newer = queue.refresh();
      scans.reads[1].complete([scan('newer')]);
      await newer;
      expect(c.read(slipQueueProvider).scans.map((s) => s.id), ['newer']);

      scans.reads[0].complete([scan('older')]);
      await older;
      expect(c.read(slipQueueProvider).scans.map((s) => s.id), ['newer']);
    },
  );

  test('a discard is not undone by a read that started before it', () async {
    final scans = _SlowScans();
    final c = ProviderContainer(
      overrides: [scanRepositoryProvider.overrideWithValue(scans)],
    );
    addTearDown(c.dispose);
    final queue = c.read(slipQueueProvider.notifier);

    final first = queue.refresh();
    scans.reads[0].complete([scan('a')]);
    await first;

    final inFlight = queue.refresh(); // started while 'a' still needs review
    queue.discard('a');
    expect(c.read(slipQueueProvider).scan('a')!.status, ScanStatus.discarded);
    scans.reads[1].complete([scan('a')]); // the old answer arrives late
    await inFlight;
    expect(c.read(slipQueueProvider).scan('a')!.status, ScanStatus.discarded);
  });

  test('another account\'s database starts from an empty queue', () async {
    final repos = [_SlowScans(), _SlowScans()];
    final generation = NotifierProvider<_Counter, int>(_Counter.new);
    final c = ProviderContainer(
      overrides: [
        scanRepositoryProvider.overrideWith(
          (ref) => repos[ref.watch(generation)],
        ),
      ],
    );
    addTearDown(c.dispose);
    final sub = c.listen(slipQueueProvider, (_, _) {});
    addTearDown(sub.close);

    final load = c.read(slipQueueProvider.notifier).refresh();
    repos[0].reads[0].complete([
      ScanRecord(
        id: 'mine',
        source: ImportSource.gallery,
        attachmentPath: 'p',
        status: ScanStatus.confirmed,
        transactionId: 'tx',
        createdAt: at,
        updatedAt: at,
      ),
    ]);
    await load;
    expect(c.read(slipQueueProvider).scans, hasLength(1));
    expect(c.read(slipQueueProvider).transactionImportSources, isNotEmpty);

    c.read(generation.notifier).bump();
    final state = c.read(slipQueueProvider);
    expect(state.scans, isEmpty);
    expect(state.transactionImportSources, isEmpty);
  });
}

class _Counter extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
