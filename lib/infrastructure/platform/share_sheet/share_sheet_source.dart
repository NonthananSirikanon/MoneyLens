import '../../../features/slip_import/domain/import_ports.dart';

/// Share Sheet intake: not wired yet.
///
/// Android needs an `ACTION_SEND` intent filter and iOS needs a native Share
/// Extension target plus an App Group. Both are platform work for the
/// ROADMAP week 1–2 prototype. Until then this source emits nothing; the
/// app already routes anything it emits into the shared import pipeline.
class UnavailableShareSheetSource implements IncomingImageSource {
  const UnavailableShareSheetSource();

  @override
  Stream<ImportRequest> get incoming => const Stream.empty();
}
