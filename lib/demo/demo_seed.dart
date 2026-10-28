import 'package:flutter/widgets.dart';

import '../core/dates/reporting_time_zone.dart';
import '../core/money/currency.dart';
import '../core/money/money.dart';
import '../features/accounts/domain/account.dart';
import '../features/categories/domain/category.dart';
import '../features/slip_import/domain/scan_record.dart';
import '../features/slip_import/domain/scan_status.dart';
import '../features/transactions/domain/transaction.dart';
import '../features/transactions/domain/transaction_type.dart';
import 'demo_models.dart';

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
    categoryId: 'food',
    accountId: 'kbank',
    confidence: _allVerified,
  );

  /// Simulated results for the two images picked from the gallery.
  List<SlipReading> get galleryReadings => [
    SlipReading(
      merchant: 'Tops Market',
      amountText: '642.50',
      occurredAt: at(1, 18, 40),
      categoryId: 'shopping',
      accountId: 'scb',
      confidence: _allVerified,
    ),
    SlipReading(
      merchant: 'ค่าไฟ กฟน.',
      amountText: '1,245.00',
      occurredAt: at(0, 7, 30),
      categoryId: 'bills',
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

  DemoState build() {
    final categories = [
      for (final (id, name, icon, chart, kind) in _categories)
        Category(
          id: id,
          name: name,
          kind: kind,
          iconKey: icon,
          colorValue: chart,
          isDefault: true,
          isArchived: false,
          createdAt: _now,
          updatedAt: _now,
        ),
    ];

    final accounts = <Account>[];
    final accountDetails = <String, AccountDetails>{};
    final targetBalances = <String, int>{};
    for (final (id, name, short, last4, tint, balance, kind) in _accounts) {
      accounts.add(
        Account(
          id: id,
          name: name,
          kind: kind,
          currency: _thb,
          isArchived: false,
          createdAt: _now,
          updatedAt: _now,
        ),
      );
      accountDetails[id] = AccountDetails(
        shortName: short,
        last4: last4,
        tint: Color(tint),
      );
      targetBalances[id] = balance * 100;
    }

    final transactions = _transactions();

    // The prototype's balances already include the seed transactions, so
    // back out their effect to get each opening balance.
    final openedAccounts = [
      for (final a in accounts)
        Account(
          id: a.id,
          name: a.name,
          kind: a.kind,
          currency: a.currency,
          openingBalanceMinor:
              targetBalances[a.id]! -
              transactions.fold(0, (sum, t) => sum + balanceEffect(t, a.id)),
          isArchived: false,
          createdAt: a.createdAt,
          updatedAt: a.updatedAt,
        ),
    ];

    final (scans, scanDetails) = _scans();

    return DemoState(
      transactions: transactions,
      seedTransactionIds: {for (final t in transactions) t.id},
      transactionImportSources: const {
        'tx-1': ImportSource.shareSheet,
        'tx-2': ImportSource.gallery,
        'tx-5': ImportSource.camera,
        'tx-6': ImportSource.gallery,
      },
      accounts: openedAccounts,
      accountDetails: accountDetails,
      categories: categories,
      categoryStyles: {
        for (final (id, _, _, chart, _) in _categories)
          id: CategoryStyle(tint: Color(_tints[id]!), chart: Color(chart)),
      },
      categorySeedCounts: const {
        'food': 24,
        'shopping': 18,
        'transport': 31,
        'entertainment': 8,
        'bills': 3,
        'other': 5,
        'salary': 1,
        'freelance': 2,
        'gift': 0,
        'otherInc': 0,
      },
      scans: scans,
      scanDetails: scanDetails,
      ocrProgress: const {},
      baseline: const MonthBaseline(
        income: 2840000,
        expense: 1235000,
        transfers: 800000,
        expenseByCategory: {
          'food': 518700,
          'shopping': 275000,
          'transport': 185000,
          'entertainment': 125000,
          'other': 131300,
        },
        incomeByCategory: {'salary': 2500000, 'freelance': 340000},
      ),
      pastPeriods: const [
        PastPeriod(
          monthsAgo: 1,
          expenseByCategory: {
            'food': 462000,
            'shopping': 310500,
            'transport': 172000,
            'entertainment': 89000,
            'other': 64500,
          },
          incomeByCategory: {'salary': 2500000, 'freelance': 430000},
          transfers: 650000,
        ),
        PastPeriod(
          monthsAgo: 6,
          expenseByCategory: {},
          incomeByCategory: {},
          transfers: 0,
        ),
      ],
      trend: const [
        TrendMonth(monthsAgo: 5, income: 2750000, expense: 1020000),
        TrendMonth(monthsAgo: 4, income: 2800000, expense: 989000),
        TrendMonth(monthsAgo: 3, income: 2600000, expense: 2750000),
        TrendMonth(monthsAgo: 2, income: 2820000, expense: 960000),
        TrendMonth(monthsAgo: 1, income: 2930000, expense: 1098000),
        TrendMonth(monthsAgo: 0, income: 2840000, expense: 1235000),
      ],
      dailySpend: [
        for (var day = 0; day < _today.day; day++)
          _daily[day % _daily.length] * 100,
      ],
    );
  }

  List<MoneyTransaction> _transactions() {
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
        category: 'transport',
        at: at(0, 10, 24),
        ocr: true,
      ),
      tx(
        2,
        'Starbucks สยามพารากอน ชั้น G โซนอาหาร',
        .expense,
        120,
        'kbank',
        category: 'food',
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
        category: 'salary',
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
        'cash',
        category: 'shopping',
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
        category: 'entertainment',
        at: at(1, 18, 24),
        slip: true,
        ocr: true,
      ),
      tx(
        7,
        'ร้านข้าวมันไก่ป้าศรี',
        .expense,
        60,
        'cash',
        category: 'food',
        at: at(2, 12, 10),
      ),
      tx(8, 'ถอนเงินสด', .transfer, 1000, 'scb', to: 'cash', at: at(4, 17, 40)),
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
          categoryId: 'transport',
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
          categoryId: 'shopping',
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
          categoryId: 'shopping',
          accountId: 'cash',
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
          categoryId: 'entertainment',
          accountId: 'scb',
          confidence: _allVerified,
        ),
      ),
    };
    return (scans, details);
  }

  static const _categories = <(String, String, String, int, CategoryKind)>[
    ('food', 'อาหารและเครื่องดื่ม', 'coffee', 0xFFE09A88, .expense),
    ('shopping', 'ช้อปปิ้ง', 'shopping-bag', 0xFF93ABCB, .expense),
    ('transport', 'เดินทาง', 'bus', 0xFFE2BC6E, .expense),
    ('entertainment', 'บันเทิง', 'clapperboard', 0xFFA8B89A, .expense),
    ('bills', 'ค่าน้ำ ค่าไฟ', 'zap', 0xFFB9B3CC, .expense),
    ('other', 'อื่นๆ', 'ellipsis', 0xFFC9C8C2, .expense),
    ('salary', 'เงินเดือน', 'banknote', 0xFF4F8A68, .income),
    ('freelance', 'ฟรีแลนซ์', 'laptop', 0xFFA8B89A, .income),
    ('gift', 'ของขวัญ', 'gift', 0xFFE2BC6E, .income),
    ('otherInc', 'รายรับอื่นๆ', 'circle-plus', 0xFFC9C8C2, .income),
  ];

  static const _tints = <String, int>{
    'food': 0xFFF6E4E2,
    'shopping': 0xFFE3E8EE,
    'transport': 0xFFF7EDD6,
    'entertainment': 0xFFE6EBDF,
    'bills': 0xFFECEAF2,
    'other': 0xFFF0F0EC,
    'salary': 0xFFE3EFE7,
    'freelance': 0xFFE6EBDF,
    'gift': 0xFFF7EDD6,
    'otherInc': 0xFFF0F0EC,
  };

  static const _accounts =
      <(String, String, String, String?, int, int, AccountKind)>[
        ('kbank', 'กสิกรไทย', 'KBank', '1234', 0xFFE3EFE7, 18250, .bank),
        ('scb', 'SCB', 'SCB', '5678', 0xFFECEAF2, 6420, .bank),
        (
          'truemoney',
          'TrueMoney',
          'TrueMoney',
          '9012',
          0xFFF7EDD6,
          0,
          .ewallet,
        ),
        ('cash', 'เงินสด', 'เงินสด', null, 0xFFE6EBDF, 1850, .cash),
      ];

  /// Seed merchant names are Thai user data, so they don't go through intl.
  static const _thaiMonths = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', //
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  static const _daily = [
    420, 180, 650, 300, 820, 240, 510, 390, 150, 700, 460, 880, //
    330, 270, 610, 520, 190, 740, 560, 410, 300, 1245, 394, 200,
  ];
}

/// The sample slip photo from the mockups, standing in for captured images.
const demoSlipImage = 'assets/images/receipt.png';

/// Icon/tint choices for the "new category" sheet (prototype NC_TINTS).
const newCategoryTints = [
  Color(0xFFF6E4E2),
  Color(0xFFE3E8EE),
  Color(0xFFF7EDD6),
  Color(0xFFE6EBDF),
  Color(0xFFECEAF2),
  Color(0xFFE3EFE7),
];

/// MOCK profile name shown on Home and Settings (no account system yet).
const demoProfileFirstName = 'นนทนันท์';
const demoProfileFullName = 'นนทนันท์ ศิริกานนท์';
