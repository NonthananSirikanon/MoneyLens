import '../../transactions/domain/transaction_type.dart';

/// A candidate value pulled from a slip, with optional per-field confidence
/// in `[0, 1]` when the provider reports it. Candidates are untrusted data
/// until a user reviews them.
class ExtractedField<T> {
  const ExtractedField(this.value, {this.confidence});

  final T value;
  final double? confidence;
}

/// Structured extraction output stored as versioned JSON in
/// `scan_records.extracted_payload`.
class ExtractedFields {
  const ExtractedFields({
    this.amountMinor,
    this.currencyCode,
    this.occurredAt,
    this.type,
    this.merchant,
    this.providerReference,
  });

  static const payloadVersion = 1;

  final ExtractedField<int>? amountMinor;
  final String? currencyCode;
  final ExtractedField<DateTime>? occurredAt;
  final ExtractedField<TransactionType>? type;
  final ExtractedField<String>? merchant;
  final ExtractedField<String>? providerReference;

  /// Required fields that are absent and must be supplied during review
  /// (PROJECT.md SL-07).
  List<ReviewField> get missingRequiredFields => [
    if (amountMinor == null) ReviewField.amount,
    if (occurredAt == null) ReviewField.occurredAt,
    if (type == null) ReviewField.type,
  ];

  Map<String, Object?> toJson() => {
    'v': payloadVersion,
    'amountMinor': _field(amountMinor, (v) => v),
    'currencyCode': currencyCode,
    'occurredAt': _field(occurredAt, (v) => v.toUtc().toIso8601String()),
    'type': _field(type, (v) => v.dbValue),
    'merchant': _field(merchant, (v) => v),
    'providerReference': _field(providerReference, (v) => v),
  };

  factory ExtractedFields.fromJson(Map<String, Object?> json) {
    final version = json['v'];
    if (version != payloadVersion) {
      throw FormatException('Unsupported extracted payload version: $version');
    }
    return ExtractedFields(
      amountMinor: _read(json['amountMinor'], (v) => v as int),
      currencyCode: json['currencyCode'] as String?,
      occurredAt: _read(
        json['occurredAt'],
        (v) => DateTime.parse(v as String).toUtc(),
      ),
      type: _read(json['type'], (v) => TransactionType.fromDb(v as String)),
      merchant: _read(json['merchant'], (v) => v as String),
      providerReference: _read(json['providerReference'], (v) => v as String),
    );
  }

  static Map<String, Object?>? _field<T>(
    ExtractedField<T>? field,
    Object? Function(T) encode,
  ) => field == null
      ? null
      : {'value': encode(field.value), 'confidence': field.confidence};

  static ExtractedField<T>? _read<T>(Object? raw, T Function(Object?) decode) {
    if (raw is! Map) return null;
    return ExtractedField(
      decode(raw['value']),
      confidence: (raw['confidence'] as num?)?.toDouble(),
    );
  }
}

enum ReviewField { amount, occurredAt, type, account, category, merchant }
