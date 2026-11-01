import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../domain/transaction.dart';
import '../domain/transaction_type.dart';

/// What the entry screen submits.
@immutable
class TransactionInput {
  const TransactionInput({
    required this.type,
    required this.amount,
    required this.accountId,
    this.destinationAccountId,
    this.categoryId,
    required this.merchant,
    this.note,
    required this.occurredAt,
    this.scanId,
  });

  final TransactionType type;
  final Money amount;
  final String accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final String merchant;
  final String? note;
  final DateTime occurredAt;
  final String? scanId;

  /// The draft to store. A transfer has a destination and no category; the
  /// other types the reverse.
  TransactionDraft toDraft({
    required TransactionSource source,
    String? attachmentPath,
  }) => TransactionDraft(
    type: type,
    amount: amount,
    accountId: accountId,
    destinationAccountId: type == TransactionType.transfer
        ? destinationAccountId
        : null,
    categoryId: type == TransactionType.transfer ? null : categoryId,
    merchant: merchant,
    note: note,
    occurredAt: occurredAt,
    source: source,
    attachmentPath: attachmentPath,
  );
}
