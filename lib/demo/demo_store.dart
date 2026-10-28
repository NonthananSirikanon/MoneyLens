import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates/clock.dart';
import '../core/money/currency.dart';
import '../features/accounts/application/account_providers.dart';
import '../features/accounts/domain/account.dart';
import '../features/categories/application/category_providers.dart';
import '../features/categories/domain/category.dart';
import '../features/slip_import/domain/scan_record.dart';
import '../features/slip_import/domain/scan_status.dart';
import '../features/transactions/application/transaction_providers.dart';
import '../features/transactions/domain/transaction.dart';
import '../features/transactions/domain/transaction_type.dart';
import '../infrastructure/database/app_database.dart';
import 'demo_config.dart';
import 'demo_models.dart';
import 'demo_seed.dart';

/// The app's UI store.
///
/// Ledger data (transactions, accounts, categories) is mirrored from the
/// Drift database and every change is written there. The slip queue is
/// SIMULATED in memory (no camera, OCR or gallery adapter is wired yet) and
/// is only populated in sample mode (`ML_SAMPLE_DATA`); see
/// `demo_config.dart`.
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

    final sample = ref.watch(sampleDataEnabledProvider);
    final seed = ref.read(demoSeedProvider);
    final (scans, details) = sample
        ? seed.scans()
        : (const <ScanRecord>[], const <String, ScanDetails>{});

    // Mirror the database. A stream event only signals that something
    // changed; the state is then re-read, so a slow or stale event can never
    // overwrite newer data. Listening (not watching) keeps the slip queue in
    // memory when a ledger stream emits.
    ref.listen(activeAccountsProvider, (_, next) {
      if (next.hasValue) unawaited(_refreshAccounts());
    });
    ref.listen(activeCategoriesProvider, (_, next) {
      if (next.hasValue) unawaited(_refreshCategories());
    });
    ref.listen(allTransactionsProvider, (_, next) {
      if (next.hasValue) unawaited(_refreshTransactions());
    });

    final accounts = ref.read(activeAccountsProvider).value ?? const [];
    final categories = ref.read(activeCategoriesProvider).value ?? const [];
    return DemoState(
      transactions: ref.read(allTransactionsProvider).value ?? const [],
      transactionImportSources: sample
          ? DemoSeed.transactionImportSources
          : const {},
      accounts: accounts,
      accountDetails: _accountDetails(accounts),
      categories: categories,
      categoryStyles: _categoryStyles(categories),
      scans: scans,
      scanDetails: details,
      ocrProgress: const {},
    );
  }

  static Map<String, AccountDetails> _accountDetails(List<Account> accounts) =>
      {for (final a in accounts) a.id: AccountDetails.of(a)};

  static Map<String, CategoryStyle> _categoryStyles(List<Category> cs) => {
    for (final c in cs) c.id: CategoryStyle.of(c),
  };

  // The database streams update the state too, but a write must be visible
  // to the caller as soon as it returns (e.g. before navigating to the new
  // transaction), so each write re-reads what it changed (one-shot reads,
  // not stream queries).
  // Each read carries a sequence number and only the newest one is applied,
  // so a slower, older read can never overwrite newer data.
  var _txSeq = 0;
  var _accountSeq = 0;
  var _categorySeq = 0;

  Future<void> _refreshTransactions() async {
    final seq = ++_txSeq;
    final txs = await ref.read(transactionRepositoryProvider).findAll();
    if (!ref.mounted) return;
    if (seq == _txSeq) state = state.copyWith(transactions: txs);
  }

  Future<void> _refreshAccounts() async {
    final seq = ++_accountSeq;
    final accounts = await ref.read(accountRepositoryProvider).findActive();
    if (!ref.mounted) return;
    if (seq == _accountSeq) _setAccounts(accounts);
  }

  Future<void> _refreshCategories() async {
    final seq = ++_categorySeq;
    final categories = await ref.read(categoryRepositoryProvider).findActive();
    if (!ref.mounted) return;
    if (seq == _categorySeq) _setCategories(categories);
  }

  void _setAccounts(List<Account> accounts) => state = state.copyWith(
    accounts: accounts,
    accountDetails: _accountDetails(accounts),
  );

  void _setCategories(List<Category> categories) => state = state.copyWith(
    categories: categories,
    categoryStyles: _categoryStyles(categories),
  );

  DateTime get _now => ref.read(clockProvider).nowUtc();

  String _nextId(String prefix) =>
      '$prefix-${_now.microsecondsSinceEpoch}-${_idCounter++}';

  // ---------------------------------------------------------------- ledger

  /// Saves a new transaction to the database; when it came from a (mock)
  /// slip, marks that scan confirmed. Returns the new transaction id.
  Future<String> addTransaction(TransactionInput input) async {
    final scan = state.scan(input.scanId);
    final tx = await ref
        .read(createTransactionProvider)
        .call(
          _draft(
            input,
            source: scan == null
                ? TransactionSource.manual
                : TransactionSource.ocr,
            attachmentPath: scan == null ? null : demoSlipImage,
          ),
        );
    await _refreshTransactions();
    if (scan != null) {
      state = state.copyWith(
        transactionImportSources: {
          ...state.transactionImportSources,
          tx.id: scan.source,
        },
      );
      _updateScan(scan.id, status: ScanStatus.confirmed, transactionId: tx.id);
      _setTitleKind(scan.id, ScanTitleKind.reading, reading: _readingFrom(tx));
    }
    return tx.id;
  }

  Future<void> updateTransaction(String id, TransactionInput input) async {
    final old = state.transaction(id);
    await ref
        .read(updateTransactionProvider)
        .call(
          id,
          _draft(
            input,
            source: old?.source ?? TransactionSource.manual,
            attachmentPath: old?.attachmentPath,
          ),
        );
    await _refreshTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await ref.read(transactionRepositoryProvider).delete(id);
    await _refreshTransactions();
  }

  /// "Delete all data" from Settings → Data & export.
  Future<void> wipeAll() async {
    await ref.read(appDatabaseProvider).wipeUserData(_now);
    await Future.wait([
      _refreshTransactions(),
      _refreshAccounts(),
      _refreshCategories(),
    ]);
    state = state.copyWith(
      scans: const [],
      scanDetails: const {},
      ocrProgress: const {},
      transactionImportSources: const {},
    );
  }

  TransactionDraft _draft(
    TransactionInput input, {
    required TransactionSource source,
    String? attachmentPath,
  }) => TransactionDraft(
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
    source: source,
    attachmentPath: attachmentPath,
  );

  // ------------------------------------------------- categories & accounts

  Future<void> addCategory({
    required String name,
    required CategoryKind kind,
    required String iconKey,
    required Color accent,
  }) async {
    await ref
        .read(categoryRepositoryProvider)
        .create(
          name: name,
          kind: kind,
          iconKey: iconKey,
          colorValue: accent.toARGB32(),
        );
    await _refreshCategories();
  }

  Future<void> addAccount({
    required String name,
    required AccountKind kind,
    String? last4,
    required int openingBalanceMinor,
  }) async {
    await ref
        .read(accountRepositoryProvider)
        .create(
          name: name,
          kind: kind,
          currency: Currency.thb,
          openingBalanceMinor: openingBalanceMinor,
          lastFour: last4,
        );
    await _refreshAccounts();
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
}

final demoSeedProvider = Provider<DemoSeed>(
  (ref) => DemoSeed(ref.watch(clockProvider).nowUtc()),
);

final demoStoreProvider = NotifierProvider<DemoStore, DemoState>(DemoStore.new);
