import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle, Matrix4;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CAFOTablePdfService {
  static Future<Uint8List> generateForecastPdf(Map<String, dynamic> forecast) async {
    final pdf = pw.Document();

    // 1. Load all required assets
    final coatOfArmsBytes = await rootBundle.load('assets/images/ghana_coat_of_arms.png');
    final wmoLogoBytes = await rootBundle.load('assets/images/wmo_logo.png');
    final gmetLogoBytes = await rootBundle.load('assets/images/gmet_logo.png');
    final twitterBytes = await rootBundle.load('assets/images/twitter_logo.png');
    final facebookBytes = await rootBundle.load('assets/images/facebook_logo.png');

    final coatOfArms = pw.MemoryImage(coatOfArmsBytes.buffer.asUint8List());
    final wmoLogo = pw.MemoryImage(wmoLogoBytes.buffer.asUint8List());
    final gmetLogo = pw.MemoryImage(gmetLogoBytes.buffer.asUint8List());
    final twitter = pw.MemoryImage(twitterBytes.buffer.asUint8List());
    final facebook = pw.MemoryImage(facebookBytes.buffer.asUint8List());

    // 2. Set strict Serif Theme to match the official Word document look
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
    final author = forecast['author'] ?? {};
    
    final issueTime = metadata['issueTimeSlot'] ?? '0500';
    // Use the newly injected formatted date for the main title
    final formattedDate = metadata['formattedDate'] ?? '01/04/2026';
    // Use the newly injected array for the 3 table columns
    final List<String> headerDates = metadata['headerDates'] ?? [formattedDate, formattedDate, formattedDate];

    final summary = metadata['tableSummary'] ?? metadata['weatherSummary'] ?? '';
    final seaStateText = metadata['seastate'] ?? 'CALM (1)';

    List<String> timeHeaders = _getTimeHeaders(issueTime);
    List<String> utcHeaders = _getUTCHeaders(issueTime);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 20), 
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildTopHeader(coatOfArms, wmoLogo, gmetLogo, twitter, facebook, ttfBold),
              pw.SizedBox(height: 8),
              _buildDivider(),
              pw.SizedBox(height: 6),
              _buildTitleSection(formattedDate, issueTime), // Uses today's date
              pw.SizedBox(height: 6),
              _buildSummaryBox(summary),
              pw.SizedBox(height: 8),
              // Pass the array of headerDates instead of a single date
              _buildPerfectForecastTable(tableData, timeHeaders, utcHeaders, headerDates),
              pw.SizedBox(height: 6),
              _buildSeaState(seaStateText),
              pw.SizedBox(height: 4),
              _buildLegend(issueTime),
              pw.Spacer(), 
              _buildFooter(formattedDate, author['name'] ?? 'DUTY FORECASTER'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // --- 1. HEADER & CONTACT INFO ---
  static pw.Widget _buildTopHeader(
    pw.MemoryImage coatOfArms,
    pw.MemoryImage wmoLogo,
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
                pw.Image(coatOfArms, width: 40, height: 40, fit: pw.BoxFit.contain),
                pw.SizedBox(width: 8),
                pw.Column(
                  children: [
                    pw.Image(wmoLogo, width: 35, height: 35, fit: pw.BoxFit.contain),
                    pw.SizedBox(height: 2),
                    pw.Text('MyWorldWeather', style: pw.TextStyle(fontSize: 6)),
                  ],
                ),
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
            fontSize: 20,  
            color: PdfColor.fromHex('#000080'),
          ),
        ),
      ),
    ),
  ),
),
            pw.Image(gmetLogo, width: 50, height: 50, fit: pw.BoxFit.contain, alignment: pw.Alignment.topRight),
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
                pw.Text('P.O Box LG 87, Accra', style: pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 2),
                pw.Text('Tel/Fax: +233-302-543252', style: pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 2),
                pw.Text('Tel: +233-0302-776171 ext. 3267/2534/3244', style: pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('E-mail: kiamo@meteo.gov.gh', style: pw.TextStyle(fontSize: 8)),
                pw.Text('Website: www.meteo.gov.gh', style: pw.TextStyle(fontSize: 8, color: PdfColors.blue, decoration: pw.TextDecoration.underline)),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Image(twitter, width: 10, height: 10),
                    pw.SizedBox(width: 4),
                    pw.Text('@GhanaMet', style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Image(facebook, width: 10, height: 10),
                    pw.SizedBox(width: 4),
                    pw.Text('GMet Forecast Office', style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDivider() {
    return pw.Container(height: 1.0, color: PdfColors.black);
  }

  // --- 2. TITLE & SUMMARY ---
  static pw.Widget _buildTitleSection(String date, String issueTime) {
    String timeDisplay = _getTimeDisplay(issueTime);
    return pw.Column(
      children: [
        pw.Text(
          '24-HOUR FORECAST FOR GHANA',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'VALID FROM $timeDisplay ($date)',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryBox(String summary) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: 'SUMMARY: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.TextSpan(text: summary, style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // --- 3. FIXED TABLE LAYOUT ---
  static pw.Widget _buildPerfectForecastTable(
    List<dynamic> tableData,
    List<String> timeHeaders,
    List<String> utcHeaders,
    List<String> headerDates, // Accepts the array of dates
  ) {
    final columnWidths = {
      0: const pw.FixedColumnWidth(80), 
      1: const pw.FlexColumnWidth(2),   
      2: const pw.FlexColumnWidth(1),   
      3: const pw.FlexColumnWidth(2),   
      4: const pw.FlexColumnWidth(1),   
      5: const pw.FlexColumnWidth(2),   
      6: const pw.FlexColumnWidth(1),   
    };

    const double headerHeight = 32.0;
    const double halfHeaderHeight = 16.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // FIXED HEADER
        pw.Container(
          height: headerHeight,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: const pw.BorderSide(width: 0.5),
              left: const pw.BorderSide(width: 0.5),
              right: const pw.BorderSide(width: 0.5),
            ),
          ),
          child: pw.Row(
            children: [
              // CITIES COLUMN
              pw.Container(
                width: 80,
                height: headerHeight,
                alignment: pw.Alignment.center,
                child: pw.Text('CITIES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              ),
              
              // WEATHER BRIEF BLOCK
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border(left: const pw.BorderSide(width: 0.5))),
                  child: pw.Column(
                    children: [
                      // Top Half: WEATHER BRIEF
                      pw.Container(
                        height: halfHeaderHeight,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(border: pw.Border(bottom: const pw.BorderSide(width: 0.5))),
                        child: pw.Text('WEATHER BRIEF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      // Bottom Half: Time Slots with specific dates mapped exactly
                      pw.Container(
                        height: halfHeaderHeight,
                        child: pw.Row(
                          children: [
                            _buildSubHeaderCell(timeHeaders[0], headerDates[0], flex: 2, borderRight: true),
                            _buildSubHeaderCell('TEMP °C', utcHeaders[0], flex: 1, borderRight: true),
                            _buildSubHeaderCell(timeHeaders[1], headerDates[1], flex: 2, borderRight: true),
                            _buildSubHeaderCell('TEMP °C', utcHeaders[1], flex: 1, borderRight: true),
                            _buildSubHeaderCell(timeHeaders[2], headerDates[2], flex: 2, borderRight: true),
                            _buildSubHeaderCell('TEMP °C', utcHeaders[2], flex: 1, borderRight: false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // STANDARD DATA TABLE
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: columnWidths,
          children: tableData.map((city) {
            String slotprob1 = city['slot1_prob'] != '0' && city['slot1_prob'] != '' ? ' ${city['slot1_prob']}%' : '';
            String slotprob2 = city['slot2_prob'] != '0' && city['slot2_prob'] != '' ? ' ${city['slot2_prob']}%' : '';
            String slotprob3 = city['slot3_prob'] != '0' && city['slot3_prob'] != '' ? ' ${city['slot3_prob']}%' : '';
            
            return pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: pw.Text(city['name']?.toString().toUpperCase() ?? '', style: pw.TextStyle(fontSize: 8)),
                ),
                _buildDataCell('${city['slot1_weather'] ?? ''}$slotprob1'),
                _buildDataCell(city['slot1_temp']?.toString() ?? ''),
                _buildDataCell('${city['slot2_weather'] ?? ''}$slotprob2'),
                _buildDataCell(city['slot2_temp']?.toString() ?? ''),
                _buildDataCell('${city['slot3_weather'] ?? ''}$slotprob3'),
                _buildDataCell(city['slot3_temp']?.toString() ?? ''),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildSubHeaderCell(String title, String subtitle, {required int flex, required bool borderRight}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        decoration: pw.BoxDecoration(border: borderRight ? pw.Border(right: const pw.BorderSide(width: 0.5)) : null),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
            pw.Text('($subtitle)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildDataCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      alignment: pw.Alignment.center,
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
    );
  }

  // --- 4. SEA STATE ---
  static pw.Widget _buildSeaState(String seaStateText) {
    PdfColor bgColor = PdfColors.green;
    String lowerText = seaStateText.toLowerCase();
    if (lowerText.contains('rough') || lowerText.contains('warning')) {
      bgColor = PdfColors.yellow;
    } else if (lowerText.contains('dangerous') || lowerText.contains('severe')) {
      bgColor = PdfColors.red;
    }

    return pw.Row(
      children: [
        pw.Text('The state of the sea is ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.Container(
          color: bgColor,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: pw.Text(
            seaStateText,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: bgColor == PdfColors.red ? PdfColors.white : PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  // --- 5. LEGEND & FOOTER ---
  static pw.Widget _buildLegend(String issueTime) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('* %: PROBABILITY OF OCCURRENCE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('*INT- INTERVALS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('* P\'RDS- PERIODS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('* M\'CLOUDY- MOSTLY CLOUDY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('* ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('ISSUED AT $issueTime UTC', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('* P\'CLOUDY- PARTLY CLOUDY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('*TSRA- THUNDERSTORMS OR RAIN', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('* V\'RY - VERY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('* SLT\'LY - SLIGHTLY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter( String date, String forecasterName) {
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

  static List<String> _getUTCHeaders(String issueTime) {
    switch (issueTime) {
      case '0500': return ['0600UTC', '1200UTC', '1800UTC'];
      case '1100': return ['1200UTC', '1800UTC', '0000UTC'];
      case '1700': return ['1800UTC', '0000UTC', '0600UTC'];
      case '2300': return ['0000UTC', '0600UTC', '1200UTC'];
      default: return ['0600UTC', '1200UTC', '1800UTC'];
    }
  }

  static String _getTimeDisplay(String issueTime) {
    switch (issueTime) {
      case '0500': return '6AM';
      case '1100': return '12PM';
      case '1700': return '6PM';
      case '2300': return '12AM';
      default: return '6AM';
    }
  }
}

// import 'dart:typed_data';
// import 'package:flutter/services.dart' show rootBundle, Matrix4;
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;

// class GMetPdfService {
//   static Future<Uint8List> generateForecastPdf(Map<String, dynamic> forecast) async {
//     final pdf = pw.Document();

//     // 1. Load all required assets
//     final coatOfArmsBytes = await rootBundle.load('assets/images/ghana_coat_of_arms.png');
//     final wmoLogoBytes = await rootBundle.load('assets/images/wmo_logo.png');
//     final gmetLogoBytes = await rootBundle.load('assets/images/gmet_logo.png');
//     final twitterBytes = await rootBundle.load('assets/images/twitter_logo.png');
//     final facebookBytes = await rootBundle.load('assets/images/facebook_logo.png');

//     final coatOfArms = pw.MemoryImage(coatOfArmsBytes.buffer.asUint8List());
//     final wmoLogo = pw.MemoryImage(wmoLogoBytes.buffer.asUint8List());
//     final gmetLogo = pw.MemoryImage(gmetLogoBytes.buffer.asUint8List());
//     final twitter = pw.MemoryImage(twitterBytes.buffer.asUint8List());
//     final facebook = pw.MemoryImage(facebookBytes.buffer.asUint8List());

//     // 2. Set strict Serif Theme to match the official Word document look
//     final ttfRegular = pw.Font.times();
//     final ttfBold = pw.Font.timesBold();

//     final theme = pw.ThemeData.withFont(
//       base: ttfRegular,
//       bold: ttfBold,
//       italic: pw.Font.timesItalic(),
//     );

//     // 3. Extract data
//     final metadata = forecast['metadata'] ?? {};
//     final tableData = forecast['tableData'] as List<dynamic>? ?? [];
//     final author = forecast['author'] ?? {};
    
//     final issueTime = metadata['issueTimeSlot'] ?? '0500';
//     final date = metadata['date'] ?? '01/04/2026';
//     final summary = metadata['tableSummary'] ?? metadata['weatherSummary'] ?? '';
//     final seaStateText = metadata['seastate'] ?? 'CALM (1)';

//     List<String> timeHeaders = _getTimeHeaders(issueTime);
//     List<String> utcHeaders = _getUTCHeaders(issueTime);

//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         // Reduced margins slightly to ensure a long 24-city table fits on one page
//         margin: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 20), 
//         theme: theme,
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//             children: [
//               _buildTopHeader(coatOfArms, wmoLogo, gmetLogo, twitter, facebook, ttfBold),
//               pw.SizedBox(height: 8),
//               _buildDivider(),
//               pw.SizedBox(height: 6),
//               _buildTitleSection(date, issueTime),
//               pw.SizedBox(height: 6),
//               _buildSummaryBox(summary),
//               pw.SizedBox(height: 8),
//               // The fixed table
//               _buildPerfectForecastTable(tableData, timeHeaders, utcHeaders, date),
//               pw.SizedBox(height: 6),
//               _buildSeaState(seaStateText),
//               pw.SizedBox(height: 4),
//               _buildLegend(issueTime),
//               pw.Spacer(), // This will now work safely because the table dimensions are bounded
//               _buildFooter( date, author['name'] ?? 'DUTY FORECASTER'),
//             ],
//           );
//         },
//       ),
//     );

//     return pdf.save();
//   }

//   // --- 1. HEADER & CONTACT INFO ---
//   static pw.Widget _buildTopHeader(
//     pw.MemoryImage coatOfArms,
//     pw.MemoryImage wmoLogo,
//     pw.MemoryImage gmetLogo,
//     pw.MemoryImage twitter,
//     pw.MemoryImage facebook,
//     pw.Font boldFont,
//   ) {
//     return pw.Column(
//       children: [
//         pw.Row(
//           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Row(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Image(coatOfArms, width: 40, height: 40, fit: pw.BoxFit.contain),
//                 pw.SizedBox(width: 8),
//                 pw.Column(
//                   children: [
//                     pw.Image(wmoLogo, width: 35, height: 35, fit: pw.BoxFit.contain),
//                     pw.SizedBox(height: 2),
//                     pw.Text('MyWorldWeather', style: pw.TextStyle(fontSize: 6)),
//                   ],
//                 ),
//               ],
//             ),
//            pw.Expanded(
//   child: pw.Center(
//     child: pw.Padding(
//       padding: const pw.EdgeInsets.only(top: 8),
//       child: pw.Transform(
//         transform: Matrix4.diagonal3Values(1.0, 1.6, 1.0),
//         alignment: pw.Alignment.center,
//         child: pw.Text(
//           'GHANA METEOROLOGICAL AGENCY',
//           textAlign: pw.TextAlign.center,
//           style: pw.TextStyle(
//             font: boldFont, // Ensure this is pw.Font.timesBold()
//             fontSize: 20,   // Reduced base size because the transform scales it up
//             color: PdfColor.fromHex('#000080'),
//           ),
//         ),
//       ),
//     ),
//   ),
// ),
//             pw.Image(gmetLogo, width: 50, height: 50, fit: pw.BoxFit.contain, alignment: pw.Alignment.topRight),
//           ],
//         ),
//         pw.SizedBox(height: 4),
//         pw.Row(
//           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text('P.O Box LG 87, Accra', style: pw.TextStyle(fontSize: 8)),
//                 pw.SizedBox(height: 2),
//                 pw.Text('Tel/Fax: +233-302-543252', style: pw.TextStyle(fontSize: 8)),
//                 pw.SizedBox(height: 2),
//                 pw.Text('Tel: +233-0302-776171 ext. 3267/2534/3244', style: pw.TextStyle(fontSize: 8)),
//               ],
//             ),
//             pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.end,
//               children: [
//                 pw.Text('E-mail: kiamo@meteo.gov.gh', style: pw.TextStyle(fontSize: 8)),
//                 pw.Text('Website: www.meteo.gov.gh', style: pw.TextStyle(fontSize: 8, color: PdfColors.blue, decoration: pw.TextDecoration.underline)),
//                 pw.SizedBox(height: 2),
//                 pw.Row(
//                   children: [
//                     pw.Image(twitter, width: 10, height: 10),
//                     pw.SizedBox(width: 4),
//                     pw.Text('@GhanaMet', style: pw.TextStyle(fontSize: 8)),
//                   ],
//                 ),
//                 pw.SizedBox(height: 2),
//                 pw.Row(
//                   children: [
//                     pw.Image(facebook, width: 10, height: 10),
//                     pw.SizedBox(width: 4),
//                     pw.Text('GMet Forecast Office', style: pw.TextStyle(fontSize: 8)),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   static pw.Widget _buildDivider() {
//     return pw.Container(height: 1.0, color: PdfColors.black);
//   }

//   // --- 2. TITLE & SUMMARY ---
//   static pw.Widget _buildTitleSection(String date, String issueTime) {
//     String timeDisplay = _getTimeDisplay(issueTime);
//     return pw.Column(
//       children: [
//         pw.Text(
//           '24-HOUR FORECAST FOR GHANA',
//           style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
//         ),
//         pw.SizedBox(height: 2),
//         pw.Text(
//           'VALID FROM $timeDisplay ($date)',
//           style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
//         ),
//       ],
//     );
//   }

//   static pw.Widget _buildSummaryBox(String summary) {
//     return pw.RichText(
//       text: pw.TextSpan(
//         children: [
//           pw.TextSpan(text: 'SUMMARY: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
//           pw.TextSpan(text: summary, style: pw.TextStyle(fontSize: 10)),
//         ],
//       ),
//     );
//   }

//   // --- 3. FIXED TABLE LAYOUT ---
//    // --- 3. FIXED TABLE LAYOUT (Explicit Heights) ---
//   static pw.Widget _buildPerfectForecastTable(
//     List<dynamic> tableData,
//     List<String> timeHeaders,
//     List<String> utcHeaders,
//     String date,
//   ) {
//     final columnWidths = {
//       0: const pw.FixedColumnWidth(80), 
//       1: const pw.FlexColumnWidth(2),   
//       2: const pw.FlexColumnWidth(1),   
//       3: const pw.FlexColumnWidth(2),   
//       4: const pw.FlexColumnWidth(1),   
//       5: const pw.FlexColumnWidth(2),   
//       6: const pw.FlexColumnWidth(1),   
//     };

//     // We use explicit heights to completely bypass the PDF layout engine limitations
//     const double headerHeight = 32.0;
//     const double halfHeaderHeight = 16.0;

//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//       children: [
//         // FIXED HEADER
//         pw.Container(
//           height: headerHeight,
//           decoration: pw.BoxDecoration(
//             border: pw.Border(
//               top: const pw.BorderSide(width: 0.5),
//               left: const pw.BorderSide(width: 0.5),
//               right: const pw.BorderSide(width: 0.5),
//             ),
//           ),
//           child: pw.Row(
//             children: [
//               // CITIES COLUMN
//               pw.Container(
//                 width: 80,
//                 height: headerHeight,
//                 alignment: pw.Alignment.center,
//                 child: pw.Text('CITIES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
//               ),
              
//               // WEATHER BRIEF BLOCK
//               pw.Expanded(
//                 child: pw.Container(
//                   decoration: pw.BoxDecoration(border: pw.Border(left: const pw.BorderSide(width: 0.5))),
//                   child: pw.Column(
//                     children: [
//                       // Top Half: WEATHER BRIEF
//                       pw.Container(
//                         height: halfHeaderHeight,
//                         alignment: pw.Alignment.center,
//                         decoration: pw.BoxDecoration(border: pw.Border(bottom: const pw.BorderSide(width: 0.5))),
//                         child: pw.Text('WEATHER BRIEF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
//                       ),
//                       // Bottom Half: Time Slots
//                       pw.Container(
//                         height: halfHeaderHeight,
//                         child: pw.Row(
//                           children: [
//                             _buildSubHeaderCell(timeHeaders[0], date, flex: 2, borderRight: true),
//                             _buildSubHeaderCell('TEMP °C', utcHeaders[0], flex: 1, borderRight: true),
//                             _buildSubHeaderCell(timeHeaders[1], date, flex: 2, borderRight: true),
//                             _buildSubHeaderCell('TEMP °C', utcHeaders[1], flex: 1, borderRight: true),
//                             _buildSubHeaderCell(timeHeaders[2], date, flex: 2, borderRight: true),
//                             _buildSubHeaderCell('TEMP °C', utcHeaders[2], flex: 1, borderRight: false),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
        
//         // STANDARD DATA TABLE
//         pw.Table(
//           border: pw.TableBorder.all(width: 0.5),
//           columnWidths: columnWidths,
//           children: tableData.map((city) {
// String slotprob1 = city['slot1_prob'] != '0' ? ' ${city['slot1_prob']}%' : '';
// String slotprob2 = city['slot2_prob'] != '0' ? ' ${city['slot2_prob']}%' : '';
// String slotprob3 = city['slot3_prob'] != '0' ? ' ${city['slot3_prob']}%' : '';
            
//             return pw.TableRow(
              
//               children: [
//                 pw.Container(
//                   padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
//                   child: pw.Text(city['name']?.toString().toUpperCase() ?? '', style: pw.TextStyle(fontSize: 8)),
//                 ),
//                 _buildDataCell('${city['slot1_weather']!}($slotprob1)'),
//                 _buildDataCell(city['slot1_temp']?.toString() ?? ''),
//                 _buildDataCell('${city['slot2_weather']!}($slotprob2)'),
//                 _buildDataCell(city['slot2_temp']?.toString() ?? ''),
//                 _buildDataCell('${city['slot3_weather']!}($slotprob3)'),
//                 _buildDataCell(city['slot3_temp']?.toString() ?? ''),
//               ],
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   static pw.Widget _buildSubHeaderCell(String title, String subtitle, {required int flex, required bool borderRight}) {
//     return pw.Expanded(
//       flex: flex,
//       child: pw.Container(
//         decoration: pw.BoxDecoration(border: borderRight ? pw.Border(right: const pw.BorderSide(width: 0.5)) : null),
//         child: pw.Column(
//           mainAxisAlignment: pw.MainAxisAlignment.center,
//           children: [
//             pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
//             pw.Text('($subtitle)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6)),
//           ],
//         ),
//       ),
//     );
//   }
//   static pw.Widget _buildDataCell(String text) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(2),
//       alignment: pw.Alignment.center,
//       child: pw.Text(text, style: pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
//     );
//   }

//   // --- 4. SEA STATE ---
//   static pw.Widget _buildSeaState(String seaStateText) {
//     PdfColor bgColor = PdfColors.green;
//     String lowerText = seaStateText.toLowerCase();
//     if (lowerText.contains('rough') || lowerText.contains('warning')) {
//       bgColor = PdfColors.yellow;
//     } else if (lowerText.contains('dangerous') || lowerText.contains('severe')) {
//       bgColor = PdfColors.red;
//     }

//     return pw.Row(
//       children: [
//         pw.Text('The state of the sea is ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
//         pw.Container(
//           color: bgColor,
//           padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//           child: pw.Text(
//             seaStateText,
//             style: pw.TextStyle(
//               fontWeight: pw.FontWeight.bold,
//               fontSize: 9,
//               color: bgColor == PdfColors.red ? PdfColors.white : PdfColors.black,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // --- 5. LEGEND & FOOTER ---
//   static pw.Widget _buildLegend(String issueTime) {
//     return pw.Row(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Expanded(
//           child: pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text('* %: PROBABILITY OF OCCURRENCE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
//               pw.Text('*INT- INTERVALS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
//               pw.Text('* P\'RDS- PERIODS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
//               pw.Text('* M\'CLOUDY- MOSTLY CLOUDY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
//               pw.Text('* ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
//               pw.Text('ISSUED AT $issueTime UTC', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
//             ],
//           ),
//         ),
//         pw.Expanded(
//           child: pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text('* P\'CLOUDY- PARTLY CLOUDY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
//               pw.Text('*TSRA- THUNDERSTORMS OR RAIN', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
//               pw.Text('* V\'RY - VERY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
//               pw.Text('* SLT\'LY - SLIGHTLY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   static pw.Widget _buildFooter( String date, String forecasterName) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Row(
//           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//           crossAxisAlignment: pw.CrossAxisAlignment.end,
//           children: [
//             pw.Text('', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
//             pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.end,
//               children: [
//                 pw.Text('DATE: $date', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
//                 pw.SizedBox(height: 12),
//                 pw.Text('SIGNED', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
//                 pw.Text(forecasterName.toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
//                 pw.Text('(DUTY FORECASTER)', style: pw.TextStyle(fontSize: 8)),
//               ],
//             ),
//           ],
//         ),
//         pw.SizedBox(height: 6),
//         pw.Container(height: 1, color: PdfColors.black),
//         pw.SizedBox(height: 4),
//         pw.Row(
//           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//           children: [
//             pw.Text('GHANA METEOROLOGICAL AGENCY, FORECAST DIVISION', style: pw.TextStyle(fontSize: 8)),
//             pw.Text('MAIN FORECAST OFFICE, ACCRA', style: pw.TextStyle(fontSize: 8)),
//           ],
//         ),
//       ],
//     );
//   }

//   // --- HELPERS ---
//   static List<String> _getTimeHeaders(String issueTime) {
//     switch (issueTime) {
//       case '0500': return ['MORNING', 'AFTERNOON', 'EVENING'];
//       case '1100': return ['AFTERNOON', 'EVENING', 'NIGHT'];
//       case '1700': return ['EVENING', 'NIGHT', 'MORNING'];
//       case '2300': return ['NIGHT', 'MORNING', 'AFTERNOON'];
//       default: return ['MORNING', 'AFTERNOON', 'EVENING'];
//     }
//   }

//   static List<String> _getUTCHeaders(String issueTime) {
//     switch (issueTime) {
//       case '0500': return ['0600UTC', '1200UTC', '1800UTC'];
//       case '1100': return ['1200UTC', '1800UTC', '0000UTC'];
//       case '1700': return ['1800UTC', '0000UTC', '0600UTC'];
//       case '2300': return ['0000UTC', '0600UTC', '1200UTC'];
//       default: return ['0600UTC', '1200UTC', '1800UTC'];
//     }
//   }

//   static String _getTimeDisplay(String issueTime) {
//     switch (issueTime) {
//       case '0500': return '6AM';
//       case '1100': return '12PM';
//       case '1700': return '6PM';
//       case '2300': return '12AM';
//       default: return '6AM';
//     }
//   }
// }