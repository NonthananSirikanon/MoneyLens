import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/app/providers.dart';
import 'package:moneylens/core/dates/clock.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/demo/demo_import_launcher.dart';
import 'package:moneylens/demo/demo_slip_queue.dart';
import 'package:moneylens/features/ledger/application/ledger.dart';
import 'package:moneylens/features/slip_import/application/slip_queue.dart';
import 'package:moneylens/features/slip_import/presentation/import_launcher.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';

import '../support/test_support.dart';

/// A normal run (no `ML_SAMPLE_DATA`, so no demo overrides) starts empty and
/// uses the real slip queue and launcher.
void main() {
  test('a normal run starts empty and does not use the demo harness', () async {
    final db = openTestDatabase();
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(
          FixedClock(ReportingTimeZone.bangkok.toUtc(2026, 10, 24, 10, 45)),
        ),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    await c.read(appStartupProvider.future);

    final ledger = c.read(ledgerProvider);
    expect(ledger.transactions, isEmpty);
    // Only the default cash account that every install has.
    expect(ledger.accounts.map((a) => a.id), ['default-cash']);
    expect(ledger.totalBalance, 0);
    expect(c.read(slipQueueProvider).scans, isEmpty);

    expect(c.read(slipQueueProvider.notifier), isNot(isA<DemoSlipQueue>()));
    expect(c.read(importLauncherProvider), isNot(isA<DemoImportLauncher>()));
    expect(c.read(importLauncherProvider), isA<DeviceImportLauncher>());
  });
}
