// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'MoneyLens';

  @override
  String get navDashboard => 'ภาพรวม';

  @override
  String get navTransactions => 'รายการ';

  @override
  String get navImport => 'นำเข้า';

  @override
  String get dashboardThisMonth => 'เดือนนี้';

  @override
  String get summaryIncome => 'รายรับ';

  @override
  String get summaryExpense => 'รายจ่าย';

  @override
  String get summaryNet => 'สุทธิ';

  @override
  String summaryTransfers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'โอน $count รายการ (ไม่นับรวม)',
      zero: 'ไม่มีการโอน',
    );
    return '$_temp0';
  }

  @override
  String get recentTransactions => 'รายการล่าสุด';

  @override
  String get transactionsEmpty => 'ยังไม่มีรายการ';

  @override
  String get transactionTypeIncome => 'รายรับ';

  @override
  String get transactionTypeExpense => 'รายจ่าย';

  @override
  String get transactionTypeTransfer => 'โอน';

  @override
  String get loadError => 'เกิดข้อผิดพลาดระหว่างโหลดข้อมูล';

  @override
  String get startupError => 'MoneyLens เปิดข้อมูลในเครื่องไม่ได้';

  @override
  String get retry => 'ลองใหม่';

  @override
  String get discard => 'ทิ้ง';

  @override
  String get importTitle => 'นำเข้าสลิป';

  @override
  String get importFromCamera => 'กล้อง';

  @override
  String get importFromGallery => 'รูปภาพ';

  @override
  String get importShareSheetHint =>
      'ยังแชร์สลิปจากแอปอื่นเข้า MoneyLens ไม่ได้';

  @override
  String get importReviewNotice =>
      'สลิปที่นำเข้าจะแสดงให้ตรวจสอบก่อนบันทึกเสมอ';

  @override
  String get scansTitle => 'สลิปที่นำเข้า';

  @override
  String get scansEmpty => 'ยังไม่มีสลิปที่นำเข้า';

  @override
  String get scanStatusQueued => 'รอคิว';

  @override
  String get scanStatusProcessing => 'กำลังอ่านสลิป…';

  @override
  String get scanStatusNeedsReview => 'รอตรวจสอบ';

  @override
  String get scanStatusConfirmed => 'บันทึกแล้ว';

  @override
  String get scanStatusDuplicate => 'อาจซ้ำ';

  @override
  String get scanStatusFailed => 'อ่านไม่สำเร็จ';

  @override
  String get scanStatusDiscarded => 'ทิ้งแล้ว';

  @override
  String get scanSourceCamera => 'กล้อง';

  @override
  String get scanSourceGallery => 'Gallery';

  @override
  String get scanSourceShareSheet => 'Share Sheet';

  @override
  String get scanSourceDiscovery => 'ตรวจพบ';

  @override
  String get failureUnsupportedFile => 'ไฟล์นี้ไม่ใช่รูปภาพที่รองรับ';

  @override
  String get failureFileTooLarge => 'รูปภาพมีขนาดใหญ่เกินไป';

  @override
  String get failurePermissionDenied => 'ไม่ได้รับสิทธิ์ อนุญาตได้ในการตั้งค่า';

  @override
  String get failureUnreadableImage => 'อ่านรูปภาพไม่ได้';

  @override
  String get failureOcrUnavailable => 'ยังไม่รองรับการอ่านข้อความจากสลิป';

  @override
  String get failureExtractionFailed => 'ดึงข้อมูลธุรกรรมไม่ได้';

  @override
  String get failureGeneric => 'เกิดข้อผิดพลาด โปรดลองใหม่';

  @override
  String get actionBack => 'ย้อนกลับ';

  @override
  String get actionClose => 'ปิด';

  @override
  String get actionCancel => 'ยกเลิก';

  @override
  String get actionNext => 'ถัดไป';

  @override
  String get actionRetry => 'ลองใหม่';

  @override
  String get navHome => 'หน้าหลัก';

  @override
  String get navAnalytics => 'วิเคราะห์';

  @override
  String get navSettings => 'ตั้งค่า';

  @override
  String get navAdd => 'เพิ่มรายการ';

  @override
  String get typeExpense => 'รายจ่าย';

  @override
  String get typeIncome => 'รายรับ';

  @override
  String get typeTransfer => 'โอน';

  @override
  String get typeAll => 'ทั้งหมด';

  @override
  String get transferCategoryName => 'โอน';

  @override
  String get soonTag => 'เร็วๆ นี้';

  @override
  String get testingTag => 'กำลังทดสอบ';

  @override
  String get hiddenAmount => '••••';

  @override
  String get hiddenBalance => '฿ ••••••';

  @override
  String get transfersExcludedNote => 'ไม่รวมการโอนระหว่างบัญชี';

  @override
  String get slipOriginal => 'สลิปต้นฉบับ';

  @override
  String get onboardingSkip => 'ข้าม';

  @override
  String get onboardingStart => 'เริ่มใช้งาน';

  @override
  String get onboardingTitle1 => 'เข้าใจเงิน\nของคุณ';

  @override
  String get onboardingBody1 =>
      'นำเข้าสลิปโอนเงินและใบเสร็จ แอปอ่านรายละเอียดให้ แล้วจัดเป็นรายการให้อัตโนมัติ';

  @override
  String get onboardingTitle2 => 'ตรวจก่อน\nบันทึกเสมอ';

  @override
  String get onboardingBody2 =>
      'ผลจากการอ่านสลิปเป็นแค่ร่าง คุณแก้ไขและยืนยันเองได้ทุกครั้ง ไม่มีอะไรบันทึกเงียบๆ';

  @override
  String get onboardingTitle3 => 'ข้อมูลอยู่\nในเครื่องคุณ';

  @override
  String get onboardingBody3 =>
      'ใช้ได้แม้ไม่มีเน็ต ข้อมูลการเงินและรูปสลิปเก็บในเครื่อง ไม่ส่งไปที่อื่นโดยไม่บอก';

  @override
  String get permissionTitle => 'ให้ MoneyLens อ่านสลิปได้';

  @override
  String get permissionBody =>
      'เราขอสิทธิ์เฉพาะตอนที่คุณใช้ฟีเจอร์นั้น และปฏิเสธได้ ยังเพิ่มรายการเองได้เสมอ';

  @override
  String get permissionCamera => 'กล้อง';

  @override
  String get permissionCameraBody => 'ถ่ายสลิปกระดาษหรือหน้าจอ';

  @override
  String get permissionPhotos => 'รูปภาพ';

  @override
  String get permissionPhotosBody => 'เลือกเฉพาะรูปสลิปที่คุณต้องการ';

  @override
  String get permissionAuto => 'ตรวจสลิปใหม่อัตโนมัติ';

  @override
  String get permissionAutoBody => 'ขึ้นกับ iOS/Android';

  @override
  String get permissionAllow => 'อนุญาตและเริ่มใช้งาน';

  @override
  String get permissionLater => 'ไว้ทีหลัง';

  @override
  String get toastPermissionGranted => 'อนุญาตแล้ว';

  @override
  String get uncategorized => 'ไม่มีหมวด';

  @override
  String get addSheetTitle => 'เพิ่มรายการ';

  @override
  String get addOptionCamera => 'ถ่ายสลิป';

  @override
  String get addOptionCameraSub => 'สลิปกระดาษหรือหน้าจออีกเครื่อง';

  @override
  String get addOptionGallery => 'เลือกจากรูปภาพ';

  @override
  String get addOptionGallerySub => 'เลือกได้หลายรูปพร้อมกัน';

  @override
  String get addOptionManual => 'เพิ่มรายการเอง';

  @override
  String get addOptionManualSub => 'รายจ่าย รายรับ หรือโอน';

  @override
  String get addOptionAuto => 'ตรวจสลิปใหม่อัตโนมัติ';

  @override
  String get addOptionAutoSub => 'ขึ้นกับความสามารถของ iOS/Android';

  @override
  String get addSheetShareHint =>
      'หรือแชร์รูปสลิปจากแอปธนาคารเข้า MoneyLens ได้เลย';

  @override
  String get toastFeatureTesting => 'ฟีเจอร์นี้กำลังทดสอบ';

  @override
  String toastImportedPhotos(int count) {
    return 'นำเข้า $count รูป กำลังอ่านสลิป…';
  }

  @override
  String get greetingMorning => 'สวัสดีตอนเช้า';

  @override
  String get greetingAfternoon => 'สวัสดีตอนบ่าย';

  @override
  String get greetingEvening => 'สวัสดีตอนเย็น';

  @override
  String get offlineTitle => 'ออฟไลน์อยู่ — ใช้งานได้ตามปกติ';

  @override
  String get offlineBody => 'บันทึก แก้ไข และดูรายการได้ ข้อมูลอยู่ในเครื่อง';

  @override
  String pendingSlipsTitle(int count) {
    return 'มีสลิปรอตรวจ $count รายการ';
  }

  @override
  String get pendingSlipsBody => 'แตะเพื่อตรวจสอบก่อนบันทึก';

  @override
  String get totalBalance => 'ยอดคงเหลือรวม';

  @override
  String get toggleBalanceVisibility => 'ซ่อน/แสดงยอด';

  @override
  String get transfersExcludedShort => 'ไม่รวมการโอนระหว่างบัญชี';

  @override
  String get quickScan => 'สแกนสลิป';

  @override
  String get quickManual => 'เพิ่มเอง';

  @override
  String get quickReport => 'ดูรายงาน';

  @override
  String get recentTitle => 'รายการล่าสุด';

  @override
  String get seeAll => 'ดูทั้งหมด';

  @override
  String get seeAllShort => 'ทั้งหมด';

  @override
  String get dailySpendTitle => 'ใช้จ่ายรายวัน';

  @override
  String dailySpendDay(String date) {
    return 'วันที่ $date';
  }

  @override
  String get today => 'วันนี้';

  @override
  String get topCategoriesTitle => 'หมวดใช้จ่ายสูงสุด';

  @override
  String topCategoryMeta(int percent, int count) {
    return '$percent% · $count รายการ';
  }

  @override
  String get transactionsTitle => 'รายการ';

  @override
  String get searchPlaceholder => 'ค้นหาร้านค้า หมายเหตุ…';

  @override
  String get categoryChip => 'หมวด';

  @override
  String get filterByCategory => 'กรองตามหมวด';

  @override
  String get allCategories => 'ทุกหมวด';

  @override
  String get clearFilter => 'ล้างตัวกรอง';

  @override
  String get transferInfoTitle => 'การโอนไม่นับเป็นรายรับหรือรายจ่าย';

  @override
  String get transferInfoBody => 'เป็นการย้ายเงินระหว่างบัญชีของคุณเอง';

  @override
  String get loadErrorTitle => 'โหลดรายการไม่สำเร็จ';

  @override
  String get loadErrorBody =>
      'ข้อมูลของคุณยังอยู่ครบ ลองใหม่อีกครั้ง\nหากยังไม่หาย ให้รีสตาร์ตแอป';

  @override
  String errorCode(String code) {
    return 'รหัส: $code';
  }

  @override
  String get noMatchesTitle => 'ไม่พบรายการที่ค้นหา';

  @override
  String get noMatchesBody => 'ลองคำค้นอื่น หรือล้างตัวกรอง';

  @override
  String get transactionsEmptyTitle => 'ยังไม่มีรายการ';

  @override
  String get transactionsEmptyBody => 'เริ่มจากสแกนสลิป หรือเพิ่มรายการเอง';

  @override
  String dayToday(String date) {
    return 'วันนี้ · $date';
  }

  @override
  String dayYesterday(String date) {
    return 'เมื่อวาน · $date';
  }

  @override
  String get detailDate => 'วันที่';

  @override
  String get detailCategory => 'หมวดหมู่';

  @override
  String get detailAccount => 'บัญชี';

  @override
  String get detailFrom => 'จากบัญชี';

  @override
  String get detailTo => 'ไปบัญชี';

  @override
  String get detailNote => 'หมายเหตุ';

  @override
  String get detailSource => 'แหล่งที่มา';

  @override
  String get sourceManual => 'เพิ่มเอง';

  @override
  String sourceSlip(String source) {
    return 'สลิป · $source';
  }

  @override
  String get slipTapToView => 'แตะเพื่อดูเต็มจอ';

  @override
  String get actionDelete => 'ลบ';

  @override
  String get actionEdit => 'แก้ไข';

  @override
  String get deleteTitle => 'ลบรายการนี้?';

  @override
  String get deleteBody =>
      'รายการและรูปสลิปที่แนบจะถูกลบถาวร ไม่สามารถกู้คืนได้';

  @override
  String get deleteConfirm => 'ลบถาวร';

  @override
  String get toastDeleted => 'ลบรายการแล้ว';

  @override
  String get entryTitleAdd => 'เพิ่มรายการ';

  @override
  String get entryTitleEdit => 'แก้ไขรายการ';

  @override
  String get entryTitleReview => 'ตรวจสอบรายการ';

  @override
  String get entrySaveAdd => 'บันทึกรายการ';

  @override
  String get entrySaveEdit => 'บันทึกการแก้ไข';

  @override
  String get entrySaveTransfer => 'บันทึกการโอน';

  @override
  String get entrySaveReview => 'ยืนยันและบันทึก';

  @override
  String get entryDiscard => 'ทิ้ง';

  @override
  String get entryAmount => 'จำนวนเงิน';

  @override
  String get entryTime => 'เวลา';

  @override
  String get entryMerchant => 'ร้านค้า / ผู้รับ';

  @override
  String get entryPayer => 'ผู้จ่าย / แหล่งที่มา';

  @override
  String get entryTransferDetail => 'รายละเอียด';

  @override
  String get entryMerchantPlaceholder => 'เช่น ร้านข้าวมันไก่ป้าศรี';

  @override
  String get entryTransferPlaceholder => 'เช่น โอนเข้ากระเป๋า';

  @override
  String get entryOptional => 'ไม่บังคับ';

  @override
  String get entrySameAccount => 'บัญชีต้นทางและปลายทางต้องเป็นคนละบัญชี';

  @override
  String get entryTransferNoteTitle => 'ไม่นับเป็นรายรับ/รายจ่าย';

  @override
  String get entryTransferNoteBody => 'ยอดบัญชีต้นทางลด ปลายทางเพิ่ม เท่านั้น';

  @override
  String get pickCategory => 'เลือกหมวดหมู่';

  @override
  String get pickAccount => 'เลือกบัญชี';

  @override
  String get viewSlip => 'ดูสลิป';

  @override
  String get actionDone => 'เสร็จสิ้น';

  @override
  String reviewHighlightTitle(int count) {
    return 'ตรวจ $count ช่องที่ไฮไลต์';
  }

  @override
  String get reviewHighlightBody =>
      'ผลจาก OCR เป็นแค่ร่าง แก้ไขได้ทุกช่องก่อนบันทึก';

  @override
  String get reviewAllReadTitle => 'อ่านได้ครบทุกช่อง';

  @override
  String get reviewAllReadBody => 'โปรดตรวจอีกครั้งก่อนบันทึก';

  @override
  String get fieldVerified => 'อ่านได้ชัดเจน';

  @override
  String get fieldUncertain => 'OCR ไม่แน่ใจ — โปรดตรวจสอบ';

  @override
  String get fieldMissing => 'จำเป็นต้องเลือกก่อนบันทึก';

  @override
  String get errorAmountFormat => 'รูปแบบจำนวนเงินไม่ถูกต้อง เช่น 120.00';

  @override
  String get errorAmountRequired => 'กรอกจำนวนเงินมากกว่า 0';

  @override
  String get errorMerchantRequired => 'ใส่ชื่อร้านค้าหรือผู้รับ';

  @override
  String get errorTransferDetailRequired => 'ใส่รายละเอียดการโอน';

  @override
  String get toastEditSaved => 'บันทึกการแก้ไขแล้ว';

  @override
  String get toastSlipDiscarded => 'ทิ้งสลิปแล้ว';

  @override
  String transactionCount(int count) {
    return '$count รายการ';
  }

  @override
  String get accountSavings => 'ออมทรัพย์';

  @override
  String get accountWallet => 'กระเป๋าสตางค์';

  @override
  String get accountKindWallet => 'e-Wallet';

  @override
  String queueTitle(int count) {
    return 'สลิปที่นำเข้า · $count';
  }

  @override
  String get queueNotice =>
      'สลิปทุกใบต้องตรวจก่อนบันทึก ไม่มีการบันทึกอัตโนมัติ';

  @override
  String get queueActionReview => 'ตรวจสอบ';

  @override
  String get queueActionCompare => 'เปรียบเทียบ';

  @override
  String get queueActionRetry => 'ลองใหม่';

  @override
  String queueDuplicateTitle(String amount) {
    return 'สลิปซ้ำ · ฿$amount';
  }

  @override
  String get scansEmptyBody => 'สแกนหรือเลือกรูปสลิปเพื่อเริ่มต้น';

  @override
  String get cameraTitle => 'สแกนสลิป';

  @override
  String get cameraHint => 'วางสลิปให้อยู่ในกรอบ · อ่านอัตโนมัติเมื่อชัด';

  @override
  String get cameraGallery => 'รูปภาพ';

  @override
  String get cameraShutter => 'ถ่าย';

  @override
  String get cameraFlash => 'แฟลช';

  @override
  String get previewTitle => 'ตรวจรูป';

  @override
  String get previewImage => 'รูปสลิป';

  @override
  String get previewQuestion => 'รูปชัดและเห็นยอดเงินครบหรือไม่?';

  @override
  String get previewRetake => 'ถ่ายใหม่';

  @override
  String get previewUse => 'ใช้รูปนี้';

  @override
  String get processingTitle => 'กำลังอ่านสลิป';

  @override
  String get processingStepFile => 'ตรวจไฟล์รูป';

  @override
  String get processingStepRecord => 'สร้างระเบียนนำเข้า';

  @override
  String get processingStepOcr => 'อ่านข้อความ (OCR)…';

  @override
  String get processingStepExtract => 'แยกยอดเงิน วันที่ ร้านค้า';

  @override
  String get processingStepDuplicate => 'ตรวจรายการซ้ำ';

  @override
  String get processingLeaveNote =>
      'ปิดหน้านี้ได้ — สลิปจะอยู่ในคิวและไม่หายไป';

  @override
  String get processingGoQueue => 'ไปที่คิวสลิป';

  @override
  String get duplicateTitle => 'อาจเป็นรายการซ้ำ';

  @override
  String get duplicateBannerTitle => 'พบรายการที่คล้ายกันมาก';

  @override
  String get duplicateBannerBody => 'ยอด วันที่ และเลขอ้างอิงตรงกัน';

  @override
  String get duplicateNew => 'สลิปใหม่';

  @override
  String get duplicateSaved => 'บันทึกไว้แล้ว';

  @override
  String get duplicateMerchant => 'ร้านค้า';

  @override
  String get duplicateAmount => 'ยอด';

  @override
  String get duplicateReference => 'อ้างอิง';

  @override
  String get duplicateMatch => 'ตรงกัน';

  @override
  String get duplicateMatchHint => 'ถ้าเป็นการจ่ายจริง 2 ครั้ง ให้บันทึกต่อได้';

  @override
  String get duplicateDiscard => 'ทิ้งสลิปนี้ (ซ้ำ)';

  @override
  String get duplicateKeep => 'ไม่ซ้ำ บันทึกต่อ';

  @override
  String get toastDuplicateDiscarded => 'ทิ้งสลิปซ้ำแล้ว';

  @override
  String get ocrFailedTitle => 'อ่านสลิปไม่สำเร็จ';

  @override
  String get ocrFailedHeading => 'อ่านรายละเอียดไม่ได้';

  @override
  String get ocrFailedBody =>
      'รูปอาจเบลอ มืด หรือเป็นรูปแบบสลิปที่ยังไม่รองรับ';

  @override
  String get ocrTipsTitle => 'ลองแบบนี้';

  @override
  String get ocrTipLight => 'ถ่ายในที่สว่าง ไม่มีเงาทับ';

  @override
  String get ocrTipVisible => 'ให้เห็นยอดเงินและวันที่ครบ';

  @override
  String get ocrTipScreenshot => 'ใช้ภาพหน้าจอจากแอปธนาคารแทนการถ่าย';

  @override
  String get ocrRetry => 'ลองอ่านใหม่';

  @override
  String get ocrManual => 'กรอกเอง';

  @override
  String get ocrDelete => 'ลบสลิป';

  @override
  String get toastSlipDeleted => 'ลบสลิปแล้ว';

  @override
  String get savedTitle => 'บันทึกแล้ว';

  @override
  String get savedView => 'ดูรายการ';

  @override
  String savedNext(int count) {
    return 'ตรวจสลิปถัดไป ($count)';
  }

  @override
  String get savedHome => 'กลับหน้าหลัก';

  @override
  String get deniedCameraTitle => 'MoneyLens ยังเข้าถึงกล้องไม่ได้';

  @override
  String get deniedPhotosTitle => 'MoneyLens ยังเข้าถึงรูปภาพไม่ได้';

  @override
  String get deniedBody => 'เปิดสิทธิ์ในการตั้งค่า หรือใช้วิธีอื่นแทนก็ได้';

  @override
  String get deniedOpenSettings => 'เปิดการตั้งค่า';

  @override
  String get deniedAltGallery => 'เลือกจากรูปภาพ';

  @override
  String get deniedAltCamera => 'ถ่ายสลิปด้วยกล้อง';

  @override
  String get toastPermissionOpened => 'เปิดสิทธิ์แล้ว';

  @override
  String get analyticsTitle => 'วิเคราะห์';

  @override
  String get analyticsTabBreakdown => 'แยกหมวด';

  @override
  String get analyticsTabTrend => 'แนวโน้ม';

  @override
  String analyticsTransfersExcluded(String amount) {
    return 'ไม่รวมการโอนระหว่างบัญชี $amount';
  }

  @override
  String get analyticsTotalExpense => 'รายจ่ายทั้งหมด';

  @override
  String get analyticsTotalIncome => 'รายรับทั้งหมด';

  @override
  String get analyticsEmptyTitle => 'ไม่มีข้อมูลในช่วงนี้';

  @override
  String get analyticsEmptyBody =>
      'ลองเลือกช่วงเวลาอื่น หรือเพิ่มรายการของเดือนนี้';

  @override
  String get analyticsChangePeriod => 'เปลี่ยนช่วงเวลา';

  @override
  String get analyticsAvgIncome => 'รายรับเฉลี่ย';

  @override
  String get analyticsAvgExpense => 'รายจ่ายเฉลี่ย';

  @override
  String get analyticsIncomeVsExpense => 'รายรับ vs รายจ่าย';

  @override
  String get analyticsSixMonths => '6 เดือน';

  @override
  String analyticsNet(String month) {
    return 'คงเหลือสุทธิ $month';
  }

  @override
  String analyticsOverspend(String month, String amount) {
    return '$month ใช้จ่ายมากกว่ารายรับ $amount';
  }

  @override
  String analyticsMonthBar(String month, String income, String expense) {
    return '$month รายรับ $income รายจ่าย $expense';
  }

  @override
  String get categoriesTitle => 'หมวดหมู่';

  @override
  String get addCategory => 'เพิ่มหมวดหมู่';

  @override
  String get newCategoryTitle => 'หมวดหมู่ใหม่';

  @override
  String get categoryNameLabel => 'ชื่อหมวด';

  @override
  String get categoryNamePlaceholder => 'เช่น สัตว์เลี้ยง';

  @override
  String get categoryIconLabel => 'ไอคอน';

  @override
  String get categoryColorLabel => 'สีพื้น';

  @override
  String categoryColorOption(int index) {
    return 'สี $index';
  }

  @override
  String get saveCategory => 'บันทึกหมวดหมู่';

  @override
  String toastCategoryAdded(String name) {
    return 'เพิ่มหมวด \"$name\" แล้ว';
  }

  @override
  String get accountsTitle => 'บัญชี';

  @override
  String get accountsTotal => 'ยอดรวมทุกบัญชี';

  @override
  String accountsCount(int count) {
    return '$count บัญชี · ไม่รวมบัญชีที่ซ่อน';
  }

  @override
  String get accountsGroupBank => 'ธนาคาร';

  @override
  String get accountsGroupOther => 'e-Wallet และเงินสด';

  @override
  String get addAccount => 'เพิ่มบัญชี';

  @override
  String get accountsMaskNote => 'แสดงเลขบัญชีแบบ mask เท่านั้น';

  @override
  String toastAccountEdit(String name) {
    return '$name · แก้ไขบัญชี';
  }

  @override
  String get newAccountTitle => 'บัญชีใหม่';

  @override
  String get accountKindBank => 'ธนาคาร';

  @override
  String get accountKindEwallet => 'e-Wallet';

  @override
  String get accountKindCash => 'เงินสด';

  @override
  String get accountNameLabel => 'ชื่อบัญชี';

  @override
  String get accountNamePlaceholder => 'เช่น กรุงเทพ ออมทรัพย์';

  @override
  String get accountLast4Label => 'เลขท้ายบัญชี (ไม่บังคับ)';

  @override
  String get accountLast4Hint => 'เก็บแค่ 4 ตัวท้ายเพื่อช่วยจับคู่สลิป';

  @override
  String get accountOpeningLabel => 'ยอดเริ่มต้น';

  @override
  String get saveAccount => 'บันทึกบัญชี';

  @override
  String toastAccountAdded(String name) {
    return 'เพิ่มบัญชี \"$name\" แล้ว';
  }

  @override
  String get settingsTitle => 'ตั้งค่า';

  @override
  String get settingsProfile => 'โปรไฟล์';

  @override
  String get settingsGroupFinance => 'การเงิน';

  @override
  String get settingsGroupDisplay => 'การแสดงผล';

  @override
  String get settingsGroupData => 'ข้อมูลและความปลอดภัย';

  @override
  String get settingsImportedSlips => 'สลิปที่นำเข้า';

  @override
  String get settingsTheme => 'ธีม';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get themeDark => 'มืด';

  @override
  String get themeSystem => 'ตามระบบ';

  @override
  String get settingsLanguage => 'ภาษา';

  @override
  String get languageName => 'ไทย';

  @override
  String get settingsCurrency => 'สกุลเงิน';

  @override
  String get toastCurrencyOnly => 'รองรับ THB เท่านั้นในตอนนี้';

  @override
  String get settingsDataExport => 'ข้อมูลและการส่งออก';

  @override
  String get settingsPrivacy => 'ความเป็นส่วนตัวและความปลอดภัย';

  @override
  String get settingsNotifications => 'การแจ้งเตือน';

  @override
  String get settingsAbout => 'เกี่ยวกับ MoneyLens';

  @override
  String settingsVersion(String version) {
    return 'MoneyLens · เวอร์ชัน $version';
  }

  @override
  String get p1Tag => 'P1';

  @override
  String get dataTitle => 'ข้อมูลและการส่งออก';

  @override
  String get dataGroupCsv => 'ส่งออกเป็น CSV';

  @override
  String get dataCsvWarning =>
      'ไฟล์มีข้อมูลการเงินที่ละเอียดอ่อน — เก็บและแชร์อย่างระวัง';

  @override
  String get dataRange => 'ช่วงเวลา';

  @override
  String get toastPickRange => 'เลือกช่วงเวลา';

  @override
  String get dataExportCsv => 'ส่งออก CSV';

  @override
  String dataExportCount(int count) {
    return '$count รายการ';
  }

  @override
  String toastExported(String file) {
    return 'ส่งออก $file แล้ว';
  }

  @override
  String get dataGroupSlips => 'รูปสลิปที่เก็บไว้';

  @override
  String get dataSlipsOnDevice => 'รูปสลิปในเครื่อง';

  @override
  String dataSlipsSize(int count, String size) {
    return '$count รูป · $size';
  }

  @override
  String get dataAutoDelete => 'ลบรูปสลิปที่บันทึกแล้วอัตโนมัติ';

  @override
  String get dataAutoDeleteSub => 'หลัง 30 วัน';

  @override
  String get dataWipe => 'ลบข้อมูลทั้งหมด';

  @override
  String get dataWipeSub =>
      'ลบรายการ บัญชี และรูปสลิปถาวร (รวมสำเนาบนเซิร์ฟเวอร์)';

  @override
  String get wipeTitle => 'ลบข้อมูลทั้งหมด?';

  @override
  String get wipeBody =>
      'รายการ บัญชี และรูปสลิปทั้งหมดในเครื่องนี้และสำเนาบนเซิร์ฟเวอร์จะถูกลบถาวร ไม่สามารถกู้คืนได้';

  @override
  String get wipeConfirm => 'ลบทั้งหมด';

  @override
  String get toastWiped => 'ลบข้อมูลทั้งหมดแล้ว';

  @override
  String get securityTitle => 'ความเป็นส่วนตัว';

  @override
  String get securityGroupAccess => 'การเข้าถึง';

  @override
  String get securityFaceId => 'ล็อกแอปด้วย Face ID';

  @override
  String get securityFaceIdSub => 'ต้องยืนยันตัวตนทุกครั้งที่เปิด';

  @override
  String get securityHideBalances => 'ซ่อนยอดเงินบนหน้าแรก';

  @override
  String get securityGroupPermissions => 'สิทธิ์ของแอป';

  @override
  String get securityCamera => 'สิทธิ์กล้อง';

  @override
  String get securityPhotos => 'สิทธิ์รูปภาพ';

  @override
  String get permissionAllowed => 'อนุญาต';

  @override
  String get permissionDenied => 'ไม่อนุญาต';

  @override
  String get permissionLimited => 'เลือกบางรูป';

  @override
  String get toastPermissionRevoked => 'ปิดสิทธิ์แล้ว (จำลอง)';

  @override
  String get securityLocalNote =>
      'รายการเงินสำรองไว้ในบัญชีของคุณ ส่วนรูปสลิปอยู่ในเครื่องนี้เท่านั้น · ไม่มีการเขียนเนื้อหาสลิปหรือเลขบัญชีลง log';

  @override
  String get authLoginTitle => 'เริ่มต้นกับ\nMoneyLens';

  @override
  String get authLoginBody => 'เข้าสู่ระบบเพื่อเก็บข้อมูลของคุณให้ปลอดภัย';

  @override
  String get authLocalNote =>
      'รายการเงินสำรองในบัญชีของคุณ รูปสลิปเก็บในเครื่องเท่านั้น';

  @override
  String get authWithGoogle => 'ดำเนินการต่อด้วย Google';

  @override
  String get authTerms =>
      'เมื่อดำเนินการต่อ แปลว่าคุณยอมรับเงื่อนไขการใช้งานและนโยบายความเป็นส่วนตัว';

  @override
  String get authErrTooMany => 'ขอรหัสบ่อยเกินไป โปรดลองใหม่ภายหลัง';

  @override
  String get authErrNetwork =>
      'เชื่อมต่อไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง';

  @override
  String get authErrUnknown => 'เกิดข้อผิดพลาด โปรดลองอีกครั้ง';

  @override
  String get authBirthTitle => 'ข้อมูลของคุณ';

  @override
  String get authBirthEditTitle => 'แก้ไขวันเกิด';

  @override
  String get authBirthHeading => 'วันเกิดของคุณ';

  @override
  String get authBirthBody => 'ใช้เป็นข้อมูลโปรไฟล์ของคุณ ไม่แสดงให้ใครเห็น';

  @override
  String get authDay => 'วัน';

  @override
  String get authMonth => 'เดือน';

  @override
  String get authYear => 'ปี (พ.ศ.)';

  @override
  String get authDayHint => 'วว';

  @override
  String get authYearHint => '2540';

  @override
  String get authPickMonth => 'เลือกเดือน';

  @override
  String get authPickMonthTitle => 'เลือกเดือนเกิด';

  @override
  String authAge(int years) {
    return 'อายุ $years ปี';
  }

  @override
  String get authYearNote => 'ปีเกิดเป็น พ.ศ. เช่น 2540';

  @override
  String get authBirthIncomplete => 'กรอกวัน เดือน และปีเกิดให้ครบ';

  @override
  String get authBirthYearFormat => 'ใส่ปี พ.ศ. 4 หลัก เช่น 2540';

  @override
  String authBirthNoSuch(int day, String month, String year) {
    return 'ไม่มีวันที่ $day $month ในปี $year';
  }

  @override
  String get authBirthFuture => 'วันเกิดต้องไม่เกินวันนี้';

  @override
  String get authBirthSaveFailed =>
      'บันทึกไม่สำเร็จ ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง';

  @override
  String get authContinue => 'ดำเนินการต่อ';

  @override
  String get authSave => 'บันทึก';

  @override
  String get toastBirthSaved => 'บันทึกวันเกิดแล้ว';

  @override
  String get accountTitle => 'บัญชีของฉัน';

  @override
  String get accountViaGoogle => 'เข้าสู่ระบบด้วย Google';

  @override
  String get accountEmail => 'อีเมล';

  @override
  String get accountBirth => 'วันเกิด';

  @override
  String get accountSignOut => 'ออกจากระบบ';

  @override
  String get accountSignOutSub => 'ข้อมูลในเครื่องยังอยู่';

  @override
  String get signOutTitle => 'ออกจากระบบ?';

  @override
  String get signOutBody =>
      'ข้อมูลในเครื่องยังอยู่ แต่ต้องเข้าสู่ระบบอีกครั้งจึงจะใช้งานต่อ';

  @override
  String get toastSignedOut => 'ออกจากระบบแล้ว';

  @override
  String get settingsAccountSub => 'บัญชีและโปรไฟล์';

  @override
  String get profileFallbackName => 'คุณ';

  @override
  String get syncTitle => 'ซิงก์ข้อมูล';

  @override
  String get syncRunning => 'กำลังซิงก์…';

  @override
  String get syncNever => 'ยังไม่เคยซิงก์ · แตะเพื่อซิงก์ตอนนี้';

  @override
  String syncDone(String time) {
    return 'ซิงก์ล่าสุด $time · แตะเพื่อซิงก์ตอนนี้';
  }

  @override
  String syncPending(int count) {
    return 'รอส่ง $count รายการ · แตะเพื่อซิงก์ตอนนี้';
  }

  @override
  String get syncOffline => 'ไม่มีอินเทอร์เน็ต จะลองใหม่อัตโนมัติ';

  @override
  String get syncFailed =>
      'ซิงก์ไม่สำเร็จ จะลองใหม่อัตโนมัติ · แตะเพื่อลองเดี๋ยวนี้';

  @override
  String get accountDelete => 'ลบบัญชี';

  @override
  String get accountDeleteSub => 'ลบบัญชีและข้อมูลทั้งหมดถาวร';

  @override
  String get accountDeleting => 'กำลังลบบัญชี…';

  @override
  String get deleteAccountTitle => 'ลบบัญชีนี้?';

  @override
  String get deleteAccountBody =>
      'รายการ บัญชี หมวดหมู่ และวันเกิดของคุณจะถูกลบถาวรทั้งบนเซิร์ฟเวอร์และในเครื่องนี้ ไม่สามารถกู้คืนได้ บัญชี Google ของคุณเองไม่ถูกลบ';

  @override
  String get deleteAccountAction => 'ดำเนินการต่อ';

  @override
  String get deleteAccountAgainTitle => 'ยืนยันลบถาวร';

  @override
  String get deleteAccountAgainBody =>
      'ข้อมูลทั้งหมดจะหายไปทันทีและกู้คืนไม่ได้ ต้องการลบบัญชีจริงหรือไม่';

  @override
  String get deleteAccountAgainAction => 'ลบบัญชีถาวร';

  @override
  String get toastAccountDeleted => 'ลบบัญชีแล้ว';

  @override
  String get accountDeleteNeedsInternet =>
      'ต้องมีอินเทอร์เน็ตเพื่อลบบัญชี ลองอีกครั้งเมื่อเชื่อมต่อแล้ว';
}
