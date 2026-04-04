// lib/app/views/seasonal_forecast_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../controllers/seasonal_forecast_controller.dart';

class SeasonalForecastView extends StatelessWidget {
  const SeasonalForecastView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(SeasonalForecastController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.blueAccent : const Color(0xFF0B4EA2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TAB BAR
        Container(
          decoration: BoxDecoration(color: isDark ? const Color(0xFF252525) : Colors.white, border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300))),
          child: TabBar(
            controller: ctrl.tabController, labelColor: primaryColor, unselectedLabelColor: Colors.grey, indicatorColor: primaryColor, indicatorWeight: 3,
            labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(icon: Icon(PhosphorIcons.clockCounterClockwise()), text: "ARCHIVES"),
              Tab(icon: Icon(PhosphorIcons.plant()), text: "CREATE ANNUAL OUTLOOK"),
            ],
          ),
        ),
        
        Expanded(
          child: TabBarView(
            controller: ctrl.tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _HistoryTab(ctrl: ctrl, isDark: isDark),
              _InputTab(ctrl: ctrl, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 1: HISTORY TABLE
// ============================================================================
class _HistoryTab extends StatelessWidget {
  final SeasonalForecastController ctrl;
  final bool isDark;
  const _HistoryTab({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final headerStyle = GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey);
    final cellStyle = TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Seasonal Forecast Archives", style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                    child: Row(children: [
                      Expanded(flex: 1, child: Text("ID", style: headerStyle)),
                      Expanded(flex: 3, child: Text("SEASON TITLE", style: headerStyle)),
                      Expanded(flex: 2, child: Text("DATE ISSUED", style: headerStyle)),
                      Expanded(flex: 2, child: Text("STATUS", style: headerStyle)),
                      Expanded(flex: 1, child: Text("", style: headerStyle)),
                    ]),
                  ),
                  Expanded(
                    child: Obx(() => ListView.separated(
                      itemCount: ctrl.history.length, separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                      itemBuilder: (ctx, idx) {
                        final item = ctrl.history[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(children: [
                            Expanded(flex: 1, child: Text(item['id'], style: cellStyle.copyWith(fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Text(item['title'], style: cellStyle)),
                            Expanded(flex: 2, child: Text(item['date'], style: cellStyle)),
                            Expanded(flex: 2, child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green)),
                              child: Text(item['status'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                            )),
                            Expanded(flex: 1, child: IconButton(icon: Icon(PhosphorIcons.eye(), color: Colors.blue), onPressed: (){})),
                          ]),
                        );
                      }
                    )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 2: DATA ENTRY & THEMATIC MAP
// ============================================================================
class _InputTab extends StatelessWidget {
  final SeasonalForecastController ctrl;
  final bool isDark;
  const _InputTab({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. GENERAL OUTLOOK SECTION
          _buildSectionHeader("1. General Outlook", isDark),
          _buildGeneralOutlookBox(),

          const SizedBox(height: 40),

          // 2. THEMATIC MAP & MILESTONES ROW
          _buildSectionHeader("2. Climatological Anomalies & Milestones", isDark),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildThematicMap()),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: _buildZonalTable()),
            ],
          ),

          const SizedBox(height: 40),

          // 3. 12-MONTH BUILDER
          _buildSectionHeader("3. Annual Rainfall Distribution (Jan - Dec)", isDark),
          _buildAnnualBuilderTable(),

          const SizedBox(height: 40),
          
          // PUBLISH BUTTON
          Center(
            child: Obx(() {
              return ElevatedButton.icon(
                onPressed: ctrl.isPublishing.value ? null : ctrl.publishForecast,
                icon: ctrl.isPublishing.value 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Icon(PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill), size: 22),
                label: Text(ctrl.isPublishing.value ? "PUBLISHING..." : "PUBLISH ANNUAL OUTLOOK", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.green.shade600 : Colors.green.shade700, 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
    );
  }

  Widget _buildGeneralOutlookBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          TextFormField(
            initialValue: ctrl.seasonTitle.value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(labelText: "Forecast Title (e.g. 2026 Annual Outlook)", labelStyle: TextStyle(color: Colors.grey.shade500)),
            onChanged: (v) => ctrl.seasonTitle.value = v,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: ctrl.seasonSummary.value, maxLines: 3,
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(labelText: "Executive Summary / Message to Public", alignLabelWithHint: true, labelStyle: TextStyle(color: Colors.grey.shade500), border: const OutlineInputBorder()),
            onChanged: (v) => ctrl.seasonSummary.value = v,
          ),
        ],
      ),
    );
  }

  Widget _buildThematicMap() {
    return Container(
      height: 380, 
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.5), borderRadius: BorderRadius.circular(8)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Obx(() => FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(7.9465, -1.0232), initialZoom: 5.6, interactionOptions: InteractionOptions(flags: InteractiveFlag.none) 
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.gmet.weather'),
                PolygonLayer(
                  polygons: ctrl.sectors.map((sector) {
                    final color = ctrl.getAnomalyColor(sector);
                    return Polygon(
                      points: ctrl.sectorPolygons[sector]!,
                      color: color.withOpacity(0.5), borderColor: color, borderStrokeWidth: 3,
                    );
                  }).toList(),
                ),
              ],
            )),
          ),
          Positioned(
            bottom: 16, left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isDark ? Colors.black87 : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(Colors.green.shade600, "Above Normal"),
                  const SizedBox(height: 4),
                  _legendItem(Colors.yellow.shade600, "Normal"),
                  const SizedBox(height: 4),
                  _legendItem(Colors.red.shade400, "Below Normal"),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
      ],
    );
  }

  Widget _buildZonalTable() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.5)),
      child: Obx(() {
        return Table(
          border: TableBorder.all(color: Colors.black, width: 1),
          columnWidths: const { 0: FixedColumnWidth(120), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1) },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200),
              children: [_headerCell("SECTOR"), _headerCell("ONSET DATE"), _headerCell("CESSATION DATE"), _headerCell("RAINFALL ANOMALY")],
            ),
            ...ctrl.sectors.map((sector) {
              final data = ctrl.zonalData[sector]!;
              return TableRow(
                decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white),
                children: [
                  Container(height: 100, padding: const EdgeInsets.all(8), alignment: Alignment.center, child: Text(sector, textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white : Colors.black))),
                  _textInputCell(sector, 'onset', data['onset'], "e.g. 2nd Wk of Mar"),
                  _textInputCell(sector, 'cessation', data['cessation'], "e.g. 1st Wk of Jul"),
                  _anomalyDropdownCell(sector, data['anomaly']),
                ],
              );
            })
          ],
        );
      }),
    );
  }

   Widget _buildAnnualBuilderTable() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.5)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          
          // UPDATED: Increased column width slightly from 100 to 115
          Map<int, TableColumnWidth> colWidths = { 0: const FixedColumnWidth(130) };
          for (int i = 1; i <= 12; i++) colWidths[i] = const FixedColumnWidth(115);

          return Table(
            border: TableBorder.all(color: Colors.black, width: 1),
            columnWidths: colWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200),
                children: [
                  _headerCell("SECTOR"),
                  ...ctrl.forecastMonths.map((m) => _headerCell(m.toUpperCase())),
                ],
              ),
              ...ctrl.sectors.map((sector) {
                return TableRow(
                  decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white),
                  children: [
                    Container(padding: const EdgeInsets.all(8), alignment: Alignment.center, child: Text(sector, textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white : Colors.black))),
                    
                    // 12 Months Generation
                    ...List.generate(12, (monthIndex) {
                      final mData = ctrl.monthlyData[sector]![monthIndex];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextFormField(
                              initialValue: mData['rain'].toString(), textAlign: TextAlign.center, keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(hintText: "Rain(mm)", hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400), border: const UnderlineInputBorder(), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 4)),
                              onChanged: (val) => ctrl.updateMonthlyRain(sector, monthIndex, val),
                            ),
                            const SizedBox(height: 8),
                            // UPDATED: Wrapped in FittedBox so it gracefully shrinks without crashing
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Dry", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mData['isWet'] ? Colors.grey : Colors.orange)),
                                  const SizedBox(width: 2),
                                  Switch(
                                    value: mData['isWet'],
                                    activeColor: Colors.green, inactiveThumbColor: Colors.orange, inactiveTrackColor: Colors.orange.withOpacity(0.3),
                                    onChanged: (val) => ctrl.toggleMonthlyWetDry(sector, monthIndex, val),
                                  ),
                                  const SizedBox(width: 2),
                                  Text("Wet", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mData['isWet'] ? Colors.green : Colors.grey)),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    })
                  ],
                );
              })
            ],
          );
        }),
      ),
    );
  }

  // --- HELPERS ---

  Widget _headerCell(String text) => Container(height: 55, padding: const EdgeInsets.all(4), alignment: Alignment.center, child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white : Colors.black)));

  Widget _textInputCell(String sector, String key, String value, String hint) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: TextFormField(
        initialValue: value, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade500), border: InputBorder.none, isDense: true),
        onChanged: (val) => ctrl.updateZonalData(sector, key, val),
      ),
    );
  }

  Widget _anomalyDropdownCell(String sector, String currentValue) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true, value: currentValue,
          dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getAnomalyTextColor(currentValue)),
          items: ctrl.anomalyOptions.map((val) => DropdownMenuItem(value: val, child: Center(child: Text(val)))).toList(),
          onChanged: (val) { if (val != null) ctrl.updateZonalData(sector, 'anomaly', val); },
        ),
      ),
    );
  }

  Color _getAnomalyTextColor(String val) {
    if (val == "Above Normal") return Colors.green;
    if (val == "Below Normal") return Colors.red;
    return Colors.orange;
  }
}