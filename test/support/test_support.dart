import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/app/providers.dart';
import 'package:moneylens/demo/demo_config.dart';
import 'package:moneylens/core/dates/clock.dart';
import 'package:moneylens/core/dates/date_range.dart';
import 'package:moneylens/core/errors/app_failure.dart';
import 'package:moneylens/core/money/currency.dart';
import 'package:moneylens/core/money/money.dart';
import 'package:moneylens/core/utils/id_generator.dart';
import 'package:moneylens/features/auth/application/local_data_eraser.dart';
import 'package:moneylens/features/slip_import/domain/import_ports.dart';
import 'package:moneylens/features/transactions/domain/transaction.dart';
import 'package:moneylens/features/transactions/domain/transaction_repository.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';

AppDatabase openTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

class FixedClock implements Clock {
  FixedClock(this.now);

  DateTime now;

  @override
  DateTime nowUtc() => now;
}

class SequentialIds implements IdGenerator {
  var _next = 0;

  @override
  String newId() => 'id-${_next++}';
}

Money thb(int minor) => Money(minor, Currency.thb);

/// A minimal valid JPEG header; enough for signature-based validation.
Uint8List fakeJpeg([int salt = 0]) =>
    Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, salt]);

MoneyTransaction transaction({
  required TransactionType type,
  required int minor,
  required DateTime occurredAt,
  String id = 'tx',
}) => MoneyTransaction(
  id: id,
  type: type,
  amount: thb(minor),
  accountId: 'acc-1',
  destinationAccountId: type == TransactionType.transfer ? 'acc-2' : null,
  occurredAt: occurredAt,
  source: TransactionSource.manual,
  createdAt: occurredAt,
  updatedAt: occurredAt,
);

/// In-memory image store; nothing touches the file system.
class MemorySlipImageStore implements SlipImageStore {
  final files = <String, Uint8List>{};
  var _next = 0;

  @override
  Future<StoredImage> save(Uint8List bytes, ImageFormat format) async {
    final path = 'slips/${_next++}.${format.name}';
    files[path] = bytes;
    return StoredImage(
      relativePath: path,
      fingerprint: 'fp:${bytes.join(',')}',
    );
  }

  @override
  Future<String> resolve(String relativePath) async => '/memory/$relativePath';

  @override
  Future<void> delete(String relativePath) async => files.remove(relativePath);
}

class StubOcrService implements OcrService {
  StubOcrService({this.failWith});

  final FailureCode? failWith;
  var calls = 0;

  @override
  Future<OcrResult> recognize(String absoluteImagePath) async {
    calls++;
    if (failWith case final code?) throw AppFailure(code);
    return const OcrResult(text: 'stub', engineId: 'stub');
  }
}

/// Transaction repository backed by a list, for widget tests.
class FakeTransactionRepository implements TransactionRepository {
  FakeTransactionRepository([List<MoneyTransaction> initial = const []])
    : _items = [...initial];

  final List<MoneyTransaction> _items;

  @override
  Stream<List<MoneyTransaction>> watchRecent({int limit = 50}) =>
      Stream.value(_items.take(limit).toList());

  @override
  Stream<List<MoneyTransaction>> watchAll() => Stream.value([..._items]);

  @override
  Future<List<MoneyTransaction>> findAll() async => [..._items];

  @override
  Future<MoneyTransaction?> findById(String id) async =>
      _items.where((t) => t.id == id).firstOrNull;

  @override
  Future<MoneyTransaction> update(String id, TransactionDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Stream<List<MoneyTransaction>> watchInRange(DateRange range) =>
      Stream.value(_items.where((t) => range.contains(t.occurredAt)).toList());

  @override
  Future<MoneyTransaction> create(TransactionDraft draft) =>
      throw UnimplementedError();

  @override
  Future<ConfirmResult> confirmFromScan({
    required String scanRecordId,
    required TransactionDraft draft,
  }) => throw UnimplementedError();
}

/// A container backed by an in-memory database seeded with the prototype's
/// sample data (sample mode), with startup already finished.
Future<ProviderContainer> sampleContainer(DateTime now) async {
  final db = openTestDatabase();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(FixedClock(now)),
      sampleDataEnabledProvider.overrideWithValue(true),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  await container.read(appStartupProvider.future);
  return container;
}

/// Remembers what would have been erased from the device, instead of
/// touching the file system.
class RecordingEraser implements LocalDataEraser {
  final erased = <({String userId, List<String> slipPaths})>[];

  @override
  Future<void> erase({
    required String userId,
    required List<String> slipPaths,
  }) async => erased.add((userId: userId, slipPaths: slipPaths));
}
