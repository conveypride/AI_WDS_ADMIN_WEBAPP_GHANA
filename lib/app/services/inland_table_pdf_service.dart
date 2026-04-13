import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle, Matrix4;
class InlandTablePdfService {
  static Future<Uint8List> generateForecastPdf(Map<String, dynamic> forecast) async {
    final pdf = pw.Document();

    // 1. Load all required assets
    final coatOfArmsBytes = await rootBundle.load('assets/images/ghana_coat_of_arms.png');
    final gmetLogoBytes = await rootBundle.load('assets/images/gmet_logo.png');
    final twitterBytes = await rootBundle.load('assets/images/twitter_logo.png');
     final facebookBytes = await rootBundle.load('assets/images/facebook_logo.png');

    final coatOfArms = pw.MemoryImage(coatOfArmsBytes.buffer.asUint8List());
    final gmetLogo = pw.MemoryImage(gmetLogoBytes.buffer.asUint8List());
    final twitter = pw.MemoryImage(twitterBytes.buffer.asUint8List());
   final facebook = pw.MemoryImage(facebookBytes.buffer.asUint8List());
    // 2. Set strict Serif Theme to match the official document look
    final ttfRegular = pw.Font.times();
    final ttfBold = pw.Font.timesBold();

    final theme = pw.ThemeData.withFont(
      base: ttfRegular,
      bold: ttfBold,
      italic: pw.Font.timesItalic(),
    );

    // 3. Extract data
    final metadata = forecast['metadata'] ?? {};
    final tableData = forecast['tableData'] as List<dynamic>? ?? [];
    final author = forecast['author'] ?? {}; // Extract author data
    final issueTime = metadata['issueTimeSlot'] ?? '0500';
    final validFrom = metadata['validFrom'] ?? '06:00 UTC'; 
    final forecasterName = author['name'] ?? 'DUTY FORECASTER'; // Grab the name
    final formattedDate = metadata['formattedDate'] ?? '01/04/2026';
    final List<String> headerDates = metadata['headerDates'] ?? [formattedDate, formattedDate, formattedDate];

    final summary = metadata['tableSummary'] ?? metadata['weatherSummary'] ?? '';

    List<String> timeHeaders = _getTimeHeaders(issueTime);

    // 4. FORCE SINGLE PAGE LAYOUT WITH EXPANDED CANVAS
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        // Tightened physical page margins to allow edge-to-edge layout
        margin: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 15), 
        theme: theme,
        build: (pw.Context context) {
          
          return pw.FittedBox(
            fit: pw.BoxFit.contain,
            alignment: pw.Alignment.topCenter,
            child: pw.Container(
              // MAGIC FIX: We set the starting canvas width to 750 (much wider than A4).
              // Because the table is so tall, FittedBox scales it down. 
              // This wider starting point ensures it stretches fully across the left/right space!
              width: 750, 
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _buildTopHeader(coatOfArms, gmetLogo, twitter, facebook, ttfBold),
                  pw.SizedBox(height: 12),
                  
                  _buildTitleSection(validFrom), 
                  pw.SizedBox(height: 12),
                  
                  _buildSummaryBox(summary),
                  pw.SizedBox(height: 12),
                  
                  _buildInlandForecastTable(tableData, timeHeaders, headerDates),
                  
                  pw.SizedBox(height: 12),
                  _buildLegend(),
                  
               pw.SizedBox(height: 40),
                  _buildFooter(formattedDate, forecasterName),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

   static pw.Widget _buildTopHeader(
    pw.MemoryImage coatOfArms, 
    pw.MemoryImage gmetLogo,
    pw.MemoryImage twitter,
    pw.MemoryImage facebook,
    pw.Font boldFont,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Image(coatOfArms, width: 60, height: 60, fit: pw.BoxFit.contain),
              
              ],
            ),
           pw.Expanded(
  child: pw.Center(
    child: pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Transform(
        transform: Matrix4.diagonal3Values(1.0, 1.6, 1.0),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'GHANA METEOROLOGICAL AGENCY',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: boldFont, 
            fontSize: 24,  
            color: PdfColor.fromHex('#000080'),
          ),
        ),
      ),
    ),
  ),
),
            pw.Image(gmetLogo, width: 70, height: 70, fit: pw.BoxFit.contain, alignment: pw.Alignment.topRight),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('P.O Box LG 87, Accra', style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 2),
                pw.Text('Tel/Fax: +233-302-543252', style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 2),
                pw.Text('Tel: +233-0302-776171 ext. 3267/2534/3244', style: pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('E-mail: kiamo@meteo.gov.gh', style: pw.TextStyle(fontSize: 12)),
                pw.Text('Website: www.meteo.gov.gh', style: pw.TextStyle(fontSize: 12, color: PdfColors.blue, decoration: pw.TextDecoration.underline)),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Image(twitter, width: 10, height: 10),
                    pw.SizedBox(width: 4),
                    pw.Text('@GhanaMet', style: pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Image(facebook, width: 10, height: 10),
                    pw.SizedBox(width: 4),
                    pw.Text('GMet Forecast Office', style: pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // static pw.Widget _buildTopHeader(
  //   pw.MemoryImage coatOfArms,
  //   pw.MemoryImage gmetLogo,
  //   pw.Font boldFont,
  // ) {
  //   return pw.Row(
  //     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  //     crossAxisAlignment: pw.CrossAxisAlignment.center,
  //     children: [
  //       // Left: Coat of Arms
  //       pw.Image(coatOfArms, width: 60, height: 60, fit: pw.BoxFit.contain),
        
  //       // Middle: Text details
  //       pw.Expanded(
  //         child: pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.center,
  //           children: [
  //             pw.Text(
  //               'GHANA METEOROLOGICAL AGENCY',
  //               textAlign: pw.TextAlign.center,
  //               style: pw.TextStyle(
  //                 font: boldFont, 
  //                 fontSize: 14,  
  //                 color: PdfColor.fromHex('#000080'), // Navy Blue
  //               ),
  //             ),
  //             pw.SizedBox(height: 4),
  //             pw.Text('P.O. Box LG 87, Accra | Tel/Fax: +233-302-543252', style: const pw.TextStyle(fontSize: 9)),
  //             pw.Text('Tel: +233-0302-776171 ext. 3267/2534/3244', style: const pw.TextStyle(fontSize: 9)),
  //             pw.Text('Digital Address: GA-485-3581', style: const pw.TextStyle(fontSize: 9)),
  //             pw.Text('E-mail: kiamo@meteo.gov.gh | Website: www.meteo.gov.gh', style: const pw.TextStyle(fontSize: 9)),
  //           ],
  //         ),
  //       ),

  //       // Right: GMet Logo
  //       pw.Image(gmetLogo, width: 60, height: 60, fit: pw.BoxFit.contain),
  //     ],
  //   );
  // }

  // --- 2. TITLE & SUMMARY ---
  static pw.Widget _buildTitleSection(String validFrom) {
    return pw.Column(
      children: [
        pw.Text(
          '24-HOUR INLAND WATER FORECAST FOR GHANA',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'VALID FROM $validFrom',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryBox(String summary) {
    return pw.RichText(
      textAlign: pw.TextAlign.justify,
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: 'SUMMARY: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.TextSpan(text: summary, style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.2)),
        ],
      ),
    );
  }

  // --- 3. EXACT PDF TABLE MATCH (SEPARATED WIND) ---
  static pw.Widget _buildInlandForecastTable(
    List<dynamic> tableData,
    List<String> timeHeaders,
    List<String> headerDates,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(width: 1.0, color: PdfColors.black),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2), // DISTRICTS
        1: const pw.FlexColumnWidth(1.0), // SLOT 1
        2: const pw.FlexColumnWidth(1.0), // SLOT 2
        3: const pw.FlexColumnWidth(1.0), // SLOT 3
        4: const pw.FlexColumnWidth(1.2), // WIND DIRECTION
      },
      children: [
        // ── HEADER ROW ──
        pw.TableRow(
          children: [
            _headerCell('DISTRICTS\n'),
            _headerCell('${timeHeaders[0]}\n(${headerDates[0]})'),
            _headerCell('${timeHeaders[1]}\n(${headerDates[1]})'),
            _headerCell('${timeHeaders[2]}\n(${headerDates[2]})'),
            _headerCell('WIND DIRECTION/\nSPEED\n') // Placed strictly at the end
          ],
        ),
        
        // ── DATA ROWS ──
        ...tableData.map((city) {
          String prob1 = city['slot1_prob'] != '0' && city['slot1_prob'] != '' ? ' (${city['slot1_prob']}%)' : '';
          String prob2 = city['slot2_prob'] != '0' && city['slot2_prob'] != '' ? ' (${city['slot2_prob']}%)' : '';
          String prob3 = city['slot3_prob'] != '0' && city['slot3_prob'] != '' ? ' (${city['slot3_prob']}%)' : '';
          
          // Safely grab wind info without appending newlines
          String windInfo = city['wind_direction']?.toString().trim() ?? '';
          
          return pw.TableRow(
            children: [
              // District Column (Left Aligned, Bold)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(city['name']?.toString().toUpperCase() ?? '', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ),
              // Data Column 1
              _dataCell('${city['slot1_weather'] ?? ''}$prob1'), 
              // Data Column 2
              _dataCell('${city['slot2_weather'] ?? ''}$prob2'), 
              // Data Column 3
              _dataCell('${city['slot3_weather'] ?? ''}$prob3'),
              // Wind Column (Far Right)
              _dataCell(windInfo),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text, 
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)
      ),
    );
  }

  static pw.Widget _dataCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text, 
        style: const pw.TextStyle(fontSize: 9), 
        textAlign: pw.TextAlign.center
      ),
    );
  }

  // --- 4. LEGEND & FOOTER ---
  static pw.Widget _buildLegend() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Column 1
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _legendItem("*TSRA", "THUNDERSTORM WITH RAIN"),
              _legendItem("*P'CLOUDY", "PARTLY CLOUDY"),
              _legendItem("*SL'T", "SLIGHT"),
              _legendItem("*LGT", "LIGHT"),
            ],
          ),
        ),
        // Column 2
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _legendItem("*B'KS", "BREAKS"),
              _legendItem("*M'CLOUDY", "MOSTLY CLOUDY"),
              _legendItem("*INT.", "INTERVAL"),
              _legendItem("*F'DRY", "FAIRLY DRY"),
            ],
          ),
        ),
        // Column 3
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _legendItem("*P'SUNNY", "PARTLY SUNNY"),
              _legendItem("*P'RDS", "PERIODS"),
              _legendItem("*V' CLOUDY", "VARIABLY CLOUDY"),
              _legendItem("*S'HAZY", "SLIGHTLY HAZY"),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _legendItem(String abbr, String full) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 50, child: pw.Text(abbr, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
          pw.Text(full, style: const pw.TextStyle(fontSize: 10)),
        ]
      )
    );
  }

  
  static pw.Widget _buildFooter(String date, String forecasterName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('DATE: $date', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Text('SIGNED', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text(forecasterName.toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('(DUTY FORECASTER)', style: pw.TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 1, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('GHANA METEOROLOGICAL AGENCY, FORECAST DIVISION', style: pw.TextStyle(fontSize: 8)),
            pw.Text('MAIN FORECAST OFFICE, ACCRA', style: pw.TextStyle(fontSize: 8)),
          ],
        ),
      ],
    );
  }


  // --- HELPERS ---
  static List<String> _getTimeHeaders(String issueTime) {
    switch (issueTime) {
      case '0500': return ['MORNING', 'AFTERNOON', 'EVENING'];
      case '1100': return ['AFTERNOON', 'EVENING', 'NIGHT'];
      case '1700': return ['EVENING', 'NIGHT', 'MORNING'];
      case '2300': return ['NIGHT', 'MORNING', 'AFTERNOON'];
      default: return ['MORNING', 'AFTERNOON', 'EVENING'];
    }
  }

  static String _getTimeDisplay(String issueTime) {
    switch (issueTime) {
      case '0500': return '6:00 AM';
      case '1100': return '12:00 PM';
      case '1700': return '6:00 PM';
      case '2300': return '12:00 AM';
      default: return '6:00 AM';
    }
  }
}