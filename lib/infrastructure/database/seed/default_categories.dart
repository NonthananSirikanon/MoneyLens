import 'package:drift/drift.dart';

import '../app_database.dart';

/// Default categories with stable IDs, so seeding is idempotent
/// (DATABASE.md §10). Names are Thai, the primary launch language.
/// The colour is the chart/accent colour; tints are derived from it.
const _defaults =
    <(String id, String name, String kind, String icon, int color)>[
      (
        'default-expense-food',
        'อาหารและเครื่องดื่ม',
        'expense',
        'food',
        0xFFE09A88,
      ),
      (
        'default-expense-transport',
        'การเดินทาง',
        'expense',
        'transport',
        0xFFE2BC6E,
      ),
      (
        'default-expense-shopping',
        'ช้อปปิ้ง',
        'expense',
        'shopping',
        0xFF93ABCB,
      ),
      (
        'default-expense-bills',
        'บิลและสาธารณูปโภค',
        'expense',
        'bills',
        0xFFB9B3CC,
      ),
      (
        'default-expense-housing',
        'ที่อยู่อาศัย',
        'expense',
        'housing',
        0xFFC9B79A,
      ),
      ('default-expense-health', 'สุขภาพ', 'expense', 'health', 0xFF9CC5B4),
      (
        'default-expense-entertainment',
        'บันเทิง',
        'expense',
        'entertainment',
        0xFFA8B89A,
      ),
      ('default-expense-other', 'รายจ่ายอื่นๆ', 'expense', 'other', 0xFFC9C8C2),
      ('default-income-salary', 'เงินเดือน', 'income', 'salary', 0xFF4F8A68),
      ('default-income-freelance', 'ฟรีแลนซ์', 'income', 'laptop', 0xFFA8B89A),
      ('default-income-gift', 'ของขวัญ', 'income', 'gift', 0xFFE2BC6E),
      ('default-income-other', 'รายรับอื่นๆ', 'income', 'other', 0xFFC9C8C2),
    ];

/// Id of the cash account every install starts with, so a first
/// transaction can be recorded before the user adds any account.
const defaultCashAccountId = 'default-cash';

/// Inserts any missing default categories and the default cash account.
/// Existing rows, including ones the user archived or renamed, are left
/// untouched.
Future<void> seedDefaults(AppDatabase db, DateTime nowUtc) async {
  await db.batch((batch) {
    batch.insertAll(db.categories, [
      for (final (id, name, kind, icon, color) in _defaults)
        CategoriesCompanion.insert(
          id: id,
          name: name,
          kind: kind,
          iconKey: Value(icon),
          colorValue: Value(color),
          isDefault: const Value(true),
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
    ], mode: InsertMode.insertOrIgnore);
    batch.insert(
      db.accounts,
      AccountsCompanion.insert(
        id: defaultCashAccountId,
        name: 'เงินสด',
        kind: 'cash',
        currencyCode: 'THB',
        createdAt: nowUtc,
        updatedAt: nowUtc,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  });
}

/// Kept for callers that only need the categories; see [seedDefaults].
Future<void> seedDefaultCategories(AppDatabase db, DateTime nowUtc) =>
    seedDefaults(db, nowUtc);
