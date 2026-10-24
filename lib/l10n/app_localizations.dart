import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MoneyLens'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get navImport;

  /// No description provided for @dashboardThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dashboardThisMonth;

  /// No description provided for @summaryIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get summaryIncome;

  /// No description provided for @summaryExpense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get summaryExpense;

  /// No description provided for @summaryNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get summaryNet;

  /// No description provided for @summaryTransfers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No transfers} =1{1 transfer (not counted)} other{{count} transfers (not counted)}}'**
  String summaryTransfers(int count);

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @transactionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get transactionsEmpty;

  /// No description provided for @transactionTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionTypeIncome;

  /// No description provided for @transactionTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionTypeExpense;

  /// No description provided for @transactionTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionTypeTransfer;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while loading.'**
  String get loadError;

  /// No description provided for @startupError.
  ///
  /// In en, this message translates to:
  /// **'MoneyLens could not open its local data.'**
  String get startupError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import a slip'**
  String get importTitle;

  /// No description provided for @importFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get importFromCamera;

  /// No description provided for @importFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get importFromGallery;

  /// No description provided for @importShareSheetHint.
  ///
  /// In en, this message translates to:
  /// **'Sharing slips into MoneyLens from other apps is not available yet.'**
  String get importShareSheetHint;

  /// No description provided for @importReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Imported slips are always shown for review before anything is saved.'**
  String get importReviewNotice;

  /// No description provided for @scansTitle.
  ///
  /// In en, this message translates to:
  /// **'Imported slips'**
  String get scansTitle;

  /// No description provided for @scansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No imported slips'**
  String get scansEmpty;

  /// No description provided for @scanStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get scanStatusQueued;

  /// No description provided for @scanStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get scanStatusProcessing;

  /// No description provided for @scanStatusNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get scanStatusNeedsReview;

  /// No description provided for @scanStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get scanStatusConfirmed;

  /// No description provided for @scanStatusDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get scanStatusDuplicate;

  /// No description provided for @scanStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get scanStatusFailed;

  /// No description provided for @scanStatusDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Discarded'**
  String get scanStatusDiscarded;

  /// No description provided for @scanSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get scanSourceCamera;

  /// No description provided for @scanSourceGallery.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get scanSourceGallery;

  /// No description provided for @scanSourceShareSheet.
  ///
  /// In en, this message translates to:
  /// **'Share Sheet'**
  String get scanSourceShareSheet;

  /// No description provided for @scanSourceDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get scanSourceDiscovery;

  /// No description provided for @failureUnsupportedFile.
  ///
  /// In en, this message translates to:
  /// **'This file is not a supported image.'**
  String get failureUnsupportedFile;

  /// No description provided for @failureFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This image is too large.'**
  String get failureFileTooLarge;

  /// No description provided for @failurePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission was denied. You can allow access in Settings.'**
  String get failurePermissionDenied;

  /// No description provided for @failureUnreadableImage.
  ///
  /// In en, this message translates to:
  /// **'The image could not be read.'**
  String get failureUnreadableImage;

  /// No description provided for @failureOcrUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Text recognition is not available yet.'**
  String get failureOcrUnavailable;

  /// No description provided for @failureExtractionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transaction details could not be extracted.'**
  String get failureExtractionFailed;

  /// No description provided for @failureGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get failureGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
