import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../demo/demo_models.dart';
import '../../../app/app_store.dart';
import '../../categories/domain/category.dart';
import '../domain/transaction_type.dart';

/// How the entry screen was opened.
sealed class EntryArgs {
  const EntryArgs();
}

/// "เพิ่มรายการเอง" — a blank manual entry of [type].
final class ManualEntryArgs extends EntryArgs {
  const ManualEntryArgs([this.type = TransactionType.expense]);

  final TransactionType type;

  @override
  bool operator ==(Object other) =>
      other is ManualEntryArgs && other.type == type;

  @override
  int get hashCode => type.hashCode;
}

/// "แก้ไข" from the detail screen.
final class EditEntryArgs extends EntryArgs {
  const EditEntryArgs(this.transactionId);

  final String transactionId;

  @override
  bool operator ==(Object other) =>
      other is EditEntryArgs && other.transactionId == transactionId;

  @override
  int get hashCode => transactionId.hashCode;
}

/// "ตรวจสอบรายการ" — reviewing an OCR reading before saving.
final class ScanEntryArgs extends EntryArgs {
  const ScanEntryArgs(this.scanId);

  final String scanId;

  @override
  bool operator ==(Object other) =>
      other is ScanEntryArgs && other.scanId == scanId;

  @override
  int get hashCode => scanId.hashCode;
}

enum EntryMode { manual, edit, scan }

/// Validation failures, mapped to the prototype's messages in the UI.
enum EntryError {
  amountFormat,
  amountRequired,
  categoryRequired,
  merchantRequired,
  transferDetailRequired,
}

enum EntryField { amount, category, merchant }

/// Visual state of one field on the review form.
enum EntryFieldStatus {
  /// No highlight, no help line.
  plain,

  /// OCR read it clearly ("อ่านได้ชัดเจน").
  verified,

  /// OCR was unsure ("OCR ไม่แน่ใจ — โปรดตรวจสอบ").
  uncertain,

  /// OCR found nothing and the field is required.
  missing,
}

@immutable
class EntryDraft {
  const EntryDraft({
    required this.mode,
    this.editId,
    this.scanId,
    required this.type,
    required this.amountText,
    required this.date,
    required this.hour,
    required this.minute,
    required this.merchant,
    required this.categoryId,
    required this.accountId,
    required this.destinationAccountId,
    required this.note,
    this.confidence,
    this.errors = const {},
  });

  final EntryMode mode;
  final String? editId;
  final String? scanId;
  final TransactionType type;
  final String amountText;

  /// Wall-clock date in Asia/Bangkok (time fields zero).
  final DateTime date;
  final int hour;
  final int minute;
  final String merchant;
  final String? categoryId;
  final String accountId;
  final String destinationAccountId;
  final String note;

  /// Per-field OCR confidence; null for manual and edit entries. A field the
  /// user has touched is removed from the map.
  final Map<ReadingField, FieldConfidence>? confidence;
  final Map<EntryField, EntryError> errors;

  bool get isTransfer => type == TransactionType.transfer;

  /// The prototype blocks saving a transfer to the same account.
  bool get sameAccount => isTransfer && accountId == destinationAccountId;

  EntryFieldStatus status(ReadingField field) {
    final c = confidence?[field];
    if (field == ReadingField.category) {
      if (categoryId != null) {
        return c == FieldConfidence.missing ? .plain : _fromConfidence(c);
      }
      return mode == EntryMode.scan ? .missing : .plain;
    }
    return _fromConfidence(c);
  }

  static EntryFieldStatus _fromConfidence(FieldConfidence? c) => switch (c) {
    FieldConfidence.verified => .verified,
    FieldConfidence.uncertain => .uncertain,
    FieldConfidence.missing => .missing,
    null => .plain,
  };

  /// Number of highlighted fields for the "ตรวจ N ช่องที่ไฮไลต์" banner.
  int get highlightCount => ReadingField.values.where((f) {
    final s = status(f);
    return s == EntryFieldStatus.uncertain || s == EntryFieldStatus.missing;
  }).length;

  EntryDraft copyWith({
    TransactionType? type,
    String? amountText,
    DateTime? date,
    int? hour,
    int? minute,
    String? merchant,
    String? Function()? categoryId,
    String? accountId,
    String? destinationAccountId,
    String? note,
    Map<ReadingField, FieldConfidence>? Function()? confidence,
    Map<EntryField, EntryError>? errors,
  }) => EntryDraft(
    mode: mode,
    editId: editId,
    scanId: scanId,
    type: type ?? this.type,
    amountText: amountText ?? this.amountText,
    date: date ?? this.date,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    merchant: merchant ?? this.merchant,
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    accountId: accountId ?? this.accountId,
    destinationAccountId: destinationAccountId ?? this.destinationAccountId,
    note: note ?? this.note,
    confidence: confidence == null ? this.confidence : confidence(),
    errors: errors ?? this.errors,
  );
}

/// Outcome of a successful save.
@immutable
class EntrySaved {
  const EntrySaved({required this.transactionId, required this.mode});

  final String transactionId;
  final EntryMode mode;
}

/// Accepts `120`, `120.5`, `1,234.50`; rejects mis-grouped input such as
/// the OCR misread `1,20.00` (prototype `amtFmtOk`).
final _amountPattern = RegExp(r'^(\d{1,3}(,\d{3})+|\d+)(\.\d{1,2})?$');

/// Validation shared by manual entry, edits and slip review.
Map<EntryField, EntryError> validateEntry(EntryDraft d) {
  final errors = <EntryField, EntryError>{};
  final text = d.amountText.trim();
  final money = _amountPattern.hasMatch(text)
      ? Money.tryParse(text, Currency.thb)
      : null;
  if (money == null || !money.isPositive) {
    errors[EntryField.amount] =
        text.isNotEmpty && !_amountPattern.hasMatch(text)
        ? EntryError.amountFormat
        : EntryError.amountRequired;
  }
  if (!d.isTransfer && d.categoryId == null) {
    errors[EntryField.category] = EntryError.categoryRequired;
  }
  if (d.merchant.trim().isEmpty) {
    errors[EntryField.merchant] = d.isTransfer
        ? EntryError.transferDetailRequired
        : EntryError.merchantRequired;
  }
  return errors;
}

/// Form state for one entry screen.
class EntryFormController extends Notifier<EntryDraft> {
  EntryFormController(this.args);

  final EntryArgs args;

  AppStore get _store => ref.read(appStoreProvider.notifier);

  @override
  EntryDraft build() {
    final s = ref.read(appStoreProvider);
    final today = ReportingTimeZone.bangkok.wallClock(
      ref.read(clockProvider).nowUtc(),
    );
    final accounts = s.accounts.map((a) => a.id).toList();
    // Default to the account used most, so frequent entries need no change.
    final usage = <String, int>{};
    for (final t in s.transactions) {
      usage.update(t.accountId, (v) => v + 1, ifAbsent: () => 1);
    }
    final firstAccount = accounts.isEmpty
        ? ''
        : accounts.reduce((a, b) => (usage[b] ?? 0) > (usage[a] ?? 0) ? b : a);
    String otherThan(String id) =>
        accounts.firstWhere((a) => a != id, orElse: () => id);

    switch (args) {
      case ManualEntryArgs(:final type):
        return EntryDraft(
          mode: EntryMode.manual,
          type: type,
          amountText: '',
          date: DateTime.utc(today.year, today.month, today.day),
          hour: 12,
          minute: 30,
          merchant: '',
          categoryId: _defaultCategory(s, type),
          accountId: firstAccount,
          // The prototype defaults a transfer to the e-wallet.
          destinationAccountId:
              firstAccount != 'truemoney' && s.account('truemoney') != null
              ? 'truemoney'
              : otherThan(firstAccount),
          note: '',
        );
      case EditEntryArgs(:final transactionId):
        final t = s.transaction(transactionId)!;
        final w = ReportingTimeZone.bangkok.wallClock(t.occurredAt);
        return EntryDraft(
          mode: EntryMode.edit,
          editId: t.id,
          type: t.type,
          amountText: _grouped(t.amount),
          date: DateTime.utc(w.year, w.month, w.day),
          hour: w.hour,
          minute: w.minute,
          merchant: t.merchant ?? '',
          categoryId: t.categoryId,
          accountId: t.accountId,
          destinationAccountId:
              t.destinationAccountId ?? otherThan(t.accountId),
          note: t.note ?? '',
        );
      case ScanEntryArgs(:final scanId):
        final details = s.scanDetails[scanId];
        final r = details?.reading ?? details?.retryReading;
        final w = ReportingTimeZone.bangkok.wallClock(
          r?.occurredAt ?? ref.read(clockProvider).nowUtc(),
        );
        final account = r?.accountId ?? firstAccount;
        return EntryDraft(
          mode: EntryMode.scan,
          scanId: scanId,
          type: TransactionType.expense,
          amountText: r?.amountText ?? '',
          date: DateTime.utc(w.year, w.month, w.day),
          hour: w.hour,
          minute: w.minute,
          merchant: r?.merchant ?? '',
          categoryId: r?.categoryId,
          accountId: account,
          destinationAccountId: otherThan(account),
          note: '',
          confidence: {...?r?.confidence},
        );
    }
  }

  static String? _defaultCategory(AppState s, TransactionType type) {
    if (type == TransactionType.transfer) return null;
    final preferred = type == TransactionType.income
        ? 'default-income-salary'
        : 'default-expense-food';
    if (s.category(preferred) != null) return preferred;
    final kind = type == TransactionType.income
        ? CategoryKind.income
        : CategoryKind.expense;
    for (final c in s.categories) {
      if (c.kind == kind) return c.id;
    }
    return null;
  }

  static String _grouped(Money m) {
    final parts = m.toDecimalString().split('.');
    final major = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return parts.length > 1 ? '$major.${parts[1]}' : major;
  }

  /// Editing a field clears its OCR highlight and any form error, as the
  /// prototype's `setD` does.
  Map<ReadingField, FieldConfidence>? _touched(ReadingField field) {
    final c = state.confidence;
    if (c == null) return null;
    return {...c}..remove(field);
  }

  void setAmount(String v) => state = state.copyWith(
    amountText: v,
    confidence: () => _touched(ReadingField.amount),
    errors: const {},
  );

  void setMerchant(String v) => state = state.copyWith(
    merchant: v,
    confidence: () => _touched(ReadingField.merchant),
    errors: const {},
  );

  void setNote(String v) => state = state.copyWith(note: v);

  void setDate(DateTime date) => state = state.copyWith(
    date: DateTime.utc(date.year, date.month, date.day),
    confidence: () => _touched(ReadingField.date),
    errors: const {},
  );

  void setTime(int hour, int minute) => state = state.copyWith(
    hour: hour,
    minute: minute,
    confidence: () => _touched(ReadingField.time),
    errors: const {},
  );

  void setCategory(String id) => state = state.copyWith(
    categoryId: () => id,
    confidence: () => _touched(ReadingField.category),
    errors: const {},
  );

  void setAccount(String id) => state = state.copyWith(accountId: id);

  void setDestination(String id) =>
      state = state.copyWith(destinationAccountId: id);

  /// Switching type keeps a category of the matching kind, otherwise picks
  /// the prototype's default; a transfer never targets its own source.
  void setType(TransactionType type) {
    final s = ref.read(appStoreProvider);
    final current = s.category(state.categoryId);
    final keep =
        current != null &&
        ((type == TransactionType.income &&
                current.kind == CategoryKind.income) ||
            (type == TransactionType.expense &&
                current.kind == CategoryKind.expense));
    final String? category = switch (type) {
      _ when keep => state.categoryId,
      TransactionType.income => _defaultCategory(s, type),
      TransactionType.expense =>
        state.mode == EntryMode.scan ? null : _defaultCategory(s, type),
      TransactionType.transfer => state.categoryId,
    };
    var destination = state.destinationAccountId;
    if (destination == state.accountId) {
      destination = s.accounts
          .map((a) => a.id)
          .firstWhere((id) => id != state.accountId, orElse: () => destination);
    }
    state = state.copyWith(
      type: type,
      categoryId: () => category,
      destinationAccountId: destination,
      errors: const {},
    );
  }

  /// Validates and saves to the database. Returns null (and shows errors)
  /// when invalid.
  Future<EntrySaved?> save() async {
    final d = state;
    if (d.sameAccount) return null;
    final errors = validateEntry(d);
    if (errors.isNotEmpty) {
      state = d.copyWith(errors: errors);
      return null;
    }
    final input = TransactionInput(
      type: d.type,
      amount: Money.tryParse(d.amountText.trim(), Currency.thb)!,
      accountId: d.accountId,
      destinationAccountId: d.isTransfer ? d.destinationAccountId : null,
      categoryId: d.isTransfer ? null : d.categoryId,
      merchant: d.merchant.trim(),
      note: d.note.trim().isEmpty ? null : d.note.trim(),
      occurredAt: ReportingTimeZone.bangkok.toUtc(
        d.date.year,
        d.date.month,
        d.date.day,
        d.hour,
        d.minute,
      ),
      scanId: d.scanId,
    );
    if (d.mode == EntryMode.edit) {
      await _store.updateTransaction(d.editId!, input);
      return EntrySaved(transactionId: d.editId!, mode: d.mode);
    }
    final id = await _store.addTransaction(input);
    return EntrySaved(transactionId: id, mode: d.mode);
  }

  /// "ทิ้ง" on a slip review.
  void discardScan() {
    final id = state.scanId;
    if (id != null) _store.discardScan(id);
  }
}

final entryFormProvider = NotifierProvider.autoDispose
    .family<EntryFormController, EntryDraft, EntryArgs>(
      EntryFormController.new,
    );
