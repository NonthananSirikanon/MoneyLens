import '../../../core/dates/reporting_time_zone.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/extracted_fields.dart';
import '../domain/import_ports.dart';

/// Reads the text of a Thai bank-transfer or bill-payment slip into
/// candidate fields (amount, date and time, payee, reference).
///
/// The slips of KBank, SCB, Krungthai, KKP, ttb and GSB differ in layout but
/// share a few anchors: a "จำนวน(เงิน)" label or an amount followed by
/// "บาท", a Thai-month date with a Buddhist-era year, a "ไปยัง" (to) label
/// before the payee, and a "รหัสอ้างอิง / เลขที่รายการ / เลขที่สลิป"
/// reference. Everything here is a *candidate*: the review screen always
/// shows it to the user before anything is saved.
///
/// The text is untrusted data; this class only reads it with patterns and
/// never evaluates or follows anything in it.
class ThaiSlipExtractionService implements ExtractionService {
  const ThaiSlipExtractionService();

  @override
  Future<ExtractedFields> extract(OcrResult ocr) async => parse(ocr.text);

  /// Pure parsing, separate so tests can call it without async.
  static ExtractedFields parse(String text) {
    final lines = [
      for (final raw in _normalize(text).split(RegExp(r'\r?\n')))
        if (raw.trim().isNotEmpty) raw.trim(),
    ];
    if (lines.isEmpty) return const ExtractedFields();

    final type = _type(lines);
    final amount = _amount(lines);
    final date = _date(lines);
    final merchant = _counterparty(
      lines,
      incoming: type?.value == TransactionType.income,
    );
    final reference = _reference(lines);
    return ExtractedFields(
      amountMinor: amount,
      currencyCode: amount == null ? null : 'THB',
      occurredAt: date,
      // A slip alone cannot tell a transfer to someone else (an expense)
      // from a move between the user's own accounts; the review screen asks.
      type: amount == null && date == null && merchant == null ? null : type,
      merchant: merchant,
      providerReference: reference,
    );
  }

  /// Some engines (Tesseract) write "ำ" as two characters, nikhahit + sara
  /// aa ("จํานวน"), which no label would match. Zero-width characters are
  /// dropped for the same reason.
  static String _normalize(String text) => text
      .replaceAll('\u0E4D\u0E32', '\u0E33')
      .replaceAll(RegExp('[\u200B-\u200D\uFEFF]'), '');

  // ------------------------------------------------------------------ type

  static ExtractedField<TransactionType>? _type(List<String> lines) {
    final all = lines.join('\n');
    // "ผู้รับเงิน…" (the payee) appears on outgoing slips, so it is not
    // evidence of money received.
    if (RegExp(r'(?<!ผู้)รับเงิน|เงินเข้า').hasMatch(all)) {
      return const ExtractedField(TransactionType.income, confidence: 0.7);
    }
    if (all.contains('จ่ายบิล')) {
      return const ExtractedField(TransactionType.expense, confidence: 0.8);
    }
    return const ExtractedField(TransactionType.expense, confidence: 0.6);
  }

  // ---------------------------------------------------------------- amount

  static final _money = RegExp(
    r'(?<![\d.,])(\d{1,3}(?:,\d{3})+|\d+)\.(\d{2})(?!\d)',
  );

  static ExtractedField<int>? _amount(List<String> lines) {
    final candidates = <({int minor, bool labelled, bool baht})>[];
    var skipNext = false;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (skipNext) {
        skipNext = false;
        continue;
      }
      if (line.contains('ค่าธรรมเนียม')) {
        // "ค่าธรรมเนียม:" alone puts its value on the next line.
        if (!_money.hasMatch(line)) skipNext = true;
        continue;
      }
      // Dates and times such as "19.21 น." are not amounts.
      if (_hasDate(line) || RegExp(r'\d[.:]\d{2}\s*น').hasMatch(line)) {
        continue;
      }
      final labelled = RegExp(r'จำนวน(เงิน)?\s*:?').hasMatch(line);
      var found = _money.allMatches(line).toList();
      var fromNext = false;
      if (found.isEmpty && labelled && i + 1 < lines.length) {
        found = _money.allMatches(lines[i + 1]).toList();
        fromNext = true;
      }
      for (final m in found) {
        final minor = _minor(m);
        if (minor == null || minor == 0) continue;
        final source = fromNext ? lines[i + 1] : line;
        candidates.add((
          minor: minor,
          labelled: labelled,
          baht: source.contains('บาท'),
        ));
      }
    }
    if (candidates.isEmpty) return null;
    final labelled = candidates.where((c) => c.labelled);
    if (labelled.isNotEmpty) {
      return ExtractedField(labelled.first.minor, confidence: 0.9);
    }
    final baht = candidates.where((c) => c.baht);
    if (baht.isNotEmpty) {
      return ExtractedField(baht.first.minor, confidence: 0.8);
    }
    return ExtractedField(candidates.first.minor, confidence: 0.6);
  }

  static int? _minor(RegExpMatch m) {
    final major = int.tryParse(m.group(1)!.replaceAll(',', ''));
    final fraction = int.tryParse(m.group(2)!);
    if (major == null || fraction == null) return null;
    return major * 100 + fraction;
  }

  // ------------------------------------------------------------------ date

  static const _months = {
    'ม.ค.': 1,
    'มกราคม': 1,
    'ก.พ.': 2,
    'กุมภาพันธ์': 2,
    'มี.ค.': 3,
    'มีนาคม': 3,
    'เม.ย.': 4,
    'เมษายน': 4,
    'พ.ค.': 5,
    'พฤษภาคม': 5,
    'มิ.ย.': 6,
    'มิถุนายน': 6,
    'ก.ค.': 7,
    'กรกฎาคม': 7,
    'ส.ค.': 8,
    'สิงหาคม': 8,
    'ก.ย.': 9,
    'กันยายน': 9,
    'ต.ค.': 10,
    'ตุลาคม': 10,
    'พ.ย.': 11,
    'พฤศจิกายน': 11,
    'ธ.ค.': 12,
    'ธันวาคม': 12,
  };

  /// A date: day, a month word (exact, or any short run of Thai letters,
  /// dots and vowel marks that [_monthOf] can resolve) and a year.
  static final _dateRe = RegExp(
    r'(\d{1,2})\s*([\u0E00-\u0E7F.]{2,12})\s*(\d{2,4})(?!\d)',
  );
  static final _timeRe = RegExp(
    r'(?<!\d)([01]?\d|2[0-3])\s*[:.\-]\s*([0-5]\d)(?!\d)',
  );

  /// Thai vowel and tone marks: they sit on or under a letter and are the
  /// part OCR most often invents or drops.
  static final _marks = RegExp('[\u0E31\u0E34-\u0E3A\u0E47-\u0E4E]');

  /// The month named by [word], or null when it is not one.
  ///
  /// An exact name or abbreviation wins. Otherwise the vowel marks and dots
  /// are ignored and the consonants decide ("ก.ุค." is still ก.ค.). Where two
  /// months share their consonants (ม.ค. / มี.ค., เม.ย. / มิ.ย.) the mark that
  /// tells them apart must be there, or the month is left unknown rather than
  /// guessed.
  static int? _monthOf(String word) {
    final exact =
        _months[word] ?? _months[word.endsWith('.') ? word : '$word.'];
    if (exact != null) return exact;
    final skeleton = word
        .replaceAll(_marks, '')
        .replaceAll('.', '')
        .replaceAll('เ', '');
    final hasI = word.contains('\u0E35'); // ี
    final hasE = word.contains('\u0E34'); // ิ
    final hasLead = word.contains('เ');
    return switch (skeleton) {
      'มค' => hasI ? 3 : (word.contains('\u0E31') ? null : 1),
      'มย' => hasLead ? 4 : (hasE ? 6 : null),
      'กพ' => 2,
      'พค' => 5,
      'กค' => 7,
      'สค' => 8,
      'กย' => 9,
      'ตค' => 10,
      'พย' => 11,
      'ธค' => 12,
      _ => null,
    };
  }

  static bool _hasDate(String line) =>
      _dateRe.allMatches(line).any((m) => _monthOf(m.group(2)!) != null);

  static ExtractedField<DateTime>? _date(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final m = _dateRe
          .allMatches(lines[i])
          .where((m) => _monthOf(m.group(2)!) != null)
          .firstOrNull;
      if (m == null) continue;
      final month = _monthOf(m.group(2)!)!;
      final day = int.parse(m.group(1)!);
      final year = _gregorianYear(int.parse(m.group(3)!), m.group(3)!.length);
      if (day < 1 || day > 31) continue;

      // The time follows the date on the same line, or starts the next one.
      final rest = lines[i].substring(m.end);
      final next = i + 1 < lines.length ? lines[i + 1] : '';
      final t = _timeRe.firstMatch(rest) ?? _timeRe.firstMatch(next);
      final hour = t == null ? 12 : int.parse(t.group(1)!);
      final minute = t == null ? 0 : int.parse(t.group(2)!);

      final local = DateTime.utc(year, month, day);
      // Reject impossible dates such as 31 ก.พ. (DateTime would roll over).
      if (local.month != month || local.day != day) continue;
      return ExtractedField(
        ReportingTimeZone.bangkok.toUtc(year, month, day, hour, minute),
        confidence: t == null ? 0.6 : 0.9,
      );
    }
    return null;
  }

  /// Thai slips print the Buddhist-era year in four digits ("2569") or two
  /// ("69"); a four-digit year below 2400 is already Gregorian.
  static int _gregorianYear(int value, int digits) {
    if (digits <= 2) return 1957 + value; // 2500 + value - 543
    return value >= 2400 ? value - 543 : value;
  }

  // ------------------------------------------------------------ counterparty

  static final _title = RegExp(
    r'^[๐-๙]?\s*(น\.ส\.|นางสาว|นาย|นาง|ด\.ช\.|ด\.ญ\.|Mr\.?|Ms\.?|Mrs\.?)',
  );
  static final _business = RegExp(
    r'^(บริษัท|บจก\.?|หจก\.?|ห้างหุ้นส่วน|ร้าน|คาเฟ่|โรงพยาบาล|มูลนิธิ)',
  );
  static final _bank = RegExp(
    r'^(ธ\.|ธนาคาร|กรุงไทย$|กสิกร|ไทยพาณิชย์|ttb$|SCB|KBank|Krungthai)',
    caseSensitive: false,
  );
  static final _account = RegExp(r'^[xX\d\-\s]{4,}$|^[xX]-?\d{3,}');
  static final _stop = RegExp(
    r'สแกน|ตรวจสอบ|QR|ผู้รับเงิน|วันที่|จำนวน|ค่าธรรมเนียม|รหัส|เลขที่|Biller|โดย|บันทึก|:',
  );

  static bool _isName(String l) => _title.hasMatch(l) || _business.hasMatch(l);

  static ExtractedField<String>? _counterparty(
    List<String> lines, {
    required bool incoming,
  }) {
    final label = incoming ? 'จาก' : 'ไปยัง';
    // The label is alone on its line, or (when the engine reads a slip's
    // two columns as one row) followed by the name: "ไปยัง   นาย ...".
    final labelLine = RegExp('^$label(?:\\s+(.+))?\$');
    for (var at = 0; at < lines.length; at++) {
      final m = labelLine.firstMatch(lines[at]);
      if (m == null) continue;
      final inline = m.group(1)?.trim();
      if (inline != null && inline.isNotEmpty && !_account.hasMatch(inline)) {
        return ExtractedField(
          _clean(_withContinuation(lines, at, first: inline)),
          confidence: 0.75,
        );
      }
      for (var i = at + 1; i < lines.length; i++) {
        final l = lines[i];
        if (_bank.hasMatch(l) && !_business.hasMatch(l)) continue;
        if (_account.hasMatch(l)) continue;
        if (_stop.hasMatch(l)) break;
        return ExtractedField(
          _clean(_withContinuation(lines, i)),
          confidence: 0.75,
        );
      }
    }
    // No label (KBank, ttb, GSB): the sender comes first, the payee second.
    final names = [
      for (final l in lines)
        if (_isName(l)) l,
    ];
    if (names.isEmpty) return null;
    final pick = incoming
        ? names.first
        : (names.length >= 2 ? names[1] : names.first);
    return ExtractedField(
      _clean(pick),
      confidence: names.length >= 2 ? 0.6 : 0.4,
    );
  }

  /// A long payee wraps onto a second line ("ร้าน… สาขา" / "สถานีบริการ…").
  /// People's names never wrap, so only join for businesses and plain text.
  static String _withContinuation(List<String> lines, int i, {String? first}) {
    first ??= lines[i];
    if (_title.hasMatch(first) || i + 1 >= lines.length) return first;
    final next = lines[i + 1];
    if (_stop.hasMatch(next) ||
        _account.hasMatch(next) ||
        _bank.hasMatch(next)) {
      return first;
    }
    return '$first $next';
  }

  static String _clean(String name) => name
      .replaceFirst(RegExp(r'^[๐-๙]\s*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // -------------------------------------------------------------- reference

  static final _refToken = RegExp(r'[A-Za-z0-9|]{10,}');

  static ExtractedField<String>? _reference(List<String> lines) {
    // The first label that has a value wins; "รหัสอ้างอิง" beats the rest.
    for (final label in [
      RegExp('รหัสอ้างอิง'),
      RegExp('เลขที่รายการ'),
      RegExp('เลขที่สลิป'),
      RegExp('รหัสธุรกรรม'),
    ]) {
      for (var i = 0; i < lines.length; i++) {
        if (!label.hasMatch(lines[i])) continue;
        final after = lines[i].substring(label.firstMatch(lines[i])!.end);
        final m =
            _refToken.firstMatch(after) ??
            (i + 1 < lines.length ? _refToken.firstMatch(lines[i + 1]) : null);
        if (m != null) {
          return ExtractedField(
            m.group(0)!.replaceAll('|', ''),
            confidence: 0.8,
          );
        }
      }
    }
    return null;
  }
}
