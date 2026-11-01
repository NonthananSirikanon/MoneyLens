import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/scan_record.dart';
import '../domain/scan_status.dart';
import 'scan_details.dart';
import 'slip_queue.dart';

/// A queue entry: the scan lifecycle record plus its demo side data.
@immutable
class ScanView {
  const ScanView({required this.scan, required this.details});

  final ScanRecord scan;
  final ScanDetails? details;
}

/// Every imported slip, newest first (SL-10 queue).
final scanViewsProvider = Provider<List<ScanView>>((ref) {
  final s = ref.watch(slipQueueProvider);
  return [
    for (final scan in s.scans)
      ScanView(scan: scan, details: s.scanDetails[scan.id]),
  ];
});

final scanViewProvider = Provider.family<ScanView?, String>((ref, id) {
  final s = ref.watch(slipQueueProvider);
  final scan = s.scan(id);
  return scan == null
      ? null
      : ScanView(scan: scan, details: s.scanDetails[scan.id]);
});

/// OCR progress (0–100) for [scanId].
final ocrProgressProvider = Provider.family<double, String>(
  (ref, scanId) => ref.watch(slipQueueProvider).ocrProgress[scanId] ?? 0,
);

/// Pending scans in queue order (needs review or possible duplicate).
final pendingScansProvider = Provider<List<ScanRecord>>(
  (ref) => ref.watch(slipQueueProvider).pending,
);

/// How the slip behind transaction [transactionId] was imported, or null for
/// a manual entry.
final transactionImportSourceProvider = Provider.family<ImportSource?, String>(
  (ref, transactionId) => ref.watch(
    slipQueueProvider.select((s) => s.transactionImportSources[transactionId]),
  ),
);
