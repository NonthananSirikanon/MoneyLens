// Per-field accuracy of the Dart extraction/voting stage over recorded OCR
// text passes. See bench/README.md. Run: flutter test bench/
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/features/slip_import/data/thai_slip_extraction_service.dart';

class _Tally {
  int n = 0, amount = 0, date = 0, payee = 0;
}

_Tally _run(String label, File manifest) {
  final dir = manifest.parent.path;
  final cases = (jsonDecode(manifest.readAsStringSync())['cases'] as List)
      .cast<Map<String, dynamic>>();
  final t = _Tally();
  final out = StringBuffer('\n== $label (${cases.length} slips)\n');
  for (final c in cases) {
    final texts = [
      for (final p in (c['passes'] as List).cast<String>())
        File('$dir/$p').readAsStringSync(),
    ];
    final got = ThaiSlipExtractionService.combine(texts);
    final want = c['expected'] as Map<String, dynamic>;
    final a = got.amountMinor?.value == want['amountMinor'];
    final d = got.occurredAt?.value ==
        (want['occurredAt'] == null
            ? null
            : DateTime.parse(want['occurredAt'] as String));
    final m = got.merchant?.value == want['merchant'];
    t
      ..n += 1
      ..amount += a ? 1 : 0
      ..date += d ? 1 : 0
      ..payee += m ? 1 : 0;
    // Only ids and verdicts are printed, never slip text.
    out.writeln('  ${c['id']}: amount ${a ? 'ok' : 'WRONG'}, '
        'date ${d ? 'ok' : 'WRONG'}, payee ${m ? 'ok' : 'WRONG'}');
  }
  out.writeln('  amount ${t.amount}/${t.n}  date ${t.date}/${t.n}  '
      'payee exact ${t.payee}/${t.n}');
  // ignore: avoid_print
  print(out);
  return t;
}

void main() {
  test('synthetic slips: every field reads correctly', () {
    final t = _run('synthetic', File('bench/synthetic/manifest.json'));
    expect(t.amount, t.n, reason: 'amount');
    expect(t.date, t.n, reason: 'date');
    expect(t.payee, t.n, reason: 'payee');
  });

  final priv = File('bench/private/manifest.json');
  test(
    'private slips: report only (no thresholds)',
    () => _run('private', priv),
    skip: priv.existsSync()
        ? false
        : 'bench/private/manifest.json not present (real slips are not in the repo)',
  );
}
