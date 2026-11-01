import 'dart:async';

import '../features/slip_import/application/scan_details.dart';
import '../features/slip_import/application/slip_queue.dart';
import '../features/transactions/domain/transaction.dart';
import '../features/slip_import/domain/scan_record.dart';
import '../features/slip_import/domain/scan_status.dart';
import '../features/transactions/application/transaction_providers.dart';
import 'demo_harness.dart';
import 'demo_seed.dart';

/// The slip queue of sample mode (`ML_SAMPLE_DATA`): the prototype's queue,
/// in memory, with a simulated camera, gallery and OCR. Nothing is stored,
/// read or recognised. Wired in by `demoOverrides`; production code never
/// refers to it.
class DemoSlipQueue extends SlipQueue {
  final _timers = <Timer>[];
  var _idCounter = 0;

  @override
  SlipQueueState build() {
    ref.onDispose(() {
      for (final t in _timers) {
        t.cancel();
      }
    });
    final seed = ref.read(demoSeedProvider);
    final (scans, details) = seed.scans();
    return SlipQueueState(
      scans: scans,
      scanDetails: details,
      transactionImportSources: DemoSeed.transactionImportSources,
    );
  }

  String _nextId(String prefix) =>
      '$prefix-${now.microsecondsSinceEpoch}-${_idCounter++}';

  // Nothing is stored, so there is nothing to load.
  @override
  Future<void> load() async {}

  @override
  Future<void> refresh() async {}

  /// A camera import simulates a capture and starts reading it; a gallery
  /// import simulates picking two images, each "read" a moment later.
  /// Returns the first new scan.
  @override
  Future<ScanRecord?> importFrom(ImportSource source) async {
    final seed = ref.read(demoSeedProvider);
    if (source == ImportSource.camera) {
      final id = _addScan(ImportSource.camera, 'IMG_2050.jpg');
      _runOcr(id, seed.cameraReading);
      return state.scan(id);
    }
    final readings = seed.galleryReadings;
    final ids = [
      _addScan(source, 'IMG_2051.jpg'),
      _addScan(source, 'IMG_2052.jpg'),
    ];
    for (var i = 0; i < ids.length; i++) {
      _timers.add(
        Timer(Duration(milliseconds: 1800 + i * 1400), () {
          if (state.scan(ids[i])?.status != ScanStatus.processing) return;
          _completeRead(ids[i], readings[i]);
        }),
      );
    }
    return state.scan(ids.first);
  }

  @override
  Future<void> keepDuplicate(String scanId) async {}

  /// Re-reads a failed scan using its prepared retry result.
  @override
  void retry(String scanId) {
    final reading = state.scanDetails[scanId]?.retryReading;
    if (reading == null) return;
    updateScan(scanId, status: ScanStatus.processing);
    _runOcr(scanId, reading);
  }

  @override
  void discard(String scanId) {
    final scan = state.scan(scanId);
    if (scan == null) return;
    if (scan.status == ScanStatus.duplicate) {
      _setTitleKind(scanId, ScanTitleKind.discardedDuplicate);
    }
    updateScan(scanId, status: ScanStatus.discarded);
  }

  @override
  void remove(String scanId) {
    state = state.copyWith(
      scans: [
        for (final s in state.scans)
          if (s.id != scanId) s,
      ],
    );
  }

  /// Saves the transaction with the sample slip image and marks the scan
  /// confirmed.
  @override
  Future<String> saveReviewed(ScanRecord scan, TransactionDraft draft) async {
    final tx = await ref
        .read(createTransactionProvider)
        .call(
          TransactionDraft(
            type: draft.type,
            amount: draft.amount,
            accountId: draft.accountId,
            destinationAccountId: draft.destinationAccountId,
            categoryId: draft.categoryId,
            merchant: draft.merchant,
            note: draft.note,
            occurredAt: draft.occurredAt,
            source: draft.source,
            attachmentPath: demoSlipImage,
          ),
        );
    state = state.copyWith(
      transactionImportSources: {
        ...state.transactionImportSources,
        tx.id: scan.source,
      },
    );
    updateScan(scan.id, status: ScanStatus.confirmed, transactionId: tx.id);
    _setTitleKind(
      scan.id,
      ScanTitleKind.reading,
      reading: SlipReading(
        merchant: tx.merchant ?? '',
        amountText: tx.amount.toDecimalString(),
        occurredAt: tx.occurredAt,
        categoryId: tx.categoryId,
        accountId: tx.accountId,
      ),
    );
    return tx.id;
  }

  String _addScan(ImportSource source, String fileName) {
    final at = now;
    final id = _nextId('scan');
    state = state.copyWith(
      scans: [
        ScanRecord(
          id: id,
          source: source,
          attachmentPath: demoSlipImage,
          status: ScanStatus.processing,
          createdAt: at,
          updatedAt: at,
        ),
        ...state.scans,
      ],
      scanDetails: {
        ...state.scanDetails,
        id: ScanDetails(fileName: fileName),
      },
    );
    return id;
  }

  /// 2.5% every 60ms, as in the prototype's `runOcr`.
  void _runOcr(String scanId, SlipReading reading) {
    state = state.copyWith(ocrProgress: {...state.ocrProgress, scanId: 0});
    late final Timer timer;
    timer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      final pct = ((state.ocrProgress[scanId] ?? 0) + 2.5).clamp(0, 100);
      state = state.copyWith(
        ocrProgress: {...state.ocrProgress, scanId: pct.toDouble()},
      );
      if (pct >= 100) {
        timer.cancel();
        _completeRead(scanId, reading);
      }
    });
    _timers.add(timer);
  }

  void _completeRead(String scanId, SlipReading reading) {
    updateScan(scanId, status: ScanStatus.needsReview);
    _setTitleKind(scanId, ScanTitleKind.reading, reading: reading);
  }

  void _setTitleKind(String id, ScanTitleKind kind, {SlipReading? reading}) {
    final details = state.scanDetails[id];
    if (details == null) return;
    state = state.copyWith(
      scanDetails: {
        ...state.scanDetails,
        id: details.copyWith(titleKind: kind, reading: reading),
      },
    );
  }
}
