import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
 
class CoastlineIbfPdfService {


  static Future<Uint8List> generateIbfPdf(
    Map<String, dynamic> forecast,
    Uint8List mapImageBytes,
  ) async {
   // Load sea state legend images
    final calmBytes = await rootBundle.load('assets/images/calm_sea.png');
    final roughBytes = await rootBundle.load('assets/images/rough_sea.png');
    final dangerousBytes = await rootBundle.load('assets/images/dangerous_sea.png');
  final calmSea = pw.MemoryImage(calmBytes.buffer.asUint8List());
    final roughSea = pw.MemoryImage(roughBytes.buffer.asUint8List());
    final dangerousSea = pw.MemoryImage(dangerousBytes.buffer.asUint8List());

    final pdf = pw.Document();

    // ========================================================================
    // 1. LOAD ASSETS  — same paths as CafoDailyForecastIbfPdfService
    // ========================================================================
    final gmetLogoBytes   = await rootBundle.load('assets/images/gmet_light_logo.png');
    final coatOfArmsBytes = await rootBundle.load('assets/images/ghana_coat_of_arms.png');
    final iconsBytes      = await rootBundle.load('assets/images/ibf_icons.png');

    final gmetLogo   = pw.MemoryImage(gmetLogoBytes.buffer.asUint8List());
    final coatOfArms = pw.MemoryImage(coatOfArmsBytes.buffer.asUint8List());
    final iconsImage = pw.MemoryImage(iconsBytes.buffer.asUint8List());
    final mapImage   = pw.MemoryImage(mapImageBytes);

    // ── Fonts (same as CAFO) ─────────────────────────────────────────────────
       final ttfRegular = pw.Font.times();
    final ttfBold = pw.Font.timesBold();
    final theme  = pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold);

    // ========================================================================
    // 2. EXTRACT DYNAMIC FORECAST FIELDS
    // ========================================================================
    final String issueDate      = _fmtDate(forecast['issueDate']) ?? '08/04/2026';
    final String issueTime      = forecast['issueTime']           ?? '10:00 AM';
    final String validFrom      = forecast['validTime']           ?? '12:00 PM';
    final String validLabel     = _fmtValidLabel(forecast['validDate'], forecast['validTime']);
    final String weatherSummary = forecast['weatherSummary']      ?? '';
    final String warningText    = forecast['warningText']         ?? '';
    final String stateOfSea     = forecast['stateOfSea']          ?? 'Rough';
    final Map<String, dynamic> tableData =
        (forecast['tableData'] as Map<String, dynamic>?) ?? {};

    // ========================================================================
    // 3. BUILD PAGE  — zero margin, same as CAFO
    // ========================================================================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: theme,
        build: (pw.Context ctx) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── THICK BLUE LEFT BORDER ──────────────────────────────────
              pw.Container(
                width: 14,
                color: PdfColor.fromHex('#1A3B85'),
              ),

              // ── MAIN CONTENT ─────────────────────────────────────────────
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(gmetLogo, coatOfArms),

                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(
                            left: 16, right: 24, top: 10, bottom: 20),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            _buildTitle(validLabel),
                            pw.SizedBox(height: 10),

                            // Map + sidebar
                            pw.Expanded(
                              flex: 5,
                              child: _buildMapAndSidebar(
                                mapImage: mapImage,
                                issueDate: issueDate,
                                issueTime: issueTime,
                                validFrom: validFrom,
                              ),
                            ),

                            pw.SizedBox(height: 8),

                            // Risk matrix + icons
                            pw.Expanded(
                              flex: 2,
                              child: _buildRiskTableAndIconsRow(iconsImage, stateOfSea, calmSea, roughSea, dangerousSea),
                            ),

                            pw.SizedBox(height: 10),

                            // Data table
                            _buildDataTable(tableData, stateOfSea),

                            pw.SizedBox(height: 8),

                            // Weather summary
                            _buildSummary(weatherSummary, warningText),

                            pw.Spacer(),

                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ],
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
  // SECTION BUILDERS
  // ══════════════════════════════════════════════════════════════════════════

  // ── HEADER ────────────────────────────────────────────────────────────────
  // Dark blue banner, bottom-right rounded corner (identical to CAFO)
  static pw.Widget _buildHeader(
      pw.MemoryImage leftLogo, pw.MemoryImage rightLogo) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1A3B85'),
        borderRadius: const pw.BorderRadius.only(
          bottomRight: pw.Radius.circular(80),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Image(leftLogo, width: 50, height: 50),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'GHANA METEOROLOGICAL AGENCY',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
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
                        pw.Text('P. O. Box LG 87, Accra',
                            style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                        pw.Text('Tel: +233-302-543252 / 307010019',
                            style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                        pw.Text('Digital Address: GA-485-3581',
                            style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Email: info@meteo.gov.gh',
                            style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                        pw.Text('Website: www.meteo.gov.gh',
                            style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                        pw.Text('Twitter: @GhanaMet',
                            style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                        pw.Text('Facebook: Ghana Meteorological Agency (GMet)',
                            style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Image(rightLogo, width: 50, height: 50),
        ],
      ),
    );
  }

  // ── TITLE ─────────────────────────────────────────────────────────────────
  static pw.Widget _buildTitle(String validLabel) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            'COASTAL & MARITIME FORECAST FOR GHANA',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text(
            'IMPACT-BASED FORECAST',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Center(
          child: pw.Text(
            validLabel,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ── MAP PANEL + RIGHT SIDEBAR ──────────────────────────────────────────────
  // Map fills the left, sidebar on the right uses the same _sideCell pattern
  // as CAFO's _cafoCell — same flex values, same border styling.
  static pw.Widget _buildMapAndSidebar({
    required pw.MemoryImage mapImage,
    required String issueDate,
    required String issueTime,
    required String validFrom,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Map
          pw.Expanded(
            flex: 4,
            child: pw.Image(mapImage, fit: pw.BoxFit.fill),
          ),

          _verticalDivider(),

          // Sidebar
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _sideCell('Date Issued',       PdfColors.black,                PdfColors.white, flex: 10),
                _sideCell(issueDate,            PdfColors.white,                PdfColors.black, flex: 10),
                _sideCell('Time Issued',        PdfColors.black,                PdfColors.white, flex: 10),
                _sideCell(issueTime,            PdfColors.white,                PdfColors.black, flex: 10),
                _sideCell('Valid From',         PdfColors.black,                PdfColors.white, flex: 10),
                _sideCell(validFrom,            PdfColors.white,                PdfColors.black, flex: 10),
                _sideCell('Nowcasting Risk',   PdfColors.black,                PdfColors.white, flex: 16),
                _sideCell('Take Action',        PdfColors.red,                  PdfColors.white, flex: 10),
                _sideCell('Be aware',           PdfColors.yellow,               PdfColors.black, flex: 10),
                _sideCell('Low risk',           PdfColors.green,    PdfColors.black, flex: 10),
                _sideCell('No risk',            PdfColors.white,                PdfColors.black, flex: 10, hideBorder: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SIDEBAR CELL — mirrors _cafoCell exactly ──────────────────────────────
  static pw.Widget _sideCell(
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
              : const pw.Border(bottom: pw.BorderSide(width: 1.5)),
        ),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            color: textColor,
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ── RISK MATRIX + ICONS ROW — mirrors CAFO _buildRiskTableAndIconsRow ─────
  static pw.Widget _buildRiskTableAndIconsRow(pw.MemoryImage iconsImage,  String stateOfSea,   pw.MemoryImage calmSea, 
    pw.MemoryImage roughSea,
    pw.MemoryImage dangerousSea) {
      pw.MemoryImage seaIcon = calmSea;
 if (stateOfSea.toUpperCase().contains('ROUGH')) {
    seaIcon = roughSea;
    
  } else if (stateOfSea.toUpperCase().contains('DANGEROUS')) {
    seaIcon = dangerousSea;
    
  }


    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Risk matrix (flex 5)
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1.5))),
                  child: pw.Text('Weather Forecast Risk Table',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // Rotated "Likelihood" label
                      pw.Container(
                        width: 25,
                        decoration: const pw.BoxDecoration(
                            border: pw.Border(
                                right: pw.BorderSide(width: 1.5))),
                        child: pw.Center(
                          child: pw.Transform.rotateBox(
                            angle: -1.5708,
                            child: pw.Text('Likelihood',
                                style: pw.TextStyle(
                                    fontSize: 5,
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                        ),
                      ),
                      // Matrix grid
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            pw.Expanded(
                              child: pw.Table(
                                border: const pw.TableBorder(
                                  bottom: pw.BorderSide(width: 1.5),
                                  horizontalInside:
                                      pw.BorderSide(width: 1.5),
                                  verticalInside:
                                      pw.BorderSide(width: 1.5),
                                ),
                                columnWidths: const {
                                  0: pw.FlexColumnWidth(2.5),
                                  1: pw.FlexColumnWidth(1),
                                  2: pw.FlexColumnWidth(1),
                                  3: pw.FlexColumnWidth(1),
                                },
                                children: [
                                  _riskRow('High (> 60%)',
                                      'G', PdfColors.green,
                                      'H', PdfColors.yellow,
                                      'I', PdfColors.red),
                                  _riskRow('Medium (40% - 60%)',
                                      'D', PdfColors.green,
                                      'E', PdfColors.yellow,
                                      'F', PdfColors.red),
                                  _riskRow('Low (< 40%)',
                                      'A', PdfColors.green,
                                      'B', PdfColors.yellow,
                                      'C', PdfColors.red),
                                ],
                              ),
                            ),
                            // Low / Medium / High footer labels
                            pw.Row(children: [
                              pw.Expanded(flex: 25, child: pw.SizedBox()),
                              pw.Expanded(
                                flex: 10,
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                      vertical: 3),
                                  decoration: const pw.BoxDecoration(
                                      border: pw.Border(
                                          left: pw.BorderSide(width: 1.5))),
                                  child: pw.Center(
                                      child: pw.Text('Low',
                                          style: pw.TextStyle(
                                              fontSize: 9,
                                              fontWeight:
                                                  pw.FontWeight.bold))),
                                ),
                              ),
                              pw.Expanded(
                                flex: 10,
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                      vertical: 3),
                                  decoration: const pw.BoxDecoration(
                                      border: pw.Border(
                                          left: pw.BorderSide(width: 1.5))),
                                  child: pw.Center(
                                      child: pw.Text('Medium',
                                          style: pw.TextStyle(
                                              fontSize: 9,
                                              fontWeight:
                                                  pw.FontWeight.bold))),
                                ),
                              ),
                              pw.Expanded(
                                flex: 10,
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                      vertical: 3),
                                  decoration: const pw.BoxDecoration(
                                      border: pw.Border(
                                          left: pw.BorderSide(width: 1.5))),
                                  child: pw.Center(
                                      child: pw.Text('High',
                                          style: pw.TextStyle(
                                              fontSize: 9,
                                              fontWeight:
                                                  pw.FontWeight.bold))),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // "Impact" bottom label
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(width: 1.5))),
                  child: pw.Text('Impact',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),

 

              ],
            ),
          ),
        ),

        pw.SizedBox(width: 8),

        // Weather icons panel (flex 4)
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(vertical: 5),
                decoration:
                    pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
                child: pw.Text('Weather Icons',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 5, horizontal: 5),
                  child: pw.Center(
                      child:
                          pw.Image(iconsImage, fit: pw.BoxFit.contain)),
                ),
              ),

        // pw.SizedBox(height: 2),

              // State of the Sea — right-aligned badge
         pw.Expanded( child:  pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('State of the Sea: ',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.SizedBox(width: 10),
            pw.Image(seaIcon, width: 90, height: 70, fit: pw.BoxFit.contain),
          
          ],
        ),),
            ],
          ),
        ),
      ],
    );
  }
 
 // ── DATA TABLE  (yellow headers, 12h / 24h rows) ──────────────────────────
  static pw.Widget _buildDataTable(
      Map<String, dynamic> tableData, String stateOfSea,  ) {
    // Same yellow as the PDF template
    const PdfColor headerBg = PdfColors.yellow;

    pw.Widget hdrCell(String text) => pw.Container(
          alignment: pw.Alignment.center,
          padding:
              const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
          color: headerBg,
          child: pw.Text(text,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 12)),
        );

    pw.Widget dataCell(String text, {bool isTimeCol = false}) =>
        pw.Container(
          alignment: pw.Alignment.center,
          padding:
              const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
          color: isTimeCol ? headerBg : PdfColors.yellow100,
          child: pw.Text(text,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontWeight: isTimeCol
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
                fontSize: 9,
              )),
        );

    String g(String k, String p) {
      final d = tableData[k] as Map<String, dynamic>?;
      return d?[p]?.toString() ?? '-';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Table(
          border: pw.TableBorder.all(width: 1.0),
          // 👇 THIS IS THE FIX: Forces all cells to stretch vertically to match the tallest cell in the row
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full, 
          columnWidths: const {
            0: pw.FlexColumnWidth(0.7),
            1: pw.FlexColumnWidth(1.3),
            2: pw.FlexColumnWidth(1.0),
            3: pw.FlexColumnWidth(1.2),
            4: pw.FlexColumnWidth(1.2),
            5: pw.FlexColumnWidth(1.2),
            6: pw.FlexColumnWidth(1.4),
          },
          children: [
            pw.TableRow(children: [
              hdrCell('Time'),
              hdrCell('Surface Wind'),
              hdrCell('Visibility'),
              hdrCell('Sea Surface\nTemperature'),
              hdrCell('Sig. Wave\nHeight'),
              hdrCell('Tide'),
              hdrCell('Wave\nCurrent (m/s)'),
            ]),
            pw.TableRow(children: [
              dataCell('12\nhours',                    isTimeCol: true),
              dataCell(g('SURFACE WIND',           '12h')),
              dataCell(g('VISIBILITY',             '12h')),
              dataCell(g('SEA SURFACE TEMPERATURE','12h')),
              dataCell(g('SIG WAVE HEIGHT',        '12h')),
              dataCell(g('TIDAL WAVE',             '12h')),
              dataCell(g('WAVE CURRENT',           '12h')),
            ]),
            pw.TableRow(children: [
              dataCell('24\nhours',                isTimeCol:true ),
              dataCell(g('SURFACE WIND',           '24h')),
              dataCell(g('VISIBILITY',             '24h')),
              dataCell(g('SEA SURFACE TEMPERATURE','24h')),
              dataCell(g('SIG WAVE HEIGHT',        '24h')),
              dataCell(g('TIDAL WAVE',             '24h')),
              dataCell(g('WAVE CURRENT',           '24h')),
            ]),
          ],
        ),

        pw.SizedBox(height: 4),

       
      ],
    );
  }

  // ── WEATHER SUMMARY + RED NB WARNING LINE ────────────────────────────────
  static pw.Widget _buildSummary(String summary, String warning) {
    return
    pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
 padding:const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 7),
  
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(children: [
            pw.TextSpan(
              text: 'WEATHER: ',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.TextSpan(
              text: summary,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.3),
            ),
          ]),
        ),
        if (warning.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text('NB: $warning',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.red,
              )),
        ],
      ],
    ),);
  }

  // ── FOOTER — light-blue pill, mirrors CAFO exactly ────────────────────────
  static pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Container(
        
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: pw.Text(
          'SIGNED: Ghana Meteorological Agency, Marine Forecast Office, Accra',
          style: pw.TextStyle(
            color: PdfColors.black,
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED UTILITIES
  // ══════════════════════════════════════════════════════════════════════════

  static pw.Widget _verticalDivider() =>
      pw.Container(width: 1.5, color: PdfColors.black);

  static pw.TableRow _riskRow(
    String label,
    String c1, PdfColor col1,
    String c2, PdfColor col2,
    String c3, PdfColor col3,
  ) {
    return pw.TableRow(children: [
      pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        alignment: pw.Alignment.centerLeft,
        child: pw.Text(label,
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        color: col1,
        alignment: pw.Alignment.center,
        child: pw.Text(c1,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black)),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        color: col2,
        alignment: pw.Alignment.center,
        child: pw.Text(c2,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black)),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        color: col3,
        alignment: pw.Alignment.center,
        child: pw.Text(c3,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black)),
      ),
    ]);
  }

  static PdfColor _seaStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'rough':
      case 'dangerous':
        return PdfColors.red;
      case 'calm':
        return PdfColor.fromHex('#92D050');
      default:
        return PdfColors.orange;
    }
  }

  /// Format ISO date string → dd/MM/yyyy
  static String? _fmtDate(dynamic raw) {
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  /// Build "VALID AT 1200Z 08/04/2026" for the title subtitle
  static String _fmtValidLabel(dynamic rawDate, String? validTime) {
    try {
      final dt = DateTime.parse(rawDate.toString());
      final d  = dt.day.toString().padLeft(2, '0');
      final m  = dt.month.toString().padLeft(2, '0');
      final y  = dt.year;
      final t  = validTime ?? '1200Z';
      return 'VALID AT $t $d/$m/$y';
    } catch (_) {
      return 'VALID AT ${validTime ?? '1200Z'}';
    }
  }
}