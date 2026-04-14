import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ══════════════════════════════════════════════════════════════════════════════
//  InlandDailyForecastIbfPdfService
//  Generates a single A4-portrait PDF matching the Inland Water IBF layout.
// ══════════════════════════════════════════════════════════════════════════════
class InlandDailyForecastIbfPdfService {
  // ─── Palette ───────────────────────────────────────────────────────────────
  static final _navy   = PdfColor.fromHex('#1A3B85');
  static final _amber  = PdfColor.fromHex('#FFC000');
  static final _cream  = PdfColor.fromHex('#FFF2CC');

  // ──────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> generateIbfPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // ── 1. Load image assets ──────────────────────────────────────────────
    final coatBytes    = await rootBundle.load('assets/images/ghana_coat_of_arms.png');
    final gmetBytes    = await rootBundle.load('assets/images/gmet_logo.png');
    final iconsBytes   = await rootBundle.load('assets/images/ibf_icons.png');

    final coat       = pw.MemoryImage(coatBytes.buffer.asUint8List());
    final gmet       = pw.MemoryImage(gmetBytes.buffer.asUint8List());
    final iconsImage = pw.MemoryImage(iconsBytes.buffer.asUint8List());

    // ── 2. Load TrueType fonts (Unicode-safe) ─────────────────────────────
    // Add these .ttf files under assets/fonts/ and register in pubspec.yaml
    final ttfRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/Tinos-Regular.ttf'));
    final ttfBold    = pw.Font.ttf(await rootBundle.load('assets/fonts/Tinos-Bold.ttf'));
    final ttfItalic  = pw.Font.ttf(await rootBundle.load('assets/fonts/Tinos-Italic.ttf'));

    final theme = pw.ThemeData.withFont(
      base:   ttfRegular,
      bold:   ttfBold,
      italic: ttfItalic,
    );

    // ── 3. Unpack data payload ────────────────────────────────────────────
    final String date           = data['formattedDate']  ?? '';
    final String timeIssued     = data['timeIssued']     ?? '';
    final String validFrom      = data['validFrom']      ?? '';
    final String summary        = data['summary']        ?? '';
    final String nowcastingRisk = data['nowcastingRisk'] ?? '';

    final List<String> headers     = List<String>.from(data['headers']     ?? ['MORNING',   'AFTERNOON',  'EVENING']);
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
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── Thick blue left border ──────────────────────────────────
              pw.Container(width: 14, color: _navy),

              // ── Main content ────────────────────────────────────────────
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [

                      // ── HEADER ─────────────────────────────────────────
                      _buildHeader(gmet, coat),
                      pw.Divider(thickness: 1.5, color: _navy),
                      pw.SizedBox(height: 3),

                      // ── TITLE ──────────────────────────────────────────
                      pw.Center(
                        child: pw.Text(
                          'INLAND WATER IMPACT-BASED FORECAST',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            decoration: pw.TextDecoration.underline,
                            color: _navy,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),

                      // ── WEATHER SUMMARY ────────────────────────────────
                      pw.Text(
                        'WEATHER SUMMARY',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        summary,
                        style: const pw.TextStyle(fontSize: 8, lineSpacing: 1.4),
                        textAlign: pw.TextAlign.justify,
                      ),
                      pw.SizedBox(height: 8),

                      // ── THREE MAP COLUMNS ──────────────────────────────
                      pw.SizedBox(
                        height: 185,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            _mapColumn(headers[0], headerDates[0], map1),
                            pw.SizedBox(width: 5),
                            _mapColumn(headers[1], headerDates[1], map2),
                            pw.SizedBox(width: 5),
                            _mapColumn(headers[2], headerDates[2], map3),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 8),

                      // ── BOTTOM SECTION: sidebar + icons/risk ───────────
                      // Height must be fixed so Expanded children in sidebar work
                     // ── BOTTOM SECTION: sidebar + icons/risk ───────────
                      // Let this expand to fill the remaining A4 page height dynamically
                      pw.Expanded(
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            pw.SizedBox(width: 8),
                            
                            // Left: CAFO sidebar (38% flex)
                            pw.Expanded(
                              flex: 38,
                              child: _buildInlandSidebar(date, timeIssued, validFrom, nowcastingRisk),
                            ),
                            
                            pw.SizedBox(width: 8),

                            // Right: Weather Icons + Risk Matrix (62% flex)
                            pw.Expanded(
                              flex: 62,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                                children: [
                                  // Weather Icons box
                                  pw.SizedBox(
                                    height: 65,
                                    child: pw.Container(
                                      // decoration: pw.BoxDecoration(
                                      //   border: pw.Border.all(width: 1),
                                      // ),
                                      child: pw.Column(
                                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                                        children: [
                                          pw.Container(
                                            alignment: pw.Alignment.center,
                                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                            decoration:  pw.BoxDecoration(
                                              border: pw.Border.all(width: 1),
                                            ),
                                            child: pw.Text(
                                              'Weather Icons',
                                              style: pw.TextStyle(
                                                fontSize: 9,
                                                fontWeight: pw.FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          pw.Expanded(
                                            child: pw.Padding(
                                              padding: const pw.EdgeInsets.all(6),
                                              child: pw.Center(
                                                child: pw.Image(iconsImage, fit: pw.BoxFit.contain),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  pw.SizedBox(height: 6),

                                  // Risk Matrix
                                  pw.Expanded(
                                    child: _riskMatrix(),
                                  ),

                                     pw.SizedBox(height: 8),

                      // ── GENERAL CONDITIONS TABLE ───────────────────────
                      _generalConditionsTable(gc),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                   
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
        borderRadius: const pw.BorderRadius.only(
          bottomRight: pw.Radius.circular(60),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Image(leftLogo, width: 48, height: 48),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'GHANA METEOROLOGICAL AGENCY',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('P. O. Box LG 87, Accra',             style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                        pw.Text('Tel: +233-302-543252 / 307010019',   style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                        pw.Text('Digital Address: GA-485-3581',        style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Email: info@meteo.gov.gh',            style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                        pw.Text('Website: www.meteo.gov.gh',           style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                        pw.Text('Twitter: @GhanaMet',                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                        pw.Text('Facebook: Ghana Meteorological Agency', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Image(rightLogo, width: 48, height: 48),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MAP COLUMN  – height is driven by the parent SizedBox(height:185)
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _mapColumn(String header, String date, Uint8List? bytes) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
            ),
            child: pw.Text(
              '$header\n($date)',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: _navy),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.8),
              ),
              child: bytes != null
                  ? pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.fill)
                  : pw.Center(child: pw.Text('No Map Data', style: const pw.TextStyle(fontSize: 7))),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  INLAND SIDEBAR  (left column in the bottom section)
  //  Parent is a SizedBox(height:195) so Expanded children are safe here.
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _buildInlandSidebar(
      String date, String timeIssued, String validFrom, String nowcastingRisk) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _sidebarCell('Date',            PdfColors.black,                    PdfColors.white,  flex: 10),
        _sidebarCell(date,              PdfColors.white,                    PdfColors.black,  flex: 10),
        _sidebarCell('Time Issued',     PdfColors.black,                    PdfColors.white,  flex: 10),
        _sidebarCell(timeIssued,        PdfColors.white,                    PdfColors.black,  flex: 10),
        _sidebarCell('Valid From',      PdfColors.black,                    PdfColors.white,  flex: 10),
        _sidebarCell(validFrom,         PdfColors.white,                    PdfColors.black,  flex: 10),
        _sidebarCell('Nowcasting\nRisk',PdfColors.black,                    PdfColors.white,  flex: 14), 
        _sidebarCell('Take Action',     PdfColors.red,                      PdfColors.white,  flex: 10),
        _sidebarCell('Be Prepared',     PdfColors.orange,                   PdfColors.white,  flex: 10),
        _sidebarCell('Be aware',        PdfColors.yellow,                   PdfColors.black,  flex: 10),
        _sidebarCell('Low risk',        PdfColor.fromHex('#92D050'),        PdfColors.black,  flex: 10),
        _sidebarCell('No risk',         PdfColors.white,                    PdfColors.black,  flex: 10, hideBorder: true),
      ],
    );
  }

  
  static pw.Widget _sidebarCell(
    String text,
    PdfColor bgColor,
    PdfColor textColor, {
    required int flex,
    bool hideBorder = false,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: bgColor,
          border: hideBorder
              ? null
              : const pw.Border(bottom: pw.BorderSide(width: 1.2)),
        ),
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

    final likelihoodLabels = ['High(>60%)', 'Medium(40-60%)', 'Low (<40%)'];
    final impactLabels     = ['Low', 'Medium', 'High'];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'Weather Forecast Risk Table',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
        ),
        pw.SizedBox(height: 3),
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Rotated "Likelihood" label
              pw.Transform.rotate(
                angle: -3.14159 / 2,
                child: pw.SizedBox(
                  width: 55,
                  child: pw.Center(
                    child: pw.Text(
                      'Likelihood',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 2),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Table
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2.2),
                        1: const pw.FlexColumnWidth(1.5),
                        2: const pw.FlexColumnWidth(1.5),
                        3: const pw.FlexColumnWidth(1.5),
                      },
                      children: [
                        // Header row
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: PdfColors.white),
                          children: [
                            _mxCell('', PdfColors.white),
                            ...impactLabels.map((l) => _mxCell(l, PdfColors.white, bold: true)),
                          ],
                        ),
                        // Data rows
                        ...List.generate(3, (ri) {
                          return pw.TableRow(
                            children: [
                              _mxCell(likelihoodLabels[ri], PdfColors.white, bold: true),
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
                    ),
                    pw.SizedBox(height: 3),
                    pw.Center(
                      child: pw.Text(
                        'Impact',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
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
  

    // Then also safely convert the nested wind/vis/temp maps:
final wind = gc['SURFACE WIND'] != null ? Map<String, dynamic>.from(gc['SURFACE WIND'] as Map) : <String, dynamic>{};
final vis  = gc['VISIBILITY']   != null ? Map<String, dynamic>.from(gc['VISIBILITY']   as Map) : <String, dynamic>{};
final temp = gc['TEMPERATURE']  != null ? Map<String, dynamic>.from(gc['TEMPERATURE']  as Map) : <String, dynamic>{};

print('General Conditions GC: $gc');
print('Parsed wind: $wind');
print('Parsed vis: $vis');
print('Parsed temp: $temp');

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2.5),
        3: pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _amber),
          children: [
            _gcCell('Time',         bold: true),
            _gcCell('Surface Wind', bold: true),
            _gcCell('Visibility',   bold: true),
            _gcCell('Temperature',  bold: true),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _cream),
          children: [
            _gcCell('12 hours', bold: true),
            _gcCell(wind['12h']?.toString() ?? ''),
            _gcCell(vis['12h']?.toString()  ?? ''),
            _gcCell(temp['12h']?.toString() ?? ''),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _cream),
          children: [
            _gcCell('24 hours', bold: true),
            _gcCell(wind['24h']?.toString() ?? ''),
            _gcCell(vis['24h']?.toString()  ?? ''),
            _gcCell(temp['24h']?.toString() ?? ''),
          ],
        ),
      ],
    );
  }

  static pw.Widget _gcCell(String text, {bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }
}
// import 'dart:typed_data';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;

// // ══════════════════════════════════════════════════════════════════════════════
// //  InlandDailyForecastIbfPdfService
// //  Generates a single A4-portrait PDF matching the Inland Water IBF layout.
// // ══════════════════════════════════════════════════════════════════════════════
// class InlandDailyForecastIbfPdfService {
//   // ─── Palette ───────────────────────────────────────────────────────────────
//   // EXACT MATCH ACTION: If the blue in your image is slightly lighter/darker, change '#000080'
//   static final _navy   = PdfColor.fromHex('#000080'); 
//   static final _amber  = PdfColor.fromHex('#FFC000'); 
//   static final _cream  = PdfColor.fromHex('#FFF2CC'); 
//   static final _green  = PdfColor.fromHex('#00B050');
//   static final _yellow = PdfColor.fromHex('#FFFF00');
//   static final _red    = PdfColor.fromHex('#FF0000');

//   // ──────────────────────────────────────────────────────────────────────────
//   static Future<Uint8List> generateIbfPdf(Map<String, dynamic> data) async {
//     final pdf = pw.Document();

//     // 1. Assets
//     final coatBytes    = await rootBundle.load('assets/images/ghana_coat_of_arms.png');
//     final gmetBytes    = await rootBundle.load('assets/images/gmet_logo.png');
//     final twitterBytes = await rootBundle.load('assets/images/twitter_logo.png');
//     final fbBytes      = await rootBundle.load('assets/images/facebook_logo.png');
//     final iconsBytes = await rootBundle.load('assets/images/ibf_icons.png');

//     // Weather-icon assets
//     final rainBytes = await rootBundle.load('assets/images/rain.png');
//     final windBytes = await rootBundle.load('assets/images/wind.png');
//     final dustBytes = await rootBundle.load('assets/images/dust.png');
//     final hailBytes = await rootBundle.load('assets/images/hail.png');

//     final coat     = pw.MemoryImage(coatBytes.buffer.asUint8List());
//     final gmet     = pw.MemoryImage(gmetBytes.buffer.asUint8List());
//     final twitter  = pw.MemoryImage(twitterBytes.buffer.asUint8List());
//     final facebook = pw.MemoryImage(fbBytes.buffer.asUint8List());
//     final rainImg  = pw.MemoryImage(rainBytes.buffer.asUint8List());
//     final windImg  = pw.MemoryImage(windBytes.buffer.asUint8List());
//     final dustImg  = pw.MemoryImage(dustBytes.buffer.asUint8List());
//     final hailImg  = pw.MemoryImage(hailBytes.buffer.asUint8List());
//     final iconsImage = pw.MemoryImage(iconsBytes.buffer.asUint8List());

//     // 2. Theme
//     final theme = pw.ThemeData.withFont(
//       base:   pw.Font.times(),
//       bold:   pw.Font.timesBold(),
//       italic: pw.Font.timesItalic(),
//     );

//     // 3. Payload
//     final String date           = data['formattedDate']  ?? '';
//     final String timeIssued     = data['timeIssued']     ?? '';
//     final String validFrom      = data['validFrom']      ?? '';
//     final String summary        = data['summary']        ?? '';
//     final String forecasterName = data['forecasterName'] ?? 'DUTY FORECASTER';
//     final String nowcastingRisk = data['nowcastingRisk'] ?? '';

//     final List<String> headers     = data['headers']     ?? ['EVENING',     'MORNING',     'AFTERNOON'];
//     final List<String> headerDates = data['headerDates'] ?? [date, date, date];

//     final Uint8List? map1 = data['map1']; 
//     final Uint8List? map2 = data['map2']; 
//     final Uint8List? map3 = data['map3']; 

//     final Map<String, dynamic> gc = (data['metadata'] ?? {})['generalConditions'] ?? {};

//     // 4. Page
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         margin: pw.EdgeInsets.zero, // Keep this zero so borders touch the edges!
//         theme: theme,
//         build: (pw.Context context) {
//           return pw.Row( // <-- Wrap the whole page in a Row
//             crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//             children: [
//               // ==========================================
//               // THE THICK BLUE LEFT BORDER
//               // ==========================================
//               pw.Container(
//                 width: 14, // Thickness of the blue line
//                 color: PdfColor.fromHex('#1A3B85'),
//               ),
              
//               // ==========================================
//               // MAIN PAGE CONTENT
//               // ==========================================
//               pw.Expanded(
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//                   children: [
//                   // ── HEADER ──────────────────────────────────────────────
//                   // Header touches the new blue border on the left and the edge on the right
//                     _buildHeader(gmet, coat),
//                   pw.Divider(thickness: 1.5, color: _navy), // EXACT MATCH ACTION: Made divider Navy Blue, change to PdfColors.black if image is black
//                   pw.SizedBox(height: 4),

//                   // ── TITLE ───────────────────────────────────────────────
//                   pw.Center(
//                     child: pw.Text(
//                       'INLAND WATER IMPACT-BASED FORECAST',
//                       style: pw.TextStyle(
//                         fontSize: 13,
//                         fontWeight: pw.FontWeight.bold,
//                         decoration: pw.TextDecoration.underline,
//                         color: _navy, // EXACT MATCH ACTION: Made title Navy Blue to match standard formats. Change if needed.
//                       ),
//                     ),
//                   ),
//                   pw.SizedBox(height: 8),

//                   // ── WEATHER SUMMARY ──────────────────────────────────────
//                   pw.Text(
//                     'WEATHER SUMMARY',
//                     style: pw.TextStyle(
//                       fontSize: 10,
//                       fontWeight: pw.FontWeight.bold,
//                       decoration: pw.TextDecoration.underline,
//                     ),
//                   ),
//                   pw.SizedBox(height: 3),
//                   pw.Text(
//                     summary,
//                     style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.4),
//                     textAlign: pw.TextAlign.justify,
//                   ),
//                   pw.SizedBox(height: 10),

//                   // ── THREE MAP COLUMNS ────────────────────────────────────
//                   pw.Row(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       _mapColumn(headers[0], headerDates[0], map1),
//                       pw.SizedBox(width: 6),
//                       _mapColumn(headers[1], headerDates[1], map2),
//                       pw.SizedBox(width: 6),
//                       _mapColumn(headers[2], headerDates[2], map3),
//                     ],
//                   ),
//                   pw.SizedBox(height: 10),

//                   // ── BOTTOM SECTION ──────────────────────────────────────
//                   pw.Row(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Expanded(
//                         flex: 38,
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.start,
//                           children: [
//                             _buildInlandSidebar(date, timeIssued, validFrom),
                            
//                           ],
//                         ),
//                       ),
//                       pw.SizedBox(width: 10),
//                       pw.Expanded(
//                         flex: 62,
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.center,
//                           children: [ 
//   pw.SizedBox(width: 8),
//        pw.SizedBox(
//   height: 120, 
//           child: pw.Container(
//             // decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//               children: [
//                 pw.Container(
//                   alignment: pw.Alignment.center,
//                   padding: const pw.EdgeInsets.symmetric(vertical: 5),
//                   decoration:  pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
//                   // REMOVED: Grey background. Matches original white.
//                   child: pw.Text('Weather Icons', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
//                 ),
//                 pw.Expanded(
//                   child: pw.Padding(
//                     padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
//                     child: pw.Center(child: pw.Image(iconsImage, fit: pw.BoxFit.contain)),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),


//                             pw.SizedBox(height: 6),
//                             _riskMatrix(),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   pw.SizedBox(height: 10),

//                   // ── GENERAL CONDITIONS TABLE (bottom) ────────────────────
//                   _generalConditionsTable(gc),
//                 ],
//               ),
//             ),
//             ]
//           );
//         },
//       ),
//     );

//     return pdf.save();
//   }

//   // ══════════════════════════════════════════════════════════════════════════
//   //  HEADER
//   // ══════════════════════════════════════════════════════════════════════════
   
//   static pw.Widget _buildHeader(pw.MemoryImage leftLogo, pw.MemoryImage rightLogo) {
//     return pw.Container(
//       decoration: pw.BoxDecoration(
//         color: PdfColor.fromHex('#1A3B85'),
//          borderRadius: const pw.BorderRadius.only(
//           bottomRight: pw.Radius.circular(80),
//       ),),
      
//       padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Image(leftLogo, width: 50, height: 50),
//           pw.Expanded(
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.center,
//               children: [
//                 pw.Text(
//                   'GHANA METEOROLOGICAL AGENCY',
//                   style: pw.TextStyle(
//                     color: PdfColors.white,
//                     fontSize: 16,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//                 pw.SizedBox(height: 4),
//                 pw.Row(
//                   mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
//                   children: [
//                     pw.Column(
//                       crossAxisAlignment: pw.CrossAxisAlignment.start,
//                       children: [
//                         pw.Text('P. O. Box LG 87, Accra', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
//                         pw.Text('Tel: +233-302-543252 / 307010019', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
//                         pw.Text('Digital Address: GA-485-3581', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
//                       ],
//                     ),
//                     pw.Column(
//                       crossAxisAlignment: pw.CrossAxisAlignment.start,
//                       children: [
//                         pw.Text('Email: info@meteo.gov.gh', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
//                         pw.Text('Website: www.meteo.gov.gh', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
//                         pw.Text('Twitter: @GhanaMet', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
//                         pw.Text('Facebook: Ghana Meteorological Agency', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           pw.Image(rightLogo, width: 50, height: 50),
//         ],
//       ),
//     );
//   }


//   // ══════════════════════════════════════════════════════════════════════════
//   //  MAP COLUMN
//   // ══════════════════════════════════════════════════════════════════════════
//   static pw.Widget _mapColumn(String header, String date, Uint8List? bytes) {
//     return pw.Expanded(
//       child: pw.Column(
//         children: [
//           pw.Text(
//             '$header\n($date)',
//             textAlign: pw.TextAlign.center,
//             style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _navy), 
//           ),
//           pw.SizedBox(height: 3),
//           pw.Container(
//             height: 155,
//             decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
//             child: bytes != null
//                 ? pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover)
//                 : pw.Center(child: pw.Text('No Map Data', style: const pw.TextStyle(fontSize: 7))),
//           ),
//         ],
//       ),
//     );
//   }

   
//   // ══════════════════════════════════════════════════════════════════════════
//   //  WEATHER ICONS LEGEND ROW 
//   // ══════════════════════════════════════════════════════════════════════════
  

//   // ══════════════════════════════════════════════════════════════════════════
//   //  RISK MATRIX
//   // ══════════════════════════════════════════════════════════════════════════
//   static pw.Widget _riskMatrix() {
//     final matrix = [
//       [('G', '#FFFF00'), ('H', '#FFC000'), ('I', '#FF0000')],
//       [('D', '#00B050'), ('E', '#FFFF00'), ('F', '#FF0000')],
//       [('A', '#00B050'), ('B', '#00B050'), ('C', '#FFC000')],
//     ];

//     final likelihoodLabels = ['>60%', '40-60%', '<40%'];
//     final impactLabels     = ['Low', 'Medium', 'High'];

//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.center,
//       children: [
//         pw.Text('Weather Forecast Risk Table',
//             style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
//         pw.SizedBox(height: 4),
//         pw.Row(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Transform.rotate(
//               angle: -3.14159 / 2, 
//               child: pw.SizedBox(
//                 width: 60,
//                 child: pw.Center(
//                   child: pw.Text('Likelihood',
//                       style: pw.TextStyle(
//                           fontWeight: pw.FontWeight.bold, fontSize: 8)),
//                 ),
//               ),
//             ),
//             pw.SizedBox(width: 2),
//             pw.Expanded(
//               child: pw.Column(
//                 children: [
//                   pw.Table(
//                     border: pw.TableBorder.all(
//                         color: PdfColors.black, width: 0.8),
//                     children: [
//                       pw.TableRow(
//                         decoration:
//                             pw.BoxDecoration(color: PdfColors.grey300),
//                         children: [
//                           _mxCell('', PdfColors.grey300, bold: true),
//                           ...impactLabels.map(
//                               (l) => _mxCell(l, PdfColors.grey300, bold: true)),
//                         ],
//                       ),
//                       ...List.generate(3, (ri) {
//                         return pw.TableRow(
//                           children: [
//                             _mxCell(likelihoodLabels[ri], PdfColors.grey300,
//                                 bold: true),
//                             ...List.generate(3, (ci) {
//                               final cell = matrix[ri][ci];
//                               return _mxCell(
//                                 cell.$1,
//                                 PdfColor.fromHex(cell.$2),
//                                 textColor: PdfColors.black,
//                                 bold: true,
//                               );
//                             }),
//                           ],
//                         );
//                       }),
//                     ],
//                   ),
//                   pw.SizedBox(height: 3),
//                   pw.Center(
//                     child: pw.Text('Impact',
//                         style: pw.TextStyle(
//                             fontWeight: pw.FontWeight.bold, fontSize: 8)),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   static pw.Widget _mxCell(String text, PdfColor bg,
//       {bool bold = false, PdfColor textColor = PdfColors.black}) {
//     return pw.Container(
//       color: bg,
//       padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
//       alignment: pw.Alignment.center,
//       child: pw.Text(
//         text,
//         textAlign: pw.TextAlign.center,
//         style: pw.TextStyle(
//           fontSize: 7,
//           fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
//           color: textColor,
//         ),
//       ),
//     );
//   }


// static pw.Widget _buildInlandSidebar(String date, String timeIssued, String validFrom) {
//     // FIXED: Using precise proportional Flex values for every cell 
//     // This perfectly divides the height so Nowcasting Risk doesn't get massive.
//     return    pw.Column(

//         crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//         children: [
//           _inlandCell('CAFO', PdfColors.grey400, PdfColors.black, flex: 11),
//           _inlandCell('Date', PdfColors.black, PdfColors.white, flex: 10),
//           _inlandCell(date, PdfColors.white, PdfColors.black, flex: 10),
//           _inlandCell('Time Issued', PdfColors.black, PdfColors.white, flex: 10),
//           _inlandCell(timeIssued, PdfColors.white, PdfColors.black, flex: 10),
//           _inlandCell('Valid From', PdfColors.black, PdfColors.white, flex: 10),
//           _inlandCell(validFrom, PdfColors.white, PdfColors.black, flex: 10),
//           _inlandCell('Nowcasting\nRisk', PdfColors.black, PdfColors.white, flex: 16), // Slightly taller for 2 lines
//           _inlandCell('Take Action', PdfColors.red, PdfColors.white, flex: 10),
//           _inlandCell('Be Prepared', PdfColors.orange, PdfColors.white, flex: 10),
//           _inlandCell('Be aware', PdfColors.yellow, PdfColors.black, flex: 10),
//           _inlandCell('Low risk', PdfColor.fromHex('#92D050'), PdfColors.black, flex: 10),
//           _inlandCell('No risk', PdfColors.white, PdfColors.black, flex: 10, hideBorder: true),
//         ],
//       );
     
//   }

//   static pw.Widget _inlandCell(String text, PdfColor bgColor, PdfColor textColor, {required int flex, bool hideBorder = false}) {
//     return pw.Expanded(
//       flex: flex,
//       child: pw.Container(
//         alignment: pw.Alignment.center,
//         decoration: pw.BoxDecoration(
//           color: bgColor,
//           border: hideBorder ? null : const pw.Border(bottom: pw.BorderSide(width: 1.5)),
//         ),
//         child: pw.Text(
//           text,
//           textAlign: pw.TextAlign.center,
//           style: pw.TextStyle(color: textColor, fontWeight: pw.FontWeight.bold, fontSize: 8),
//         ),
//       ),
//     );
//   }
//   // ══════════════════════════════════════════════════════════════════════════
//   //  GENERAL CONDITIONS TABLE 
//   // ══════════════════════════════════════════════════════════════════════════
//   static pw.Widget _generalConditionsTable(Map<String, dynamic> gc) {
//     final wind = gc['SURFACE WIND'] ?? {};
//     final vis  = gc['VISIBILITY']   ?? {};
//     final temp = gc['TEMPERATURE']  ?? {};

//     return pw.Table(
//       border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
//       // EXACT MATCH ACTION: Tweak these flex widths if columns in your image look wider/narrower
//       columnWidths: {
//         0: const pw.FlexColumnWidth(2), // Time 
//         1: const pw.FlexColumnWidth(3), // Surface Wind (Usually widest)
//         2: const pw.FlexColumnWidth(2.5), // Visibility
//         3: const pw.FlexColumnWidth(2.5), // Temperature
//       },
//       children: [
//         // Header row – amber background
//         pw.TableRow(
//           decoration: pw.BoxDecoration(color: _amber),
//           children: [
//             _gcCell('Time',         bold: true, align: pw.TextAlign.center),
//             _gcCell('Surface Wind', bold: true, align: pw.TextAlign.center),
//             _gcCell('Visibility',   bold: true, align: pw.TextAlign.center),
//             _gcCell('Temperature',  bold: true, align: pw.TextAlign.center),
//           ],
//         ),
//         // 12 hours row
//         pw.TableRow(
//           decoration: pw.BoxDecoration(color: _cream),
//           children: [
//             _gcCell('12 hours', bold: true, align: pw.TextAlign.center),
//             _gcCell(wind['12h']?.toString() ?? '', align: pw.TextAlign.center),
//             _gcCell(vis['12h']?.toString()  ?? '', align: pw.TextAlign.center),
//             _gcCell(temp['12h']?.toString() ?? '', align: pw.TextAlign.center),
//           ],
//         ),
//         // 24 hours row
//         pw.TableRow(
//           decoration: pw.BoxDecoration(color: _cream),
//           children: [
//             _gcCell('24 hours', bold: true, align: pw.TextAlign.center),
//             _gcCell(wind['24h']?.toString() ?? '', align: pw.TextAlign.center),
//             _gcCell(vis['24h']?.toString()  ?? '', align: pw.TextAlign.center),
//             _gcCell(temp['24h']?.toString() ?? '', align: pw.TextAlign.center),
//           ],
//         ),
//       ],
//     );
//   }

//   // EXACT MATCH ACTION: Adjust horizontal/vertical padding and fontSize below if the text feels too cramped or too small
//   static pw.Widget _gcCell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0), // Added breathing room
//       alignment: pw.Alignment.center,
//       child: pw.Text(
//         text,
//         textAlign: align, 
//         style: pw.TextStyle(
//           fontSize: 9, // Slightly increased font size for readability
//           fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
//           color: PdfColors.black,
//         ),
//       ),
//     );
//   }
// }