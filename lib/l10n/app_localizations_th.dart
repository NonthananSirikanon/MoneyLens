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
  String get scanStatusQueued => 'รอประมวลผล';

  @override
  String get scanStatusProcessing => 'กำลังประมวลผล';

  @override
  String get scanStatusNeedsReview => 'รอตรวจสอบ';

  @override
  String get scanStatusConfirmed => 'ยืนยันแล้ว';

  @override
  String get scanStatusDuplicate => 'อาจซ้ำ';

  @override
  String get scanStatusFailed => 'ล้มเหลว';

  @override
  String get scanStatusDiscarded => 'ทิ้งแล้ว';

  @override
  String get scanSourceCamera => 'กล้อง';

  @override
  String get scanSourceGallery => 'รูปภาพ';

  @override
  String get scanSourceShareSheet => 'แชร์';

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
}
