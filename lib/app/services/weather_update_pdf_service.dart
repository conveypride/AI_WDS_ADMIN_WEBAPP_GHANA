import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class WeatherUpdatePdfService {
  static Future<Uint8List> generatePdf(Map<String, dynamic> data, Uint8List mapImageBytes) async {
    final pdf = pw.Document();

    // 1. LOAD ASSETS
    final gmetLogoBytes = await rootBundle.load('assets/images/gmet_light_logo.png');
    final coatOfArmsBytes = await rootBundle.load('assets/images/ghana_coat_of_arms.png');
    final gmetLogo = pw.MemoryImage(gmetLogoBytes.buffer.asUint8List());
    final coatOfArms = pw.MemoryImage(coatOfArmsBytes.buffer.asUint8List());
    final mapImage = pw.MemoryImage(mapImageBytes);

    // Load Weather Icons
    final rainIcon = pw.MemoryImage((await rootBundle.load('assets/images/rain.png')).buffer.asUint8List());
    final windIcon = pw.MemoryImage((await rootBundle.load('assets/images/wind.png')).buffer.asUint8List());
    final dustIcon = pw.MemoryImage((await rootBundle.load('assets/images/dust.png')).buffer.asUint8List());
    final hailIcon = pw.MemoryImage((await rootBundle.load('assets/images/hail.png')).buffer.asUint8List());

    final fontData = await rootBundle.load('assets/fonts/Tinos-Regular.ttf');
    final ttfRegular = pw.Font.ttf(fontData);
    final fontDataBold = await rootBundle.load('assets/fonts/Tinos-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontDataBold);
    final theme = pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold);

    // 2. EXTRACT DATA
    final validFrom = DateTime.parse(data['validFrom']);
    final issueTime = data['issueTime'] ?? '';
    final summary = data['summary'] ?? '';
    final affectedAreas = data['affectedAreas'] as List<dynamic>? ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeader(gmetLogo, coatOfArms),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _buildTitle(),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // LEFT: MAP
                        pw.Expanded(
                          flex: 3,
                          child: pw.Container(
                            height: 350,
                            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
                            child: pw.Image(mapImage, fit: pw.BoxFit.contain),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        // MIDDLE: DATE/TIME/RISK
                        pw.Expanded(
                          flex: 2,
                          child: pw.Column(
                            children: [
                              _buildInfoBox("Date", DateFormat('dd-MMM-yyyy').format(validFrom).toUpperCase()),
                              _buildInfoBox("Time Issued", "${issueTime}UTC"),
                              _buildInfoBox("Valid From", "${issueTime}UTC"),
                              pw.SizedBox(height: 5),
                              _buildNowcastingRiskLegend(),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        // RIGHT: SUMMARY
                        pw.Expanded(
                          flex: 3,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                alignment: pw.Alignment.center,
                                child: pw.Text("SUMMARY", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(summary, style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                         pw.Expanded(
                          flex: 3,
                          child: _buildRiskMatrix(),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          flex: 5,
                          child: _buildWeatherIconsLegend(
                            rain: rainIcon, 
                            wind: windIcon, 
                            dust: dustIcon, 
                            hail: hailIcon
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    _buildAffectedAreasTable(affectedAreas),
                    pw.SizedBox(height: 20),
                    _buildFooter(),
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

  static pw.Widget _buildHeader(pw.MemoryImage leftLogo, pw.MemoryImage rightLogo) {
    return pw.Container(
      color: PdfColor.fromHex('#1A3B85'),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Image(leftLogo, width: 40, height: 40),
          pw.Column(
            children: [
              pw.Text('GHANA METEOROLOGICAL AGENCY', style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Row(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('P. O. Box LG 87, Accra', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                      pw.Text('Tel: +233-302-543252 / 307010019', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                      pw.Text('Digital Address: GA-485-3581', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                    ],
                  ),
                  pw.SizedBox(width: 40),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Email: info@meteo.gov.gh', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                      pw.Text('Website: www.meteo.gov.gh', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                      pw.Text('Twitter: @GhanaMet', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                      pw.Text('Facebook: Ghana Meteorological Agency (GMet)', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          pw.Image(rightLogo, width: 40, height: 40),
        ],
      ),
    );
  }

  static pw.Widget _buildTitle() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text("IMPACT-BASED WEATHER UPDATE FOR GHANA", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
    );
  }

  static pw.Widget _buildInfoBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          color: PdfColors.black,
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          alignment: pw.Alignment.center,
          child: pw.Text(label, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
          child: pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        ),
        pw.SizedBox(height: 2),
      ],
    );
  }

  static pw.Widget _buildNowcastingRiskLegend() {
    final risks = [
      {'label': 'Take Action', 'color': PdfColors.red},
      {'label': 'Be Prepared', 'color': PdfColors.orange},
      {'label': 'Be aware', 'color': PdfColors.yellow},
      {'label': 'Low risk', 'color': PdfColors.green},
      {'label': 'No risk', 'color': PdfColors.white},
    ];

    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          color: PdfColors.black,
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          alignment: pw.Alignment.center,
          child: pw.Text("Nowcasting Risk", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
        ...risks.map((risk) => pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: risk['color'] as PdfColor,
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.Text(risk['label'] as String, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        )),
      ],
    );
  }

  static pw.Widget _buildRiskMatrix() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      children: [
        _buildMatrixRow(["High (> 60%)", "G", "H", "I"]),
        _buildMatrixRow(["Medium (40% - 60%)", "D", "E", "F"]),
        _buildMatrixRow(["Low (< 40%)", "A", "B", "C"]),
        _buildMatrixRow(["", "Low", "Medium", "High"]),
      ],
    );
  }

  static pw.TableRow _buildMatrixRow(List<String> cells) {
    return pw.TableRow(
      children: cells.map((cell) {
        PdfColor? color;
        if (cell == "A") color = PdfColors.green;
        else if (cell == "B") color = PdfColors.yellow;
        else if (cell == "C") color = PdfColors.yellow;
        else if (cell == "D") color = PdfColors.green;
        else if (cell == "E") color = PdfColors.yellow;
        else if (cell == "F") color = PdfColors.orange;
        else if (cell == "G") color = PdfColors.yellow;
        else if (cell == "H") color = PdfColors.orange;
        else if (cell == "I") color = PdfColors.red;

        return pw.Container(
          height: 18,
          color: color,
          alignment: pw.Alignment.center,
          child: pw.Text(cell, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildWeatherIconsLegend({
    required pw.MemoryImage rain,
    required pw.MemoryImage wind,
    required pw.MemoryImage dust,
    required pw.MemoryImage hail,
  }) {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          color: PdfColor.fromHex('#1A3B85'),
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          alignment: pw.Alignment.center,
          child: pw.Text("Weather Icons", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8)),
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildIconItem("Rain", rain),
            _buildIconItem("Wind", wind),
            _buildIconItem("Dust", dust),
            _buildIconItem("Hail", hail),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildIconItem(String label, pw.MemoryImage image) {
    return pw.Column(
      children: [
        pw.Image(image, width: 25, height: 25),
        pw.SizedBox(height: 2),
        pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildAffectedAreasTable(List<dynamic> areas) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: {
        0: const pw.FlexColumnWidth(5),
        1: const pw.FixedColumnWidth(40),
        2: const pw.FixedColumnWidth(40),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(40),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Areas To Be Affected / Valid Time", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("T+1hr", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("T+2hr", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("T+3hr", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Outlook", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
          ],
        ),
        ...areas.map((area) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("${area['areas']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  pw.Text("(${area['validTime']})", style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            _buildMatrixCell(area['t1']),
            _buildMatrixCell(area['t2']),
            _buildMatrixCell(area['t3']),
            _buildMatrixCell(area['outlook']),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildMatrixCell(String letter) {
    PdfColor? color;
    if (letter == "A") color = PdfColors.green;
    else if (letter == "B") color = PdfColors.yellow;
    else if (letter == "C") color = PdfColors.yellow;
    else if (letter == "D") color = PdfColors.green;
    else if (letter == "E") color = PdfColors.yellow;
    else if (letter == "F") color = PdfColors.orange;
    else if (letter == "G") color = PdfColors.yellow;
    else if (letter == "H") color = PdfColors.orange;
    else if (letter == "I") color = PdfColors.red;

    return pw.Container(
      color: color,
      height: 30,
      alignment: pw.Alignment.center,
      child: pw.Text(letter, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Text("SIGNED: Ghana Meteorological Agency. Central Analysis and Forecasting Office (CAFO)", style: pw.TextStyle(color: PdfColors.blue, fontWeight: pw.FontWeight.bold, fontSize: 10)),
    );
  }
}
