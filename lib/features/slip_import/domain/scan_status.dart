/// Where an imported image came from. Every source enters the same
/// pipeline (PROJECT.md SL-04).
enum ImportSource {
  camera('camera'),
  gallery('gallery'),
  shareSheet('share_sheet'),

  /// Automatic discovery of saved images. Reserved: not implemented until
  /// the SL-12 platform validation gate is passed.
  discovery('discovery');

  const ImportSource(this.dbValue);

  final String dbValue;

  static ImportSource fromDb(String value) =>
      values.firstWhere((s) => s.dbValue == value);
}

/// Persistent scan lifecycle (DATABASE.md §3.4).
enum ScanStatus {
  queued('queued'),
  processing('processing'),
  needsReview('needs_review'),
  confirmed('confirmed'),
  duplicate('duplicate'),
  failed('failed'),
  discarded('discarded');

  const ScanStatus(this.dbValue);

  final String dbValue;

  static ScanStatus fromDb(String value) =>
      values.firstWhere((s) => s.dbValue == value);

  bool get isTerminal => this == confirmed || this == discarded;

  /// Allowed lifecycle moves. Notably, nothing reaches [confirmed] except
  /// from [needsReview]: OCR completion alone never confirms a transaction.
  bool canTransitionTo(ScanStatus next) => switch (this) {
    queued => next == processing || next == discarded,
    // `queued` here is crash recovery for work interrupted mid-flight.
    processing => const {needsReview, duplicate, failed, queued}.contains(next),
    needsReview => const {confirmed, discarded, queued}.contains(next),
    // The user may decide a flagged duplicate is genuine.
    duplicate => next == needsReview || next == discarded,
    failed => next == queued || next == discarded,
    confirmed || discarded => false,
  };
}
