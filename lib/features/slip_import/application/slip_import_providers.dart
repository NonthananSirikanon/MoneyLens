import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/id_generator.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../../infrastructure/ocr/platform_ocr_service.dart';
import '../../../infrastructure/platform/gallery/image_picker_source.dart';
import '../../../infrastructure/platform/share_sheet/share_sheet_source.dart';
import '../../transactions/application/transaction_providers.dart';
import '../data/drift_scan_repository.dart';
import '../data/fingerprint_duplicate_detector.dart';
import '../data/local_slip_image_store.dart';
import '../data/magic_byte_image_validator.dart';
import '../data/thai_slip_extraction_service.dart';
import '../domain/import_ports.dart';
import '../domain/scan_record.dart';
import '../domain/scan_repository.dart';
import '../domain/scan_status.dart';
import 'confirm_scan.dart';
import 'slip_import_pipeline.dart';

final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) => DriftScanRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final slipImageStoreProvider = Provider<SlipImageStore>(
  (ref) => LocalSlipImageStore(ref.watch(idGeneratorProvider)),
);

/// Swap this binding to plug in another OCR engine.
///
/// Tesseract (Android) reads each slip up to three times, preparing the
/// image differently each time, and stops after two readings that agree.
/// Apple Vision reads it once.
final ocrServiceProvider = Provider<OcrService>(
  (ref) => PlatformOcrService(
    passes: defaultTargetPlatform == TargetPlatform.android ? 3 : 1,
    enough: (readings) =>
        ThaiSlipExtractionService.readingsAgree(readings[0], readings[1]),
  ),
);

final extractionServiceProvider = Provider<ExtractionService>(
  (ref) => const ThaiSlipExtractionService(),
);

final imageSourcesProvider = Provider<Map<ImportSource, ImageSourceAdapter>>(
  (ref) => {
    ImportSource.camera: ImagePickerSource.camera(),
    ImportSource.gallery: ImagePickerSource.gallery(),
  },
);

final shareSheetSourceProvider = Provider<IncomingImageSource>(
  (ref) => const UnavailableShareSheetSource(),
);

final slipImportPipelineProvider = Provider<SlipImportPipeline>((ref) {
  final scans = ref.watch(scanRepositoryProvider);
  return SlipImportPipeline(
    validator: const MagicByteImageValidator(),
    store: ref.watch(slipImageStoreProvider),
    scans: scans,
    duplicates: FingerprintDuplicateDetector(scans),
    ocr: ref.watch(ocrServiceProvider),
    extraction: ref.watch(extractionServiceProvider),
    ids: ref.watch(idGeneratorProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final confirmScanProvider = Provider<ConfirmScan>(
  (ref) => ConfirmScan(
    ref.watch(transactionDraftCheckerProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

final visibleScansProvider = StreamProvider<List<ScanRecord>>(
  (ref) => ref.watch(scanRepositoryProvider).watchVisible(),
);
