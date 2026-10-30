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
  /// **'Reading slip…'**
  String get scanStatusProcessing;

  /// No description provided for @scanStatusNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get scanStatusNeedsReview;

  /// No description provided for @scanStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get scanStatusConfirmed;

  /// No description provided for @scanStatusDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get scanStatusDuplicate;

  /// No description provided for @scanStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read'**
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
  /// **'Gallery'**
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

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navAdd.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get navAdd;

  /// No description provided for @typeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get typeExpense;

  /// No description provided for @typeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get typeIncome;

  /// No description provided for @typeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get typeTransfer;

  /// No description provided for @typeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get typeAll;

  /// No description provided for @transferCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferCategoryName;

  /// No description provided for @soonTag.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soonTag;

  /// No description provided for @testingTag.
  ///
  /// In en, this message translates to:
  /// **'In testing'**
  String get testingTag;

  /// No description provided for @hiddenAmount.
  ///
  /// In en, this message translates to:
  /// **'••••'**
  String get hiddenAmount;

  /// No description provided for @hiddenBalance.
  ///
  /// In en, this message translates to:
  /// **'฿ ••••••'**
  String get hiddenBalance;

  /// No description provided for @transfersExcludedNote.
  ///
  /// In en, this message translates to:
  /// **'Excludes transfers between accounts'**
  String get transfersExcludedNote;

  /// No description provided for @slipOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original slip'**
  String get slipOriginal;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Understand\nyour money'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Import transfer slips and receipts. The app reads the details and turns them into transactions for you.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Always review\nbefore saving'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'What the app reads from a slip is only a draft. You can edit and confirm it every time; nothing is saved silently.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Your data stays\non your phone'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Works offline. Your financial data and slip images stay on this device and are never sent anywhere without telling you.'**
  String get onboardingBody3;

  /// No description provided for @permissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Let MoneyLens read your slips'**
  String get permissionTitle;

  /// No description provided for @permissionBody.
  ///
  /// In en, this message translates to:
  /// **'We only ask when you use a feature, and you can say no. You can always add transactions manually.'**
  String get permissionBody;

  /// No description provided for @permissionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permissionCamera;

  /// No description provided for @permissionCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Photograph paper slips or another screen'**
  String get permissionCameraBody;

  /// No description provided for @permissionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get permissionPhotos;

  /// No description provided for @permissionPhotosBody.
  ///
  /// In en, this message translates to:
  /// **'Choose only the slips you want'**
  String get permissionPhotosBody;

  /// No description provided for @permissionAuto.
  ///
  /// In en, this message translates to:
  /// **'Detect new slips automatically'**
  String get permissionAuto;

  /// No description provided for @permissionAutoBody.
  ///
  /// In en, this message translates to:
  /// **'Depends on iOS/Android'**
  String get permissionAutoBody;

  /// No description provided for @permissionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow and get started'**
  String get permissionAllow;

  /// No description provided for @permissionLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get permissionLater;

  /// No description provided for @toastPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Access allowed'**
  String get toastPermissionGranted;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @addSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addSheetTitle;

  /// No description provided for @addOptionCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan a slip'**
  String get addOptionCamera;

  /// No description provided for @addOptionCameraSub.
  ///
  /// In en, this message translates to:
  /// **'Paper slip or another phone\'s screen'**
  String get addOptionCameraSub;

  /// No description provided for @addOptionGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Photos'**
  String get addOptionGallery;

  /// No description provided for @addOptionGallerySub.
  ///
  /// In en, this message translates to:
  /// **'Pick several at once'**
  String get addOptionGallerySub;

  /// No description provided for @addOptionManual.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get addOptionManual;

  /// No description provided for @addOptionManualSub.
  ///
  /// In en, this message translates to:
  /// **'Expense, income or transfer'**
  String get addOptionManualSub;

  /// No description provided for @addOptionAuto.
  ///
  /// In en, this message translates to:
  /// **'Detect new slips automatically'**
  String get addOptionAuto;

  /// No description provided for @addOptionAutoSub.
  ///
  /// In en, this message translates to:
  /// **'Depends on iOS/Android support'**
  String get addOptionAutoSub;

  /// No description provided for @addSheetShareHint.
  ///
  /// In en, this message translates to:
  /// **'Or share slip images from your banking app into MoneyLens'**
  String get addSheetShareHint;

  /// No description provided for @toastFeatureTesting.
  ///
  /// In en, this message translates to:
  /// **'This feature is being tested'**
  String get toastFeatureTesting;

  /// No description provided for @toastImportedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} photos, reading slips…'**
  String toastImportedPhotos(int count);

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — everything still works'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In en, this message translates to:
  /// **'Add, edit and browse as usual. Your data is on this device.'**
  String get offlineBody;

  /// No description provided for @pendingSlipsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} slips waiting for review'**
  String pendingSlipsTitle(int count);

  /// No description provided for @pendingSlipsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to check them before saving'**
  String get pendingSlipsBody;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get totalBalance;

  /// No description provided for @toggleBalanceVisibility.
  ///
  /// In en, this message translates to:
  /// **'Hide or show balances'**
  String get toggleBalanceVisibility;

  /// No description provided for @transfersExcludedShort.
  ///
  /// In en, this message translates to:
  /// **'Excludes transfers between accounts'**
  String get transfersExcludedShort;

  /// No description provided for @quickScan.
  ///
  /// In en, this message translates to:
  /// **'Scan slip'**
  String get quickScan;

  /// No description provided for @quickManual.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get quickManual;

  /// No description provided for @quickReport.
  ///
  /// In en, this message translates to:
  /// **'View report'**
  String get quickReport;

  /// No description provided for @recentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTitle;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @seeAllShort.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get seeAllShort;

  /// No description provided for @dailySpendTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily spending'**
  String get dailySpendTitle;

  /// No description provided for @dailySpendDay.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String dailySpendDay(String date);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @topCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Top spending categories'**
  String get topCategoriesTitle;

  /// No description provided for @topCategoryMeta.
  ///
  /// In en, this message translates to:
  /// **'{percent}% · {count} transactions'**
  String topCategoryMeta(int percent, int count);

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search merchants, notes…'**
  String get searchPlaceholder;

  /// No description provided for @categoryChip.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryChip;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterByCategory;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// No description provided for @transferInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfers aren\'t counted as income or expenses'**
  String get transferInfoTitle;

  /// No description provided for @transferInfoBody.
  ///
  /// In en, this message translates to:
  /// **'They move money between your own accounts'**
  String get transferInfoBody;

  /// No description provided for @loadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load transactions'**
  String get loadErrorTitle;

  /// No description provided for @loadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is still safe. Try again,\nor restart the app if it keeps happening.'**
  String get loadErrorBody;

  /// No description provided for @errorCode.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String errorCode(String code);

  /// No description provided for @noMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get noMatchesTitle;

  /// No description provided for @noMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Try another search or clear the filters'**
  String get noMatchesBody;

  /// No description provided for @transactionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get transactionsEmptyTitle;

  /// No description provided for @transactionsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start by scanning a slip or adding one manually'**
  String get transactionsEmptyBody;

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String dayToday(String date);

  /// No description provided for @dayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday · {date}'**
  String dayYesterday(String date);

  /// No description provided for @detailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get detailDate;

  /// No description provided for @detailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get detailCategory;

  /// No description provided for @detailAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get detailAccount;

  /// No description provided for @detailFrom.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get detailFrom;

  /// No description provided for @detailTo.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get detailTo;

  /// No description provided for @detailNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get detailNote;

  /// No description provided for @detailSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get detailSource;

  /// No description provided for @sourceManual.
  ///
  /// In en, this message translates to:
  /// **'Added manually'**
  String get sourceManual;

  /// No description provided for @sourceSlip.
  ///
  /// In en, this message translates to:
  /// **'Slip · {source}'**
  String sourceSlip(String source);

  /// No description provided for @slipTapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view full screen'**
  String get slipTapToView;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get deleteTitle;

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'The transaction and its attached slip will be deleted permanently. This can\'t be undone.'**
  String get deleteBody;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteConfirm;

  /// No description provided for @toastDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get toastDeleted;

  /// No description provided for @entryTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get entryTitleAdd;

  /// No description provided for @entryTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get entryTitleEdit;

  /// No description provided for @entryTitleReview.
  ///
  /// In en, this message translates to:
  /// **'Review transaction'**
  String get entryTitleReview;

  /// No description provided for @entrySaveAdd.
  ///
  /// In en, this message translates to:
  /// **'Save transaction'**
  String get entrySaveAdd;

  /// No description provided for @entrySaveEdit.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get entrySaveEdit;

  /// No description provided for @entrySaveTransfer.
  ///
  /// In en, this message translates to:
  /// **'Save transfer'**
  String get entrySaveTransfer;

  /// No description provided for @entrySaveReview.
  ///
  /// In en, this message translates to:
  /// **'Confirm and save'**
  String get entrySaveReview;

  /// No description provided for @entryDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get entryDiscard;

  /// No description provided for @entryAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get entryAmount;

  /// No description provided for @entryTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get entryTime;

  /// No description provided for @entryMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant / payee'**
  String get entryMerchant;

  /// No description provided for @entryPayer.
  ///
  /// In en, this message translates to:
  /// **'Payer / source'**
  String get entryPayer;

  /// No description provided for @entryTransferDetail.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get entryTransferDetail;

  /// No description provided for @entryMerchantPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pa Sri\'s chicken rice'**
  String get entryMerchantPlaceholder;

  /// No description provided for @entryTransferPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Top up wallet'**
  String get entryTransferPlaceholder;

  /// No description provided for @entryOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get entryOptional;

  /// No description provided for @entrySameAccount.
  ///
  /// In en, this message translates to:
  /// **'Source and destination must be different accounts'**
  String get entrySameAccount;

  /// No description provided for @entryTransferNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Not counted as income or expense'**
  String get entryTransferNoteTitle;

  /// No description provided for @entryTransferNoteBody.
  ///
  /// In en, this message translates to:
  /// **'Only the source balance goes down and the destination goes up'**
  String get entryTransferNoteBody;

  /// No description provided for @pickCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get pickCategory;

  /// No description provided for @pickAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose an account'**
  String get pickAccount;

  /// No description provided for @viewSlip.
  ///
  /// In en, this message translates to:
  /// **'View slip'**
  String get viewSlip;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @reviewHighlightTitle.
  ///
  /// In en, this message translates to:
  /// **'Check {count} highlighted fields'**
  String reviewHighlightTitle(int count);

  /// No description provided for @reviewHighlightBody.
  ///
  /// In en, this message translates to:
  /// **'OCR results are only a draft. You can edit every field before saving.'**
  String get reviewHighlightBody;

  /// No description provided for @reviewAllReadTitle.
  ///
  /// In en, this message translates to:
  /// **'Every field was read'**
  String get reviewAllReadTitle;

  /// No description provided for @reviewAllReadBody.
  ///
  /// In en, this message translates to:
  /// **'Please check once more before saving'**
  String get reviewAllReadBody;

  /// No description provided for @fieldVerified.
  ///
  /// In en, this message translates to:
  /// **'Read clearly'**
  String get fieldVerified;

  /// No description provided for @fieldUncertain.
  ///
  /// In en, this message translates to:
  /// **'OCR isn\'t sure — please check'**
  String get fieldUncertain;

  /// No description provided for @fieldMissing.
  ///
  /// In en, this message translates to:
  /// **'Required before saving'**
  String get fieldMissing;

  /// No description provided for @errorAmountFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount format, e.g. 120.00'**
  String get errorAmountFormat;

  /// No description provided for @errorAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than 0'**
  String get errorAmountRequired;

  /// No description provided for @errorMerchantRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a merchant or payee'**
  String get errorMerchantRequired;

  /// No description provided for @errorTransferDetailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter transfer details'**
  String get errorTransferDetailRequired;

  /// No description provided for @toastEditSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get toastEditSaved;

  /// No description provided for @toastSlipDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Slip discarded'**
  String get toastSlipDiscarded;

  /// No description provided for @transactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String transactionCount(int count);

  /// No description provided for @accountSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get accountSavings;

  /// No description provided for @accountWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get accountWallet;

  /// No description provided for @accountKindWallet.
  ///
  /// In en, this message translates to:
  /// **'e-Wallet'**
  String get accountKindWallet;

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Imported slips · {count}'**
  String queueTitle(int count);

  /// No description provided for @queueNotice.
  ///
  /// In en, this message translates to:
  /// **'Every slip is reviewed before saving — nothing is saved automatically'**
  String get queueNotice;

  /// No description provided for @queueActionReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get queueActionReview;

  /// No description provided for @queueActionCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get queueActionCompare;

  /// No description provided for @queueActionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get queueActionRetry;

  /// No description provided for @queueDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate slip · ฿{amount}'**
  String queueDuplicateTitle(String amount);

  /// No description provided for @scansEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Scan or choose a slip to get started'**
  String get scansEmptyBody;

  /// No description provided for @cameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan slip'**
  String get cameraTitle;

  /// No description provided for @cameraHint.
  ///
  /// In en, this message translates to:
  /// **'Fit the slip inside the frame · reads automatically when sharp'**
  String get cameraHint;

  /// No description provided for @cameraGallery.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get cameraGallery;

  /// No description provided for @cameraShutter.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get cameraShutter;

  /// No description provided for @cameraFlash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get cameraFlash;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check photo'**
  String get previewTitle;

  /// No description provided for @previewImage.
  ///
  /// In en, this message translates to:
  /// **'Slip photo'**
  String get previewImage;

  /// No description provided for @previewQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is the photo sharp with the full amount visible?'**
  String get previewQuestion;

  /// No description provided for @previewRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get previewRetake;

  /// No description provided for @previewUse.
  ///
  /// In en, this message translates to:
  /// **'Use photo'**
  String get previewUse;

  /// No description provided for @processingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading slip'**
  String get processingTitle;

  /// No description provided for @processingStepFile.
  ///
  /// In en, this message translates to:
  /// **'Checking the image file'**
  String get processingStepFile;

  /// No description provided for @processingStepRecord.
  ///
  /// In en, this message translates to:
  /// **'Creating the import record'**
  String get processingStepRecord;

  /// No description provided for @processingStepOcr.
  ///
  /// In en, this message translates to:
  /// **'Reading text (OCR)…'**
  String get processingStepOcr;

  /// No description provided for @processingStepExtract.
  ///
  /// In en, this message translates to:
  /// **'Extracting amount, date and merchant'**
  String get processingStepExtract;

  /// No description provided for @processingStepDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Checking for duplicates'**
  String get processingStepDuplicate;

  /// No description provided for @processingLeaveNote.
  ///
  /// In en, this message translates to:
  /// **'You can close this screen — the slip stays in the queue'**
  String get processingLeaveNote;

  /// No description provided for @processingGoQueue.
  ///
  /// In en, this message translates to:
  /// **'Go to slip queue'**
  String get processingGoQueue;

  /// No description provided for @duplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get duplicateTitle;

  /// No description provided for @duplicateBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'A very similar transaction exists'**
  String get duplicateBannerTitle;

  /// No description provided for @duplicateBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Amount, date and reference match'**
  String get duplicateBannerBody;

  /// No description provided for @duplicateNew.
  ///
  /// In en, this message translates to:
  /// **'New slip'**
  String get duplicateNew;

  /// No description provided for @duplicateSaved.
  ///
  /// In en, this message translates to:
  /// **'Already saved'**
  String get duplicateSaved;

  /// No description provided for @duplicateMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get duplicateMerchant;

  /// No description provided for @duplicateAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get duplicateAmount;

  /// No description provided for @duplicateReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get duplicateReference;

  /// No description provided for @duplicateMatch.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get duplicateMatch;

  /// No description provided for @duplicateMatchHint.
  ///
  /// In en, this message translates to:
  /// **'if you really paid twice, you can still save it'**
  String get duplicateMatchHint;

  /// No description provided for @duplicateDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard this slip (duplicate)'**
  String get duplicateDiscard;

  /// No description provided for @duplicateKeep.
  ///
  /// In en, this message translates to:
  /// **'Not a duplicate, continue'**
  String get duplicateKeep;

  /// No description provided for @toastDuplicateDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Duplicate slip discarded'**
  String get toastDuplicateDiscarded;

  /// No description provided for @ocrFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read slip'**
  String get ocrFailedTitle;

  /// No description provided for @ocrFailedHeading.
  ///
  /// In en, this message translates to:
  /// **'The details couldn\'t be read'**
  String get ocrFailedHeading;

  /// No description provided for @ocrFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The photo may be blurry or dark, or the slip format isn\'t supported yet'**
  String get ocrFailedBody;

  /// No description provided for @ocrTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Try this'**
  String get ocrTipsTitle;

  /// No description provided for @ocrTipLight.
  ///
  /// In en, this message translates to:
  /// **'Shoot in good light without shadows'**
  String get ocrTipLight;

  /// No description provided for @ocrTipVisible.
  ///
  /// In en, this message translates to:
  /// **'Keep the amount and date fully visible'**
  String get ocrTipVisible;

  /// No description provided for @ocrTipScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Use a screenshot from your banking app instead'**
  String get ocrTipScreenshot;

  /// No description provided for @ocrRetry.
  ///
  /// In en, this message translates to:
  /// **'Read again'**
  String get ocrRetry;

  /// No description provided for @ocrManual.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get ocrManual;

  /// No description provided for @ocrDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete slip'**
  String get ocrDelete;

  /// No description provided for @toastSlipDeleted.
  ///
  /// In en, this message translates to:
  /// **'Slip deleted'**
  String get toastSlipDeleted;

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTitle;

  /// No description provided for @savedView.
  ///
  /// In en, this message translates to:
  /// **'View transaction'**
  String get savedView;

  /// No description provided for @savedNext.
  ///
  /// In en, this message translates to:
  /// **'Review next slip ({count})'**
  String savedNext(int count);

  /// No description provided for @savedHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get savedHome;

  /// No description provided for @deniedCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'MoneyLens can\'t access the camera yet'**
  String get deniedCameraTitle;

  /// No description provided for @deniedPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'MoneyLens can\'t access your photos yet'**
  String get deniedPhotosTitle;

  /// No description provided for @deniedBody.
  ///
  /// In en, this message translates to:
  /// **'Allow access in Settings, or use another way instead'**
  String get deniedBody;

  /// No description provided for @deniedOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get deniedOpenSettings;

  /// No description provided for @deniedAltGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Photos'**
  String get deniedAltGallery;

  /// No description provided for @deniedAltCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan with the camera'**
  String get deniedAltCamera;

  /// No description provided for @toastPermissionOpened.
  ///
  /// In en, this message translates to:
  /// **'Access turned on'**
  String get toastPermissionOpened;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsTabBreakdown.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get analyticsTabBreakdown;

  /// No description provided for @analyticsTabTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get analyticsTabTrend;

  /// No description provided for @analyticsTransfersExcluded.
  ///
  /// In en, this message translates to:
  /// **'Excludes transfers between accounts {amount}'**
  String analyticsTransfersExcluded(String amount);

  /// No description provided for @analyticsTotalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total expenses'**
  String get analyticsTotalExpense;

  /// No description provided for @analyticsTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get analyticsTotalIncome;

  /// No description provided for @analyticsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get analyticsEmptyTitle;

  /// No description provided for @analyticsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try another period, or add transactions for this month'**
  String get analyticsEmptyBody;

  /// No description provided for @analyticsChangePeriod.
  ///
  /// In en, this message translates to:
  /// **'Change period'**
  String get analyticsChangePeriod;

  /// No description provided for @analyticsAvgIncome.
  ///
  /// In en, this message translates to:
  /// **'Average income'**
  String get analyticsAvgIncome;

  /// No description provided for @analyticsAvgExpense.
  ///
  /// In en, this message translates to:
  /// **'Average expenses'**
  String get analyticsAvgExpense;

  /// No description provided for @analyticsIncomeVsExpense.
  ///
  /// In en, this message translates to:
  /// **'Income vs expenses'**
  String get analyticsIncomeVsExpense;

  /// No description provided for @analyticsSixMonths.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get analyticsSixMonths;

  /// No description provided for @analyticsNet.
  ///
  /// In en, this message translates to:
  /// **'Net {month}'**
  String analyticsNet(String month);

  /// No description provided for @analyticsOverspend.
  ///
  /// In en, this message translates to:
  /// **'{month}: spent {amount} more than earned'**
  String analyticsOverspend(String month, String amount);

  /// No description provided for @analyticsMonthBar.
  ///
  /// In en, this message translates to:
  /// **'{month}: income {income}, expenses {expense}'**
  String analyticsMonthBar(String month, String income, String expense);

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @newCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategoryTitle;

  /// No description provided for @categoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameLabel;

  /// No description provided for @categoryNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pets'**
  String get categoryNamePlaceholder;

  /// No description provided for @categoryIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryIconLabel;

  /// No description provided for @categoryColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Background colour'**
  String get categoryColorLabel;

  /// No description provided for @categoryColorOption.
  ///
  /// In en, this message translates to:
  /// **'Colour {index}'**
  String categoryColorOption(int index);

  /// No description provided for @saveCategory.
  ///
  /// In en, this message translates to:
  /// **'Save category'**
  String get saveCategory;

  /// No description provided for @toastCategoryAdded.
  ///
  /// In en, this message translates to:
  /// **'Added category \"{name}\"'**
  String toastCategoryAdded(String name);

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @accountsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total across accounts'**
  String get accountsTotal;

  /// No description provided for @accountsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} accounts · hidden accounts excluded'**
  String accountsCount(int count);

  /// No description provided for @accountsGroupBank.
  ///
  /// In en, this message translates to:
  /// **'Banks'**
  String get accountsGroupBank;

  /// No description provided for @accountsGroupOther.
  ///
  /// In en, this message translates to:
  /// **'e-Wallets and cash'**
  String get accountsGroupOther;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @accountsMaskNote.
  ///
  /// In en, this message translates to:
  /// **'Account numbers are only shown masked'**
  String get accountsMaskNote;

  /// No description provided for @toastAccountEdit.
  ///
  /// In en, this message translates to:
  /// **'{name} · edit account'**
  String toastAccountEdit(String name);

  /// No description provided for @newAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get newAccountTitle;

  /// No description provided for @accountKindBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountKindBank;

  /// No description provided for @accountKindEwallet.
  ///
  /// In en, this message translates to:
  /// **'e-Wallet'**
  String get accountKindEwallet;

  /// No description provided for @accountKindCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountKindCash;

  /// No description provided for @accountNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountNameLabel;

  /// No description provided for @accountNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bangkok Bank savings'**
  String get accountNamePlaceholder;

  /// No description provided for @accountLast4Label.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits (optional)'**
  String get accountLast4Label;

  /// No description provided for @accountLast4Hint.
  ///
  /// In en, this message translates to:
  /// **'Only the last 4 digits are kept, to help match slips'**
  String get accountLast4Hint;

  /// No description provided for @accountOpeningLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get accountOpeningLabel;

  /// No description provided for @saveAccount.
  ///
  /// In en, this message translates to:
  /// **'Save account'**
  String get saveAccount;

  /// No description provided for @toastAccountAdded.
  ///
  /// In en, this message translates to:
  /// **'Added account \"{name}\"'**
  String toastAccountAdded(String name);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsGroupFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get settingsGroupFinance;

  /// No description provided for @settingsGroupDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsGroupDisplay;

  /// No description provided for @settingsGroupData.
  ///
  /// In en, this message translates to:
  /// **'Data and security'**
  String get settingsGroupData;

  /// No description provided for @settingsImportedSlips.
  ///
  /// In en, this message translates to:
  /// **'Imported slips'**
  String get settingsImportedSlips;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @toastCurrencyOnly.
  ///
  /// In en, this message translates to:
  /// **'Only THB is supported for now'**
  String get toastCurrencyOnly;

  /// No description provided for @settingsDataExport.
  ///
  /// In en, this message translates to:
  /// **'Data and export'**
  String get settingsDataExport;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy and security'**
  String get settingsPrivacy;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About MoneyLens'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'MoneyLens · version {version}'**
  String settingsVersion(String version);

  /// No description provided for @p1Tag.
  ///
  /// In en, this message translates to:
  /// **'P1'**
  String get p1Tag;

  /// No description provided for @dataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data and export'**
  String get dataTitle;

  /// No description provided for @dataGroupCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get dataGroupCsv;

  /// No description provided for @dataCsvWarning.
  ///
  /// In en, this message translates to:
  /// **'The file contains sensitive financial data — store and share it carefully'**
  String get dataCsvWarning;

  /// No description provided for @dataRange.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get dataRange;

  /// No description provided for @toastPickRange.
  ///
  /// In en, this message translates to:
  /// **'Choose a period'**
  String get toastPickRange;

  /// No description provided for @dataExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get dataExportCsv;

  /// No description provided for @dataExportCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String dataExportCount(int count);

  /// No description provided for @toastExported.
  ///
  /// In en, this message translates to:
  /// **'Exported {file}'**
  String toastExported(String file);

  /// No description provided for @dataGroupSlips.
  ///
  /// In en, this message translates to:
  /// **'Stored slip images'**
  String get dataGroupSlips;

  /// No description provided for @dataSlipsOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Slip images on this device'**
  String get dataSlipsOnDevice;

  /// No description provided for @dataSlipsSize.
  ///
  /// In en, this message translates to:
  /// **'{count} images · {size}'**
  String dataSlipsSize(int count, String size);

  /// No description provided for @dataAutoDelete.
  ///
  /// In en, this message translates to:
  /// **'Auto-delete images of saved slips'**
  String get dataAutoDelete;

  /// No description provided for @dataAutoDeleteSub.
  ///
  /// In en, this message translates to:
  /// **'After 30 days'**
  String get dataAutoDeleteSub;

  /// No description provided for @dataWipe.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get dataWipe;

  /// No description provided for @dataWipeSub.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete transactions, accounts and slip images (including the server copy)'**
  String get dataWipeSub;

  /// No description provided for @wipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get wipeTitle;

  /// No description provided for @wipeBody.
  ///
  /// In en, this message translates to:
  /// **'All transactions, accounts and slip images on this device, and their copies on the server, will be deleted permanently. This can\'t be undone.'**
  String get wipeBody;

  /// No description provided for @wipeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get wipeConfirm;

  /// No description provided for @toastWiped.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get toastWiped;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get securityTitle;

  /// No description provided for @securityGroupAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get securityGroupAccess;

  /// No description provided for @securityFaceId.
  ///
  /// In en, this message translates to:
  /// **'Lock the app with Face ID'**
  String get securityFaceId;

  /// No description provided for @securityFaceIdSub.
  ///
  /// In en, this message translates to:
  /// **'Verify every time the app opens'**
  String get securityFaceIdSub;

  /// No description provided for @securityHideBalances.
  ///
  /// In en, this message translates to:
  /// **'Hide balances on Home'**
  String get securityHideBalances;

  /// No description provided for @securityGroupPermissions.
  ///
  /// In en, this message translates to:
  /// **'App permissions'**
  String get securityGroupPermissions;

  /// No description provided for @securityCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera access'**
  String get securityCamera;

  /// No description provided for @securityPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photo access'**
  String get securityPhotos;

  /// No description provided for @permissionAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get permissionAllowed;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get permissionDenied;

  /// No description provided for @permissionLimited.
  ///
  /// In en, this message translates to:
  /// **'Selected photos'**
  String get permissionLimited;

  /// No description provided for @toastPermissionRevoked.
  ///
  /// In en, this message translates to:
  /// **'Access turned off (simulated)'**
  String get toastPermissionRevoked;

  /// No description provided for @securityLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Your entries are backed up to your account; slip images stay on this device only · slip content and account numbers are never written to logs'**
  String get securityLocalNote;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Get started with\nMoneyLens'**
  String get authLoginTitle;

  /// No description provided for @authLoginBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your data safe'**
  String get authLoginBody;

  /// No description provided for @authLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Your entries are backed up to your account; slip images stay on your phone'**
  String get authLocalNote;

  /// No description provided for @authWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authWithGoogle;

  /// No description provided for @authTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you accept the Terms of Use and Privacy Policy'**
  String get authTerms;

  /// No description provided for @authErrTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later'**
  String get authErrTooMany;

  /// No description provided for @authErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection and try again'**
  String get authErrNetwork;

  /// No description provided for @authErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again'**
  String get authErrUnknown;

  /// No description provided for @authBirthTitle.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get authBirthTitle;

  /// No description provided for @authBirthEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit birth date'**
  String get authBirthEditTitle;

  /// No description provided for @authBirthHeading.
  ///
  /// In en, this message translates to:
  /// **'Your date of birth'**
  String get authBirthHeading;

  /// No description provided for @authBirthBody.
  ///
  /// In en, this message translates to:
  /// **'Used as your profile information and never shown to others'**
  String get authBirthBody;

  /// No description provided for @authDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get authDay;

  /// No description provided for @authMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get authMonth;

  /// No description provided for @authYear.
  ///
  /// In en, this message translates to:
  /// **'Year (B.E.)'**
  String get authYear;

  /// No description provided for @authDayHint.
  ///
  /// In en, this message translates to:
  /// **'DD'**
  String get authDayHint;

  /// No description provided for @authYearHint.
  ///
  /// In en, this message translates to:
  /// **'2540'**
  String get authYearHint;

  /// No description provided for @authPickMonth.
  ///
  /// In en, this message translates to:
  /// **'Choose month'**
  String get authPickMonth;

  /// No description provided for @authPickMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'Birth month'**
  String get authPickMonthTitle;

  /// No description provided for @authAge.
  ///
  /// In en, this message translates to:
  /// **'Age {years}'**
  String authAge(int years);

  /// No description provided for @authYearNote.
  ///
  /// In en, this message translates to:
  /// **'Use the Buddhist year, e.g. 2540'**
  String get authYearNote;

  /// No description provided for @authBirthIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Fill in day, month and year'**
  String get authBirthIncomplete;

  /// No description provided for @authBirthYearFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter a 4-digit Buddhist year, e.g. 2540'**
  String get authBirthYearFormat;

  /// No description provided for @authBirthNoSuch.
  ///
  /// In en, this message translates to:
  /// **'There is no {day} {month} in {year}'**
  String authBirthNoSuch(int day, String month, String year);

  /// No description provided for @authBirthFuture.
  ///
  /// In en, this message translates to:
  /// **'Date of birth can\'t be after today'**
  String get authBirthFuture;

  /// No description provided for @authBirthSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Check your connection and try again'**
  String get authBirthSaveFailed;

  /// No description provided for @authContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinue;

  /// No description provided for @authSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get authSave;

  /// No description provided for @toastBirthSaved.
  ///
  /// In en, this message translates to:
  /// **'Birth date saved'**
  String get toastBirthSaved;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get accountTitle;

  /// No description provided for @accountViaGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get accountViaGoogle;

  /// No description provided for @accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// No description provided for @accountBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get accountBirth;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignOutSub.
  ///
  /// In en, this message translates to:
  /// **'Data on this device stays'**
  String get accountSignOutSub;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your data on this device stays, but you\'ll need to sign in again to keep using the app.'**
  String get signOutBody;

  /// No description provided for @toastSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get toastSignedOut;

  /// No description provided for @settingsAccountSub.
  ///
  /// In en, this message translates to:
  /// **'Account and profile'**
  String get settingsAccountSub;

  /// No description provided for @profileFallbackName.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get profileFallbackName;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @syncRunning.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncRunning;

  /// No description provided for @syncNever.
  ///
  /// In en, this message translates to:
  /// **'Never synced · tap to sync now'**
  String get syncNever;

  /// No description provided for @syncDone.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time} · tap to sync now'**
  String syncDone(String time);

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} changes waiting · tap to sync now'**
  String syncPending(int count);

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet. Will retry automatically'**
  String get syncOffline;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Will retry automatically · tap to try now'**
  String get syncFailed;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// No description provided for @accountDeleteSub.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete the account and all its data'**
  String get accountDeleteSub;

  /// No description provided for @accountDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting account…'**
  String get accountDeleting;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your transactions, accounts, categories and date of birth will be permanently deleted from the server and from this device. This can\'t be undone. Your Google account itself is not deleted.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get deleteAccountAction;

  /// No description provided for @deleteAccountAgainTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteAccountAgainTitle;

  /// No description provided for @deleteAccountAgainBody.
  ///
  /// In en, this message translates to:
  /// **'Everything will be gone immediately and can\'t be recovered. Do you really want to delete the account?'**
  String get deleteAccountAgainBody;

  /// No description provided for @deleteAccountAgainAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account permanently'**
  String get deleteAccountAgainAction;

  /// No description provided for @toastAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get toastAccountDeleted;

  /// No description provided for @accountDeleteNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'You need an internet connection to delete the account. Try again when you\'re connected.'**
  String get accountDeleteNeedsInternet;

  /// No description provided for @exportPeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get exportPeriodThisMonth;

  /// No description provided for @exportPeriodLast3.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get exportPeriodLast3;

  /// No description provided for @exportPeriodThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get exportPeriodThisYear;

  /// No description provided for @exportPeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get exportPeriodAll;

  /// No description provided for @exportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this period'**
  String get exportEmpty;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Try again'**
  String get exportFailed;

  /// No description provided for @csvColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get csvColDate;

  /// No description provided for @csvColTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get csvColTime;

  /// No description provided for @csvColType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get csvColType;

  /// No description provided for @csvColAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get csvColAmount;

  /// No description provided for @csvColCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get csvColCurrency;

  /// No description provided for @csvColAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get csvColAccount;

  /// No description provided for @csvColToAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get csvColToAccount;

  /// No description provided for @csvColCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get csvColCategory;

  /// No description provided for @csvColMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant / payee'**
  String get csvColMerchant;

  /// No description provided for @csvColNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get csvColNote;

  /// No description provided for @csvColSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get csvColSource;

  /// No description provided for @analyticsPickMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose month and year'**
  String get analyticsPickMonthTitle;

  /// No description provided for @analyticsPreviousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get analyticsPreviousYear;

  /// No description provided for @analyticsNextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get analyticsNextYear;

  /// No description provided for @analyticsAllYear.
  ///
  /// In en, this message translates to:
  /// **'Whole year'**
  String get analyticsAllYear;

  /// No description provided for @analyticsWholeYear.
  ///
  /// In en, this message translates to:
  /// **'All of {year}'**
  String analyticsWholeYear(String year);

  /// No description provided for @queueUntitledSlip.
  ///
  /// In en, this message translates to:
  /// **'Imported slip'**
  String get queueUntitledSlip;
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
