import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/demo/demo_store.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';
import 'package:moneylens/features/transactions/application/entry_form.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';

import '../support/test_support.dart';

void main() {
  final now = ReportingTimeZone.bangkok.toUtc(2026, 10, 24, 10, 45);

  Future<ProviderContainer> container() => sampleContainer(now);

  group('validateEntry', () {
    EntryDraft draft({
      String amount = '120.00',
      String merchant = 'Shop',
      String? category = 'food',
      TransactionType type = TransactionType.expense,
    }) => EntryDraft(
      mode: EntryMode.manual,
      type: type,
      amountText: amount,
      date: DateTime.utc(2026, 10, 24),
      hour: 12,
      minute: 30,
      merchant: merchant,
      categoryId: category,
      accountId: 'kbank',
      destinationAccountId: 'scb',
      note: '',
    );

    test('accepts grouped and plain amounts', () async {
      for (final amount in ['120', '120.5', '1,234.50', '25000']) {
        expect(validateEntry(draft(amount: amount)), isEmpty, reason: amount);
      }
    });

    test('rejects the OCR misread 1,20.00 as a format error', () async {
      expect(validateEntry(draft(amount: '1,20.00')), {
        EntryField.amount: EntryError.amountFormat,
      });
    });

    test('requires a positive amount', () async {
      expect(
        validateEntry(draft(amount: ''))[EntryField.amount],
        EntryError.amountRequired,
      );
      expect(
        validateEntry(draft(amount: '0'))[EntryField.amount],
        EntryError.amountRequired,
      );
    });

    test('requires a category except for transfers', () async {
      expect(
        validateEntry(draft(category: null))[EntryField.category],
        EntryError.categoryRequired,
      );
      expect(
        validateEntry(draft(category: null, type: TransactionType.transfer)),
        isEmpty,
      );
    });

    test('uses transfer wording for a missing transfer description', () async {
      expect(
        validateEntry(
          draft(merchant: ' ', type: TransactionType.transfer),
        )[EntryField.merchant],
        EntryError.transferDetailRequired,
      );
    });
  });

  group('EntryFormController', () {
    test('a manual expense saves and lowers the account balance', () async {
      final c = await container();
      const args = ManualEntryArgs();
      final before = c.read(demoStoreProvider).balanceOf('kbank');
      final form = c.read(entryFormProvider(args).notifier);
      form
        ..setAmount('150')
        ..setMerchant('Test shop');
      final saved = await form.save();

      expect(saved, isNotNull);
      final state = c.read(demoStoreProvider);
      expect(state.balanceOf('kbank'), before - 15000);
      expect(
        state.transaction(saved!.transactionId)!.categoryId,
        'default-expense-food',
      );
    });

    test('a transfer to the same account cannot be saved', () async {
      final c = await container();
      const args = ManualEntryArgs(TransactionType.transfer);
      final form = c.read(entryFormProvider(args).notifier);
      form
        ..setAmount('100')
        ..setMerchant('Move')
        ..setDestination('kbank');

      expect(c.read(entryFormProvider(args)).sameAccount, isTrue);
      expect(await form.save(), isNull);
    });

    test(
      'a transfer moves money without counting as income or expense',
      () async {
        final c = await container();
        const args = ManualEntryArgs(TransactionType.transfer);
        final store = c.read(demoStoreProvider);
        final total = store.totalBalance;
        final from = store.balanceOf('kbank');
        final to = store.balanceOf('truemoney');
        final form = c.read(entryFormProvider(args).notifier);
        form
          ..setAmount('500')
          ..setMerchant('Top up');
        expect(await form.save(), isNotNull);

        final after = c.read(demoStoreProvider);
        expect(after.balanceOf('kbank'), from - 50000);
        expect(after.balanceOf('truemoney'), to + 50000);
        expect(after.totalBalance, total);
      },
    );

    test('reviewing the misread Starbucks slip needs two fixes', () async {
      final c = await container();
      const args = ScanEntryArgs('s1');
      final form = c.read(entryFormProvider(args).notifier);
      expect(c.read(entryFormProvider(args)).highlightCount, 2);

      expect(await form.save(), isNull);
      expect(c.read(entryFormProvider(args)).errors, {
        EntryField.amount: EntryError.amountFormat,
        EntryField.category: EntryError.categoryRequired,
      });

      form
        ..setAmount('120.00')
        ..setCategory('default-expense-food');
      expect(c.read(entryFormProvider(args)).highlightCount, 0);
      final saved = await form.save();

      expect(saved, isNotNull);
      final state = c.read(demoStoreProvider);
      expect(state.scan('s1')!.status, ScanStatus.confirmed);
      expect(state.scan('s1')!.transactionId, saved!.transactionId);
      expect(c.read(demoStoreProvider.notifier).pending.map((s) => s.id), [
        's2',
      ]);
    });

    test('editing keeps the transaction id and its slip', () async {
      final c = await container();
      const args = EditEntryArgs('tx-2');
      final form = c.read(entryFormProvider(args).notifier);
      expect(c.read(entryFormProvider(args)).amountText, '120.00');
      form.setAmount('130');
      final saved = await form.save();

      expect(saved!.transactionId, 'tx-2');
      final t = c.read(demoStoreProvider).transaction('tx-2')!;
      expect(t.amount.minor, 13000);
      expect(t.attachmentPath, isNotNull);
    });
  });
}
