import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../demo/demo_models.dart';
import '../../../demo/demo_store.dart';
import '../domain/scan_record.dart';

/// A queue entry: the scan lifecycle record plus its demo side data.
@immutable
class ScanView {
  const ScanView({required this.scan, required this.details});

  final ScanRecord scan;
  final ScanDetails? details;
}

/// Every imported slip, newest first (SL-10 queue).
final scanViewsProvider = Provider<List<ScanView>>((ref) {
  final s = ref.watch(appStoreProvider);
  return [
    for (final scan in s.scans)
      ScanView(scan: scan, details: s.scanDetails[scan.id]),
  ];
});

final scanViewProvider = Provider.family<ScanView?, String>((ref, id) {
  final s = ref.watch(appStoreProvider);
  final scan = s.scan(id);
  return scan == null
      ? null
      : ScanView(scan: scan, details: s.scanDetails[scan.id]);
});

/// Simulated OCR progress (0–100) for [scanId].
final ocrProgressProvider = Provider.family<double, String>(
  (ref, scanId) => ref.watch(appStoreProvider).ocrProgress[scanId] ?? 0,
);

/// Pending scans in queue order (needs review or possible duplicate).
final pendingScansProvider = Provider<List<ScanRecord>>((ref) {
  ref.watch(appStoreProvider);
  return ref.read(appStoreProvider.notifier).pending;
});
