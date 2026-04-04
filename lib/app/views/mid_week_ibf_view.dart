import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/views/widgets/risk_InfoSidePanel.dart';
import '../controllers/mid_week_ibf_controller.dart';
import 'widgets/mid_week_map_widget.dart';

class MidWeekIBFView extends StatelessWidget {
  const MidWeekIBFView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final ctrl = Get.put(MidWeekIBFController());
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
              Tab(icon: Icon(PhosphorIcons.mapTrifold()), text: "FORECAST INPUT"),
            ],
          ),
        ),
        
        // TAB CONTENT
        Expanded(
          child: TabBarView(
            controller: ctrl.tabController,
            physics: const NeverScrollableScrollPhysics(), // Prevents accidental map swiping
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
  final MidWeekIBFController ctrl;
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
          Text("Mid-Week IBF Archives", style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
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
// TAB 2: INPUT MAPS & TABLE
// ============================================================================
class _InputTab extends StatelessWidget {
  final MidWeekIBFController ctrl;
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
              Text("Draw Mid-Week Impact Areas", style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context, 
                    initialDate: ctrl.validFrom.value, 
                    firstDate: DateTime(2020), 
                    lastDate: DateTime(2030)
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
                      "START DATE: ${DateFormat('dd MMM yyyy').format(ctrl.validFrom.value)}", 
                      style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, color: Colors.blue)
                    )),
                  ]),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),

          // 3 MAPS ROW
          SizedBox(
            height: 480, // strict height for the maps to prevent layout errors
            child: Obx(() {
              final dates = ctrl.dynamicDates;
              return Row(
                children: [
                  Expanded(child: MidWeekMapWidget(ctrl: ctrl, period: 'day1', dateLabel: "DAY 1: ${DateFormat('E, d MMM').format(dates[0])}", isDark: isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: MidWeekMapWidget(ctrl: ctrl, period: 'day2', dateLabel: "DAY 2: ${DateFormat('E, d MMM').format(dates[1])}", isDark: isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: MidWeekMapWidget(ctrl: ctrl, period: 'day3', dateLabel: "DAY 3: ${DateFormat('E, d MMM').format(dates[2])}", isDark: isDark)),
                ],
              );
            }),
          ),
          
          const SizedBox(height: 40),
          
         InfoSidePanel(ctrl: ctrl, isDark: isDark),
           const SizedBox(height: 24),
          Text("Impact-Based Forecast Details", style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
   // IBF TABLE (SECTOR vs DAY MATRIX)
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.5)),
            child: Obx(() {
              final dates = ctrl.dynamicDates;
              return Table(
                border: TableBorder.all(color: Colors.black, width: 1),
                columnWidths: const {
                  0: FixedColumnWidth(140), // Sector Column
                  1: FlexColumnWidth(1),    // Day 1
                  2: FlexColumnWidth(1),    // Day 2
                  3: FlexColumnWidth(1),    // Day 3
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // MATRIX HEADER
                  TableRow(
                    decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200),
                    children: [
                      _headerCell("SECTOR", isDark), 
                      _headerCell("DAY 1\n${DateFormat('E, dd MMM').format(dates[0])}", isDark), 
                      _headerCell("DAY 2\n${DateFormat('E, dd MMM').format(dates[1])}", isDark),
                      _headerCell("DAY 3\n${DateFormat('E, dd MMM').format(dates[2])}", isDark), 
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
                        _bulletInputCell(ctrl, sector, 0, isDark),
                        _bulletInputCell(ctrl, sector, 1, isDark),
                        _bulletInputCell(ctrl, sector, 2, isDark),
                      ],
                    );
                  })
                ],
              );
            }),
          ),

       

           const SizedBox(height: 24),
          // NEW: YELLOW TEXTBOX FOR SHORT DESCRIPTION
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
                    hintText: "Type a short description, summary, or note here...",
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
                label: Text(ctrl.isPublishing.value ? "PUBLISHING..." : "PUBLISH MID-WEEK IBF", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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

  // Multi-line text field for bullet points
  Widget _bulletInputCell(MidWeekIBFController ctrl, String sector, int dayIndex, bool isDark) {
    return Container(
      height: 120, // Gives plenty of space for multiple lines
      padding: const EdgeInsets.all(8),
      child: TextFormField(
        initialValue: ctrl.ibfDetails[sector]![dayIndex],
        maxLines: null, // Allows the text field to expand and scroll internally
        expands: true,
        keyboardType: TextInputType.multiline,
        style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black, height: 1.5),
        decoration: InputDecoration(
          hintText: "• Type hazard/impacts...\n• Recommended actions...",
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