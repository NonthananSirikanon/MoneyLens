import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/dates/clock.dart';
import '../../../core/errors/app_failure.dart';
import '../../../infrastructure/database/app_database.dart';
import '../domain/extracted_fields.dart';
import '../domain/scan_record.dart';
import '../domain/scan_repository.dart';
import '../domain/scan_status.dart';

class DriftScanRepository implements ScanRepository {
  DriftScanRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<ScanRecord> create({
    required String id,
    required ImportSource source,
    required String attachmentPath,
    required String imageFingerprint,
  }) async {
    final now = _clock.nowUtc();
    final row = await _db
        .into(_db.scanRecords)
        .insertReturning(
          ScanRecordsCompanion.insert(
            id: id,
            source: source.dbValue,
            attachmentPath: Value(attachmentPath),
            imageFingerprint: Value(imageFingerprint),
            status: ScanStatus.queued.dbValue,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return _toDomain(row);
  }

  @override
  Future<ScanRecord?> findById(String id) async {
    final row = await _byId(id).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<ScanRecord>> findByFingerprint(String fingerprint) async {
    final rows =
        await (_db.select(_db.scanRecords)
              ..where(
                (s) =>
                    s.imageFingerprint.equals(fingerprint) &
                    s.status.equals(ScanStatus.discarded.dbValue).not(),
              )
              ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<ScanRecord>> watchVisible() {
    final query = _db.select(_db.scanRecords)
      ..where((s) => s.status.equals(ScanStatus.discarded.dbValue).not())
      ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<ScanRecord> transition(
    String id,
    ScanStatus next, {
    ExtractedFields? extracted,
    FailureCode? failureCode,
    String? duplicateOfScanId,
    String? processorVersion,
    bool clearAttachment = false,
  }) {
    if (next == ScanStatus.confirmed) {
      throw const AppFailure(FailureCode.invalidScanState);
    }
    return _db.transaction(() async {
      final current = await _byId(id).getSingleOrNull();
      if (current == null) throw const AppFailure(FailureCode.notFound);
      if (!ScanStatus.fromDb(current.status).canTransitionTo(next)) {
        throw const AppFailure(FailureCode.invalidScanState);
      }

      final now = _clock.nowUtc();
      final finishedProcessing =
          next == ScanStatus.needsReview ||
          next == ScanStatus.duplicate ||
          next == ScanStatus.failed;
      await (_db.update(_db.scanRecords)..where((s) => s.id.equals(id))).write(
        ScanRecordsCompanion(
          status: Value(next.dbValue),
          updatedAt: Value(now),
          // A new attempt or outcome replaces the previous failure.
          failureCode: Value(failureCode?.dbValue),
          extractedPayload: extracted == null
              ? const Value.absent()
              : Value(jsonEncode(extracted.toJson())),
          duplicateOfScanId: duplicateOfScanId == null
              ? const Value.absent()
              : Value(duplicateOfScanId),
          processorVersion: processorVersion == null
              ? const Value.absent()
              : Value(processorVersion),
          processedAt: finishedProcessing ? Value(now) : const Value.absent(),
          attachmentPath: clearAttachment
              ? const Value(null)
              : const Value.absent(),
        ),
      );
      return _toDomain(await _byId(id).getSingle());
    });
  }

  @override
  Future<int> requeueInterrupted() {
    return (_db.update(
      _db.scanRecords,
    )..where((s) => s.status.equals(ScanStatus.processing.dbValue))).write(
      ScanRecordsCompanion(
        status: Value(ScanStatus.queued.dbValue),
        updatedAt: Value(_clock.nowUtc()),
      ),
    );
  }

  SimpleSelectStatement<$ScanRecordsTable, ScanRecordRow> _byId(String id) =>
      _db.select(_db.scanRecords)..where((s) => s.id.equals(id));

  static ScanRecord _toDomain(ScanRecordRow row) => ScanRecord(
    id: row.id,
    source: ImportSource.fromDb(row.source),
    attachmentPath: row.attachmentPath,
    imageFingerprint: row.imageFingerprint,
    extracted: row.extractedPayload == null
        ? null
        : ExtractedFields.fromJson(
            jsonDecode(row.extractedPayload!) as Map<String, Object?>,
          ),
    status: ScanStatus.fromDb(row.status),
    failureCode: row.failureCode == null
        ? null
        : FailureCode.fromDb(row.failureCode!),
    duplicateOfScanId: row.duplicateOfScanId,
    transactionId: row.transactionId,
    processorVersion: row.processorVersion,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    processedAt: row.processedAt?.toUtc(),
  );
}
