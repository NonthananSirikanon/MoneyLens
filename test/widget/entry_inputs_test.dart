import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:moneylens/app/theme/app_theme.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/features/transactions/application/entry_form.dart';
import 'package:moneylens/features/transactions/presentation/entry_screen.dart';
import 'package:moneylens/l10n/app_localizations.dart';

import '../support/test_support.dart';

void main() {
  final now = ReportingTimeZone.bangkok.toUtc(2026, 10, 24, 10, 45);

  Future<ProviderContainer> pumpEntry(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = (await tester.runAsync(() => sampleContainer(now)))!;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.material(),
          locale: const Locale('en'),
          supportedLocales: const [Locale('th'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            FLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => FTheme(
            data: AppTheme.light,
            child: FToaster(child: child!),
          ),
          home: const EntryScreen(args: ManualEntryArgs()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    return container;
  }

  /// The editable text inside the field whose semantics label is [label].
  Finder field(String label) => find
      .descendant(
        of: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == label,
        ),
        matching: find.byType(EditableText),
      )
      .first;

  String textOf(WidgetTester tester, String label) =>
      tester.widget<EditableText>(field(label)).controller.text;

  group('amount field', () {
    testWidgets('shows thousands separators while typing', (tester) async {
      final container = await pumpEntry(tester);
      await tester.enterText(field('Amount'), '10000');
      await tester.pump();
      expect(textOf(tester, 'Amount'), '10,000');
      expect(find.text('10,000'), findsOneWidget);

      await tester.enterText(field('Amount'), '1234.5');
      await tester.pump();
      expect(textOf(tester, 'Amount'), '1,234.5');

      await tester.enterText(field('Amount'), '1234.567');
      await tester.pump();
      expect(textOf(tester, 'Amount'), '1,234.56');

      // The form holds exactly what the field shows, and that validates.
      final draft = container.read(entryFormProvider(const ManualEntryArgs()));
      expect(draft.amountText, '1,234.56');
      expect(validateEntry(draft)[EntryField.amount], isNull);
    });

    testWidgets('a pasted symbol and grouping are normalised', (tester) async {
      await pumpEntry(tester);
      await tester.enterText(field('Amount'), '฿1,234,567.8');
      await tester.pump();
      expect(textOf(tester, 'Amount'), '1,234,567.8');
    });
  });

  group('Thai text', () {
    testWidgets('merchant and note keep what the keyboard sends', (
      tester,
    ) async {
      final container = await pumpEntry(tester);
      await tester.enterText(field('Merchant / payee'), 'ร้านกาแฟ');
      await tester.enterText(field('Note'), 'ค่ากาแฟตอนเช้า วันจันทร์');
      await tester.pump();

      expect(textOf(tester, 'Merchant / payee'), 'ร้านกาแฟ');
      expect(textOf(tester, 'Note'), 'ค่ากาแฟตอนเช้า วันจันทร์');
      final draft = container.read(entryFormProvider(const ManualEntryArgs()));
      expect(draft.merchant, 'ร้านกาแฟ');
      expect(draft.note, 'ค่ากาแฟตอนเช้า วันจันทร์');
    });
  });
}
