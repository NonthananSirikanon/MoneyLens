import 'package:drift/drift.dart';

import '../app_database.dart';

/// Default categories with stable IDs, so seeding is idempotent
/// (DATABASE.md §10). Names are Thai, the primary launch language.
const _defaults = <(String id, String name, String kind, String icon)>[
  ('default-expense-food', 'อาหารและเครื่องดื่ม', 'expense', 'food'),
  ('default-expense-transport', 'การเดินทาง', 'expense', 'transport'),
  ('default-expense-shopping', 'ช้อปปิ้ง', 'expense', 'shopping'),
  ('default-expense-bills', 'บิลและสาธารณูปโภค', 'expense', 'bills'),
  ('default-expense-housing', 'ที่อยู่อาศัย', 'expense', 'housing'),
  ('default-expense-health', 'สุขภาพ', 'expense', 'health'),
  ('default-expense-entertainment', 'บันเทิง', 'expense', 'entertainment'),
  ('default-expense-other', 'รายจ่ายอื่นๆ', 'expense', 'other'),
  ('default-income-salary', 'เงินเดือน', 'income', 'salary'),
  ('default-income-other', 'รายรับอื่นๆ', 'income', 'other'),
];

/// Inserts any missing default categories. Existing rows, including ones
/// the user archived or renamed, are left untouched.
Future<void> seedDefaultCategories(AppDatabase db, DateTime nowUtc) async {
  await db.batch((batch) {
    batch.insertAll(db.categories, [
      for (final (id, name, kind, icon) in _defaults)
        CategoriesCompanion.insert(
          id: id,
          name: name,
          kind: kind,
          iconKey: Value(icon),
          isDefault: const Value(true),
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
    ], mode: InsertMode.insertOrIgnore);
  });
}
