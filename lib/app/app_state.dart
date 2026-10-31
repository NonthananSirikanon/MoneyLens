import 'package:flutter/widgets.dart';

import '../core/money/money.dart';
import '../features/accounts/domain/account.dart';
import '../features/categories/domain/category.dart';
import '../features/slip_import/domain/scan_record.dart';
import '../features/slip_import/domain/scan_status.dart';
import '../features/transactions/domain/transaction.dart';
import '../features/transactions/domain/transaction_type.dart';

/// Prototype-only models for the in-memory demo store.
///
/// Ledger entities reuse the domain classes (`MoneyTransaction`, `Account`,
/// `Category`, `ScanRecord`) so screens can later be pointed at the Drift
/// repositories. Values the domain does not model yet live in the small
/// side records below.

/// How sure the (simulated) OCR is about one review field.
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

  /// What a retry of a failed read will produce (simulated OCR).
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

/// Side data for an [Account]: the short label used in rows, the masked
/// last four digits (never the full number) and the icon tint.
@immutable
class AccountDetails {
  const AccountDetails({
    required this.shortName,
    this.last4,
    required this.tint,
  });

  final String shortName;
  final String? last4;
  final Color tint;

  /// Derives display details from a stored account: the first word of the
  /// name as the short label, and a tint by kind.
  factory AccountDetails.of(Account a) => AccountDetails(
    shortName: a.name.trim().split(RegExp(r'\s+')).first,
    last4: a.lastFour,
    tint: switch (a.kind) {
      AccountKind.bank => const Color(0xFFE3EFE7),
      AccountKind.ewallet => const Color(0xFFF7EDD6),
      AccountKind.cash => const Color(0xFFE6EBDF),
      AccountKind.other => const Color(0xFFF0F0EC),
    },
  );

  /// `•••• 1234`, or empty when no digits were given.
  String get mask => last4 == null || last4!.isEmpty ? '' : '•••• $last4';
}

/// Visual identity of a category: the tint behind its icon and the colour
/// used for it in charts.
@immutable
class CategoryStyle {
  const CategoryStyle({required this.tint, required this.chart});

  final Color tint;
  final Color chart;

  /// [colorValue] is the stored accent colour. The tint behind the icon is
  /// that colour at 22% over white.
  factory CategoryStyle.of(Category c) =>
      CategoryStyle.fromAccent(Color(c.colorValue ?? 0xFFC9C8C2));

  factory CategoryStyle.fromAccent(Color accent) => CategoryStyle(
    tint: Color.alphaBlend(
      accent.withValues(alpha: .22),
      const Color(0xFFFFFFFF),
    ),
    chart: accent,
  );
}

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
}

/// Everything the app store holds: ledger data mirrored from the Drift
/// database, plus the in-memory (simulated) slip queue.
@immutable
class AppState {
  const AppState({
    required this.transactions,
    required this.transactionImportSources,
    required this.accounts,
    required this.accountDetails,
    required this.categories,
    required this.categoryStyles,
    required this.scans,
    required this.scanDetails,
    required this.ocrProgress,
  });

  /// Newest first.
  final List<MoneyTransaction> transactions;

  /// Import source for slip-backed transactions (for the "source" row).
  final Map<String, ImportSource> transactionImportSources;
  final List<Account> accounts;
  final Map<String, AccountDetails> accountDetails;
  final List<Category> categories;
  final Map<String, CategoryStyle> categoryStyles;

  /// Newest first.
  final List<ScanRecord> scans;
  final Map<String, ScanDetails> scanDetails;

  /// Simulated OCR progress (0–100) for scans being read.
  final Map<String, double> ocrProgress;

  AppState copyWith({
    List<MoneyTransaction>? transactions,
    Map<String, ImportSource>? transactionImportSources,
    List<Account>? accounts,
    Map<String, AccountDetails>? accountDetails,
    List<Category>? categories,
    Map<String, CategoryStyle>? categoryStyles,
    List<ScanRecord>? scans,
    Map<String, ScanDetails>? scanDetails,
    Map<String, double>? ocrProgress,
  }) => AppState(
    transactions: transactions ?? this.transactions,
    transactionImportSources:
        transactionImportSources ?? this.transactionImportSources,
    accounts: accounts ?? this.accounts,
    accountDetails: accountDetails ?? this.accountDetails,
    categories: categories ?? this.categories,
    categoryStyles: categoryStyles ?? this.categoryStyles,
    scans: scans ?? this.scans,
    scanDetails: scanDetails ?? this.scanDetails,
    ocrProgress: ocrProgress ?? this.ocrProgress,
  );

  Account? account(String? id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Category? category(String? id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  MoneyTransaction? transaction(String? id) {
    for (final t in transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  ScanRecord? scan(String? id) {
    for (final s in scans) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Opening balance plus the effect of every transaction (minor units).
  /// Transfers only move money between the two accounts.
  int balanceOf(String accountId) {
    final account = this.account(accountId);
    var balance = account?.openingBalanceMinor ?? 0;
    for (final t in transactions) {
      balance += balanceEffect(t, accountId);
    }
    return balance;
  }

  int get totalBalance => accounts.fold(0, (sum, a) => sum + balanceOf(a.id));
}

/// The change [t] makes to [accountId]'s balance, in minor units.
int balanceEffect(MoneyTransaction t, String accountId) {
  final amount = t.amount.minor;
  return switch (t.type) {
    TransactionType.expense => t.accountId == accountId ? -amount : 0,
    TransactionType.income => t.accountId == accountId ? amount : 0,
    TransactionType.transfer =>
      (t.accountId == accountId ? -amount : 0) +
          (t.destinationAccountId == accountId ? amount : 0),
  };
}
