import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class WeekendIbfPdfService {
  static Future<Uint8List> generateIbfPdf(Map<String, dynamic> data, Uint8List mapsImageBytes) async {
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
    
    // Load the generated 3-map image
    final mapsImage = pw.MemoryImage(mapsImageBytes);

    final fontData = await rootBundle.load('assets/fonts/Tinos-Regular.ttf');
    final ttfRegular = pw.Font.ttf(fontData);
    final fontDataBold = await rootBundle.load('assets/fonts/Tinos-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontDataBold);
    
    final theme = pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold);

    // ========================================================================
    // 2. EXTRACT DYNAMIC DATA
    // ========================================================================
    DateTime validFrom = DateTime.parse(data['validFrom']); 
    String issueTime = data['issueTime'] ?? '';
    Map<String, dynamic> ibfDetails = data['ibfDetails'] ?? {}; 
    // ADDED: Calculate Valid From Time (1 hour after Issue Time)
    String validFromTime = '1800'; // Default fallback
    if (issueTime.length == 4) {
      int hour = int.tryParse(issueTime.substring(0, 2)) ?? 17;
      int nextHour = (hour + 1) % 24; // Handles 2300 -> 0000 wrap-around
      validFromTime = '${nextHour.toString().padLeft(2, '0')}00';
    }

    // Calculate the three dates
    final date2 = validFrom.add(const Duration(days: 1));
    final date3 = validFrom.add(const Duration(days: 2));

    final day1Date = DateFormat('dd/MM/yyyy').format(validFrom);
    final day2Date = DateFormat('dd/MM/yyyy').format(date2);
    final day3Date = DateFormat('dd/MM/yyyy').format(date3);
    
    // Get dynamic Day Names (e.g., TUESDAY, WEDNESDAY)
    final day2Name = DateFormat('EEEE').format(date2).toUpperCase();
    final day3Name = DateFormat('EEEE').format(date3).toUpperCase();
    
    // Calculate CAFO date
    final cafoDateFrom = DateFormat('dd/MM/yyyy').format(validFrom);
    final cafoDateTo = DateFormat('dd/MM/yyyy').format(date3);

    // ========================================================================
    // 3. BUILD THE PDF PAGE
    // ========================================================================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: theme,
        build: (pw.Context context) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Blue border
              pw.Container(
                width: 14,
                color: PdfColor.fromHex('#1A3B85'),
              ),
              
              // Main content
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(gmetLogo, coatOfArms),
                    
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 16, right: 24, top: 8, bottom: 24),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            _buildTitle(),
                            pw.SizedBox(height: 8),
                            
                            pw.Expanded(
                              flex: 4,
                              child: _buildThreeMapsSection(
                                mapsImage: mapsImage,
                                day1Date: day1Date,
                                day2Date: day2Date,
                                day3Date: day3Date,
                                day2Name: day2Name,
                                day3Name: day3Name,
                                cafoDateFrom: cafoDateFrom,
                                cafoDateTo: cafoDateTo,
                                timeIssued: issueTime,
                                validFromTime: validFromTime,
                              ),
                            ),
                            
                            pw.SizedBox(height: 8),
                            
                            pw.Expanded(
                              flex: 2,
                              child: _buildRiskTableAndIconsRow(iconsImage),
                            ),
                            
                            pw.SizedBox(height: 10),
                            
                            _buildIBFTable(ibfDetails, day2Name, day3Name),
                            
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
                        pw.Text('Facebook: Ghana Meteorological Agency (GMet)', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
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
    return pw.Center(
      child: pw.Text(
        'IMPACT-BASED FORECAST FOR GHANA (WEEKEND)',
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          decoration: pw.TextDecoration.underline,
        ),
      ),
    );
  }

  static pw.Widget _buildThreeMapsSection({
    required pw.MemoryImage mapsImage,
    required String day1Date,
    required String day2Date,
    required String day3Date,
    required String day2Name,
    required String day3Name,
    required String cafoDateFrom,
    required String cafoDateTo,
    required String timeIssued,
    required String validFromTime,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // LEFT: The 3 Maps
          pw.Expanded(
            flex: 7,
            child: pw.Column(
              children: [
                // Header row
                pw.Container(
                  height: 30,
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF4472C4),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: _dateHeader('TONIGHT ($day1Date)'),
                      ),
                      pw.Container(width: 2, color: PdfColors.black),
                      pw.Expanded(
                        child: _dateHeader('$day2Name ($day2Date)'),
                      ),
                      pw.Container(width: 2, color: PdfColors.black),
                      pw.Expanded(
                        child: _dateHeader('$day3Name ($day3Date)'),
                      ),
                    ],
                  ),
                ),
                
                // The 3 maps image
                pw.Expanded(
                  child: pw.Container(
                    width: double.infinity,
                    child: pw.Image(mapsImage, fit: pw.BoxFit.fill),
                  ),
                ),
              ],
            ),
          ),
          
          // RIGHT: Metadata panel
          pw.Container(width: 2, color: PdfColors.black),
          pw.Container(
            width: 90,
            color: PdfColors.black,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildBlackSideLabel('CAFO\nDate'),
                _buildWhiteSideBox('$cafoDateFrom\nTO\n$cafoDateTo'),
                _buildBlackSideLabel('Time Issued'),
                _buildWhiteSideBox('$timeIssued UTC'),
                _buildBlackSideLabel('Valid From'),
                _buildWhiteSideBox('$validFromTime UTC'),
                _buildBlackSideLabel('Nowcasting\nRisk'),
                _buildColorSideBox('Take Action', PdfColors.red),
                _buildColorSideBox('Be Prepared', PdfColors.orange),
                _buildColorSideBox('Be aware', PdfColors.yellow, PdfColors.black),
                _buildColorSideBox('Low risk', PdfColors.green),
                _buildColorSideBox('No risk', PdfColors.white, PdfColors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _dateHeader(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  static pw.Widget _buildBlackSideLabel(String text) {
    return pw.Container(
      height: 22,
      alignment: pw.Alignment.center,
      decoration: const pw.BoxDecoration(
        color: PdfColors.black,
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.white)),
      ),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 7,
        ),
      ),
    );
  }

  static pw.Widget _buildWhiteSideBox(String text) {
    return pw.Container(
      height: 28,
      alignment: pw.Alignment.center,
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(bottom: pw.BorderSide(width: 1)),
      ),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
      ),
    );
  }

  static pw.Widget _buildColorSideBox(String text, PdfColor color, [PdfColor textColor = PdfColors.white]) {
    return pw.Container(
      height: 18,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: color,
        border: const pw.Border(bottom: pw.BorderSide(width: 1)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: textColor,
          fontWeight: pw.FontWeight.bold,
          fontSize: 7,
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
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
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


  static pw.Widget _buildIBFTable(Map<String, dynamic> ibfDetails, String day2Name, String day3Name) {
    final sectors = ['COASTLINE', 'SLIGHTLY NORTH OF THE COASTLINE', 'MIDDLE', 'TRANSITION', 'NORTH'];
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(110),
        1: const pw.FlexColumnWidth(),
        2: const pw.FlexColumnWidth(),
        3: const pw.FlexColumnWidth(),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF4472C4)),
          children: [
            _tableHeaderCell('SECTORS'),
            _tableHeaderCell('TONIGHT'),
            _tableHeaderCell(day2Name),
            _tableHeaderCell(day3Name),
          ],
        ),
        
        // Data Rows
        ...sectors.map((sector) {
         return pw.TableRow(
         verticalAlignment: pw.TableCellVerticalAlignment.full,
          children: [
            pw.Container(
              // ADDED: Set the background color only for this specific cell
              color: const PdfColor.fromInt(0xFF4472C4), 
              padding: const pw.EdgeInsets.all(6),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                sector, 
                style: pw.TextStyle(
                  color: PdfColors.white, // Added white text so it's readable on the blue background
                  fontWeight: pw.FontWeight.bold, 
                  fontSize: 8
                ),
              ),
            ),
            _buildIBFCell(ibfDetails[sector]?[0]),
            _buildIBFCell(ibfDetails[sector]?[1]),
            _buildIBFCell(ibfDetails[sector]?[2]),
          ],
        );
      }).toList(),
    ],
  );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
      ),
    );
  }

  static pw.Widget _buildIBFCell(dynamic dayData) {
    if (dayData == null) return pw.SizedBox();
    
    // Extract conditions
    List<String> conditions = [];
    if (dayData['cond1'] != null && dayData['cond1'].toString().isNotEmpty) {
      conditions.add(dayData['cond1'].toString());
    }
    if (dayData['cond2'] != null && dayData['cond2'].toString().isNotEmpty) {
      conditions.add(dayData['cond2'].toString());
    }
    if (dayData['cond3'] != null && dayData['cond3'].toString().isNotEmpty) {
      conditions.add(dayData['cond3'].toString());
    }
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Build checkbox items using simple square boxes
          ...conditions.map((cond) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Simple checkbox using Container
                pw.Container(
                  width: 7,
                  height: 7,
                  margin: const pw.EdgeInsets.only(right: 4, top: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.black,
                    border: pw.Border.all(color: PdfColors.black, width: 0.5),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(cond, style: const pw.TextStyle(fontSize: 7)),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#D9E1F2'),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: pw.Text(
          'SIGNED: Central Analysis and Forecasting Office (CAFO)',
          style: pw.TextStyle(
            color: PdfColors.blue800,
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}