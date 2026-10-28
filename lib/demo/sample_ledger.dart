import 'package:drift/drift.dart';

import '../infrastructure/database/app_database.dart';
import 'demo_seed.dart';

/// Writes the prototype's sample accounts and transactions into the real
/// database (sample mode only). Idempotent: existing rows are kept, except
/// the default cash account, which gets the sample opening balance.
Future<void> insertSampleLedger(AppDatabase db, DemoSeed seed) async {
  final now = DateTime.now().toUtc();
  await db.transaction(() async {
    for (final a in seed.accounts()) {
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: a.id,
              name: a.name,
              kind: a.kind.dbValue,
              currencyCode: a.currency.code,
              openingBalanceMinor: Value(a.openingBalanceMinor),
              lastFour: Value(a.lastFour),
              createdAt: a.createdAt,
              updatedAt: now,
            ),
            onConflict: DoUpdate(
              (_) => AccountsCompanion(
                openingBalanceMinor: Value(a.openingBalanceMinor),
                lastFour: Value(a.lastFour),
              ),
            ),
          );
    }
    for (final t in seed.transactions()) {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: t.id,
              type: t.type.dbValue,
              amountMinor: t.amount.minor,
              currencyCode: t.amount.currency.code,
              accountId: t.accountId,
              destinationAccountId: Value(t.destinationAccountId),
              categoryId: Value(t.categoryId),
              merchant: Value(t.merchant),
              note: Value(t.note),
              occurredAt: t.occurredAt,
              source: t.source.dbValue,
              attachmentPath: Value(t.attachmentPath),
              createdAt: t.createdAt,
              updatedAt: t.updatedAt,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  });
}
