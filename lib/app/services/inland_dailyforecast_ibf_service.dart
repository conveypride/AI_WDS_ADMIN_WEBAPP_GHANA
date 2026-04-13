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
  // EXACT MATCH ACTION: If the blue in your image is slightly lighter/darker, change '#000080'
  static final _navy   = PdfColor.fromHex('#000080'); 
  static final _amber  = PdfColor.fromHex('#FFC000'); 
  static final _cream  = PdfColor.fromHex('#FFF2CC'); 
  static final _green  = PdfColor.fromHex('#00B050');
  static final _yellow = PdfColor.fromHex('#FFFF00');
  static final _red    = PdfColor.fromHex('#FF0000');

  // ──────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> generateIbfPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // 1. Assets
    final coatBytes    = await rootBundle.load('assets/images/ghana_coat_of_arms.png');
    final gmetBytes    = await rootBundle.load('assets/images/gmet_logo.png');
    final twitterBytes = await rootBundle.load('assets/images/twitter_logo.png');
    final fbBytes      = await rootBundle.load('assets/images/facebook_logo.png');

    // Weather-icon assets
    final rainBytes = await rootBundle.load('assets/images/rain.png');
    final windBytes = await rootBundle.load('assets/images/wind.png');
    final dustBytes = await rootBundle.load('assets/images/dust.png');
    final hailBytes = await rootBundle.load('assets/images/hail.png');

    final coat     = pw.MemoryImage(coatBytes.buffer.asUint8List());
    final gmet     = pw.MemoryImage(gmetBytes.buffer.asUint8List());
    final twitter  = pw.MemoryImage(twitterBytes.buffer.asUint8List());
    final facebook = pw.MemoryImage(fbBytes.buffer.asUint8List());
    final rainImg  = pw.MemoryImage(rainBytes.buffer.asUint8List());
    final windImg  = pw.MemoryImage(windBytes.buffer.asUint8List());
    final dustImg  = pw.MemoryImage(dustBytes.buffer.asUint8List());
    final hailImg  = pw.MemoryImage(hailBytes.buffer.asUint8List());

    // 2. Theme
    final theme = pw.ThemeData.withFont(
      base:   pw.Font.times(),
      bold:   pw.Font.timesBold(),
      italic: pw.Font.timesItalic(),
    );

    // 3. Payload
    final String date           = data['formattedDate']  ?? '';
    final String timeIssued     = data['timeIssued']     ?? '';
    final String validFrom      = data['validFrom']      ?? '';
    final String summary        = data['summary']        ?? '';
    final String forecasterName = data['forecasterName'] ?? 'DUTY FORECASTER';
    final String nowcastingRisk = data['nowcastingRisk'] ?? '';

    final List<String> headers     = data['headers']     ?? ['EVENING',     'MORNING',     'AFTERNOON'];
    final List<String> headerDates = data['headerDates'] ?? [date, date, date];

    final Uint8List? map1 = data['map1']; 
    final Uint8List? map2 = data['map2']; 
    final Uint8List? map3 = data['map3']; 

    final Map<String, dynamic> gc = (data['metadata'] ?? {})['generalConditions'] ?? {};

    // 4. Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        theme: theme,
        build: (pw.Context ctx) {
          return pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            alignment: pw.Alignment.topCenter,
            child: pw.SizedBox(
              width: PdfPageFormat.a4.width - 36,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // ── HEADER ──────────────────────────────────────────────
                  // Header touches the new blue border on the left and the edge on the right
                    _buildHeader(gmet, coat),
                  pw.Divider(thickness: 1.5, color: _navy), // EXACT MATCH ACTION: Made divider Navy Blue, change to PdfColors.black if image is black
                  pw.SizedBox(height: 4),

                  // ── TITLE ───────────────────────────────────────────────
                  pw.Center(
                    child: pw.Text(
                      'INLAND WATER IMPACT-BASED FORECAST',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline,
                        color: _navy, // EXACT MATCH ACTION: Made title Navy Blue to match standard formats. Change if needed.
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // ── WEATHER SUMMARY ──────────────────────────────────────
                  pw.Text(
                    'WEATHER SUMMARY',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    summary,
                    style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.4),
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 10),

                  // ── THREE MAP COLUMNS ────────────────────────────────────
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _mapColumn(headers[0], headerDates[0], map1),
                      pw.SizedBox(width: 6),
                      _mapColumn(headers[1], headerDates[1], map2),
                      pw.SizedBox(width: 6),
                      _mapColumn(headers[2], headerDates[2], map3),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // ── BOTTOM SECTION ──────────────────────────────────────
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 38,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _metaTable(date, timeIssued, validFrom, forecasterName),
                            pw.SizedBox(height: 8),
                            _nowcastingLegend(nowcastingRisk),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        flex: 62,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            _weatherIconsRow(rainImg, windImg, dustImg, hailImg),
                            pw.SizedBox(height: 6),
                            _riskMatrix(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // ── GENERAL CONDITIONS TABLE (bottom) ────────────────────
                  _generalConditionsTable(gc),
                ],
              ),
            ),
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


  // ══════════════════════════════════════════════════════════════════════════
  //  MAP COLUMN
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _mapColumn(String header, String date, Uint8List? bytes) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(
            '$header\n($date)',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _navy), 
          ),
          pw.SizedBox(height: 3),
          pw.Container(
            height: 155,
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
            child: bytes != null
                ? pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover)
                : pw.Center(child: pw.Text('No Map Data', style: const pw.TextStyle(fontSize: 7))),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  META TABLE 
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _metaTable(
      String date, String time, String validFrom, String forecaster) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1.4),
      },
      children: [
        _mRow('Date',           date),
        _mRow('Time Issued',    time),
        _mRow('Valid From',     validFrom),
        _mRow('Duty Forecaster', forecaster.toUpperCase()),
      ],
    );
  }

  static pw.TableRow _mRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Container(
        color: _amber,
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6), // EXACT MATCH ACTION: Adjusted padding
        child: pw.Text(label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6), // EXACT MATCH ACTION: Adjusted padding
        child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  NOWCASTING RISK LEGEND
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _nowcastingLegend(String activeRisk) {
    final rows = [
      (_red,    'Take Action'),
      (_amber,  'Be aware'),
      (_yellow, 'Low risk'),
      (_green,  'No risk'),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          color: PdfColors.grey300,
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          child: pw.Text('Nowcasting Risk',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        ),
        ...rows.map((r) {
          final isActive = activeRisk.toLowerCase() == r.$2.toLowerCase();
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: r.$1,
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            child: pw.Row(
              children: [
                if (isActive)
                  pw.Text('► ',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 8)),
                pw.Text(
                  r.$2,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                    color: (r.$1 == _red) ? PdfColors.white : PdfColors.black,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  WEATHER ICONS LEGEND ROW 
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _weatherIconsRow(
    pw.MemoryImage rain,
    pw.MemoryImage wind,
    pw.MemoryImage dust,
    pw.MemoryImage hail,
  ) {
    final icons = [
      (rain, 'Rain'),
      (wind, 'Wind'),
      (dust, 'Dust'),
      (hail, 'Hail'),
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
        color: PdfColors.grey200,
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Weather Icons',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: icons.map((ic) {
              return pw.Column(
                children: [
                  pw.Image(ic.$1, width: 24, height: 24),
                  pw.SizedBox(height: 2),
                  pw.Text(ic.$2, style: const pw.TextStyle(fontSize: 7)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  RISK MATRIX
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _riskMatrix() {
    final matrix = [
      [('G', '#FFFF00'), ('H', '#FFC000'), ('I', '#FF0000')],
      [('D', '#00B050'), ('E', '#FFFF00'), ('F', '#FF0000')],
      [('A', '#00B050'), ('B', '#00B050'), ('C', '#FFC000')],
    ];

    final likelihoodLabels = ['>60%', '40-60%', '<40%'];
    final impactLabels     = ['Low', 'Medium', 'High'];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('Weather Forecast Risk Table',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.SizedBox(height: 4),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Transform.rotate(
              angle: -3.14159 / 2, 
              child: pw.SizedBox(
                width: 60,
                child: pw.Center(
                  child: pw.Text('Likelihood',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 8)),
                ),
              ),
            ),
            pw.SizedBox(width: 2),
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Table(
                    border: pw.TableBorder.all(
                        color: PdfColors.black, width: 0.8),
                    children: [
                      pw.TableRow(
                        decoration:
                            pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _mxCell('', PdfColors.grey300, bold: true),
                          ...impactLabels.map(
                              (l) => _mxCell(l, PdfColors.grey300, bold: true)),
                        ],
                      ),
                      ...List.generate(3, (ri) {
                        return pw.TableRow(
                          children: [
                            _mxCell(likelihoodLabels[ri], PdfColors.grey300,
                                bold: true),
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
                    child: pw.Text('Impact',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _mxCell(String text, PdfColor bg,
      {bool bold = false, PdfColor textColor = PdfColors.black}) {
    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 7,
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
    final wind = gc['SURFACE WIND'] ?? {};
    final vis  = gc['VISIBILITY']   ?? {};
    final temp = gc['TEMPERATURE']  ?? {};

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
      // EXACT MATCH ACTION: Tweak these flex widths if columns in your image look wider/narrower
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Time 
        1: const pw.FlexColumnWidth(3), // Surface Wind (Usually widest)
        2: const pw.FlexColumnWidth(2.5), // Visibility
        3: const pw.FlexColumnWidth(2.5), // Temperature
      },
      children: [
        // Header row – amber background
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _amber),
          children: [
            _gcCell('Time',         bold: true, align: pw.TextAlign.center),
            _gcCell('Surface Wind', bold: true, align: pw.TextAlign.center),
            _gcCell('Visibility',   bold: true, align: pw.TextAlign.center),
            _gcCell('Temperature',  bold: true, align: pw.TextAlign.center),
          ],
        ),
        // 12 hours row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _cream),
          children: [
            _gcCell('12 hours', bold: true, align: pw.TextAlign.center),
            _gcCell(wind['12h']?.toString() ?? '', align: pw.TextAlign.center),
            _gcCell(vis['12h']?.toString()  ?? '', align: pw.TextAlign.center),
            _gcCell(temp['12h']?.toString() ?? '', align: pw.TextAlign.center),
          ],
        ),
        // 24 hours row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _cream),
          children: [
            _gcCell('24 hours', bold: true, align: pw.TextAlign.center),
            _gcCell(wind['24h']?.toString() ?? '', align: pw.TextAlign.center),
            _gcCell(vis['24h']?.toString()  ?? '', align: pw.TextAlign.center),
            _gcCell(temp['24h']?.toString() ?? '', align: pw.TextAlign.center),
          ],
        ),
      ],
    );
  }

  // EXACT MATCH ACTION: Adjust horizontal/vertical padding and fontSize below if the text feels too cramped or too small
  static pw.Widget _gcCell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0), // Added breathing room
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: align, 
        style: pw.TextStyle(
          fontSize: 9, // Slightly increased font size for readability
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }
}