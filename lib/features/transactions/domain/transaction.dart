import '../../../core/money/money.dart';
import 'transaction_type.dart';

/// The fields a user (or a reviewed scan) supplies to record a transaction.
class TransactionDraft {
  const TransactionDraft({
    required this.type,
    required this.amount,
    required this.accountId,
    this.destinationAccountId,
    this.categoryId,
    this.merchant,
    this.note,
    required this.occurredAt,
    this.source = TransactionSource.manual,
    this.providerReference,
  });

  final TransactionType type;
  final Money amount;
  final String accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final String? merchant;
  final String? note;

  /// The instant the transaction happened, in UTC.
  final DateTime occurredAt;
  final TransactionSource source;

  /// Bank/provider reference. Sensitive: never log it.
  final String? providerReference;
}

/// A confirmed ledger entry.
///
/// Named `MoneyTransaction` to avoid clashing with database transactions.
class MoneyTransaction {
  const MoneyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    this.destinationAccountId,
    this.categoryId,
    this.merchant,
    this.note,
    required this.occurredAt,
    required this.source,
    this.scanRecordId,
    this.attachmentPath,
    this.providerReference,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final TransactionType type;
  final Money amount;
  final String accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final String? merchant;
  final String? note;
  final DateTime occurredAt;
  final TransactionSource source;
  final String? scanRecordId;

  /// Relative path to an app-owned file, never an external URI.
  final String? attachmentPath;
  final String? providerReference;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Result of confirming a scan. [alreadyConfirmed] is true when the call
/// was a repeat and the existing transaction was returned unchanged.
class ConfirmResult {
  const ConfirmResult({
    required this.transaction,
    required this.alreadyConfirmed,
  });

  final MoneyTransaction transaction;
  final bool alreadyConfirmed;
}
