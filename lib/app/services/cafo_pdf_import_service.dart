import 'dart:typed_data';

// The engine package (pure Dart) rather than `package:pdfrx/pdfrx.dart` (which
// pulls in Flutter widgets), so this parser can be exercised headlessly.
// The platform backend is wired up by `pdfrxFlutterInitialize()` in main.dart.
import 'package:pdfrx_engine/pdfrx_engine.dart';

/// Parses a GMet forecast bulletin PDF (e.g. "EVENING FORECAST 11072026.pdf")
/// back into the shape the CAFO daily forecast table uses.
///
/// This is the inverse of [CafoTablePdfService], which renders each cell as
/// "WEATHER (PROB%)" followed by the temperature. The bulletins are produced by
/// Microsoft Word, so they carry a real text layer — we recover the table by
/// grouping the text by its coordinates rather than by guessing at line breaks.
///
/// The table looks like this on the page (x positions from the sample bulletin):
///
///   CITIES(20)  EVENING(131) TEMP(214)  NIGHT(304) TEMP(382)  MORNING(459) TEMP(538)
///   AFLAO       SL’T RAIN (30%)     26  SL’T RAIN (30%)    24  SL’T RAIN (30%)     23
///   KASOA       M’CLOUDY            26  SL’T RAIN (30%)    24  SL’T RAIN (30%)     23
///   WINNEBA     M’CLOUDY            26  SL’T RAIN (30%)    22  MIST (40%)          24
///
/// The three period columns always appear in the order dictated by the issue
/// time, matching `CAFOController.dynamicHeaders`.
///
/// Note the cells are CENTRE-aligned, so a cell's content does not start at a
/// fixed x — "SL’T RAIN (30%)" begins ~11pt left of where "M’CLOUDY" begins. We
/// therefore take column boundaries midway between the header labels (including
/// the TEMP sub-labels) rather than at a fixed offset from them, which keeps a
/// >20pt margin on either side of every boundary.

/// The period names that can head the three forecast columns.
const _periodNames = ['MORNING', 'AFTERNOON', 'EVENING', 'NIGHT'];

/// Reverse of `CAFOController.dynamicHeaders`: a column triple uniquely
/// identifies the issue time, so we can recover the issue time from the table
/// header alone even if the "ISSUED AT ... UTC" line is unreadable.
const _headersToIssueTime = <String, String>{
  'MORNING|AFTERNOON|EVENING': '0500',
  'AFTERNOON|EVENING|NIGHT': '1100',
  'EVENING|NIGHT|MORNING': '1700',
  'NIGHT|MORNING|AFTERNOON': '2300',
};

/// Thrown when the PDF does not look like a GMet forecast bulletin.
class CafoPdfParseException implements Exception {
  CafoPdfParseException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// One forecast period for one city, exactly as printed in the PDF.
class ParsedSlot {
  const ParsedSlot({this.weather = '', this.prob = '', this.temp = ''});

  /// Condition code as printed, e.g. "TSRA", "RAIN", "MIST". Empty for fair weather.
  final String weather;

  /// Probability of occurrence without the % sign, e.g. "40". Empty if absent.
  final String prob;

  /// Temperature in °C, e.g. "26". Empty if absent.
  final String temp;

  bool get isEmpty => weather.isEmpty && prob.isEmpty && temp.isEmpty;
}

/// One city row from the bulletin table.
class ParsedPdfRow {
  const ParsedPdfRow({required this.cityName, required this.slots});

  /// City name as printed in the PDF, e.g. "CAPE COAST".
  final String cityName;

  /// Always exactly three, in the PDF's column order.
  final List<ParsedSlot> slots;
}

/// Everything we managed to recover from a bulletin.
class ParsedBulletin {
  const ParsedBulletin({
    required this.issueTime,
    required this.periodHeaders,
    required this.summary,
    required this.rows,
    required this.warnings,
  });

  /// '0500' | '1100' | '1700' | '2300', or null if it could not be determined.
  final String? issueTime;

  /// The three column headers as printed, e.g. ['EVENING', 'NIGHT', 'MORNING'].
  final List<String> periodHeaders;

  /// The SUMMARY paragraph, whitespace-normalised. Empty if not found.
  final String summary;

  final List<ParsedPdfRow> rows;

  /// Non-fatal problems worth showing the user before they apply the import.
  final List<String> warnings;
}

/// A parsed row after it has been reconciled against the table the user is
/// actually editing: matched to a configured city, and its conditions mapped
/// onto the department's weather vocabulary.
class PdfImportRow {
  const PdfImportRow({
    required this.pdfCityName,
    required this.slots,
    required this.targetIndex,
    required this.unmappedConditions,
  });

  /// The city name as printed in the PDF.
  final String pdfCityName;

  /// The values that will be written, already mapped to `weatherOptions`.
  final List<ParsedSlot> slots;

  /// Index into `CAFOController.cityData`, or -1 when the PDF names a city that
  /// is not configured for this department.
  final int targetIndex;

  /// Conditions that had no equivalent in `weatherOptions` and will be written
  /// through as free text.
  final List<String> unmappedConditions;

  bool get isMatched => targetIndex >= 0;
}

/// Extracts the forecast table from [bytes].
///
/// Throws [CafoPdfParseException] if the document has no text layer (a scanned
/// bulletin) or if the table header cannot be located.
Future<ParsedBulletin> parseCafoBulletin(Uint8List bytes) async {
  final document = await PdfDocument.openData(bytes);
  try {
    if (document.pages.isEmpty) {
      throw CafoPdfParseException('The PDF has no pages.');
    }
    final pageText = await document.pages.first.loadStructuredText();
    return _parsePage(pageText);
  } finally {
    await document.dispose();
  }
}

// ── Geometry primitives ─────────────────────────────────────────────────────
//
// pdfrx reports coordinates in PDF space: the origin is bottom-left and y grows
// upwards, so `top` is numerically GREATER than `bottom` and a line further down
// the page has a SMALLER y.

/// A run of characters with no significant horizontal gap inside it.
class _Word {
  _Word(this.text, this.left, this.right, this.centerY);
  final String text;
  final double left;
  final double right;
  final double centerY;
}

/// All the words that share a baseline, left to right.
class _Line {
  _Line(this.centerY, this.words);
  final double centerY;
  final List<_Word> words;

  String get text => words.map((w) => w.text).join(' ');

  /// Uppercase A-Z only. Immune to however the PDF happened to space the text,
  /// which is what makes keyword matching reliable here.
  String get letters => text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
}

ParsedBulletin _parsePage(PdfPageText pageText) {
  final lines = _buildLines(pageText);
  if (lines.isEmpty) {
    throw CafoPdfParseException(
      'No readable text found in this PDF. If it is a scanned document, it '
      'cannot be imported.',
    );
  }

  // ── Locate the table header, which defines the columns ────────────────────
  final headerIndex = lines.indexWhere((l) => l.letters.contains('CITIES'));
  if (headerIndex == -1) {
    throw CafoPdfParseException(
      'Could not find the forecast table (no "CITIES" header row). This does '
      'not look like a GMet forecast bulletin.',
    );
  }
  final headerLine = lines[headerIndex];

  final cityAnchor = _anchorOf(headerLine, 'CITIES');
  final periods = _periodAnchors(headerLine);
  if (cityAnchor == null || periods.length != 3) {
    throw CafoPdfParseException(
      'The forecast table header is not in the expected format. Expected a '
      'CITIES column followed by three period columns (e.g. EVENING, NIGHT, '
      'MORNING), but found ${periods.length}.',
    );
  }

  final periodHeaders = periods.map((p) => p.name).toList();
  final warnings = <String>[];
  final boundaries = _columnBoundaries(headerLine, cityAnchor, periods, warnings);

  // ── Issue time ────────────────────────────────────────────────────────────
  // The header triple is authoritative because it is what actually labels the
  // columns; "ISSUED AT ... UTC" is a cross-check.
  final issueTimeFromHeaders = _headersToIssueTime[periodHeaders.join('|')];
  final issueTimeFromText = _issueTimeFromText(pageText.fullText);

  if (issueTimeFromHeaders == null) {
    warnings.add(
      'Unrecognised column order "${periodHeaders.join(' / ')}" — the issue '
      'time could not be derived from the table header.',
    );
  } else if (issueTimeFromText != null &&
      issueTimeFromText != issueTimeFromHeaders) {
    warnings.add(
      'The bulletin says it was issued at $issueTimeFromText UTC, but its '
      'columns (${periodHeaders.join(' / ')}) belong to the '
      '$issueTimeFromHeaders UTC slot. Using $issueTimeFromHeaders.',
    );
  }
  final issueTime = issueTimeFromHeaders ?? issueTimeFromText;

  // ── Summary ───────────────────────────────────────────────────────────────
  final summary = _extractSummary(lines, headerIndex);

  // ── City rows ─────────────────────────────────────────────────────────────
  final rows = <ParsedPdfRow>[];
  for (var i = headerIndex + 1; i < lines.length; i++) {
    final line = lines[i];

    // The sea-state line marks the end of the table.
    if (line.letters.contains('STATEOFTHESEA')) break;

    final row = _rowFrom(line, boundaries);
    if (row != null) {
      rows.add(row);
    } else if (rows.isNotEmpty) {
      // We were reading rows and hit something that is not one — the table has
      // ended (legend, signature block, footer).
      break;
    }
    // Before the first row we skip freely: the date sub-header
    // "(11/07/2026) 1800UTC ..." sits between the header and the first city.
  }

  if (rows.isEmpty) {
    throw CafoPdfParseException(
      'Found the table header but no city rows underneath it.',
    );
  }

  return ParsedBulletin(
    issueTime: issueTime,
    periodHeaders: periodHeaders,
    summary: summary,
    rows: rows,
    warnings: warnings,
  );
}

// ── Text reconstruction ─────────────────────────────────────────────────────

/// Rebuilds words and lines from the page's per-character bounding boxes.
///
/// We deliberately work from [PdfPageText.charRects] rather than
/// [PdfPageText.fragments]: a fragment can span a whole visual line, which would
/// leave us with one bounding box for "AFLAO TSRA (30%) 26 24 23" and no way to
/// tell the columns apart.
List<_Line> _buildLines(PdfPageText pageText) {
  final full = pageText.fullText;
  final rects = pageText.charRects;
  final count = full.length < rects.length ? full.length : rects.length;

  // Group characters into lines by vertical position. 4pt of tolerance: the row
  // pitch in the bulletin is ~12pt, and superscripts (the ° in "TEMP °C") sit
  // ~3pt above their own baseline.
  const lineTolerance = 4.0;

  final glyphs = <_Glyph>[];
  var spacePending = false;
  for (var i = 0; i < count; i++) {
    final ch = full[i];
    if (ch.trim().isEmpty) {
      spacePending = true; // includes the newlines pdfrx inserts between lines
      continue;
    }
    final rect = rects[i];
    if (rect.isEmpty) continue;
    glyphs.add(_Glyph(ch, rect, spacePending));
    spacePending = false;
  }
  if (glyphs.isEmpty) return const [];

  // Bucket by y, then order each line left-to-right.
  final buckets = <double, List<_Glyph>>{};
  for (final g in glyphs) {
    final key = buckets.keys.firstWhere(
      (k) => (k - g.centerY).abs() <= lineTolerance,
      orElse: () => double.nan,
    );
    if (key.isNaN) {
      buckets[g.centerY] = [g];
    } else {
      buckets[key]!.add(g);
    }
  }

  final lines = <_Line>[];
  // Descending y == top of the page downwards.
  final keys = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
  for (final key in keys) {
    final lineGlyphs = buckets[key]!..sort((a, b) => a.left.compareTo(b.left));
    lines.add(_Line(key, _wordsFrom(lineGlyphs)));
  }
  return lines;
}

class _Glyph {
  _Glyph(this.char, this.rect, this.spaceBefore);
  final String char;
  final PdfRect rect;

  /// Whitespace preceded this character in the document's own text order.
  final bool spaceBefore;

  double get left => rect.left;
  double get right => rect.right;
  double get centerY => (rect.top + rect.bottom) / 2;
  double get height => (rect.top - rect.bottom).abs();
}

/// Splits a line's glyphs into words.
///
/// A break is taken where the PDF itself had whitespace, or where there is a
/// gap wide enough that it cannot be mere kerning. The geometric rule is only a
/// safety net for PDFs whose text layer omits spaces — and it is deliberately
/// conservative, because an extra split *within* a column is harmless (words are
/// re-joined per column) while a missed split never merges across columns, whose
/// gaps are 30pt or more.
List<_Word> _wordsFrom(List<_Glyph> glyphs) {
  final words = <_Word>[];
  var buffer = StringBuffer();
  var left = glyphs.first.left;
  var right = glyphs.first.right;
  var centerY = glyphs.first.centerY;

  void flush() {
    if (buffer.isEmpty) return;
    words.add(_Word(buffer.toString(), left, right, centerY));
    buffer = StringBuffer();
  }

  for (var i = 0; i < glyphs.length; i++) {
    final g = glyphs[i];
    if (i > 0) {
      final prev = glyphs[i - 1];
      final gap = g.left - prev.right;
      final breakHere = g.spaceBefore || gap > 0.4 * g.height;
      if (breakHere) {
        flush();
        left = g.left;
        centerY = g.centerY;
      }
    }
    buffer.write(g.char);
    right = g.right;
  }
  flush();
  return words;
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Anchor {
  _Anchor(this.name, this.left);
  final String name;
  final double left;
}

/// Finds [keyword] in [line] and returns the x of its first character.
///
/// Matching runs against a letters-only projection of the line, so it survives
/// the PDF splitting "EVENING" across text runs or dropping the space in
/// "CITIES EVENING".
_Anchor? _anchorOf(_Line line, String keyword) {
  final letters = StringBuffer();
  final lefts = <double>[];
  for (final word in line.words) {
    for (final ch in word.text.toUpperCase().split('')) {
      if (RegExp(r'[A-Z]').hasMatch(ch)) {
        letters.write(ch);
        // Approximate: every letter of a word is attributed to the word's left
        // edge. Good enough — we only need to know which column a header sits
        // in, and columns are ~130pt apart.
        lefts.add(word.left);
      }
    }
  }
  final index = letters.toString().indexOf(keyword);
  if (index == -1) return null;
  return _Anchor(keyword, lefts[index]);
}

/// The three period columns, left to right.
List<_Anchor> _periodAnchors(_Line headerLine) {
  final found = <_Anchor>[];
  for (final name in _periodNames) {
    final anchor = _anchorOf(headerLine, name);
    if (anchor != null) found.add(anchor);
  }
  found.sort((a, b) => a.left.compareTo(b.left));
  return found;
}

/// The "TEMP °C" sub-labels, left to right — one inside each period column.
List<_Anchor> _tempAnchors(_Line headerLine) {
  final found = <_Anchor>[];
  for (final word in headerLine.words) {
    final letters = word.text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    // The third one comes through as a single "TEMPOC" word in the sample.
    if (letters.startsWith('TEMP')) {
      found.add(_Anchor('TEMP', word.left));
    }
  }
  found.sort((a, b) => a.left.compareTo(b.left));
  return found;
}

/// The three x positions that separate CITIES | period 1 | period 2 | period 3.
///
/// Each boundary is placed midway between the label ending one column and the
/// label starting the next. Because the temperature sits at the right-hand end
/// of a period column and the condition at the left, the previous column's TEMP
/// label is the correct left-hand reference — using the period labels alone
/// would put the boundary left of the temperatures and steal them.
List<double> _columnBoundaries(
  _Line headerLine,
  _Anchor cityAnchor,
  List<_Anchor> periods,
  List<String> warnings,
) {
  final temps = _tempAnchors(headerLine);
  double midpoint(double a, double b) => (a + b) / 2;

  final boundaries = <double>[
    midpoint(cityAnchor.left, periods[0].left),
  ];
  for (var i = 1; i < 3; i++) {
    if (temps.length >= i) {
      boundaries.add(midpoint(temps[i - 1].left, periods[i].left));
    } else {
      // No TEMP sub-label to anchor against; fall back to a fixed back-off.
      boundaries.add(periods[i].left - 30);
    }
  }
  if (temps.length < 2) {
    warnings.add(
      'The table header has no "TEMP" sub-labels, so the column boundaries had '
      'to be estimated. Check the imported values carefully.',
    );
  }
  return boundaries;
}

String? _issueTimeFromText(String fullText) {
  // Strip everything but letters and digits so that "ISSUED AT 1700UTC",
  // "ISSUEDAT1700UTC" and "ISSUED  AT 1700 UTC" all match.
  final compact = fullText.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final match = RegExp(r'ISSUEDAT(\d{4})UTC').firstMatch(compact);
  final value = match?.group(1);
  return _headersToIssueTime.containsValue(value) ? value : null;
}

/// The SUMMARY paragraph: everything from the "SUMMARY:" line down to the table
/// header.
String _extractSummary(List<_Line> lines, int headerIndex) {
  final start = lines.indexWhere(
    (l) => l.letters.startsWith('SUMMARY'),
  );
  if (start == -1 || start >= headerIndex) return '';

  final body = lines
      .sublist(start, headerIndex)
      .map((l) => l.text)
      .join(' ');

  return body
      // Drop the "SUMMARY :" label itself.
      .replaceFirst(RegExp(r'^\s*SUMMARY\s*:?\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

// ── Rows ────────────────────────────────────────────────────────────────────

/// Turns a line into a city row, or returns null if it is not one.
ParsedPdfRow? _rowFrom(_Line line, List<double> boundaries) {
  // Words are placed by their left edge. Bucketing per word rather than per
  // character is what makes this safe for multi-word names like "CAPE COAST":
  // every word of the name still starts well inside the CITIES column.
  final columns = List.generate(4, (_) => <_Word>[]);
  for (final word in line.words) {
    var column = 0;
    for (final boundary in boundaries) {
      if (word.left >= boundary) column++;
    }
    columns[column].add(word);
  }

  final cityName = _collapse(columns[0].map((w) => w.text).join(' '));
  if (cityName.length < 2) return null;

  // City names in the bulletin are set in capitals. This rejects the prose that
  // follows the table ("The state of the sea is ROUGH (2)") and the footer.
  if (cityName != cityName.toUpperCase()) return null;
  if (!RegExp(r"^[A-Z][A-Z\s.'\-]*$").hasMatch(cityName)) return null;

  final slots = [
    for (var c = 1; c <= 3; c++)
      _slotFrom(columns[c].map((w) => w.text).join(' ')),
  ];

  // A real row always carries at least one temperature.
  if (slots.every((s) => s.temp.isEmpty)) return null;

  return ParsedPdfRow(cityName: cityName, slots: slots);
}

/// Parses one cell, e.g. "SL’T RAIN (30%) 26", "M’CLOUDY 26" or "TSRA (40%) 27".
///
/// This is the inverse of the cell that `CafoTablePdfService` writes:
///   '${city['slot1_weather']} (${city['slot1_prob']}%)'  followed by the temp.
ParsedSlot _slotFrom(String raw) {
  var text = _collapse(raw);
  if (text.isEmpty) return const ParsedSlot();

  // Temperature: the trailing bare number. Taken first so it cannot be confused
  // with the digits inside "(40%)". The lookbehind stops us from biting the
  // last two digits off a longer number — "DATE: 11/07/2026" must not yield 26.
  var temp = '';
  final tempMatch = RegExp(
    r'(?<![\d/.])(-?\d{1,2}(?:\.\d)?)\s*$',
  ).firstMatch(text);
  if (tempMatch != null) {
    final value = double.tryParse(tempMatch.group(1)!);
    if (value != null && value >= -20 && value <= 60) {
      temp = tempMatch.group(1)!;
      text = text.substring(0, tempMatch.start);
    }
  }

  // Probability of occurrence.
  var prob = '';
  final probMatch = RegExp(r'\(\s*(\d{1,3})\s*%\s*\)').firstMatch(text);
  if (probMatch != null) {
    final value = int.tryParse(probMatch.group(1)!);
    if (value != null && value >= 0 && value <= 100) {
      prob = probMatch.group(1)!;
      text = text.replaceRange(probMatch.start, probMatch.end, ' ');
    }
  }

  // Whatever is left is the condition. Keep the apostrophes and ampersands the
  // bulletin's abbreviations rely on ("M’CLOUDY", "SL’T RAIN") — only the
  // leftover digits and brackets go.
  final weather = _collapse(
    text.replaceAll(RegExp(r"[^A-Za-z\s&/’'\-]"), ' '),
  );

  return ParsedSlot(weather: weather, prob: prob, temp: temp);
}

String _collapse(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
