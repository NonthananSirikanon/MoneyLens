import 'package:flutter/foundation.dart' show immutable;

/// What the slip queue and the review screen know about a scan beyond its
/// lifecycle record: what was read, and how its title is built.

/// How sure the OCR is about one review field.
enum FieldConfidence { verified, uncertain, missing }

/// The review fields that carry an OCR confidence.
enum ReadingField { amount, date, time, merchant, category }

/// One OCR result for a slip, in the shape the review screen needs.
///
/// [amountText] is the raw text as read, which may be malformed (the
/// prototype's `1,20.00`), so it is not a [Money].
@immutable
class SlipReading {
  const SlipReading({
    required this.merchant,
    required this.amountText,
    required this.occurredAt,
    this.accountId,
    this.categoryId,
    this.providerReference,
    this.confidence = const {},
  });

  final String merchant;
  final String amountText;

  /// UTC instant printed on the slip.
  final DateTime occurredAt;

  /// The account the slip belongs to, when known (a slip does not say; the
  /// review screen then offers the most used account).
  final String? accountId;
  final String? categoryId;
  final String? providerReference;
  final Map<ReadingField, FieldConfidence> confidence;
}

/// How a scan's queue title is built.
enum ScanTitleKind {
  /// The image file name, before a successful read.
  fileName,

  /// `merchant · ฿amount` from the reading.
  reading,

  /// A discarded duplicate: "Duplicate slip · ฿amount".
  discardedDuplicate,
}

/// Side data for a [ScanRecord].
@immutable
class ScanDetails {
  const ScanDetails({
    required this.fileName,
    this.reading,
    this.retryReading,
    this.duplicateOfTransactionId,
    this.titleKind = ScanTitleKind.fileName,
  });

  final String fileName;

  /// Present once the slip has been read.
  final SlipReading? reading;

  /// What a retry of a failed read will produce (sample mode only).
  final SlipReading? retryReading;

  /// The saved transaction a `duplicate` scan matches.
  final String? duplicateOfTransactionId;
  final ScanTitleKind titleKind;

  ScanDetails copyWith({SlipReading? reading, ScanTitleKind? titleKind}) =>
      ScanDetails(
        fileName: fileName,
        reading: reading ?? this.reading,
        retryReading: retryReading,
        duplicateOfTransactionId: duplicateOfTransactionId,
        titleKind: titleKind ?? this.titleKind,
      );
}
