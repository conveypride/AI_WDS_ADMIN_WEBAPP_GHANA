import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/controllers/weekend_ibf_controller.dart';
import 'package:weather_admin_dashboard/app/views/widgets/risk_InfoSidePanel.dart'; 
import 'widgets/weekend_map_widget.dart';
 
 class WeekendIBFView extends StatelessWidget {
  const WeekendIBFView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(WeekendIBFController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.blueAccent : const Color(0xFF0B4EA2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TAB BAR
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : Colors.white, 
            border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300))
          ),
          child: TabBar(
            controller: ctrl.tabController, 
            labelColor: primaryColor, 
            unselectedLabelColor: Colors.grey, 
            indicatorColor: primaryColor, 
            indicatorWeight: 3,
            labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(icon: Icon(PhosphorIcons.clockCounterClockwise()), text: "FORECAST HISTORY"),
              Tab(icon: Icon(PhosphorIcons.mapTrifold()), text: "WEEKEND INPUT"),
            ],
          ),
        ),
        
        // TAB CONTENT
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
  final WeekendIBFController ctrl;
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
          Text("Weekend IBF Archives", style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
                borderRadius: BorderRadius.circular(8), 
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade100, 
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8))
                    ),
                    child: Row(children: [
                      Expanded(flex: 1, child: Text("ID", style: headerStyle)),
                      Expanded(flex: 3, child: Text("VALIDITY PERIOD", style: headerStyle)),
                      Expanded(flex: 2, child: Text("RISK AREAS", style: headerStyle)),
                      Expanded(flex: 2, child: Text("STATUS", style: headerStyle)),
                      Expanded(flex: 1, child: Text("", style: headerStyle)),
                    ]),
                  ),
                  // List
                  Expanded(
                    child: Obx(() => ListView.separated(
                      itemCount: ctrl.ibfHistory.length, 
                      separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                      itemBuilder: (ctx, idx) {
                        final item = ctrl.ibfHistory[idx];
                        final isPublished = item['status'] == 'Published';
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(children: [
                            Expanded(flex: 1, child: Text(item['id'], style: cellStyle.copyWith(fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Text(item['validity'], style: cellStyle)),
                            Expanded(flex: 2, child: Text(item['areas'], style: cellStyle)),
                            Expanded(flex: 2, child: _buildStatusBadge(item['status'], isPublished)),
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

  Widget _buildStatusBadge(String status, bool isPublished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(4), 
        border: Border.all(color: isPublished ? Colors.green : Colors.orange)
      ),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPublished ? Colors.green : Colors.orange)),
    );
  }
}

// ============================================================================
// TAB 2: INPUT MAPS & TABLE (3 DAYS)
// ============================================================================
class _InputTab extends StatelessWidget {
  final WeekendIBFController ctrl;
  final bool isDark;
  const _InputTab({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Date Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Draw Weekend Impact Areas", style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context, 
                    initialDate: ctrl.fridayDate.value, 
                    firstDate: DateTime(2020), 
                    lastDate: DateTime(2030),
                    // Helps user pick the correct Friday for the start of the weekend forecast
                    selectableDayPredicate: (DateTime val) => val.weekday == DateTime.friday,
                  );
                  if (date != null) ctrl.updateStartDate(date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.blue.shade50, 
                    borderRadius: BorderRadius.circular(8), 
                    border: Border.all(color: Colors.blue)
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_month, color: Colors.blue, size: 20), 
                    const SizedBox(width: 8),
                    Obx(() => Text(
                      "START DATE (FRI): ${DateFormat('dd MMM yyyy').format(ctrl.fridayDate.value)}", 
                      style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, color: Colors.blue)
                    )),
                  ]),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),

          // 3 MAPS ROW (FRI, SAT, SUN)
          SizedBox(
            height: 480, 
            child: Obx(() {
              final dates = ctrl.weekendDates;
              return Row(
                children: [
                  Expanded(child: WeekendMapWidget(ctrl: ctrl, period: 'fri', dateLabel: "FRIDAY: ${DateFormat('d MMM').format(dates[0])}", isDark: isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: WeekendMapWidget(ctrl: ctrl, period: 'sat', dateLabel: "SATURDAY: ${DateFormat('d MMM').format(dates[1])}", isDark: isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: WeekendMapWidget(ctrl: ctrl, period: 'sun', dateLabel: "SUNDAY: ${DateFormat('d MMM').format(dates[2])}", isDark: isDark)),
                ],
              );
            }),
          ),
          
          const SizedBox(height: 40),
            InfoSidePanel(ctrl:  ctrl, isDark: isDark),
            const SizedBox(height: 24),
          Text("Weekend Impact Details", style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
  
          // IBF TABLE (SECTOR vs 3 DAYS MATRIX)
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.5)),
            child: Obx(() {
              final dates = ctrl.weekendDates;
              return Table(
                border: TableBorder.all(color: Colors.black, width: 1),
                columnWidths: const {
                  0: FixedColumnWidth(140), // Sector Column
                  1: FlexColumnWidth(1),    // Friday
                  2: FlexColumnWidth(1),    // Saturday
                  3: FlexColumnWidth(1),    // Sunday
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // MATRIX HEADER
                  TableRow(
                    decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200),
                    children: [
                      _headerCell("SECTOR", isDark), 
                      _headerCell("FRIDAY\n${DateFormat('dd MMM').format(dates[0])}", isDark), 
                      _headerCell("SATURDAY\n${DateFormat('dd MMM').format(dates[1])}", isDark),
                      _headerCell("SUNDAY\n${DateFormat('dd MMM').format(dates[2])}", isDark),
                    ],
                  ),
                  
                  // MATRIX ROWS (By Sector)
                  ...ctrl.sectors.map((sector) {
                    return TableRow(
                      decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white),
                      children: [
                        // Sector Name Label
                        Container(
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.center, 
                          child: Text(
                            sector, 
                            textAlign: TextAlign.center, 
                            style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 12, color: isDark ? Colors.white : Colors.black)
                          )
                        ),
                        // 3 Days of Bullet Inputs
                        _bulletInputCell(ctrl, sector, 0, isDark), // Friday
                        _bulletInputCell(ctrl, sector, 1, isDark), // Saturday 
                        _bulletInputCell(ctrl, sector, 2, isDark), // Sunday 
                      ],
                    );
                  })
                ],
              );
            }),
          ),

          const SizedBox(height: 24),

       
          // YELLOW TEXTBOX FOR SHORT DESCRIPTION
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.amber.shade900.withOpacity(0.2) : const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.amber.shade800 : const Color(0xFFFDD835)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHORT DESCRIPTION / CAUTION', 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.orangeAccent : Colors.orange.shade900)
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: ctrl.shortDescription.value,
                  maxLines: 3,
                  onChanged: (val) => ctrl.shortDescription.value = val,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13, height: 1.5),
                  decoration: InputDecoration(
                    hintText: "Type a summary note for the weekend here...",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          
          // PUBLISH BUTTON
          Center(
            child: Obx(() {
              return ElevatedButton.icon(
                onPressed: ctrl.isPublishing.value ? null : ctrl.publishForecast,
                icon: ctrl.isPublishing.value 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Icon(PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill), size: 22),
                label: Text(ctrl.isPublishing.value ? "PUBLISHING..." : "PUBLISH WEEKEND IBF", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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

  Widget _headerCell(String text, bool isDark) {
    return Container(
      height: 55, 
      padding: const EdgeInsets.all(4), 
      alignment: Alignment.center, 
      child: Text(
        text, 
        textAlign: TextAlign.center, 
        style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white : Colors.black)
      )
    );
  }

  Widget _bulletInputCell(WeekendIBFController ctrl, String sector, int dayIndex, bool isDark) {
    return Container(
      height: 120, 
      padding: const EdgeInsets.all(8),
      child: TextFormField(
        initialValue: ctrl.ibfDetails[sector]![dayIndex],
        maxLines: null, 
        expands: true,
        keyboardType: TextInputType.multiline,
        style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black, height: 1.5),
        decoration: InputDecoration(
          hintText: "• Hazard/Impacts...",
          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (val) {
          ctrl.ibfDetails[sector]![dayIndex] = val;
        },
      ),
    );
  }
}