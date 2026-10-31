import '../../../core/dates/reporting_time_zone.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/extracted_fields.dart';
import '../domain/import_ports.dart';

/// Reads the text of a Thai bank-transfer or bill-payment slip into
/// candidate fields (amount, date and time, payee, reference).
///
/// The slips of KBank, SCB, Krungthai, KKP, ttb, GSB, Bangkok Bank, Krungsri
/// and TrueMoney Wallet (tested on invented look-alikes) differ in layout but
/// share a few anchors: a "จำนวน(เงิน)" label or an amount followed by
/// "บาท", a Thai-month date with a Buddhist-era year, a "ไปยัง" (to) label
/// before the payee, and a reference labelled "รหัสอ้างอิง", "เลขที่รายการ",
/// "เลขที่สลิป" or "หมายเลขอ้างอิง". Everything here is a *candidate*: the review screen always
/// shows it to the user before anything is saved.
///
/// The text is untrusted data; this class only reads it with patterns and
/// never evaluates or follows anything in it.
class ThaiSlipExtractionService implements ExtractionService {
  const ThaiSlipExtractionService();

  @override
  Future<ExtractedFields> extract(OcrResult ocr) async =>
      ocr.alternatives.isEmpty
      ? parse(ocr.text)
      : combine([ocr.text, ...ocr.alternatives]);

  /// Several readings of one slip (the image prepared in different ways
  /// before OCR): each field takes the value most readings agree on, ties
  /// going to the earlier reading. A value that only one reading found is
  /// marked uncertain, so the review screen highlights it.
  static ExtractedFields combine(List<String> texts) {
    final readings = [for (final t in texts) parse(t)];
    if (readings.length == 1) return readings.single;
    final amount = _vote([for (final r in readings) r.amountMinor]);
    final date = _vote([for (final r in readings) r.occurredAt]);
    final merchant = _votePayee([for (final r in readings) r.merchant]);
    final type = _vote([for (final r in readings) r.type]);
    return ExtractedFields(
      amountMinor: amount,
      currencyCode: amount == null ? null : 'THB',
      occurredAt: date,
      type: amount == null && date == null && merchant == null ? null : type,
      merchant: merchant,
      providerReference: _vote([for (final r in readings) r.providerReference]),
    );
  }

  /// Whether two readings already agree on amount, date and payee, so a
  /// further reading could not change the result.
  static bool readingsAgree(String a, String b) {
    final x = parse(a);
    final y = parse(b);
    return x.amountMinor != null &&
        x.amountMinor!.value == y.amountMinor?.value &&
        x.occurredAt != null &&
        x.occurredAt!.value == y.occurredAt?.value &&
        x.merchant != null &&
        y.merchant != null &&
        _nameKey(x.merchant!.value) == _nameKey(y.merchant!.value);
  }

  /// Confidence of a value that only one reading found.
  static const _singleReading = 0.6;

  static ExtractedField<T>? _vote<T>(
    List<ExtractedField<T>?> fields, {
    Object? Function(T value)? key,
  }) {
    final read = fields.nonNulls.toList();
    if (read.isEmpty) return null;
    Object? keyOf(ExtractedField<T> f) => key == null ? f.value : key(f.value);
    List<ExtractedField<T>> best = const [];
    for (final f in read) {
      final agreeing = [
        for (final o in read)
          if (keyOf(o) == keyOf(f)) o,
      ];
      if (agreeing.length > best.length) best = agreeing;
    }
    final confidence = best
        .map((f) => f.confidence ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return ExtractedField(
      best.first.value,
      confidence: best.length >= 2
          ? confidence
          : (confidence < _singleReading ? confidence : _singleReading),
    );
  }

  /// Names rarely come out identical: spelling slips differ per reading.
  /// When no two readings agree, the reading closest to all the others is
  /// taken, marked uncertain.
  static ExtractedField<String>? _votePayee(
    List<ExtractedField<String>?> fields,
  ) {
    final agreed = _vote(fields, key: _nameKey);
    final read = fields.nonNulls.toList();
    if (agreed == null || read.length < 3) return agreed;
    if (read.where((f) => _nameKey(f.value) == _nameKey(agreed.value)).length >=
        2) {
      return agreed;
    }
    double closeness(String a) => read.fold(
      0,
      (sum, o) => sum + _similarity(_nameKey(a), _nameKey(o.value)),
    );
    var medoid = read.first;
    for (final f in read.skip(1)) {
      if (closeness(f.value) > closeness(medoid.value)) medoid = f;
    }
    return ExtractedField(medoid.value, confidence: agreed.confidence);
  }

  static String _nameKey(String name) => name.replaceAll(RegExp(r'\s+'), '');

  /// 1 minus the edit distance over the longer length.
  static double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    var prev = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      final cur = [i];
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final best = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost];
        cur.add(best.reduce((x, y) => x < y ? x : y));
      }
      prev = cur;
    }
    return 1 - prev.last / (a.length > b.length ? a.length : b.length);
  }

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
  /// dropped for the same reason. Slips print Arabic digits, so Thai digits
  /// in the text are misreadings of them ("๐" for "0").
  static String _normalize(String text) => text
      .replaceAll('\u0E4D\u0E32', '\u0E33')
      .replaceAll(RegExp('[\u200B-\u200D\uFEFF]'), '')
      .replaceAllMapped(
        RegExp('[\u0E50-\u0E59]'),
        (m) => '${m.group(0)!.codeUnitAt(0) - 0x0E50}',
      );

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
      var source = _repairSeparators(line);
      var found = _money.allMatches(source).toList();
      if (found.isEmpty && labelled && i + 1 < lines.length) {
        source = _repairSeparators(lines[i + 1]);
        found = _money.allMatches(source).toList();
      }
      for (final m in found) {
        final minor = _minor(m);
        if (minor == null || minor == 0) continue;
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

  /// OCR doubles or swaps separators in large amounts: "1,.000.00",
  /// "1.000.00". A separator before exactly three digits that are followed
  /// by the decimals is a thousands comma.
  static String _repairSeparators(String line) => line
      .replaceAllMapped(
        RegExp(r'(\d)[,.]{2}(\d{3})(?=[,.]\d)'),
        (m) => '${m[1]},${m[2]}',
      )
      .replaceAllMapped(
        RegExp(r'(?<![\d.,])(\d{1,3})\.(\d{3})\.(\d{2})(?!\d)'),
        (m) => '${m[1]},${m[2]}.${m[3]}',
      );

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
    r'(\d{1,2})\s*([\u0E00-\u0E7F.]{2,12})[\s=\-]*(\d{2,4})(?!\d)',
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
    final shared = word.contains('\u0E31');
    final month = switch (skeleton) {
      'มค' => hasI ? 3 : (shared ? null : 1),
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
    return month ?? _monthWithExtraLetter(skeleton);
  }

  /// Consonant pairs that name exactly one month.
  static const _unambiguous = {
    'กพ': 2,
    'พค': 5,
    'กค': 7,
    'สค': 8,
    'กย': 9,
    'ตค': 10,
    'พย': 11,
    'ธค': 12,
  };

  /// A month abbreviation with one stray letter ("ธร.ค." for ธ.ค.): dropping
  /// one letter must leave exactly one month, never ม.ค./มี.ค. or
  /// เม.ย./มิ.ย. (those need their vowel to be told apart).
  static int? _monthWithExtraLetter(String skeleton) {
    if (skeleton.length != 3) return null;
    final found = <int>{};
    for (var i = 0; i < 3; i++) {
      final month = _unambiguous[skeleton.replaceRange(i, i + 1, '')];
      if (month != null) found.add(month);
    }
    return found.length == 1 ? found.single : null;
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
      final word = m.group(2)!;
      final month = _monthOf(word)!;
      // A month recovered from a misreading is shown as uncertain.
      final exact = _months[word] ?? _months['$word.'];
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
        confidence: t == null || exact == null ? 0.6 : 0.9,
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
    r'^[0-9]?\s*(น\.ส\.|นางสาว|นาย|นาง|ด\.ช\.|ด\.ญ\.|Mr\.?|Ms\.?|Mrs\.?)',
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

  /// A title within the first few characters: what comes before it is an
  /// icon or a stray mark read as text ("(6) นาย…", "แนาย…").
  static final _titleNearStart = RegExp(
    r'^.{1,5}?(?=น\.ส\.|นางสาว|นาย|นาง|ด\.ช\.|ด\.ญ\.)',
  );

  /// A token with no Thai letter but with a symbol: an account number, an
  /// icon or masking read as text ("%-8782", "“*\"", "(6)", "=").
  static final _junkToken = RegExp(
    '^[^\u0E01-\u0E2E]*[^\\w\\s\u0E00-\u0E7F.][^\u0E01-\u0E2E]*\$',
  );

  static String _clean(String name) {
    final tokens = name
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        // "น.ส." is often read as "บ.ส.", sometimes with a stray mark.
        .replaceAll(
          RegExp('(?<![\u0E00-\u0E7F])บ\\.[\u0E38\u0E39]?ส\\.'),
          'น.ส.',
        )
        .split(' ');
    while (tokens.length > 1 && _junkToken.hasMatch(tokens.first)) {
      tokens.removeAt(0);
    }
    // People's names never end in a number; a stray digit is a misread mark.
    final person = _title.hasMatch(tokens.join(' '));
    while (tokens.length > 1 &&
        (_junkToken.hasMatch(tokens.last) ||
            (person && RegExp(r'^[0-9]+$').hasMatch(tokens.last)))) {
      tokens.removeLast();
    }
    // A lone letter or digit before a name is a misread icon ("ซ น.ส.…").
    if (tokens.length > 2 &&
        RegExp('^[\u0E01-\u0E2E0-9]\$').hasMatch(tokens.first) &&
        _isName(tokens.sublist(1).join(' '))) {
      tokens.removeAt(0);
    }
    return tokens.join(' ').replaceFirst(_titleNearStart, '');
  }

  // -------------------------------------------------------------- reference

  static final _refToken = RegExp(r'[A-Za-z0-9|]{10,}');

  static ExtractedField<String>? _reference(List<String> lines) {
    // The first label that has a value wins; "รหัสอ้างอิง" beats the rest.
    for (final label in [
      RegExp('รหัสอ้างอิง'),
      RegExp('เลขที่รายการ'),
      RegExp('เลขที่สลิป'),
      RegExp('รหัสธุรกรรม'),
      RegExp('หมายเลขอ้างอิง'),
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
