import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates/clock.dart';
import '../core/money/currency.dart';
import '../features/accounts/domain/account.dart';
import '../features/categories/domain/category.dart';
import '../features/slip_import/domain/scan_record.dart';
import '../features/slip_import/domain/scan_status.dart';
import '../features/transactions/domain/transaction.dart';
import '../features/transactions/domain/transaction_type.dart';
import 'demo_models.dart';
import 'demo_scenario.dart';
import 'demo_seed.dart';

/// In-memory stand-in for the ledger, accounts, categories and slip queue.
///
/// MOCK DATA: nothing here touches the Drift database or a real OCR engine.
/// Every action mirrors a handler in `design/mockups/prototype.html` so the
/// prototype's flows work end to end. Swapping to the real repositories is a
/// change to the feature `*_view_providers.dart` files only.
class DemoStore extends Notifier<DemoState> {
  final _timers = <Timer>[];
  var _idCounter = 0;

  @override
  DemoState build() {
    ref.onDispose(() {
      for (final t in _timers) {
        t.cancel();
      }
    });
    final seed = ref.watch(demoSeedProvider).build();
    if (ref.watch(demoScenarioProvider) == DemoScenario.emptyTx) {
      return seed.copyWith(transactions: const [], seedTransactionIds: {});
    }
    return seed;
  }

  DateTime get _now => ref.read(clockProvider).nowUtc();

  String _nextId(String prefix) =>
      '$prefix-${_now.microsecondsSinceEpoch}-${_idCounter++}';

  // ---------------------------------------------------------------- ledger

  /// Saves a new transaction; when it came from a slip, marks the scan
  /// confirmed. Returns the new transaction id.
  String addTransaction(TransactionInput input) {
    final now = _now;
    final id = _nextId('tx');
    final scan = state.scan(input.scanId);
    final tx = MoneyTransaction(
      id: id,
      type: input.type,
      amount: input.amount,
      accountId: input.accountId,
      destinationAccountId: input.type == TransactionType.transfer
          ? input.destinationAccountId
          : null,
      categoryId: input.type == TransactionType.transfer
          ? null
          : input.categoryId,
      merchant: input.merchant,
      note: input.note,
      occurredAt: input.occurredAt,
      source: scan == null ? TransactionSource.manual : TransactionSource.ocr,
      scanRecordId: scan?.id,
      attachmentPath: scan == null ? null : demoSlipImage,
      createdAt: now,
      updatedAt: now,
    );
    state = state.copyWith(
      transactions: _sorted([tx, ...state.transactions]),
      transactionImportSources: scan == null
          ? null
          : {...state.transactionImportSources, id: scan.source},
    );
    if (scan != null) {
      _updateScan(scan.id, status: ScanStatus.confirmed, transactionId: id);
      _setTitleKind(scan.id, ScanTitleKind.reading, reading: _readingFrom(tx));
    }
    return id;
  }

  void updateTransaction(String id, TransactionInput input) {
    final old = state.transaction(id);
    if (old == null) return;
    final updated = MoneyTransaction(
      id: old.id,
      type: input.type,
      amount: input.amount,
      accountId: input.accountId,
      destinationAccountId: input.type == TransactionType.transfer
          ? input.destinationAccountId
          : null,
      categoryId: input.type == TransactionType.transfer
          ? null
          : input.categoryId,
      merchant: input.merchant,
      note: input.note,
      occurredAt: input.occurredAt,
      source: old.source,
      scanRecordId: old.scanRecordId,
      attachmentPath: old.attachmentPath,
      providerReference: old.providerReference,
      createdAt: old.createdAt,
      updatedAt: _now,
    );
    state = state.copyWith(
      transactions: _sorted([
        for (final t in state.transactions) t.id == id ? updated : t,
      ]),
    );
  }

  void deleteTransaction(String id) {
    state = state.copyWith(
      transactions: [
        for (final t in state.transactions)
          if (t.id != id) t,
      ],
    );
  }

  /// "Delete all data" from Settings → Data & export.
  void wipeAll() {
    state = state.copyWith(
      transactions: const [],
      seedTransactionIds: {},
      scans: const [],
      scanDetails: const {},
      ocrProgress: const {},
      baseline: MonthBaseline.empty,
      dailySpend: [for (final _ in state.dailySpend) 0],
      accounts: [for (final a in state.accounts) _withOpening(a, 0)],
    );
  }

  // ------------------------------------------------- categories & accounts

  void addCategory({
    required String name,
    required CategoryKind kind,
    required String iconKey,
    required Color tint,
  }) {
    final now = _now;
    final id = _nextId('cat');
    state = state.copyWith(
      categories: [
        ...state.categories,
        Category(
          id: id,
          name: name,
          kind: kind,
          iconKey: iconKey,
          colorValue: 0xFFB9B3CC,
          isDefault: false,
          isArchived: false,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      categoryStyles: {
        ...state.categoryStyles,
        id: CategoryStyle(tint: tint, chart: const Color(0xFFB9B3CC)),
      },
    );
  }

  void addAccount({
    required String name,
    required AccountKind kind,
    String? last4,
    required int openingBalanceMinor,
  }) {
    final now = _now;
    final id = _nextId('acc');
    state = state.copyWith(
      accounts: [
        ...state.accounts,
        Account(
          id: id,
          name: name,
          kind: kind,
          currency: Currency.thb,
          openingBalanceMinor: openingBalanceMinor,
          isArchived: false,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      accountDetails: {
        ...state.accountDetails,
        id: AccountDetails(
          shortName: name.split(' ').first,
          last4: last4,
          tint: const Color(0xFFE3E8EE),
        ),
      },
    );
  }

  // ------------------------------------------------------------ slip queue

  /// Simulates picking two images from the gallery; each is "read" a moment
  /// later. Returns the new scan ids.
  List<String> importFromGallery() {
    final readings = ref.read(demoSeedProvider).galleryReadings;
    final ids = [
      _addScan(ImportSource.gallery, 'IMG_2051.jpg'),
      _addScan(ImportSource.gallery, 'IMG_2052.jpg'),
    ];
    for (var i = 0; i < ids.length; i++) {
      _timers.add(
        Timer(Duration(milliseconds: 1800 + i * 1400), () {
          if (state.scan(ids[i])?.status != ScanStatus.processing) return;
          _completeRead(ids[i], readings[i]);
        }),
      );
    }
    return ids;
  }

  /// Simulates a camera capture and starts reading it. Returns the scan id.
  String captureFromCamera() {
    final id = _addScan(ImportSource.camera, 'IMG_2050.jpg');
    _runOcr(id, ref.read(demoSeedProvider).cameraReading);
    return id;
  }

  /// Re-reads a failed scan using its prepared retry result.
  void retryFailed(String scanId) {
    final reading = state.scanDetails[scanId]?.retryReading;
    if (reading == null) return;
    _updateScan(scanId, status: ScanStatus.processing);
    _runOcr(scanId, reading);
  }

  void discardScan(String scanId) {
    final scan = state.scan(scanId);
    if (scan == null) return;
    if (scan.status == ScanStatus.duplicate) {
      _setTitleKind(scanId, ScanTitleKind.discardedDuplicate);
    }
    _updateScan(scanId, status: ScanStatus.discarded);
  }

  void removeScan(String scanId) {
    state = state.copyWith(
      scans: [
        for (final s in state.scans)
          if (s.id != scanId) s,
      ],
    );
  }

  /// Scans that still need the user's decision, oldest-first in the queue.
  List<ScanRecord> get pending => [
    for (final s in state.scans)
      if (s.status == ScanStatus.needsReview ||
          s.status == ScanStatus.duplicate)
        s,
  ];

  String _addScan(ImportSource source, String fileName) {
    final now = _now;
    final id = _nextId('scan');
    state = state.copyWith(
      scans: [
        ScanRecord(
          id: id,
          source: source,
          attachmentPath: demoSlipImage,
          status: ScanStatus.processing,
          createdAt: now,
          updatedAt: now,
        ),
        ...state.scans,
      ],
      scanDetails: {
        ...state.scanDetails,
        id: ScanDetails(fileName: fileName),
      },
    );
    return id;
  }

  /// 2.5% every 60ms, as in the prototype's `runOcr`.
  void _runOcr(String scanId, SlipReading reading) {
    state = state.copyWith(ocrProgress: {...state.ocrProgress, scanId: 0});
    late final Timer timer;
    timer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      final pct = ((state.ocrProgress[scanId] ?? 0) + 2.5).clamp(0, 100);
      state = state.copyWith(
        ocrProgress: {...state.ocrProgress, scanId: pct.toDouble()},
      );
      if (pct >= 100) {
        timer.cancel();
        _completeRead(scanId, reading);
      }
    });
    _timers.add(timer);
  }

  void _completeRead(String scanId, SlipReading reading) {
    _updateScan(scanId, status: ScanStatus.needsReview);
    _setTitleKind(scanId, ScanTitleKind.reading, reading: reading);
  }

  void _updateScan(String id, {ScanStatus? status, String? transactionId}) {
    state = state.copyWith(
      scans: [
        for (final s in state.scans)
          if (s.id == id)
            ScanRecord(
              id: s.id,
              source: s.source,
              attachmentPath: s.attachmentPath,
              imageFingerprint: s.imageFingerprint,
              extracted: s.extracted,
              status: status ?? s.status,
              failureCode: s.failureCode,
              duplicateOfScanId: s.duplicateOfScanId,
              transactionId: transactionId ?? s.transactionId,
              processorVersion: s.processorVersion,
              createdAt: s.createdAt,
              updatedAt: _now,
              processedAt: s.processedAt,
            )
          else
            s,
      ],
    );
  }

  void _setTitleKind(String id, ScanTitleKind kind, {SlipReading? reading}) {
    final details = state.scanDetails[id];
    if (details == null) return;
    state = state.copyWith(
      scanDetails: {
        ...state.scanDetails,
        id: details.copyWith(titleKind: kind, reading: reading),
      },
    );
  }

  SlipReading _readingFrom(MoneyTransaction t) => SlipReading(
    merchant: t.merchant ?? '',
    amountText: t.amount.toDecimalString(),
    occurredAt: t.occurredAt,
    categoryId: t.categoryId,
    accountId: t.accountId,
  );

  static Account _withOpening(Account a, int opening) => Account(
    id: a.id,
    name: a.name,
    kind: a.kind,
    currency: a.currency,
    openingBalanceMinor: opening,
    isArchived: a.isArchived,
    createdAt: a.createdAt,
    updatedAt: a.updatedAt,
  );

  static List<MoneyTransaction> _sorted(List<MoneyTransaction> txs) =>
      [...txs]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
}

final demoSeedProvider = Provider<DemoSeed>(
  (ref) => DemoSeed(ref.watch(clockProvider).nowUtc()),
);

final demoStoreProvider = NotifierProvider<DemoStore, DemoState>(DemoStore.new);
