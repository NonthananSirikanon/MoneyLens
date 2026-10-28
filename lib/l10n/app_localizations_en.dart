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
  String get scanStatusProcessing => 'Reading slip…';

  @override
  String get scanStatusNeedsReview => 'Needs review';

  @override
  String get scanStatusConfirmed => 'Saved';

  @override
  String get scanStatusDuplicate => 'Possible duplicate';

  @override
  String get scanStatusFailed => 'Couldn\'t read';

  @override
  String get scanStatusDiscarded => 'Discarded';

  @override
  String get scanSourceCamera => 'Camera';

  @override
  String get scanSourceGallery => 'Gallery';

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

  @override
  String get actionBack => 'Back';

  @override
  String get actionClose => 'Close';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionNext => 'Next';

  @override
  String get actionRetry => 'Try again';

  @override
  String get navHome => 'Home';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAdd => 'Add transaction';

  @override
  String get typeExpense => 'Expense';

  @override
  String get typeIncome => 'Income';

  @override
  String get typeTransfer => 'Transfer';

  @override
  String get typeAll => 'All';

  @override
  String get transferCategoryName => 'Transfer';

  @override
  String get soonTag => 'Soon';

  @override
  String get testingTag => 'In testing';

  @override
  String get hiddenAmount => '••••';

  @override
  String get hiddenBalance => '฿ ••••••';

  @override
  String get transfersExcludedNote => 'Excludes transfers between accounts';

  @override
  String get slipOriginal => 'Original slip';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingTitle1 => 'Understand\nyour money';

  @override
  String get onboardingBody1 =>
      'Import transfer slips and receipts. The app reads the details and turns them into transactions for you.';

  @override
  String get onboardingTitle2 => 'Always review\nbefore saving';

  @override
  String get onboardingBody2 =>
      'What the app reads from a slip is only a draft. You can edit and confirm it every time; nothing is saved silently.';

  @override
  String get onboardingTitle3 => 'Your data stays\non your phone';

  @override
  String get onboardingBody3 =>
      'Works offline. Your financial data and slip images stay on this device and are never sent anywhere without telling you.';

  @override
  String get permissionTitle => 'Let MoneyLens read your slips';

  @override
  String get permissionBody =>
      'We only ask when you use a feature, and you can say no. You can always add transactions manually.';

  @override
  String get permissionCamera => 'Camera';

  @override
  String get permissionCameraBody => 'Photograph paper slips or another screen';

  @override
  String get permissionPhotos => 'Photos';

  @override
  String get permissionPhotosBody => 'Choose only the slips you want';

  @override
  String get permissionAuto => 'Detect new slips automatically';

  @override
  String get permissionAutoBody => 'Depends on iOS/Android';

  @override
  String get permissionAllow => 'Allow and get started';

  @override
  String get permissionLater => 'Maybe later';

  @override
  String get toastPermissionGranted => 'Access allowed';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get addSheetTitle => 'Add transaction';

  @override
  String get addOptionCamera => 'Scan a slip';

  @override
  String get addOptionCameraSub => 'Paper slip or another phone\'s screen';

  @override
  String get addOptionGallery => 'Choose from Photos';

  @override
  String get addOptionGallerySub => 'Pick several at once';

  @override
  String get addOptionManual => 'Add manually';

  @override
  String get addOptionManualSub => 'Expense, income or transfer';

  @override
  String get addOptionAuto => 'Detect new slips automatically';

  @override
  String get addOptionAutoSub => 'Depends on iOS/Android support';

  @override
  String get addSheetShareHint =>
      'Or share slip images from your banking app into MoneyLens';

  @override
  String get toastFeatureTesting => 'This feature is being tested';

  @override
  String toastImportedPhotos(int count) {
    return 'Imported $count photos, reading slips…';
  }

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get offlineTitle => 'You\'re offline — everything still works';

  @override
  String get offlineBody =>
      'Add, edit and browse as usual. Your data is on this device.';

  @override
  String pendingSlipsTitle(int count) {
    return '$count slips waiting for review';
  }

  @override
  String get pendingSlipsBody => 'Tap to check them before saving';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get toggleBalanceVisibility => 'Hide or show balances';

  @override
  String get transfersExcludedShort => 'Excludes transfers between accounts';

  @override
  String get quickScan => 'Scan slip';

  @override
  String get quickManual => 'Add manually';

  @override
  String get quickReport => 'View report';

  @override
  String get recentTitle => 'Recent transactions';

  @override
  String get seeAll => 'See all';

  @override
  String get seeAllShort => 'All';

  @override
  String get dailySpendTitle => 'Daily spending';

  @override
  String dailySpendDay(String date) {
    return '$date';
  }

  @override
  String get today => 'Today';

  @override
  String get topCategoriesTitle => 'Top spending categories';

  @override
  String topCategoryMeta(int percent, int count) {
    return '$percent% · $count transactions';
  }

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get searchPlaceholder => 'Search merchants, notes…';

  @override
  String get categoryChip => 'Category';

  @override
  String get filterByCategory => 'Filter by category';

  @override
  String get allCategories => 'All categories';

  @override
  String get clearFilter => 'Clear filter';

  @override
  String get transferInfoTitle =>
      'Transfers aren\'t counted as income or expenses';

  @override
  String get transferInfoBody => 'They move money between your own accounts';

  @override
  String get loadErrorTitle => 'Couldn\'t load transactions';

  @override
  String get loadErrorBody =>
      'Your data is still safe. Try again,\nor restart the app if it keeps happening.';

  @override
  String errorCode(String code) {
    return 'Code: $code';
  }

  @override
  String get noMatchesTitle => 'No matching transactions';

  @override
  String get noMatchesBody => 'Try another search or clear the filters';

  @override
  String get transactionsEmptyTitle => 'No transactions yet';

  @override
  String get transactionsEmptyBody =>
      'Start by scanning a slip or adding one manually';

  @override
  String dayToday(String date) {
    return 'Today · $date';
  }

  @override
  String dayYesterday(String date) {
    return 'Yesterday · $date';
  }

  @override
  String get detailDate => 'Date';

  @override
  String get detailCategory => 'Category';

  @override
  String get detailAccount => 'Account';

  @override
  String get detailFrom => 'From account';

  @override
  String get detailTo => 'To account';

  @override
  String get detailNote => 'Note';

  @override
  String get detailSource => 'Source';

  @override
  String get sourceManual => 'Added manually';

  @override
  String sourceSlip(String source) {
    return 'Slip · $source';
  }

  @override
  String get slipTapToView => 'Tap to view full screen';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get deleteTitle => 'Delete this transaction?';

  @override
  String get deleteBody =>
      'The transaction and its attached slip will be deleted permanently. This can\'t be undone.';

  @override
  String get deleteConfirm => 'Delete permanently';

  @override
  String get toastDeleted => 'Transaction deleted';

  @override
  String get entryTitleAdd => 'Add transaction';

  @override
  String get entryTitleEdit => 'Edit transaction';

  @override
  String get entryTitleReview => 'Review transaction';

  @override
  String get entrySaveAdd => 'Save transaction';

  @override
  String get entrySaveEdit => 'Save changes';

  @override
  String get entrySaveTransfer => 'Save transfer';

  @override
  String get entrySaveReview => 'Confirm and save';

  @override
  String get entryDiscard => 'Discard';

  @override
  String get entryAmount => 'Amount';

  @override
  String get entryTime => 'Time';

  @override
  String get entryMerchant => 'Merchant / payee';

  @override
  String get entryPayer => 'Payer / source';

  @override
  String get entryTransferDetail => 'Details';

  @override
  String get entryMerchantPlaceholder => 'e.g. Pa Sri\'s chicken rice';

  @override
  String get entryTransferPlaceholder => 'e.g. Top up wallet';

  @override
  String get entryOptional => 'Optional';

  @override
  String get entrySameAccount =>
      'Source and destination must be different accounts';

  @override
  String get entryTransferNoteTitle => 'Not counted as income or expense';

  @override
  String get entryTransferNoteBody =>
      'Only the source balance goes down and the destination goes up';

  @override
  String get pickCategory => 'Choose a category';

  @override
  String get pickAccount => 'Choose an account';

  @override
  String get viewSlip => 'View slip';

  @override
  String get actionDone => 'Done';

  @override
  String reviewHighlightTitle(int count) {
    return 'Check $count highlighted fields';
  }

  @override
  String get reviewHighlightBody =>
      'OCR results are only a draft. You can edit every field before saving.';

  @override
  String get reviewAllReadTitle => 'Every field was read';

  @override
  String get reviewAllReadBody => 'Please check once more before saving';

  @override
  String get fieldVerified => 'Read clearly';

  @override
  String get fieldUncertain => 'OCR isn\'t sure — please check';

  @override
  String get fieldMissing => 'Required before saving';

  @override
  String get errorAmountFormat => 'Invalid amount format, e.g. 120.00';

  @override
  String get errorAmountRequired => 'Enter an amount greater than 0';

  @override
  String get errorMerchantRequired => 'Enter a merchant or payee';

  @override
  String get errorTransferDetailRequired => 'Enter transfer details';

  @override
  String get toastEditSaved => 'Changes saved';

  @override
  String get toastSlipDiscarded => 'Slip discarded';

  @override
  String transactionCount(int count) {
    return '$count transactions';
  }

  @override
  String get accountSavings => 'Savings';

  @override
  String get accountWallet => 'Wallet';

  @override
  String get accountKindWallet => 'e-Wallet';

  @override
  String queueTitle(int count) {
    return 'Imported slips · $count';
  }

  @override
  String get queueNotice =>
      'Every slip is reviewed before saving — nothing is saved automatically';

  @override
  String get queueActionReview => 'Review';

  @override
  String get queueActionCompare => 'Compare';

  @override
  String get queueActionRetry => 'Retry';

  @override
  String queueDuplicateTitle(String amount) {
    return 'Duplicate slip · ฿$amount';
  }

  @override
  String get scansEmptyBody => 'Scan or choose a slip to get started';

  @override
  String get cameraTitle => 'Scan slip';

  @override
  String get cameraHint =>
      'Fit the slip inside the frame · reads automatically when sharp';

  @override
  String get cameraGallery => 'Photos';

  @override
  String get cameraShutter => 'Take photo';

  @override
  String get cameraFlash => 'Flash';

  @override
  String get previewTitle => 'Check photo';

  @override
  String get previewImage => 'Slip photo';

  @override
  String get previewQuestion =>
      'Is the photo sharp with the full amount visible?';

  @override
  String get previewRetake => 'Retake';

  @override
  String get previewUse => 'Use photo';

  @override
  String get processingTitle => 'Reading slip';

  @override
  String get processingStepFile => 'Checking the image file';

  @override
  String get processingStepRecord => 'Creating the import record';

  @override
  String get processingStepOcr => 'Reading text (OCR)…';

  @override
  String get processingStepExtract => 'Extracting amount, date and merchant';

  @override
  String get processingStepDuplicate => 'Checking for duplicates';

  @override
  String get processingLeaveNote =>
      'You can close this screen — the slip stays in the queue';

  @override
  String get processingGoQueue => 'Go to slip queue';

  @override
  String get duplicateTitle => 'Possible duplicate';

  @override
  String get duplicateBannerTitle => 'A very similar transaction exists';

  @override
  String get duplicateBannerBody => 'Amount, date and reference match';

  @override
  String get duplicateNew => 'New slip';

  @override
  String get duplicateSaved => 'Already saved';

  @override
  String get duplicateMerchant => 'Merchant';

  @override
  String get duplicateAmount => 'Amount';

  @override
  String get duplicateReference => 'Reference';

  @override
  String get duplicateMatch => 'Matches';

  @override
  String get duplicateMatchHint =>
      'if you really paid twice, you can still save it';

  @override
  String get duplicateDiscard => 'Discard this slip (duplicate)';

  @override
  String get duplicateKeep => 'Not a duplicate, continue';

  @override
  String get toastDuplicateDiscarded => 'Duplicate slip discarded';

  @override
  String get ocrFailedTitle => 'Couldn\'t read slip';

  @override
  String get ocrFailedHeading => 'The details couldn\'t be read';

  @override
  String get ocrFailedBody =>
      'The photo may be blurry or dark, or the slip format isn\'t supported yet';

  @override
  String get ocrTipsTitle => 'Try this';

  @override
  String get ocrTipLight => 'Shoot in good light without shadows';

  @override
  String get ocrTipVisible => 'Keep the amount and date fully visible';

  @override
  String get ocrTipScreenshot =>
      'Use a screenshot from your banking app instead';

  @override
  String get ocrRetry => 'Read again';

  @override
  String get ocrManual => 'Enter manually';

  @override
  String get ocrDelete => 'Delete slip';

  @override
  String get toastSlipDeleted => 'Slip deleted';

  @override
  String get savedTitle => 'Saved';

  @override
  String get savedView => 'View transaction';

  @override
  String savedNext(int count) {
    return 'Review next slip ($count)';
  }

  @override
  String get savedHome => 'Back to Home';

  @override
  String get deniedCameraTitle => 'MoneyLens can\'t access the camera yet';

  @override
  String get deniedPhotosTitle => 'MoneyLens can\'t access your photos yet';

  @override
  String get deniedBody =>
      'Allow access in Settings, or use another way instead';

  @override
  String get deniedOpenSettings => 'Open Settings';

  @override
  String get deniedAltGallery => 'Choose from Photos';

  @override
  String get deniedAltCamera => 'Scan with the camera';

  @override
  String get toastPermissionOpened => 'Access turned on';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get analyticsTabBreakdown => 'By category';

  @override
  String get analyticsTabTrend => 'Trend';

  @override
  String analyticsTransfersExcluded(String amount) {
    return 'Excludes transfers between accounts $amount';
  }

  @override
  String get analyticsTotalExpense => 'Total expenses';

  @override
  String get analyticsTotalIncome => 'Total income';

  @override
  String get analyticsEmptyTitle => 'No data for this period';

  @override
  String get analyticsEmptyBody =>
      'Try another period, or add transactions for this month';

  @override
  String get analyticsChangePeriod => 'Change period';

  @override
  String get analyticsAvgIncome => 'Average income';

  @override
  String get analyticsAvgExpense => 'Average expenses';

  @override
  String get analyticsIncomeVsExpense => 'Income vs expenses';

  @override
  String get analyticsSixMonths => '6 months';

  @override
  String analyticsNet(String month) {
    return 'Net $month';
  }

  @override
  String analyticsOverspend(String month, String amount) {
    return '$month: spent $amount more than earned';
  }

  @override
  String analyticsMonthBar(String month, String income, String expense) {
    return '$month: income $income, expenses $expense';
  }

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get addCategory => 'Add category';

  @override
  String get newCategoryTitle => 'New category';

  @override
  String get categoryNameLabel => 'Category name';

  @override
  String get categoryNamePlaceholder => 'e.g. Pets';

  @override
  String get categoryIconLabel => 'Icon';

  @override
  String get categoryColorLabel => 'Background colour';

  @override
  String categoryColorOption(int index) {
    return 'Colour $index';
  }

  @override
  String get saveCategory => 'Save category';

  @override
  String toastCategoryAdded(String name) {
    return 'Added category \"$name\"';
  }

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsTotal => 'Total across accounts';

  @override
  String accountsCount(int count) {
    return '$count accounts · hidden accounts excluded';
  }

  @override
  String get accountsGroupBank => 'Banks';

  @override
  String get accountsGroupOther => 'e-Wallets and cash';

  @override
  String get addAccount => 'Add account';

  @override
  String get accountsMaskNote => 'Account numbers are only shown masked';

  @override
  String toastAccountEdit(String name) {
    return '$name · edit account';
  }

  @override
  String get newAccountTitle => 'New account';

  @override
  String get accountKindBank => 'Bank';

  @override
  String get accountKindEwallet => 'e-Wallet';

  @override
  String get accountKindCash => 'Cash';

  @override
  String get accountNameLabel => 'Account name';

  @override
  String get accountNamePlaceholder => 'e.g. Bangkok Bank savings';

  @override
  String get accountLast4Label => 'Last 4 digits (optional)';

  @override
  String get accountLast4Hint =>
      'Only the last 4 digits are kept, to help match slips';

  @override
  String get accountOpeningLabel => 'Opening balance';

  @override
  String get saveAccount => 'Save account';

  @override
  String toastAccountAdded(String name) {
    return 'Added account \"$name\"';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsGroupFinance => 'Finance';

  @override
  String get settingsGroupDisplay => 'Display';

  @override
  String get settingsGroupData => 'Data and security';

  @override
  String get settingsImportedSlips => 'Imported slips';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageName => 'English';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get toastCurrencyOnly => 'Only THB is supported for now';

  @override
  String get settingsDataExport => 'Data and export';

  @override
  String get settingsPrivacy => 'Privacy and security';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsAbout => 'About MoneyLens';

  @override
  String settingsVersion(String version) {
    return 'MoneyLens · version $version';
  }

  @override
  String get p1Tag => 'P1';

  @override
  String get dataTitle => 'Data and export';

  @override
  String get dataGroupCsv => 'Export as CSV';

  @override
  String get dataCsvWarning =>
      'The file contains sensitive financial data — store and share it carefully';

  @override
  String get dataRange => 'Period';

  @override
  String get toastPickRange => 'Choose a period';

  @override
  String get dataExportCsv => 'Export CSV';

  @override
  String dataExportCount(int count) {
    return '$count transactions';
  }

  @override
  String toastExported(String file) {
    return 'Exported $file';
  }

  @override
  String get dataGroupSlips => 'Stored slip images';

  @override
  String get dataSlipsOnDevice => 'Slip images on this device';

  @override
  String dataSlipsSize(int count, String size) {
    return '$count images · $size';
  }

  @override
  String get dataAutoDelete => 'Auto-delete images of saved slips';

  @override
  String get dataAutoDeleteSub => 'After 30 days';

  @override
  String get dataWipe => 'Delete all data';

  @override
  String get dataWipeSub =>
      'Permanently delete transactions, accounts and slip images (including the server copy)';

  @override
  String get wipeTitle => 'Delete all data?';

  @override
  String get wipeBody =>
      'All transactions, accounts and slip images on this device, and their copies on the server, will be deleted permanently. This can\'t be undone.';

  @override
  String get wipeConfirm => 'Delete everything';

  @override
  String get toastWiped => 'All data deleted';

  @override
  String get securityTitle => 'Privacy';

  @override
  String get securityGroupAccess => 'Access';

  @override
  String get securityFaceId => 'Lock the app with Face ID';

  @override
  String get securityFaceIdSub => 'Verify every time the app opens';

  @override
  String get securityHideBalances => 'Hide balances on Home';

  @override
  String get securityGroupPermissions => 'App permissions';

  @override
  String get securityCamera => 'Camera access';

  @override
  String get securityPhotos => 'Photo access';

  @override
  String get permissionAllowed => 'Allowed';

  @override
  String get permissionDenied => 'Not allowed';

  @override
  String get permissionLimited => 'Selected photos';

  @override
  String get toastPermissionRevoked => 'Access turned off (simulated)';

  @override
  String get securityLocalNote =>
      'Your entries are backed up to your account; slip images stay on this device only · slip content and account numbers are never written to logs';

  @override
  String get authLoginTitle => 'Get started with\nMoneyLens';

  @override
  String get authLoginBody => 'Sign in to keep your data safe';

  @override
  String get authLocalNote =>
      'Your entries are backed up to your account; slip images stay on your phone';

  @override
  String get authWithGoogle => 'Continue with Google';

  @override
  String get authTerms =>
      'By continuing, you accept the Terms of Use and Privacy Policy';

  @override
  String get authErrTooMany => 'Too many requests. Please try again later';

  @override
  String get authErrNetwork =>
      'Couldn\'t reach the server. Check your connection and try again';

  @override
  String get authErrUnknown => 'Something went wrong. Please try again';

  @override
  String get authBirthTitle => 'Your details';

  @override
  String get authBirthEditTitle => 'Edit birth date';

  @override
  String get authBirthHeading => 'Your date of birth';

  @override
  String get authBirthBody =>
      'Used as your profile information and never shown to others';

  @override
  String get authDay => 'Day';

  @override
  String get authMonth => 'Month';

  @override
  String get authYear => 'Year (B.E.)';

  @override
  String get authDayHint => 'DD';

  @override
  String get authYearHint => '2540';

  @override
  String get authPickMonth => 'Choose month';

  @override
  String get authPickMonthTitle => 'Birth month';

  @override
  String authAge(int years) {
    return 'Age $years';
  }

  @override
  String get authYearNote => 'Use the Buddhist year, e.g. 2540';

  @override
  String get authBirthIncomplete => 'Fill in day, month and year';

  @override
  String get authBirthYearFormat => 'Enter a 4-digit Buddhist year, e.g. 2540';

  @override
  String authBirthNoSuch(int day, String month, String year) {
    return 'There is no $day $month in $year';
  }

  @override
  String get authBirthFuture => 'Date of birth can\'t be after today';

  @override
  String get authBirthSaveFailed =>
      'Couldn\'t save. Check your connection and try again';

  @override
  String get authContinue => 'Continue';

  @override
  String get authSave => 'Save';

  @override
  String get toastBirthSaved => 'Birth date saved';

  @override
  String get accountTitle => 'My account';

  @override
  String get accountViaGoogle => 'Signed in with Google';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountBirth => 'Date of birth';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignOutSub => 'Data on this device stays';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody =>
      'Your data on this device stays, but you\'ll need to sign in again to keep using the app.';

  @override
  String get toastSignedOut => 'Signed out';

  @override
  String get settingsAccountSub => 'Account and profile';

  @override
  String get profileFallbackName => 'there';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncRunning => 'Syncing…';

  @override
  String get syncNever => 'Never synced · tap to sync now';

  @override
  String syncDone(String time) {
    return 'Last synced $time · tap to sync now';
  }

  @override
  String syncPending(int count) {
    return '$count changes waiting · tap to sync now';
  }

  @override
  String get syncOffline => 'No internet. Will retry automatically';

  @override
  String get syncFailed =>
      'Sync failed. Will retry automatically · tap to try now';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteSub =>
      'Permanently delete the account and all its data';

  @override
  String get accountDeleting => 'Deleting account…';

  @override
  String get deleteAccountTitle => 'Delete this account?';

  @override
  String get deleteAccountBody =>
      'Your transactions, accounts, categories and date of birth will be permanently deleted from the server and from this device. This can\'t be undone. Your Google account itself is not deleted.';

  @override
  String get deleteAccountAction => 'Continue';

  @override
  String get deleteAccountAgainTitle => 'Delete permanently';

  @override
  String get deleteAccountAgainBody =>
      'Everything will be gone immediately and can\'t be recovered. Do you really want to delete the account?';

  @override
  String get deleteAccountAgainAction => 'Delete account permanently';

  @override
  String get toastAccountDeleted => 'Account deleted';

  @override
  String get accountDeleteNeedsInternet =>
      'You need an internet connection to delete the account. Try again when you\'re connected.';

  @override
  String get exportPeriodThisMonth => 'This month';

  @override
  String get exportPeriodLast3 => 'Last 3 months';

  @override
  String get exportPeriodThisYear => 'This year';

  @override
  String get exportPeriodAll => 'All time';

  @override
  String get exportEmpty => 'No transactions in this period';

  @override
  String get exportFailed => 'Export failed. Try again';

  @override
  String get csvColDate => 'Date';

  @override
  String get csvColTime => 'Time';

  @override
  String get csvColType => 'Type';

  @override
  String get csvColAmount => 'Amount';

  @override
  String get csvColCurrency => 'Currency';

  @override
  String get csvColAccount => 'Account';

  @override
  String get csvColToAccount => 'To account';

  @override
  String get csvColCategory => 'Category';

  @override
  String get csvColMerchant => 'Merchant / payee';

  @override
  String get csvColNote => 'Note';

  @override
  String get csvColSource => 'Source';

  @override
  String get analyticsPickMonthTitle => 'Choose month and year';

  @override
  String get analyticsPreviousYear => 'Previous year';

  @override
  String get analyticsNextYear => 'Next year';
}
