import '../core/dates/reporting_time_zone.dart';
import '../core/money/currency.dart';
import '../core/money/money.dart';
import '../features/accounts/domain/account.dart';
import '../features/slip_import/domain/scan_record.dart';
import '../features/slip_import/domain/scan_status.dart';
import '../features/transactions/domain/transaction.dart';
import '../features/transactions/domain/transaction_type.dart';
import '../app/app_state.dart';

/// Mock data copied from `design/mockups/prototype.html` (CATS, ACCS, TX,
/// SCANS, BASE, PERIODS, TREND, DAILY, CAM_RESULT, GAL_RESULTS).
///
/// The prototype is pinned to "24 ต.ค. 2569"; here every date is relative
/// to the injected clock's current day in Asia/Bangkok, so the demo stays
/// current. MOCK DATA — not connected to the Drift database.
class DemoSeed {
  DemoSeed(DateTime nowUtc)
    : _now = nowUtc,
      _today = ReportingTimeZone.bangkok.wallClock(nowUtc);

  final DateTime _now;
  final DateTime _today;

  static const _thb = Currency.thb;

  /// UTC instant for [daysAgo] days before today at [hour]:[minute] Bangkok.
  DateTime at(int daysAgo, int hour, int minute) => ReportingTimeZone.bangkok
      .toUtc(_today.year, _today.month, _today.day - daysAgo, hour, minute);

  static Money baht(num amount) => Money((amount * 100).round(), _thb);

  /// Simulated result of the in-app camera capture.
  SlipReading get cameraReading => SlipReading(
    merchant: 'Café Amazon สาขาสามย่าน',
    amountText: '65.00',
    occurredAt: _now,
    categoryId: 'default-expense-food',
    accountId: 'kbank',
    confidence: _allVerified,
  );

  /// Simulated results for the two images picked from the gallery.
  List<SlipReading> get galleryReadings => [
    SlipReading(
      merchant: 'Tops Market',
      amountText: '642.50',
      occurredAt: at(1, 18, 40),
      categoryId: 'default-expense-shopping',
      accountId: 'scb',
      confidence: _allVerified,
    ),
    SlipReading(
      merchant: 'ค่าไฟ กฟน.',
      amountText: '1,245.00',
      occurredAt: at(0, 7, 30),
      categoryId: 'default-expense-bills',
      accountId: 'kbank',
      confidence: {..._allVerified, ReadingField.amount: .uncertain},
    ),
  ];

  static const _allVerified = {
    ReadingField.amount: FieldConfidence.verified,
    ReadingField.date: FieldConfidence.verified,
    ReadingField.time: FieldConfidence.verified,
    ReadingField.merchant: FieldConfidence.verified,
    ReadingField.category: FieldConfidence.verified,
  };

  /// Sample accounts: the prototype's four, with the cash one mapped onto
  /// the default cash account. Opening balances are chosen so the balances
  /// shown in the prototype come out after the sample transactions.
  List<Account> accounts() {
    final txs = transactions();
    return [
      for (final (id, name, last4, balance, kind) in _accounts)
        Account(
          id: id,
          name: name,
          kind: kind,
          currency: _thb,
          lastFour: last4,
          openingBalanceMinor:
              balance * 100 - txs.fold(0, (sum, t) => sum + _effect(t, id)),
          isArchived: false,
          createdAt: _now,
          updatedAt: _now,
        ),
    ];
  }

  static int _effect(MoneyTransaction t, String id) {
    final amount = t.amount.minor;
    return switch (t.type) {
      TransactionType.income => t.accountId == id ? amount : 0,
      TransactionType.expense => t.accountId == id ? -amount : 0,
      TransactionType.transfer =>
        (t.accountId == id ? -amount : 0) +
            (t.destinationAccountId == id ? amount : 0),
    };
  }

  /// Import source shown on the detail screen of sample slip transactions.
  static const transactionImportSources = {
    'tx-1': ImportSource.shareSheet,
    'tx-2': ImportSource.gallery,
    'tx-5': ImportSource.camera,
    'tx-6': ImportSource.gallery,
  };

  /// The sample slip queue (prototype SCANS) and its reading details.
  (List<ScanRecord>, Map<String, ScanDetails>) scans() => _scans();

  List<MoneyTransaction> transactions() {
    MoneyTransaction tx(
      int n,
      String merchant,
      TransactionType type,
      num amount,
      String account, {
      String? category,
      String? to,
      required DateTime at,
      bool slip = false,
      bool ocr = false,
      String? note,
    }) => MoneyTransaction(
      id: 'tx-$n',
      type: type,
      amount: baht(amount),
      accountId: account,
      destinationAccountId: to,
      categoryId: category,
      merchant: merchant,
      note: note,
      occurredAt: at,
      source: ocr ? TransactionSource.ocr : TransactionSource.manual,
      attachmentPath: slip ? demoSlipImage : null,
      createdAt: at,
      updatedAt: at,
    );

    final salaryMonth = _thaiMonths[_today.month - 1];
    return [
      tx(
        1,
        'Grab',
        .expense,
        80,
        'kbank',
        category: 'default-expense-transport',
        at: at(0, 10, 24),
        ocr: true,
      ),
      tx(
        2,
        'Starbucks สยามพารากอน ชั้น G โซนอาหาร',
        .expense,
        120,
        'kbank',
        category: 'default-expense-food',
        at: at(0, 9, 15),
        slip: true,
        ocr: true,
        note: 'Latte grande',
      ),
      tx(
        3,
        'เงินเดือน $salaryMonth',
        .income,
        25000,
        'kbank',
        category: 'default-income-salary',
        at: at(0, 8, 0),
      ),
      tx(
        4,
        'โอนเข้ากระเป๋า',
        .transfer,
        2000,
        'kbank',
        to: 'truemoney',
        at: at(1, 20, 12),
      ),
      tx(
        5,
        '7-Eleven',
        .expense,
        45,
        'default-cash',
        category: 'default-expense-shopping',
        at: at(1, 20, 12),
        slip: true,
        ocr: true,
      ),
      tx(
        6,
        'Netflix',
        .expense,
        349,
        'scb',
        category: 'default-expense-entertainment',
        at: at(1, 18, 24),
        slip: true,
        ocr: true,
      ),
      tx(
        7,
        'ร้านข้าวมันไก่ป้าศรี',
        .expense,
        60,
        'default-cash',
        category: 'default-expense-food',
        at: at(2, 12, 10),
      ),
      tx(
        8,
        'ถอนเงินสด',
        .transfer,
        1000,
        'scb',
        to: 'default-cash',
        at: at(4, 17, 40),
      ),
    ];
  }

  (List<ScanRecord>, Map<String, ScanDetails>) _scans() {
    ScanRecord scan(
      String id,
      ScanStatus status,
      ImportSource source,
      DateTime createdAt, {
      String? transactionId,
    }) => ScanRecord(
      id: id,
      source: source,
      attachmentPath: demoSlipImage,
      status: status,
      transactionId: transactionId,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final scans = [
      scan('s1', .needsReview, .gallery, at(0, 10, 24)),
      scan('s2', .duplicate, .shareSheet, at(0, 10, 30)),
      scan('s3', .failed, .camera, at(0, 10, 31)),
      scan('s4', .processing, .gallery, at(0, 10, 32)),
      scan('s5', .queued, .gallery, at(0, 10, 32)),
      scan('s6', .confirmed, .camera, at(1, 20, 12), transactionId: 'tx-5'),
      scan('s7', .discarded, .gallery, at(1, 18, 30)),
    ];

    final details = {
      's1': ScanDetails(
        fileName: 'IMG_2038.jpg',
        titleKind: .reading,
        reading: SlipReading(
          merchant: 'Starbucks',
          amountText: '1,20.00',
          occurredAt: at(2, 10, 24),
          accountId: 'kbank',
          confidence: const {
            ReadingField.amount: .uncertain,
            ReadingField.date: .verified,
            ReadingField.time: .verified,
            ReadingField.merchant: .verified,
            ReadingField.category: .missing,
          },
        ),
      ),
      's2': ScanDetails(
        fileName: 'IMG_2039.jpg',
        titleKind: .reading,
        duplicateOfTransactionId: 'tx-1',
        reading: SlipReading(
          merchant: 'Grab',
          amountText: '80.00',
          occurredAt: at(0, 10, 24),
          categoryId: 'default-expense-transport',
          accountId: 'kbank',
          providerReference: '…8842',
          confidence: _allVerified,
        ),
      ),
      's3': ScanDetails(
        fileName: 'IMG_2041.jpg',
        retryReading: SlipReading(
          merchant: "Lotus's พระราม 4",
          amountText: '389.00',
          occurredAt: at(0, 10, 5),
          categoryId: 'default-expense-shopping',
          accountId: 'scb',
          confidence: {..._allVerified, ReadingField.time: .uncertain},
        ),
      ),
      's4': const ScanDetails(fileName: 'IMG_2042.jpg'),
      's5': const ScanDetails(fileName: 'IMG_2043.jpg'),
      's6': ScanDetails(
        fileName: 'IMG_2036.jpg',
        titleKind: .reading,
        reading: SlipReading(
          merchant: '7-Eleven',
          amountText: '45.00',
          occurredAt: at(1, 20, 12),
          categoryId: 'default-expense-shopping',
          accountId: 'default-cash',
          confidence: _allVerified,
        ),
      ),
      's7': ScanDetails(
        fileName: 'IMG_2035.jpg',
        titleKind: .discardedDuplicate,
        reading: SlipReading(
          merchant: 'Netflix',
          amountText: '349.00',
          occurredAt: at(1, 18, 24),
          categoryId: 'default-expense-entertainment',
          accountId: 'scb',
          confidence: _allVerified,
        ),
      ),
    };
    return (scans, details);
  }

  static const _accounts = <(String, String, String?, int, AccountKind)>[
    ('kbank', 'กสิกรไทย', '1234', 18250, .bank),
    ('scb', 'SCB', '5678', 6420, .bank),
    ('truemoney', 'TrueMoney', '9012', 0, .ewallet),
    ('default-cash', 'เงินสด', null, 1850, .cash),
  ];

  /// Seed merchant names are Thai user data, so they don't go through intl.
  static const _thaiMonths = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', //
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];
}

/// The sample slip photo from the mockups, standing in for captured images.
const demoSlipImage = 'assets/images/receipt.png';

/// MOCK profile name shown on Home and Settings (no account system yet).
const demoProfileFirstName = 'นนทนันท์';
const demoProfileFullName = 'นนทนันท์ ศิริกานนท์';
