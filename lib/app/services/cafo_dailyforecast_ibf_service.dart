import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CafoDailyForecastIbfPdfService {
  static Future<Uint8List> generateIbfPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // ========================================================================
    // 1. LOAD ASSETS (Logos, Icons & FONTS)
    // ========================================================================
    final gmetLogoBytes = await rootBundle.load('assets/images/gmet_light_logo.png');
    final coatOfArmsBytes = await rootBundle.load('assets/images/ghana_coat_of_arms.png');
    final iconsBytes = await rootBundle.load('assets/images/ibf_icons.png');

    final gmetLogo = pw.MemoryImage(gmetLogoBytes.buffer.asUint8List());
    final coatOfArms = pw.MemoryImage(coatOfArmsBytes.buffer.asUint8List());
    final iconsImage = pw.MemoryImage(iconsBytes.buffer.asUint8List());

    final fontData = await rootBundle.load('assets/fonts/Tinos-Regular.ttf');
    final ttfRegular = pw.Font.ttf(fontData);
    final fontDataBold = await rootBundle.load('assets/fonts/Tinos-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontDataBold);
    
    final theme = pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold);

    // ========================================================================
    // 2. EXTRACT DYNAMIC DATA
    // ========================================================================
    final List<String> headers = data['headers'] ?? ['MORNING', 'AFTERNOON', 'EVENING'];
    final List<String> headerDates = data['headerDates'] ?? ['03/04/2026', '03/04/2026', '04/04/2026'];

    final map1 = data['map1'] != null ? pw.MemoryImage(data['map1']) : null;
    final map2 = data['map2'] != null ? pw.MemoryImage(data['map2']) : null;
    final map3 = data['map3'] != null ? pw.MemoryImage(data['map3']) : null;

    final dateStr = data['date'] ?? '03-APR-26';
    final timeIssued = data['timeIssued'] ?? '2300 UTC';
    final validFrom = data['validFrom'] ?? '00:00';

    final temps = data['temperatures'] ?? [
      {'sector': 'Coast', 'min': '-', 'max': '-'},
      {'sector': 'Forest', 'min': '-', 'max': '-'},
      {'sector': 'Transition', 'min': '-', 'max': '-'},
      {'sector': 'Northern', 'min': '-', 'max': '-'},
    ];

    final summary = data['summary'] ?? 'In general, most areas in southern Ghana are expected to experience sunny weather with periodic cloudiness...';

    // ========================================================================
    // 3. BUILD THE PDF PAGE
    // ========================================================================
   // ========================================================================
    // 3. BUILD THE PDF PAGE
    // ========================================================================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // Keep this zero so borders touch the edges!
        theme: theme,
        build: (pw.Context context) {
          return pw.Row( // <-- Wrap the whole page in a Row
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // THE THICK BLUE LEFT BORDER
              // ==========================================
              pw.Container(
                width: 14, // Thickness of the blue line
                color: PdfColor.fromHex('#1A3B85'),
              ),
              
              // ==========================================
              // MAIN PAGE CONTENT
              // ==========================================
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Header touches the new blue border on the left and the edge on the right
                    _buildHeader(gmetLogo, coatOfArms),
                    
                    // Padding applied to the rest of the document below the header
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 16, right: 24, top: 12, bottom: 24),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            _buildTitle(),
                            pw.SizedBox(height: 12),
                            
                            pw.Expanded(
                              flex: 5,
                              child: _buildMainGridWithMaps(
                                headers: headers,
                                headerDates: headerDates,
                                dateStr: dateStr,
                                timeIssued: timeIssued,
                                validFrom: validFrom,
                                map1: map1,
                                map2: map2,
                                map3: map3,
                              ),
                            ),
                            
                            pw.SizedBox(height: 8),
                            
                            pw.Expanded(
                              flex: 2,
                              child: _buildRiskTableAndIconsRow(iconsImage),
                            ),
                            
                            pw.SizedBox(height: 12),
                            _buildTemperatureTable(temps),
                            pw.SizedBox(height: 8),
                            _buildSummary(summary),
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

  // ========================================================================
  // WIDGET BUILDERS
  // ========================================================================

  static pw.Widget _buildHeader(pw.MemoryImage leftLogo, pw.MemoryImage rightLogo) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1A3B85'),
         borderRadius: const pw.BorderRadius.only(
          bottomRight: pw.Radius.circular(80),
      ),),
      
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
                        pw.Text('P. O. Box LG 87, Accra', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                        pw.Text('Tel: +233-302-543252 / 307010019', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                        pw.Text('Digital Address: GA-485-3581', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Email: info@meteo.gov.gh', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                        pw.Text('Website: www.meteo.gov.gh', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                        pw.Text('Twitter: @GhanaMet', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                        pw.Text('Facebook: Ghana Meteorological Agency', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
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

  static pw.Widget _buildTitle() {
    // REMOVED: The box border. Just bold underlined text now.
    return pw.Center(
      child: pw.Text(
        '24-HOUR IMPACT-BASED FORECAST FOR GHANA',
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          decoration: pw.TextDecoration.underline,
        ),
      ),
    );
  }

  static pw.Widget _buildMainGridWithMaps({
    required List<String> headers,
    required List<String> headerDates,
    required String dateStr,
    required String timeIssued,
    required String validFrom,
    pw.MemoryImage? map1,
    pw.MemoryImage? map2,
    pw.MemoryImage? map3,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildMapColumn('${headers[0]} (${headerDates[0]})', map1),
          _verticalDivider(),
          _buildMapColumn('${headers[1]} (${headerDates[1]})', map2),
          _verticalDivider(),
          _buildMapColumn('${headers[2]} (${headerDates[2]})', map3),
          _verticalDivider(),
          _buildCafoSidebar(dateStr, timeIssued, validFrom),
        ],
      ),
    );
  }

  static pw.Widget _buildMapColumn(String title, pw.MemoryImage? mapImage) {
    return pw.Expanded(
      flex: 3,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            height: 22,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1.5)),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ),
          pw.Expanded(
            // REMOVED: pw.Padding. The image will now touch the exact edges.
            child: mapImage != null
                // CHANGED: From BoxFit.contain to BoxFit.fill
                ? pw.Image(mapImage, fit: pw.BoxFit.fill)
                : pw.Center(
                    child: pw.Text(
                      'Map Capture Required',
                      style: const pw.TextStyle(color: PdfColors.grey, fontSize: 9),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCafoSidebar(String date, String timeIssued, String validFrom) {
    // FIXED: Using precise proportional Flex values for every cell 
    // This perfectly divides the height so Nowcasting Risk doesn't get massive.
    return pw.Expanded(
      flex: 1,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _cafoCell('CAFO', PdfColors.grey400, PdfColors.black, flex: 11),
          _cafoCell('Date', PdfColors.black, PdfColors.white, flex: 10),
          _cafoCell(date, PdfColors.white, PdfColors.black, flex: 10),
          _cafoCell('Time Issued', PdfColors.black, PdfColors.white, flex: 10),
          _cafoCell(timeIssued, PdfColors.white, PdfColors.black, flex: 10),
          _cafoCell('Valid From', PdfColors.black, PdfColors.white, flex: 10),
          _cafoCell(validFrom, PdfColors.white, PdfColors.black, flex: 10),
          _cafoCell('Nowcasting\nRisk', PdfColors.black, PdfColors.white, flex: 16), // Slightly taller for 2 lines
          _cafoCell('Take Action', PdfColors.red, PdfColors.white, flex: 10),
          _cafoCell('Be Prepared', PdfColors.orange, PdfColors.white, flex: 10),
          _cafoCell('Be aware', PdfColors.yellow, PdfColors.black, flex: 10),
          _cafoCell('Low risk', PdfColor.fromHex('#92D050'), PdfColors.black, flex: 10),
          _cafoCell('No risk', PdfColors.white, PdfColors.black, flex: 10, hideBorder: true),
        ],
      ),
    );
  }

  static pw.Widget _cafoCell(String text, PdfColor bgColor, PdfColor textColor, {required int flex, bool hideBorder = false}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: bgColor,
          border: hideBorder ? null : const pw.Border(bottom: pw.BorderSide(width: 1.5)),
        ),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(color: textColor, fontWeight: pw.FontWeight.bold, fontSize: 8),
        ),
      ),
    );
  }

  static pw.Widget _buildRiskTableAndIconsRow(pw.MemoryImage iconsImage) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
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
                    border: pw.Border(bottom: pw.BorderSide(width: 1.5)),
                  ),
                  // REMOVED: Grey background. Matches original white.
                  child: pw.Text('Weather Forecast Risk Matrix', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Container(
                        width: 25,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(right: pw.BorderSide(width: 1.5)),
                        ),
                        child: pw.Center(
                          child: pw.Transform.rotateBox(
                            angle: -1.5708,
                            child: pw.Text('Likelihood', style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold)),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                             pw.Expanded(
                               child: pw.Table(
                                border: const pw.TableBorder(
                                  bottom: pw.BorderSide(width: 1.5),
                                  horizontalInside: pw.BorderSide(width: 1.5),
                                  verticalInside: pw.BorderSide(width: 1.5),
                                ),
                                columnWidths: {
                                  0: const pw.FlexColumnWidth(2.5),
                                  1: const pw.FlexColumnWidth(1),
                                  2: const pw.FlexColumnWidth(1),
                                  3: const pw.FlexColumnWidth(1),
                                },
                                children: [
                                  _riskRow('High (> 60%)', 'G', PdfColors.yellow, 'H', PdfColors.orange, 'I', PdfColors.red),
                                  _riskRow('Medium (40% - 60%)', 'D', PdfColor.fromHex('#92D050'), 'E', PdfColors.yellow, 'F', PdfColors.orange),
                                  _riskRow('Low (< 40%)', 'A', PdfColor.fromHex('#92D050'), 'B', PdfColor.fromHex('#92D050'), 'C', PdfColors.yellow),
                                ],
                              ),
                             ),
                            pw.Row(
                              children: [
                                pw.Expanded(flex: 25, child: pw.SizedBox()),
                                pw.Expanded(flex: 10, child: pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                                  decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 1.5))),
                                  child: pw.Center(child: pw.Text('Low', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                                )),
                                pw.Expanded(flex: 10, child: pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                                  decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 1.5))),
                                  child: pw.Center(child: pw.Text('Medium', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                                )),
                                pw.Expanded(flex: 10, child: pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                                  decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 1.5))),
                                  child: pw.Center(child: pw.Text('High', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                                )),
                              ]
                            )
                          ]
                        )
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(width: 1.5)),
                  ),
                  child: pw.Text('Impact', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            // decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  decoration:  pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
                  // REMOVED: Grey background. Matches original white.
                  child: pw.Text('Weather Icons', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: pw.Center(child: pw.Image(iconsImage, fit: pw.BoxFit.contain)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.TableRow _riskRow(String label, String c1, PdfColor col1, String c2, PdfColor col2, String c3, PdfColor col3) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          color: col1,
          alignment: pw.Alignment.center,
          child: pw.Text(c1, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          color: col2,
          alignment: pw.Alignment.center,
          child: pw.Text(c2, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          color: col3,
          alignment: pw.Alignment.center,
          child: pw.Text(c3, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ),
      ],
    );
  }

  static pw.Widget _buildTemperatureTable(List<dynamic> temps) {
    return pw.Table(
      border: pw.TableBorder.all(width: 1.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration:  pw.BoxDecoration(color: PdfColor.fromHex('#B4C6E7')),
          children: [
            _tempCell('Sector', isHeader: true),
            _tempCell('Minimum Temperature (°C)', isHeader: true),
            _tempCell('Maximum Temperature (°C)', isHeader: true),
          ],
        ),
        ...temps.map((temp) {
          return pw.TableRow(
            children: [
              _tempCell(temp['sector'] ?? '', isBold: true),
              _tempCell(temp['min']?.toString() ?? '-'),
              _tempCell(temp['max']?.toString() ?? '-'),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _tempCell(String text, {bool isHeader = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: pw.Text(
        text,
        textAlign: isHeader ? pw.TextAlign.center : (isBold ? pw.TextAlign.left : pw.TextAlign.center),
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildSummary(String summary) {
    return pw.RichText(
      textAlign: pw.TextAlign.justify,
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: 'SUMMARY: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.TextSpan(text: summary, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.3)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#B4C6E7'),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: pw.Text(
          'SIGNED: Central Analysis and Forecasting Office (CAFO)',
          style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
      ),
    );
  }

  static pw.Widget _verticalDivider() {
    return pw.Container(width: 1.5, color: PdfColors.black);
  }
} 