import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle, Matrix4;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class CoastlineTablePdfService {
  static Future<Uint8List> generateForecastPdf(Map<String, dynamic> forecast) async {
    final pdf = pw.Document();

    // 1. Load all required official assets
    final coatOfArmsBytes = await rootBundle.load('assets/images/ghana_coat_of_arms.png');
    final wmoLogoBytes = await rootBundle.load('assets/images/wmo_logo.png');
    final gmetLogoBytes = await rootBundle.load('assets/images/gmet_logo.png');
    final twitterBytes = await rootBundle.load('assets/images/twitter_logo.png');
    final facebookBytes = await rootBundle.load('assets/images/facebook_logo.png');
    
    // Load sea state legend images
    final calmBytes = await rootBundle.load('assets/images/calm_sea.png');
    final roughBytes = await rootBundle.load('assets/images/rough_sea.png');
    final dangerousBytes = await rootBundle.load('assets/images/dangerous_sea.png');
    
    // Load organization logos for footer
    final gmesLogoBytes = await rootBundle.load('assets/images/gmes_logo.png');
    final auLogoBytes = await rootBundle.load('assets/images/african_union_logo.png');
    final euLogoBytes = await rootBundle.load('assets/images/eu_logo.png');
    final ugLogoBytes = await rootBundle.load('assets/images/ug_logo.png');

    final coatOfArms = pw.MemoryImage(coatOfArmsBytes.buffer.asUint8List());
    final wmoLogo = pw.MemoryImage(wmoLogoBytes.buffer.asUint8List());
    final gmetLogo = pw.MemoryImage(gmetLogoBytes.buffer.asUint8List());
    final twitter = pw.MemoryImage(twitterBytes.buffer.asUint8List());
    final facebook = pw.MemoryImage(facebookBytes.buffer.asUint8List());
    
    final calmSea = pw.MemoryImage(calmBytes.buffer.asUint8List());
    final roughSea = pw.MemoryImage(roughBytes.buffer.asUint8List());
    final dangerousSea = pw.MemoryImage(dangerousBytes.buffer.asUint8List());
    
    final gmesLogo = pw.MemoryImage(gmesLogoBytes.buffer.asUint8List());
    final auLogo = pw.MemoryImage(auLogoBytes.buffer.asUint8List());
    final euLogo = pw.MemoryImage(euLogoBytes.buffer.asUint8List());
    final ugLogo = pw.MemoryImage(ugLogoBytes.buffer.asUint8List());

    // 2. Set Fonts (Times New Roman equivalent)
    final ttfRegular = pw.Font.times();
    final ttfBold = pw.Font.timesBold();

    final theme = pw.ThemeData.withFont(
      base: ttfRegular,
      bold: ttfBold,
    );

    // 3. Extract and Format Data
    final validTime = forecast['dailyValidTime'] ?? '1200Z';
    String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    if (forecast['dailyValidDate'] != null) {
      try {
        final dt = DateTime.parse(forecast['dailyValidDate']);
        formattedDate = DateFormat('dd/MM/yyyy').format(dt);
      } catch (_) {}
    }

    String issueDate = formattedDate;
    if (forecast['dailyIssueDate'] != null) {
      try {
        final dt = DateTime.parse(forecast['dailyIssueDate']);
        issueDate = DateFormat('dd/MM/yyyy').format(dt);
      } catch (_) {}
    }

    final seaStateText = forecast['dailyStateOfSea']?.toString().toUpperCase() ?? 'CALM (1)';
    final warningText = forecast['dailyWarningText'] ?? '';
    final weatherText = forecast['dailyWeatherSummary'] ?? '';
    final author = forecast['author'] ?? {};
    final tableData = forecast['tableData'] as Map<String, dynamic>? ?? {};

    // 4. Build the Document
   // 4. Build the Document
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        // REDUCED MARGINS slightly to give the footer more room to breathe
        margin: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 20), 
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildTopHeader(coatOfArms, wmoLogo, gmetLogo, twitter, facebook, ttfBold),
              pw.SizedBox(height: 10),
              
              // --- TITLE SECTION ---
              pw.Center(
                child: pw.Text(
                  'COASTLINE & MARITIME WEATHER FORECAST FOR GHANA',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 8),
              
              // --- VALIDITY SECTION ---
              pw.Center(
                child: pw.Text(
                  'VALID AT $validTime $formattedDate',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  '(VALID FROM COAST EXTENDING 200NM INTO SEA)',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 10),

              // --- SEA STATE WITH ICON & WARNING ---
              _buildSeaStateSection(seaStateText, warningText, calmSea, roughSea, dangerousSea),
              pw.SizedBox(height: 10),

              // --- THE DATA TABLE ---
              _buildForecastTable(tableData),
              pw.SizedBox(height: 10),
              
              // --- WEATHER SECTION ---
              if (weatherText.isNotEmpty) ...[
                _buildWeatherSection(weatherText),
                pw.SizedBox(height: 10),
              ],
              
              // --- LEGEND SECTION ---
              _buildLegendSection(calmSea, roughSea, dangerousSea),
              
              // FIXED: Uncommented the Spacer to push the footer perfectly to the bottom
              pw.Spacer(), 
              
              // --- FOOTER SIGNATURE & LOGOS ---
              // FIXED: Added fallback for dailyIssueTime so it doesn't crash if it's null
              _buildFooter(
                issueDate, 
                forecast['dailyIssueTime'] ?? forecast['dailyIssueTime'] ?? '0500Z', 
                author['name'] ?? 'DUTY FORECASTER', 
                gmesLogo, auLogo, euLogo, ugLogo, twitter, facebook
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // --- 1. OFFICIAL GMET HEADER ---
  static pw.Widget _buildTopHeader(
    pw.MemoryImage coatOfArms,
    pw.MemoryImage wmoLogo,
    pw.MemoryImage gmetLogo,
    pw.MemoryImage twitter,
    pw.MemoryImage facebook,
    pw.Font boldFont,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left: Ghana Coat of Arms + WMO Logo
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Image(coatOfArms, width: 50, height: 50, fit: pw.BoxFit.contain),
            pw.SizedBox(width: 15),
          ],
        ),
        

        // Center: Agency Name
        pw.Expanded(
          child: pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'GHANA METEOROLOGICAL AGENCY',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: boldFont, 
                    fontSize: 20,  
                    color: PdfColor.fromHex('#000080'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'www.meteo.gov.gh / +233 302543252 / info@meteo.gov.gh/kiamo@meteo.gov.gh',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 10,  color: PdfColor.fromHex('#000080'),),
                ),
              ],
            ),
          ),
        ),
        
        // Right: GMet Logo
        pw.Image(gmetLogo, width: 60, height: 60, fit: pw.BoxFit.contain),
      ],
    );
  }

  // --- 2. SEA STATE SECTION WITH ICON ---
  static pw.Widget _buildSeaStateSection(
    String seaStateText,
    String warningText,
    pw.MemoryImage calmSea,
    pw.MemoryImage roughSea,
    pw.MemoryImage dangerousSea,
  ) {
    // Determine which icon to show based on sea state
    pw.MemoryImage seaIcon = calmSea;
      int seaNumber = 1;

  if (seaStateText.toUpperCase().contains('ROUGH')) {
    seaIcon = roughSea;
    seaNumber = 2;
  } else if (seaStateText.toUpperCase().contains('DANGEROUS')) {
    seaIcon = dangerousSea;
    seaNumber = 3;
  }




    return pw.Column(
      children: [
        // Sea State with Icon
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'The state of the sea will be ',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              '$seaStateText ($seaNumber)',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(width: 10),
            pw.Image(seaIcon, width: 90, height: 70, fit: pw.BoxFit.contain),
          ],
        ),
        
        // Warning if present
        if (warningText.isNotEmpty && warningText.toUpperCase() != 'NIL') ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'WARNING: $warningText',
            style: pw.TextStyle(
              fontSize: 13, 
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ],
    );
  }

  // --- 3. FORECAST TABLE BUILDER ---
  static pw.Widget _buildForecastTable(Map<String, dynamic> tableData) {
    final parameters = [
      "SURFACE WIND", 
      "VISIBILITY", 
      "SEA SURFACE TEMPERATURE", 
      "SIG WAVE HEIGHT", 
      "TIDAL WAVE", 
      "WAVE CURRENT"
    ];

    return pw.Table(
      border: pw.TableBorder.all(width: 1.5, color: PdfColors.black),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.6), // Parameter column wider
        1: const pw.FlexColumnWidth(1.6), // 12 Hours
        2: const pw.FlexColumnWidth(1.5), // 24 Hours
      },
      children: [
        // Header Row (Navy Blue Background)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#000080'),
          ),
          children: [
            _buildHeaderCell('PARAMETER'),
            _buildHeaderCell('12 HOURS'),
            _buildHeaderCell('24 HOURS'),
          ],
        ),
        
        // Data Rows (alternating white background)
        ...parameters.map((param) {
          final rowData = tableData[param] ?? {};
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
            ),
            children: [
              // Parameter name (left-aligned, bold, navy blue background)
              _buildParameterCell(param),
              // Data cells (centered)
              _buildDataCell(rowData['12h']?.toString() ?? '-'),
              _buildDataCell(rowData['24h']?.toString() ?? '-'),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text, 
        style: pw.TextStyle(
          fontSize: 11, 
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildParameterCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      alignment: pw.Alignment.centerLeft,
      // decoration: pw.BoxDecoration(
      //   color: PdfColor.fromHex('#000080'),
      // ),
      child: pw.Text(
        text, 
        style: pw.TextStyle(
          fontSize: 10, 
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildDataCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text, 
        style: const pw.TextStyle(fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // --- 4. WEATHER SECTION ---
  static pw.Widget _buildWeatherSection(String weatherText) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'WEATHER: ',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        
        pw.Text(
          weatherText,
          style: const pw.TextStyle(fontSize: 12),
          textAlign: pw.TextAlign.justify,
        ),
      ],
    );
  }

  // --- 5. LEGEND SECTION ---
  static pw.Widget _buildLegendSection(
    pw.MemoryImage calmSea,
    pw.MemoryImage roughSea,
    pw.MemoryImage dangerousSea,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'LEGEND',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(dangerousSea, 'Dangerous'),
            _buildLegendItem(roughSea, 'Rough'),
            _buildLegendItem(calmSea, 'Calm'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildLegendItem(pw.MemoryImage icon, String label) {
    return pw.Row(
      children: [
        pw.Image(icon, width: 130, height: 115, fit: pw.BoxFit.contain),
       
      ],
    );
  }

  // --- 6. FOOTER & SIGNATURE WITH ORGANIZATION LOGOS ---
  static pw.Widget _buildFooter(
  String date,
  String dailyIssueTime,
  String forecasterName,
  pw.MemoryImage gmesLogo,
  pw.MemoryImage auLogo,
  pw.MemoryImage euLogo,
  pw.MemoryImage ugLogo,
  pw.MemoryImage twitter,
  pw.MemoryImage facebook,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      // --- TOP: Issue Info + Signature ---
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ISSUED AT $dailyIssueTime',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'DATE: $date',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'MARINE FORECAST OFFICE',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                forecasterName,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '(SIGNED)',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),

      pw.SizedBox(height: 10),

      // --- SUPPORT TEXT ---
      pw.Center(
        child: pw.Text(
          'PROVIDED WITH SUPPORT OF EU & AU',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ),

      pw.SizedBox(height: 10),

      // --- SOCIAL MEDIA ---
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Image(twitter, width: 15, height: 15),
              pw.SizedBox(width: 5),
              pw.Text('@GhanaMet', style: pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.SizedBox(width: 15),
          pw.Row(
            children: [
              pw.Image(facebook, width: 15, height: 15),
              pw.SizedBox(width: 5),
              pw.Text('Ghana Meteorological Agency', style: pw.TextStyle(fontSize: 9)),
            ],
          ),
        ],
      ),

      pw.SizedBox(height: 10),

      // --- ORGANIZATION LOGOS ---
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Image(gmesLogo, width: 75, height: 60),
          pw.SizedBox(width: 10),
          pw.Image(auLogo, width: 75, height: 60),
          pw.SizedBox(width: 10),
          pw.Image(euLogo, width: 50, height: 40),
          pw.SizedBox(width: 10),
          pw.Image(ugLogo, width: 75, height: 60),
        ],
      ),
    ],
  );
}
}