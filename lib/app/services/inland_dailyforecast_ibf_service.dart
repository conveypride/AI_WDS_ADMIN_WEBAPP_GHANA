import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ══════════════════════════════════════════════════════════════════════════════
//  InlandDailyForecastIbfPdfService
//  Generates a single A4-portrait PDF matching the Inland Water IBF layout.
// ══════════════════════════════════════════════════════════════════════════════
class InlandDailyForecastIbfPdfService {
  // ─── Palette ───────────────────────────────────────────────────────────────
  static final _navy = PdfColor.fromHex('#1A3B85');
  static final _amber = PdfColor.fromHex('#FFC000');
  static final _cream = PdfColor.fromHex('#FFF2CC');
  static final _darkGrey = PdfColor.fromHex('#4A4A4A');

  // ──────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> generateIbfPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // ── 1. Load image assets ──────────────────────────────────────────────
    final coatBytes = await rootBundle.load('assets/images/ghana_coat_of_arms.png');
    final gmetBytes = await rootBundle.load('assets/images/gmet_logo.png');
    final iconsBytes = await rootBundle.load('assets/images/ibf_icons.png');

    final coat = pw.MemoryImage(coatBytes.buffer.asUint8List());
    final gmet = pw.MemoryImage(gmetBytes.buffer.asUint8List());
    final iconsImage = pw.MemoryImage(iconsBytes.buffer.asUint8List());

    // ── 2. Load TrueType fonts (Unicode-safe) ─────────────────────────────
    final ttfRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/Tinos-Regular.ttf'));
    final ttfBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Tinos-Bold.ttf'));
    final ttfItalic = pw.Font.ttf(await rootBundle.load('assets/fonts/Tinos-Italic.ttf'));

    final theme = pw.ThemeData.withFont(
      base: ttfRegular,
      bold: ttfBold,
      italic: ttfItalic,
    );

    // ── 3. Unpack data payload ────────────────────────────────────────────
    final String date = data['formattedDate'] ?? '';
    final String timeIssued = data['timeIssued'] ?? '';
    final String validFrom = data['validFrom'] ?? '';
    final String summary = data['summary'] ?? '';
    final String nowcastingRisk = data['nowcastingRisk'] ?? '';

    final List<String> headers = List<String>.from(data['headers'] ?? ['EVENING', 'MORNING', 'AFTERNOON']);
    final List<String> headerDates = List<String>.from(data['headerDates'] ?? [date, date, date]);

    final Uint8List? map1 = data['map1'];
    final Uint8List? map2 = data['map2'];
    final Uint8List? map3 = data['map3'];

    // ── Safe extraction of generalConditions from Firestore LinkedMaps ──
    final rawMetadata = data['metadata'];
    final Map<String, dynamic> metadata = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : {};

    final rawGc = metadata['generalConditions'];
    final Map<String, dynamic> gc = rawGc is Map
        ? Map<String, dynamic>.from(rawGc)
        : {};

    // ── 4. Build page ─────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: theme,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── HEADER ─────────────────────────────────────────
              _buildHeader(gmet, coat),
              
              pw.SizedBox(height: 6),

              // ── Main content with padding ──────────────────────
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // ── TITLE ──────────────────────────────────────────
                      pw.Center(
                        child: pw.Text(
                          'INLAND WATER IMPACT-BASED FORECAST',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            decoration: pw.TextDecoration.underline,
                            color: _navy,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),

                      // ── WEATHER SUMMARY ────────────────────────────────
                    pw.Center(
                      child:  pw.Text(
                        'WEATHER SUMMARY',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        
                        ),
                      ),),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        summary,
                        style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.3),
                        textAlign: pw.TextAlign.justify,
                      ),
                      pw.SizedBox(height: 8),

                      // ── THREE MAP COLUMNS ──────────────────────────────
                      pw.SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            _mapColumn(headers[0], headerDates[0], map1),
                            pw.SizedBox(width: 4),
                            _mapColumn(headers[1], headerDates[1], map2),
                            pw.SizedBox(width: 4),
                            _mapColumn(headers[2], headerDates[2], map3),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 8),

                      // ── WEATHER ICONS ROW ──────────────────────────────
                      pw.Container(
                        height: 55,
                        // decoration: pw.BoxDecoration(
                        //   border: pw.Border.all(color: PdfColors.black, width: 0.8),
                        // ),
                        child: pw.Column(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 3),
                               decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.black, width: 0.8),
                        ),
                        
                              child: pw.Center(
                                child: pw.Text(
                                  'Weather Icons',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Center(
                                  child: pw.Image(iconsImage, fit: pw.BoxFit.contain),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 8),

                      // ── BOTTOM SECTION: sidebar + risk matrix + GC table ──
                      // ── BOTTOM SECTION: sidebar (left) + stacked tables (right) ──
pw.SizedBox(
  height: 220, // Adjusted height to fit both tables stacked
  width: double.infinity,
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      // 1. LEFT SIDEBAR (Fixed Width)
      pw.SizedBox(
        width: 105, 
        child: _buildInlandSidebar(date, timeIssued, validFrom, nowcastingRisk),
      ),

      pw.SizedBox(width: 8),

    // 2. RIGHT SIDE (Fixed Width Container)
pw.SizedBox(
  width: 400, // Adjust this numerical value to your preferred fixed width
  child: pw.Column(
    // Change to .start if you want tables to maintain their own widths 
    // or keep .stretch if you want them both to be exactly 320px wide.
    crossAxisAlignment: pw.CrossAxisAlignment.stretch, 
    children: [
      // TOP: Risk Matrix
      _riskMatrix(), 
      
      pw.SizedBox(height: 10), // Vertical spacing

      // BOTTOM: General Conditions Table
      _generalConditionsTable(gc),
    ],
  ),
),
    ],
  ),
),
                      pw.SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HEADER
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _buildHeader(pw.MemoryImage leftLogo, pw.MemoryImage rightLogo) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _navy,
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Image(leftLogo, width: 42, height: 42),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'GHANA METEOROLOGICAL AGENCY',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('P. O. Box LG 87, Accra', style: const pw.TextStyle(color: PdfColors.white, fontSize: 6.5)),
                        pw.Text('Tel: +233-302-543252 / 307010019', style: const pw.TextStyle(color: PdfColors.white, fontSize: 6.5)),
                        pw.Text('Digital Address: GA-485-3581', style: const pw.TextStyle(color: PdfColors.white, fontSize: 6.5)),
                      ],
                    ),
                    pw.SizedBox(width: 20),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Email: info@meteo.gov.gh', style: const pw.TextStyle(color: PdfColors.white, fontSize: 6.5)),
                        pw.Text('Website: www.meteo.gov.gh', style: const pw.TextStyle(color: PdfColors.white, fontSize: 6.5)),
                        pw.Text('Twitter: @GhanaMet', style: const pw.TextStyle(color: PdfColors.white, fontSize: 6.5)),
                        pw.Text('Facebook: Ghana Meteorological Agency', style: const pw.TextStyle(color: PdfColors.white, fontSize: 6.5)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Image(rightLogo, width: 42, height: 42),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MAP COLUMN
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _mapColumn(String header, String date, Uint8List? bytes) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
            ),
            child: pw.Text(
              '$header ($date)',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 7.5,
                color: _darkGrey,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                ),
              ),
              child: bytes != null
                  ? pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain)
                  : pw.Center(
                      child: pw.Text(
                        'No Map Data',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  INLAND SIDEBAR (left column in the bottom section)
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _buildInlandSidebar(
      String date, String timeIssued, String validFrom, String nowcastingRisk) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sidebarCell('Date', _darkGrey, PdfColors.white, flex: 8),
          _sidebarCell(date, PdfColors.white, PdfColors.black, flex: 8),
          _sidebarCell('Time Issued', _darkGrey, PdfColors.white, flex: 8),
          _sidebarCell(timeIssued, PdfColors.white, PdfColors.black, flex: 8),
          _sidebarCell('Valid From', _darkGrey, PdfColors.white, flex: 8),
          _sidebarCell(validFrom, PdfColors.white, PdfColors.black, flex: 8),
          _sidebarCell('Nowcasting\nRisk', _darkGrey, PdfColors.white, flex: 10),
          _sidebarCell('Take Action', PdfColors.red, PdfColors.white, flex: 9),
          _sidebarCell('Be Prepared', PdfColors.orange, PdfColors.white, flex: 9),
          _sidebarCell('Be aware', PdfColors.yellow, PdfColors.black, flex: 9),
          _sidebarCell('Low risk', PdfColor.fromHex('#92D050'), PdfColors.black, flex: 9),
          _sidebarCell('No risk', PdfColors.white, PdfColors.black, flex: 8),
        ],
      ),
    );
  }

  static pw.Widget _sidebarCell(
    String text,
    PdfColor bgColor,
    PdfColor textColor, {
    required int flex,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: bgColor,
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
          ),
        ),
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            color: textColor,
            fontWeight: pw.FontWeight.bold,
            fontSize: 7,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  RISK MATRIX
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _riskMatrix() {
    final matrix = [
      [('G', '#00B050'), ('H', '#FFFF00'), ('I', '#FF0000')],
      [('D', '#00B050'), ('E', '#FFFF00'), ('F', '#FF0000')],
      [('A', '#00B050'), ('B', '#FFFF00'), ('C', '#FF0000')],
    ];

    final likelihoodLabels = ['High (>60%)', 'Medium (40-60%)', 'Low (<40%)'];
    final impactLabels = ['Low', 'Medium', 'High'];

    // The table itself (no Expanded wrapping it)
    final table = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _mxCell('', PdfColors.grey200),
            ...impactLabels.map((l) => _mxCell(l, PdfColors.grey200, bold: true)),
          ],
        ),
        // Data rows
        ...List.generate(3, (ri) {
          return pw.TableRow(
            children: [
              _mxCell(likelihoodLabels[ri], PdfColors.grey200, bold: true),
              ...List.generate(3, (ci) {
                final cell = matrix[ri][ci];
                return _mxCell(
                  cell.$1,
                  PdfColor.fromHex(cell.$2),
                  textColor: PdfColors.black,
                  bold: true,
                );
              }),
            ],
          );
        }),
      ],
    );

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // ── Title ──
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
      ),
            child: pw.Center(
              child: pw.Text(
                'Weather Forecast Risk Table',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ),
          ),

          // ── Likelihood label (rotated) + table + Impact label ──
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(4, 6, 6, 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Rotated "Likelihood" — use a fixed SizedBox that is as tall
                // as the table area and wide enough to show the rotated word.
                pw.SizedBox(
                  width: 40,
                  height: 100,
                  child: pw.Transform.rotate(
                    angle: -3.14159 / 2,
                    child: pw.Center(
                      child: pw.Text(
                        'Likelihood',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 7,
                        ),
                      ),
                    ),
                  ),
                ),

                pw.SizedBox(width: 4),

                // Table + "Impact" label below
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      table,
                      pw.SizedBox(height: 4),
                      pw.Center(
                        child: pw.Text(
                          'Impact',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _mxCell(
    String text,
    PdfColor bg, {
    bool bold = false,
    PdfColor textColor = PdfColors.black,
  }) {
    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GENERAL CONDITIONS TABLE
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _generalConditionsTable(Map<String, dynamic> gc) {
    // Safely convert the nested wind/vis/temp maps
    final wind = gc['SURFACE WIND'] != null
        ? Map<String, dynamic>.from(gc['SURFACE WIND'] as Map)
        : <String, dynamic>{};
    final vis = gc['VISIBILITY'] != null
        ? Map<String, dynamic>.from(gc['VISIBILITY'] as Map)
        : <String, dynamic>{};
    final temp = gc['TEMPERATURE'] != null
        ? Map<String, dynamic>.from(gc['TEMPERATURE'] as Map)
        : <String, dynamic>{};

    return pw.Align(
      alignment: pw.Alignment.topLeft,
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.8),
        ),
        child: pw.Table(
          border: pw.TableBorder.symmetric(
            inside: pw.BorderSide(color: PdfColors.black, width: 0.8),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.2),
            1: pw.FlexColumnWidth(1.8),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _amber),
              children: [
                _gcCell('Time', bold: true),
                _gcCell('Surface Wind', bold: true),
                _gcCell('Visibility', bold: true),
                _gcCell('Temperature', bold: true),
              ],
            ),
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _cream),
              children: [
                _gcCell('12 hours', bold: true),
                _gcCell(wind['12h']?.toString() ?? 'S/SE 05\nMax 10'),
                _gcCell(vis['12h']?.toString() ?? '(5 - 10) km'),
                _gcCell(temp['12h']?.toString() ?? '(25 - 30)°C'),
              ],
            ),
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _cream),
              children: [
                _gcCell('24 hours', bold: true),
                _gcCell(wind['24h']?.toString() ?? 'SE/SW 05\nMax 10'),
                _gcCell(vis['24h']?.toString() ?? '(5 - 10) km'),
                _gcCell(temp['24h']?.toString() ?? '(25 - 30)°C'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _gcCell(String text, {bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }
}

