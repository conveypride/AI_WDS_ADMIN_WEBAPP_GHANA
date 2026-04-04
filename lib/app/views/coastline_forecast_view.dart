import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/controllers/coastline_forecast_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'package:weather_admin_dashboard/app/views/widgets/risk_InfoSidePanel.dart'; 
import 'widgets/coastline_map_widget.dart';

class CoastlineForecastView extends StatelessWidget {
  const CoastlineForecastView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CoastlineForecastController());
    final wc = context.wColors;

    return Column(
      children: [
        // ── TAB BAR ──────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: wc.card,
            border: Border(bottom: BorderSide(color: wc.border)),
          ),
          child: TabBar(
            controller: ctrl.tabController, 
            labelColor: AppTheme.accentBlue, 
            unselectedLabelColor: wc.textMuted, 
            indicatorColor: AppTheme.accentBlue, 
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, 
              fontSize: 13,
              letterSpacing: 0.5,
            ),
            tabs: [
              Tab(icon: Icon(PhosphorIcons.clockCounterClockwise()), text: "COASTLINE HISTORY"),
              Tab(icon: Icon(PhosphorIcons.anchor()), text: "COASTLINE INPUT"),
            ],
          ),
        ),
        // ── TAB CONTENT ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: ctrl.tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _CoastlineHistoryTab(ctrl: ctrl),
              _CoastlineInputTab(ctrl: ctrl),
            ],
          ),
        )
      ],
    );
  }
}

// ============================================================================
// TAB 1: COASTLINE HISTORY
// ============================================================================
class _CoastlineHistoryTab extends StatelessWidget {
  final CoastlineForecastController ctrl;

  const _CoastlineHistoryTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;
    
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Coastline Forecast Archives", 
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: wc.textPrimary,
                ) ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => ctrl.tabController.animateTo(1),
                icon: Icon(PhosphorIcons.plus(), size: 18),
                label: const Text(
                  "NEW FORECAST",
                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 4,
                  shadowColor: AppTheme.accentBlue.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: wc.card, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: wc.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: wc.elevated, 
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      border: Border(bottom: BorderSide(color: wc.borderSoft)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: _buildHeader("ID", context)),
                        Expanded(flex: 3, child: _buildHeader("VALIDITY", context)),
                        Expanded(flex: 2, child: _buildHeader("AUTHOR", context)),
                        Expanded(flex: 2, child: _buildHeader("STATUS", context)),
                        Expanded(flex: 1, child: _buildHeader("", context)),
                      ],
                    ),
                  ),
                  
                  // Table Rows
                  Expanded(
                    child: Obx(() => ListView.separated(
                      itemCount: ctrl.coastlineHistory.length, 
                      separatorBuilder: (_, __) => Divider(height: 1, color: wc.borderSoft),
                      itemBuilder: (ctx, idx) {
                        final item = ctrl.coastlineHistory[idx];
                        final isPublished = item['status'] == 'Published';
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(flex: 1, child: Text(item['id'], style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary))),
                              Expanded(flex: 3, child: Text(item['validity'], style: TextStyle(color: wc.textSecondary, fontWeight: FontWeight.w500))),
                              Expanded(flex: 2, child: Text(item['author'], style: TextStyle(color: wc.textSecondary, fontWeight: FontWeight.w500))),
                              Expanded(
                                flex: 2, 
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                                    decoration: BoxDecoration(
                                      color: isPublished ? AppTheme.successGreen.withOpacity(0.1) : AppTheme.warningAmber.withOpacity(0.1), 
                                      borderRadius: BorderRadius.circular(20), 
                                    ), 
                                    child: Text(
                                      item['status'], 
                                      style: TextStyle(
                                        fontSize: 11, 
                                        fontWeight: FontWeight.w800, 
                                        color: isPublished ? AppTheme.successGreen : AppTheme.warningAmber,
                                        letterSpacing: 0.3,
                                      )
                                    )
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1, 
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _ActionBtn(icon: PhosphorIcons.eye(), color: AppTheme.accentBlue)
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildHeader(String text, BuildContext context) {
    return Text(
      text, 
      style: TextStyle(
        fontWeight: FontWeight.w800, 
        fontSize: 11, 
        color: context.wColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ============================================================================
// TAB 2: COASTLINE INPUT
// ============================================================================
class _CoastlineInputTab extends StatelessWidget {
  final CoastlineForecastController ctrl;

  const _CoastlineInputTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Coastline & Maritime Forecast", 
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: wc.textPrimary,
            ) ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // 1. DATE, TIME & SUMMARY SECTION
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Issue & Validity Selectors
                Row(
                  children: [
                    Expanded(child: _buildDateTimeSelector(context, "ISSUE TIME", ctrl.issueDate, ctrl.issueTime, AppTheme.accentBlue)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildDateTimeSelector(context, "VALID TIME", ctrl.validDate, ctrl.validTime, AppTheme.successGreen)),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Weather Summary Textbox
                Text("Weather Summary", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: ctrl.weatherSummary.value,
                  maxLines: 4,
                  onChanged: (v) => ctrl.weatherSummary.value = v,
                  decoration: _inputDecoration("Enter the general weather summary for the coastline...", wc),
                  style: TextStyle(color: wc.textPrimary, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. SEA STATE & WARNINGS
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("State of the Sea", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: ctrl.stateOfSea.value,
                  dropdownColor: wc.elevated,
                  style: TextStyle(fontWeight: FontWeight.w600, color: wc.textPrimary, fontSize: 14),
                  decoration: _inputDecoration("", wc, isDropdown: true),
                  icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
                  items: ctrl.seaStateOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (val) { if(val != null) ctrl.stateOfSea.value = val; },
                ),
                const SizedBox(height: 24),
                
                Text("Warning / Important Notes", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.warningAmber)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: ctrl.warningText.value,
                  onChanged: (v) => ctrl.warningText.value = v,
                  decoration: InputDecoration(
                    hintText: "e.g. WARNING: MAX WAVE CURRENT RANGE...",
                    hintStyle: TextStyle(color: AppTheme.warningAmber.withOpacity(0.5)),
                    filled: true, 
                    fillColor: AppTheme.warningAmber.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.warningAmber.withOpacity(0.3))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.warningAmber.withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.warningAmber, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 3. TABLE & MAP ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TABLE (Left Side)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Forecast Parameters", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: wc.textPrimary)),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: wc.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: wc.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Obx(() {
                          return Table(
                            border: TableBorder(
                              horizontalInside: BorderSide(color: wc.borderSoft, width: 1),
                              verticalInside: BorderSide(color: wc.borderSoft, width: 1),
                            ),
                            columnWidths: const { 
                              0: FlexColumnWidth(1.2), 
                              1: FlexColumnWidth(1), 
                              2: FlexColumnWidth(1) 
                            },
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: wc.elevated),
                                children: [
                                  _headerCell("PARAMETER", context), 
                                  _headerCell("12 HOURS", context), 
                                  _headerCell("24 HOURS", context)
                                ],
                              ),
                              ...ctrl.parameters.asMap().entries.map((entry) {
                                final index = entry.key;
                                final param = entry.value;
                                final data = ctrl.tableData[param]!;
                                
                                return TableRow(
                                  decoration: BoxDecoration(
                                    color: index.isEven ? Colors.transparent : wc.elevated.withOpacity(0.3)
                                  ),
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16), 
                                      child: Text(
                                        param, 
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: wc.textPrimary)
                                      )
                                    ),
                                    _textInputCell(param, '12h', data['12h'], context),
                                    _textInputCell(param, '24h', data['24h'], context),
                                  ],
                                );
                              })
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 32),

              // IBF MAP (Right Side)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Impact-Based Map", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: wc.textPrimary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "EEZ Limit: 200NM", 
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.accentBlue)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 540, 
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: wc.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CoastlineMapWidget(ctrl: ctrl, isDark: isDark), // Keeping isDark for map specific tiles
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          InfoSidePanel(ctrl: ctrl, isDark: isDark), // Retaining original panel

          const SizedBox(height: 48),
          
          // PUBLISH BUTTON
          Center(
            child: Obx(() {
              return ElevatedButton.icon(
                onPressed: ctrl.isPublishing.value ? null : ctrl.publishForecast,
                icon: ctrl.isPublishing.value 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Icon(PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill), size: 20),
                label: Text(
                  ctrl.isPublishing.value ? "PUBLISHING..." : "PUBLISH COASTLINE FORECAST", 
                  style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen, 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  shadowColor: AppTheme.successGreen.withOpacity(0.4),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  BoxDecoration _cardDecoration(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;
    return BoxDecoration(
      color: wc.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: wc.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, WColors wc, {bool isDropdown = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: wc.textMuted, fontSize: 13),
      filled: true, 
      fillColor: wc.elevated,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5), width: 1.5)),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isDropdown ? 14 : 16),
    );
  }

  Widget _buildDateTimeSelector(BuildContext context, String label, Rx<DateTime> dateObs, RxString timeObs, Color themeColor) {
    final wc = context.wColors;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: themeColor, letterSpacing: 1)
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Date Picker
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: dateObs.value, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (d != null) dateObs.value = d;
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.05), 
                    borderRadius: BorderRadius.circular(10), 
                    border: Border.all(color: themeColor.withOpacity(0.3))
                  ),
                  child: Row(children: [
                    Icon(PhosphorIcons.calendarBlank(), color: themeColor, size: 18), 
                    const SizedBox(width: 10),
                    Obx(() => Text(
                      DateFormat('dd MMM yyyy').format(dateObs.value), 
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: wc.textPrimary)
                    )),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Z-Time Dropdown
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: timeObs.value,
                dropdownColor: wc.elevated,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: wc.textPrimary),
                icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: wc.elevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: ctrl.zTimeOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (val) { if(val != null) timeObs.value = val; },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerCell(String text, BuildContext context) {
    return Container(
      height: 55, 
      padding: const EdgeInsets.all(4), 
      alignment: Alignment.center, 
      child: Text(
        text, 
        textAlign: TextAlign.center, 
        style: TextStyle(
          fontWeight: FontWeight.w800, 
          fontSize: 10, 
          color: context.wColors.textSecondary,
          letterSpacing: 0.5,
        )
      )
    );
  }

  Widget _textInputCell(String param, String period, String value, BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextFormField(
        initialValue: value, 
        maxLines: null, 
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: wc.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none, 
          isDense: true, 
          hintText: "-",
          hintStyle: TextStyle(color: wc.textMuted),
        ),
        onChanged: (val) => ctrl.updateTableData(param, period, val),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  
  const _ActionBtn({required this.icon, required this.color});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? widget.color.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:weather_admin_dashboard/app/controllers/coastline_forecast_controller.dart';
// import 'package:weather_admin_dashboard/app/views/widgets/risk_InfoSidePanel.dart'; 
// import 'widgets/coastline_map_widget.dart';

// class CoastlineForecastView extends StatelessWidget {
//   const CoastlineForecastView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ctrl = Get.put(CoastlineForecastController());
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final primaryColor = isDark ? Colors.blueAccent : const Color(0xFF0B4EA2);

//     return Column(
//       children: [
//         // TAB BAR
//         Container(
//           color: isDark ? const Color(0xFF252525) : Colors.white,
//           child: TabBar(
//             controller: ctrl.tabController, labelColor: primaryColor, unselectedLabelColor: Colors.grey, indicatorColor: primaryColor, indicatorWeight: 3,
//             labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 13),
//             tabs: [
//               Tab(icon: Icon(PhosphorIcons.clockCounterClockwise()), text: "COASTLINE HISTORY"),
//               Tab(icon: Icon(PhosphorIcons.anchor()), text: "COASTLINE INPUT"),
//             ],
//           ),
//         ),
//         // TAB CONTENT
//         Expanded(
//           child: TabBarView(
//             controller: ctrl.tabController,
//             physics: const NeverScrollableScrollPhysics(),
//             children: [
//               _CoastlineHistoryTab(ctrl: ctrl, isDark: isDark),
//               _CoastlineInputTab(ctrl: ctrl, isDark: isDark),
//             ],
//           ),
//         )
//       ],
//     );
//   }
// }

// // --- COASTLINE HISTORY TAB ---
// class _CoastlineHistoryTab extends StatelessWidget {
//   final CoastlineForecastController ctrl;
//   final bool isDark;
//   const _CoastlineHistoryTab({required this.ctrl, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     final headerStyle = GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey);
//     final cellStyle = TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13);

//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text("Coastline Forecast Archives", style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//           const SizedBox(height: 16),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
//               child: Column(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
//                     child: Row(children: [
//                       Expanded(flex: 1, child: Text("ID", style: headerStyle)),
//                       Expanded(flex: 3, child: Text("VALIDITY", style: headerStyle)),
//                       Expanded(flex: 2, child: Text("AUTHOR", style: headerStyle)),
//                       Expanded(flex: 2, child: Text("STATUS", style: headerStyle)),
//                       Expanded(flex: 1, child: Text("", style: headerStyle)),
//                     ]),
//                   ),
//                   Expanded(
//                     child: Obx(() => ListView.separated(
//                       itemCount: ctrl.coastlineHistory.length, separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
//                       itemBuilder: (ctx, idx) {
//                         final item = ctrl.coastlineHistory[idx];
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                           child: Row(children: [
//                             Expanded(flex: 1, child: Text(item['id'], style: cellStyle.copyWith(fontWeight: FontWeight.bold))),
//                             Expanded(flex: 3, child: Text(item['validity'], style: cellStyle)),
//                             Expanded(flex: 2, child: Text(item['author'], style: cellStyle)),
//                             Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green)), child: Text(item['status'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)))),
//                             Expanded(flex: 1, child: IconButton(icon: Icon(PhosphorIcons.eye(), color: Colors.blue), onPressed: (){})),
//                           ]),
//                         );
//                       }
//                     )),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // --- COASTLINE INPUT TAB --- 
// class _CoastlineInputTab extends StatelessWidget {
//   final CoastlineForecastController ctrl;
//   final bool isDark;
//   const _CoastlineInputTab({required this.ctrl, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text("Coastline & Maritime Forecast", style: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//           const SizedBox(height: 24),

//           // 1. DATE, TIME & SUMMARY SECTION
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Issue & Validity Selectors
//                 Row(
//                   children: [
//                     Expanded(child: _buildDateTimeSelector(context, "ISSUE TIME", ctrl.issueDate, ctrl.issueTime, Colors.blue)),
//                     const SizedBox(width: 16),
//                     Expanded(child: _buildDateTimeSelector(context, "VALID TIME", ctrl.validDate, ctrl.validTime, Colors.green)),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
                
//                 // Weather Summary Textbox
//                 Text("Weather Summary", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   initialValue: ctrl.weatherSummary.value,
//                   maxLines: 4,
//                   onChanged: (v) => ctrl.weatherSummary.value = v,
//                   decoration: InputDecoration(
//                     hintText: "Enter the general weather summary for the coastline...",
//                     filled: true, fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
//                     enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
//                   ),
//                   style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13, height: 1.4),
//                 )
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),

//           // 2. SEA STATE & WARNINGS
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("State of the Sea", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
//                 const SizedBox(height: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
//                   child: DropdownButtonHideUnderline(
//                     child: Obx(() => DropdownButton<String>(
//                       isExpanded: true, value: ctrl.stateOfSea.value,
//                       dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
//                       style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
//                       items: ctrl.seaStateOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
//                       onChanged: (val) { if(val != null) ctrl.stateOfSea.value = val; },
//                     )),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text("Warning / Important Notes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   initialValue: ctrl.warningText.value,
//                   onChanged: (v) => ctrl.warningText.value = v,
//                   decoration: InputDecoration(
//                     hintText: "e.g. WARNING: MAX WAVE CURRENT RANGE...",
//                     filled: true, fillColor: isDark ? Colors.orange.shade900.withOpacity(0.1) : Colors.orange.shade50,
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.orange.shade300)),
//                     enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.orange.shade300)),
//                   ),
//                   style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
//                 )
//               ],
//             ),
//           ),
//           const SizedBox(height: 32),

//           // 3. TABLE & MAP ROW
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // TABLE (Left Side)
//               Expanded(
//                 flex: 3,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text("Forecast Parameters", style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//                     const SizedBox(height: 12),
//                     Container(
//                       decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.5)),
//                       child: Obx(() {
//                         return Table(
//                           border: TableBorder.all(color: Colors.black, width: 1),
//                           columnWidths: const { 0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1) },
//                           defaultVerticalAlignment: TableCellVerticalAlignment.middle,
//                           children: [
//                             TableRow(
//                               decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200),
//                               children: [_headerCell("PARAMETER", isDark), _headerCell("12 HOURS", isDark), _headerCell("24 HOURS", isDark)],
//                             ),
//                             ...ctrl.parameters.map((param) {
//                               final data = ctrl.tableData[param]!;
//                               return TableRow(
//                                 decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white),
//                                 children: [
//                                   Container(padding: const EdgeInsets.all(12), child: Text(param, style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white : Colors.black))),
//                                   _textInputCell(param, '12h', data['12h'], isDark),
//                                   _textInputCell(param, '24h', data['24h'], isDark),
//                                 ],
//                               );
//                             })
//                           ],
//                         );
//                       }),
//                     ),
//                   ],
//                 ),
//               ),

            
//             ],
//           ),
//   const SizedBox(height: 24),

//               // IBF MAP (Right Side)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text("Impact-Based Map", style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//                       Text("EEZ Limit: 200NM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   SizedBox(
//                     height: 480, 
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: CoastlineMapWidget(ctrl: ctrl, isDark: isDark),
//                     ),
//                   ),
//                 ],
//               ),
// const SizedBox(height: 24),
//        InfoSidePanel(ctrl: ctrl, isDark: isDark),

//           const SizedBox(height: 40),
          
//           // PUBLISH BUTTON
//           Center(
//             child: Obx(() {
//               return ElevatedButton.icon(
//                 onPressed: ctrl.isPublishing.value ? null : ctrl.publishForecast,
//                 icon: ctrl.isPublishing.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill), size: 22),
//                 label: Text(ctrl.isPublishing.value ? "PUBLISHING..." : "PUBLISH COASTLINE FORECAST", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
//                 style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.green.shade600 : Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- UI HELPERS ---

//   Widget _buildDateTimeSelector(BuildContext context, String label, Rx<DateTime> dateObs, RxString timeObs, Color themeColor) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, letterSpacing: 1)),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             // Date Picker
//             Expanded(
//               flex: 3,
//               child: InkWell(
//                 onTap: () async {
//                   final d = await showDatePicker(context: context, initialDate: dateObs.value, firstDate: DateTime(2020), lastDate: DateTime(2030));
//                   if (d != null) dateObs.value = d;
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                   decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : themeColor.withOpacity(0.05), borderRadius: BorderRadius.circular(6), border: Border.all(color: themeColor.withOpacity(0.5))),
//                   child: Row(children: [
//                     Icon(Icons.calendar_month, color: themeColor, size: 18), const SizedBox(width: 8),
//                     Obx(() => Text(DateFormat('dd MMM yyyy').format(dateObs.value), style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87))),
//                   ]),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             // Z-Time Dropdown
//             Expanded(
//               flex: 2,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
//                 decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade400)),
//                 child: DropdownButtonHideUnderline(
//                   child: Obx(() => DropdownButton<String>(
//                     isExpanded: true, value: timeObs.value,
//                     dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
//                     items: ctrl.zTimeOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
//                     onChanged: (val) { if(val != null) timeObs.value = val; },
//                   )),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _headerCell(String text, bool isDark) => Container(height: 50, padding: const EdgeInsets.all(4), alignment: Alignment.center, child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white : Colors.black)));
//   Widget _textInputCell(String param, String period, String value, bool isDark) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       child: TextFormField(
//         initialValue: value, maxLines: null, textAlign: TextAlign.center,
//         style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
//         decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
//         onChanged: (val) => ctrl.updateTableData(param, period, val),
//       ),
//     );
//   }
// }