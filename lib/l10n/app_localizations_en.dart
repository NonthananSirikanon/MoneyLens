// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MoneyLens';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navImport => 'Import';

  @override
  String get dashboardThisMonth => 'This month';

  @override
  String get summaryIncome => 'Income';

  @override
  String get summaryExpense => 'Expenses';

  @override
  String get summaryNet => 'Net';

  @override
  String summaryTransfers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers (not counted)',
      one: '1 transfer (not counted)',
      zero: 'No transfers',
    );
    return '$_temp0';
  }

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get transactionsEmpty => 'No transactions yet';

  @override
  String get transactionTypeIncome => 'Income';

  @override
  String get transactionTypeExpense => 'Expense';

  @override
  String get transactionTypeTransfer => 'Transfer';

  @override
  String get loadError => 'Something went wrong while loading.';

  @override
  String get startupError => 'MoneyLens could not open its local data.';

  @override
  String get retry => 'Retry';

  @override
  String get discard => 'Discard';

  @override
  String get importTitle => 'Import a slip';

  @override
  String get importFromCamera => 'Camera';

  @override
  String get importFromGallery => 'Photos';

  @override
  String get importShareSheetHint =>
      'Sharing slips into MoneyLens from other apps is not available yet.';

  @override
  String get importReviewNotice =>
      'Imported slips are always shown for review before anything is saved.';

  @override
  String get scansTitle => 'Imported slips';

  @override
  String get scansEmpty => 'No imported slips';

  @override
  String get scanStatusQueued => 'Waiting';

  @override
  String get scanStatusProcessing => 'Processing';

  @override
  String get scanStatusNeedsReview => 'Needs review';

  @override
  String get scanStatusConfirmed => 'Confirmed';

  @override
  String get scanStatusDuplicate => 'Possible duplicate';

  @override
  String get scanStatusFailed => 'Failed';

  @override
  String get scanStatusDiscarded => 'Discarded';

  @override
  String get scanSourceCamera => 'Camera';

  @override
  String get scanSourceGallery => 'Photos';

  @override
  String get scanSourceShareSheet => 'Share Sheet';

  @override
  String get scanSourceDiscovery => 'Detected';

  @override
  String get failureUnsupportedFile => 'This file is not a supported image.';

  @override
  String get failureFileTooLarge => 'This image is too large.';

  @override
  String get failurePermissionDenied =>
      'Permission was denied. You can allow access in Settings.';

  @override
  String get failureUnreadableImage => 'The image could not be read.';

  @override
  String get failureOcrUnavailable => 'Text recognition is not available yet.';

  @override
  String get failureExtractionFailed =>
      'Transaction details could not be extracted.';

  @override
  String get failureGeneric => 'Something went wrong. Please try again.';
}
