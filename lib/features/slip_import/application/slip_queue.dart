import 'dart:async';

import 'package:flutter/foundation.dart' show immutable, protected;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../transactions/application/transaction_providers.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/extracted_fields.dart';
import '../domain/scan_record.dart';
import '../domain/scan_status.dart';
import 'scan_details.dart';
import 'slip_import_providers.dart';

/// The slip queue as the UI sees it: every visible scan (newest first) with
/// what was read from it.
@immutable
class SlipQueueState {
  const SlipQueueState({
    this.scans = const [],
    this.scanDetails = const {},
    this.ocrProgress = const {},
    this.transactionImportSources = const {},
  });

  /// Newest first.
  final List<ScanRecord> scans;
  final Map<String, ScanDetails> scanDetails;

  /// OCR progress (0-100) for scans being read.
  final Map<String, double> ocrProgress;

  /// Import source of slip-backed transactions (for the "source" row).
  final Map<String, ImportSource> transactionImportSources;

  SlipQueueState copyWith({
    List<ScanRecord>? scans,
    Map<String, ScanDetails>? scanDetails,
    Map<String, double>? ocrProgress,
    Map<String, ImportSource>? transactionImportSources,
  }) => SlipQueueState(
    scans: scans ?? this.scans,
    scanDetails: scanDetails ?? this.scanDetails,
    ocrProgress: ocrProgress ?? this.ocrProgress,
    transactionImportSources:
        transactionImportSources ?? this.transactionImportSources,
  );

  ScanRecord? scan(String? id) {
    for (final s in scans) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Scans that still need the user's decision, in queue order.
  List<ScanRecord> get pending => [
    for (final s in scans)
      if (s.status == ScanStatus.needsReview ||
          s.status == ScanStatus.duplicate)
        s,
  ];
}

/// The slip queue: slips picked or shared by the user, read on the device by
/// `SlipImportPipeline`, waiting for review. The scans live in the database;
/// this keeps their latest read for the UI.
///
/// Sample mode (`ML_SAMPLE_DATA`) replaces this class with a simulated queue
/// from `lib/demo`; the methods below are what that queue stands in for.
class SlipQueue extends Notifier<SlipQueueState> {
  @override
  SlipQueueState build() {
    // The queue belongs to the signed-in user's database. When the repository
    // is rebuilt (another account's database), start from an empty queue.
    ref.watch(scanRepositoryProvider);
    return const SlipQueueState();
  }

  // Each database read carries a sequence number and only the newest one is
  // applied, so a slower, older read can never overwrite newer data.
  var _seq = 0;

  @protected
  DateTime get now => ref.read(clockProvider).nowUtc();

  /// Loads the queue from the database, and resumes any scan the app was
  /// killed in the middle of.
  Future<void> load() async {
    await refresh();
    for (final s in state.scans) {
      if (s.status == ScanStatus.queued) unawaited(_process(s.id));
    }
  }

  /// Re-reads the queue from the database.
  Future<void> refresh() async {
    final seq = ++_seq;
    final repo = ref.read(scanRepositoryProvider);
    final scans = await repo.findVisible();
    // A duplicate points at the scan it repeats; show that scan's reading
    // and, when it was saved, its transaction.
    final byId = {for (final s in scans) s.id: s};
    final originals = <String, ScanRecord>{};
    for (final s in scans) {
      final of = s.duplicateOfScanId;
      if (s.status == ScanStatus.duplicate && of != null) {
        final original = byId[of] ?? await repo.findById(of);
        if (original != null) originals[s.id] = original;
      }
    }
    if (!ref.mounted || seq != _seq) return;
    state = state.copyWith(
      scans: scans,
      scanDetails: {
        for (final s in scans) s.id: _detailsOf(s, originals[s.id]),
      },
      ocrProgress: {for (final s in scans) s.id: _progressOf(s.status)},
      transactionImportSources: {
        ...state.transactionImportSources,
        for (final s in scans)
          if (s.transactionId != null) s.transactionId!: s.source,
      },
    );
  }

  /// There is no real percentage: report where the scan is, honestly.
  static double _progressOf(ScanStatus status) => switch (status) {
    ScanStatus.queued => 15,
    ScanStatus.processing => 60,
    _ => 100,
  };

  static ScanDetails _detailsOf(ScanRecord s, ScanRecord? original) {
    final fields = s.extracted ?? original?.extracted;
    return ScanDetails(
      fileName: '',
      reading: fields == null ? null : _readingOf(fields, s.createdAt),
      duplicateOfTransactionId: original?.transactionId,
      titleKind: fields == null
          ? ScanTitleKind.fileName
          : ScanTitleKind.reading,
    );
  }

  /// What the review screen shows for what was read. Nothing here is a
  /// verdict: confidence only decides how loudly a field is flagged.
  static SlipReading _readingOf(ExtractedFields f, DateTime fallbackTime) {
    FieldConfidence level(ExtractedField<Object?>? field) {
      if (field == null) return FieldConfidence.missing;
      return (field.confidence ?? 0) >= 0.8
          ? FieldConfidence.verified
          : FieldConfidence.uncertain;
    }

    final minor = f.amountMinor?.value;
    return SlipReading(
      merchant: f.merchant?.value ?? '',
      amountText: minor == null
          ? ''
          : Money(minor, Currency.thb).toDecimalString(),
      occurredAt: f.occurredAt?.value ?? fallbackTime,
      providerReference: f.providerReference?.value,
      confidence: {
        ReadingField.amount: level(f.amountMinor),
        ReadingField.date: level(f.occurredAt),
        ReadingField.time: level(f.occurredAt),
        ReadingField.merchant: level(f.merchant),
        // A slip does not say which category the user files it under.
        ReadingField.category: FieldConfidence.missing,
      },
    );
  }

  /// Runs the pipeline on a queued scan, refreshing the queue when it ends.
  Future<void> _process(String scanId) async {
    try {
      await ref.read(slipImportPipelineProvider).process(scanId);
    } on Object {
      // The pipeline records the failure on the scan; nothing else to do.
    }
    await refresh();
  }

  /// Lets the user pick or take a photo, stores it and starts reading it in
  /// the background. Returns the new scan, or null when the user cancelled.
  /// Throws [AppFailure] (permission denied, a file that is not an image,
  /// ...).
  Future<ScanRecord?> importFrom(ImportSource source) async {
    final adapter = ref.read(imageSourcesProvider)[source];
    if (adapter == null) throw const AppFailure(FailureCode.notImplemented);
    final request = await adapter.acquire();
    if (request == null) return null;
    final scan = await ref.read(slipImportPipelineProvider).accept(request);
    await refresh();
    unawaited(_process(scan.id));
    return scan;
  }

  /// "This is not a duplicate": reads the slip after all and moves it to
  /// review.
  Future<void> keepDuplicate(String scanId) async {
    await ref.read(slipImportPipelineProvider).keepDuplicate(scanId);
    await refresh();
  }

  /// Re-reads a failed scan.
  void retry(String scanId) {
    _seq++; // an in-flight read must not restore the old status
    updateScan(scanId, status: ScanStatus.processing);
    unawaited(_retry(scanId));
  }

  Future<void> _retry(String scanId) async {
    try {
      await ref.read(slipImportPipelineProvider).retry(scanId);
    } on Object {
      // Recorded on the scan.
    }
    await refresh();
  }

  /// Takes the scan out of the queue.
  void discard(String scanId) {
    if (state.scan(scanId) == null) return;
    _seq++; // an in-flight read must not restore the old status
    updateScan(scanId, status: ScanStatus.discarded);
    unawaited(_discard(scanId));
  }

  Future<void> _discard(String scanId) async {
    try {
      await ref.read(slipImportPipelineProvider).discard(scanId);
    } on Object {
      // Already gone or not discardable; the refresh shows the truth.
    }
    await refresh();
  }

  /// Removes a finished scan from the list.
  void remove(String scanId) => discard(scanId);

  /// Saves the reviewed slip through `ConfirmScan`, which creates the
  /// transaction and confirms the scan in one database transaction and is
  /// safe to repeat. Returns the transaction id; the ledger has reloaded by
  /// then.
  Future<String> saveReviewed(ScanRecord scan, TransactionDraft draft) async {
    final result = await ref
        .read(confirmScanProvider)
        .call(
          scanId: scan.id,
          // The repository sets the source (ocr) and the slip image itself.
          reviewedDraft: draft,
        );
    await refresh();
    await reloadTransactions(ref);
    return result.transaction.id;
  }

  /// Forgets every scan (after "delete all data", whose rows are gone).
  void clear() => state = const SlipQueueState();

  @protected
  void updateScan(String id, {ScanStatus? status, String? transactionId}) {
    state = state.copyWith(
      scans: [
        for (final s in state.scans)
          if (s.id == id)
            ScanRecord(
              id: s.id,
              source: s.source,
              attachmentPath: s.attachmentPath,
              imageFingerprint: s.imageFingerprint,
              extracted: s.extracted,
              status: status ?? s.status,
              failureCode: s.failureCode,
              duplicateOfScanId: s.duplicateOfScanId,
              transactionId: transactionId ?? s.transactionId,
              processorVersion: s.processorVersion,
              createdAt: s.createdAt,
              updatedAt: now,
              processedAt: s.processedAt,
            )
          else
            s,
      ],
    );
  }
}

final slipQueueProvider = NotifierProvider<SlipQueue, SlipQueueState>(
  SlipQueue.new,
);
