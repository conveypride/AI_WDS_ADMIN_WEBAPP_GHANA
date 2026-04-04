import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/controllers/seven_day_forecast_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart'; 

class SevenDayForecastView extends StatelessWidget {
  const SevenDayForecastView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final ctrl = Get.put(SevenDayForecastController());
    final wc = context.wColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Tab(
                icon: Icon(PhosphorIcons.clockCounterClockwise()), 
                text: "FORECAST HISTORY"
              ),
              Tab(
                icon: Icon(PhosphorIcons.calendarPlus()), 
                text: "CREATE 7-DAY FORECAST"
              ),
            ],
          ),
        ),

        // ── TAB CONTENT ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: ctrl.tabController,
            children: [
              _HistoryTab(ctrl: ctrl),
              _CreateForecastTab(ctrl: ctrl),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 1: HISTORY & PAGINATION
// ============================================================================
class _HistoryTab extends StatelessWidget {
  final SevenDayForecastController ctrl;

  const _HistoryTab({required this.ctrl});

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
                "Archived & Draft Forecasts", 
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
                        Expanded(flex: 2, child: Text("ID", style: _colStyle(context))),
                        Expanded(flex: 3, child: Text("DATE RANGE", style: _colStyle(context))),
                        Expanded(flex: 2, child: Text("AUTHOR", style: _colStyle(context))),
                        Expanded(flex: 2, child: Text("STATUS", style: _colStyle(context))),
                        Expanded(flex: 2, child: Text("ACTIONS", style: _colStyle(context), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
                  
                  // Table Rows
                  Expanded(
                    child: Obx(() => ListView.separated(
                      itemCount: ctrl.forecastHistory.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: wc.borderSoft),
                      itemBuilder: (context, index) {
                        final item = ctrl.forecastHistory[index];
                        final isPublished = item['status'] == 'Published';
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2, 
                                child: Text(
                                  item['id'], 
                                  style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary),
                                ),
                              ),
                              Expanded(
                                flex: 3, 
                                child: Text(
                                  item['dateRange'], 
                                  style: TextStyle(color: wc.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                flex: 2, 
                                child: Text(
                                  item['author'], 
                                  style: TextStyle(color: wc.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                flex: 2, 
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPublished 
                                          ? AppTheme.successGreen.withOpacity(0.1) 
                                          : AppTheme.warningAmber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item['status'], 
                                      style: TextStyle(
                                        fontSize: 11, 
                                        fontWeight: FontWeight.w800, 
                                        color: isPublished ? AppTheme.successGreen : AppTheme.warningAmber,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2, 
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _ActionBtn(icon: PhosphorIcons.eye(), color: AppTheme.accentBlue),
                                    if (!isPublished) ...[
                                      const SizedBox(width: 8),
                                      _ActionBtn(icon: PhosphorIcons.pencilSimple(), color: AppTheme.warningAmber),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )),
                  ),

                  // Pagination Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: wc.borderSoft)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Showing recent forecasts", 
                          style: TextStyle(fontSize: 12, color: wc.textMuted, fontWeight: FontWeight.w500),
                        ),
                        Obx(() => Row(
                          children: [
                            IconButton(
                              icon: Icon(PhosphorIcons.caretLeft(), color: wc.textSecondary, size: 18), 
                              onPressed: ctrl.previousPage,
                            ),
                            Text(
                              "Page ${ctrl.currentPage.value} of ${ctrl.totalPages}", 
                              style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary, fontSize: 13),
                            ),
                            IconButton(
                              icon: Icon(PhosphorIcons.caretRight(), color: wc.textSecondary, size: 18), 
                              onPressed: ctrl.nextPage,
                            ),
                          ],
                        )),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _colStyle(BuildContext context) => TextStyle(
    fontWeight: FontWeight.w800, 
    fontSize: 11, 
    color: context.wColors.textMuted,
    letterSpacing: 0.8,
  );
}

// ============================================================================
// TAB 2: DATA ENTRY TABLE
// ============================================================================
class _CreateForecastTab extends StatelessWidget {
  final SevenDayForecastController ctrl;

  const _CreateForecastTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Date Picker
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Provide 7-Day Forecast", 
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ) ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Fill in the weather condition, probability, and min/max temperatures.", 
                    style: TextStyle(color: wc.textMuted, fontSize: 14),
                  ),
                ],
              ),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context, 
                    initialDate: ctrl.startDate.value,
                    firstDate: DateTime(2020), 
                    lastDate: DateTime(2030),
                  );
                  if (date != null) ctrl.updateStartDate(date);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.08),
                    border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)), 
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.calendarStar(), color: AppTheme.accentBlue, size: 20),
                      const SizedBox(width: 10),
                      Obx(() => Text(
                        "START DATE: ${DateFormat('dd MMM yyyy').format(ctrl.startDate.value).toUpperCase()}",
                        style: TextStyle(
                          fontWeight: FontWeight.w800, 
                          color: AppTheme.accentBlue,
                          letterSpacing: 0.5,
                          fontSize: 12,
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // The Scrollable Data Grid
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: wc.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: wc.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Obx(() {
                    final dates = ctrl.dynamicDates;
                    return Table(
                      border: TableBorder(
                        horizontalInside: BorderSide(color: wc.borderSoft, width: 1),
                        verticalInside: BorderSide(color: wc.borderSoft, width: 1),
                      ),
                      columnWidths: const {
                        0: FixedColumnWidth(110), // Location Column
                        1: FixedColumnWidth(170), // Day 1
                        2: FixedColumnWidth(170),
                        3: FixedColumnWidth(170),
                        4: FixedColumnWidth(170),
                        5: FixedColumnWidth(170),
                        6: FixedColumnWidth(170),
                        7: FixedColumnWidth(170), // Day 7
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        // HEADER ROW
                        TableRow(
                          decoration: BoxDecoration(color: wc.elevated),
                          children: [
                            _headerCell("CITY", context),
                            ...dates.map((d) => _headerCell(DateFormat('EEE, dd MMM').format(d).toUpperCase(), context)),
                          ],
                        ),
                        
                        // DATA ROWS
                        ...ctrl.locations.asMap().entries.map((entry) {
                          final rowIndex = entry.key;
                          final city = entry.value;
                          
                          return TableRow(
                            decoration: BoxDecoration(
                              color: rowIndex.isEven ? Colors.transparent : wc.elevated.withOpacity(0.3)
                            ),
                            children: [
                              // City Name
                              Container(
                                height: 105, 
                                alignment: Alignment.center,
                                child: Text(
                                  city, 
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800, 
                                    fontSize: 12, 
                                    color: wc.textPrimary,
                                  ),
                                ),
                              ),
                              
                              // 7 Days of Inputs
                              ...List.generate(7, (dayIndex) {
                                return _DayEntryCell(ctrl: ctrl, city: city, dayIndex: dayIndex);
                              })
                            ],
                          );
                        }),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),

        // Publish Button Area
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: wc.card,
            border: Border(top: BorderSide(color: wc.border)),
          ),
          child: Center(
            child: Obx(() {
              return ElevatedButton.icon(
                onPressed: ctrl.isPublishing.value ? null : ctrl.publishForecast,
                icon: ctrl.isPublishing.value 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(PhosphorIcons.cloudArrowUp(PhosphorIconsStyle.fill), size: 20),
                label: Text(
                  ctrl.isPublishing.value ? "PUBLISHING..." : "PUBLISH 7-DAY FORECAST", 
                  style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
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
        )
      ],
    );
  }

  Widget _headerCell(String text, BuildContext context) {
    return Container(
      height: 55, padding: const EdgeInsets.all(4), alignment: Alignment.center,
      child: Text(
        text, 
        textAlign: TextAlign.center, 
        style: TextStyle(
          fontWeight: FontWeight.w800, 
          fontSize: 11, 
          color: context.wColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// --- COMPLEX INPUT CELL WIDGET ---
class _DayEntryCell extends StatelessWidget {
  final SevenDayForecastController ctrl;
  final String city;
  final int dayIndex;

  const _DayEntryCell({
    required this.ctrl, 
    required this.city, 
    required this.dayIndex, 
  });

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final borderCol = wc.borderSoft;

    return Container(
      height: 105, padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // 1. Weather Condition (Searchable)
          Expanded(
            child: Autocomplete<String>(
              initialValue: TextEditingValue(text: ctrl.forecastGrid[city]![dayIndex]['cond']),
              optionsBuilder: (tv) => tv.text.isEmpty 
                  ? ctrl.weatherOptions 
                  : ctrl.weatherOptions.where((opt) => opt.toLowerCase().contains(tv.text.toLowerCase())),
              onSelected: (val) => ctrl.forecastGrid[city]![dayIndex]['cond'] = val,
              fieldViewBuilder: (ctx, tCtrl, focus, onEdit) => TextFormField(
                controller: tCtrl, 
                focusNode: focus, 
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.w700, 
                  color: AppTheme.accentBlue,
                ),
                decoration: InputDecoration(
                  hintText: "Condition...", 
                  hintStyle: TextStyle(fontSize: 10, color: wc.textMuted), 
                  border: InputBorder.none, 
                  isDense: true, 
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (val) => ctrl.forecastGrid[city]![dayIndex]['cond'] = val,
              ),
              optionsViewBuilder: (ctx, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8, 
                  borderRadius: BorderRadius.circular(8),
                  color: wc.elevated,
                  shadowColor: Colors.black.withOpacity(0.3),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 140),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8), 
                      shrinkWrap: true, 
                      itemCount: options.length,
                      itemBuilder: (c, i) => InkWell(
                        onTap: () => onSelected(options.elementAt(i)), 
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
                          child: Text(
                            options.elementAt(i), 
                            style: TextStyle(
                              fontSize: 11, 
                              color: wc.textPrimary, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                  )
                )
              ),
            ),
          ),
          Divider(height: 1, color: borderCol),
          
          // 2. Min & Max Temps
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tempInput(city, dayIndex, 'min', 'Min°', context)),
                Container(width: 1, color: borderCol),
                Expanded(child: _tempInput(city, dayIndex, 'max', 'Max°', context)),
              ],
            ),
          ),
          Divider(height: 1, color: borderCol),
          
          // 3. Probability
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Prob: ", style: TextStyle(fontSize: 10, color: wc.textMuted, fontWeight: FontWeight.w600)),
                Expanded(
                  child: Obx(() {
                    final currentProb = ctrl.forecastGrid[city]![dayIndex]['prob'];
                    
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentProb == "" ? null : currentProb,
                        isExpanded: true, 
                        icon: Icon(PhosphorIcons.caretDown(), size: 12, color: wc.textSecondary),
                        hint: Text("-", style: TextStyle(fontSize: 11, color: wc.textMuted), textAlign: TextAlign.center),
                        dropdownColor: wc.elevated,
                        borderRadius: BorderRadius.circular(8),
                        style: TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.w700, 
                          color: wc.textPrimary,
                        ),
                        items: ctrl.probOptions.map((val) => DropdownMenuItem(
                          value: val, 
                          child: Center(child: Text("$val%"))
                        )).toList(),
                        onChanged: (val) { 
                          if (val != null) { 
                            ctrl.forecastGrid[city]![dayIndex]['prob'] = val; 
                            ctrl.forecastGrid.refresh(); 
                          } 
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tempInput(String city, int dayIndex, String key, String hint, BuildContext context) {
    final wc = context.wColors;
    return TextFormField(
      initialValue: ctrl.forecastGrid[city]![dayIndex][key], 
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
      style: TextStyle(
        fontSize: 12, 
        fontWeight: FontWeight.w700, 
        color: wc.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint, 
        hintStyle: TextStyle(fontSize: 10, color: wc.textMuted), 
        border: InputBorder.none, 
        isDense: true, 
        contentPadding: const EdgeInsets.only(top: 8),
      ),
      onChanged: (val) => ctrl.forecastGrid[city]![dayIndex][key] = val,
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
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:weather_admin_dashboard/app/controllers/seven_day_forecast_controller.dart'; 

// class SevenDayForecastView extends StatelessWidget {
//   const SevenDayForecastView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Inject the controller
//     final ctrl = Get.put(SevenDayForecastController());
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final primaryColor = isDark ? Colors.blueAccent : const Color(0xFF0B4EA2);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // TAB BAR
//         Container(
//           decoration: BoxDecoration(
//             color: isDark ? const Color(0xFF252525) : Colors.white,
//             border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
//           ),
//           child: TabBar(
//             controller: ctrl.tabController,
//             labelColor: primaryColor,
//             unselectedLabelColor: Colors.grey,
//             indicatorColor: primaryColor,
//             indicatorWeight: 3,
//             labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 13),
//             tabs: [
//               Tab(icon: Icon(PhosphorIcons.clockCounterClockwise()), text: "FORECAST HISTORY"),
//               Tab(icon: Icon(PhosphorIcons.calendarPlus()), text: "CREATE 7-DAY FORECAST"),
//             ],
//           ),
//         ),

//         // TAB CONTENT
//         Expanded(
//           child: TabBarView(
//             controller: ctrl.tabController,
//             children: [
//               _HistoryTab(ctrl: ctrl, isDark: isDark),
//               _CreateForecastTab(ctrl: ctrl, isDark: isDark),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ============================================================================
// // TAB 1: HISTORY & PAGINATION
// // ============================================================================
// class _HistoryTab extends StatelessWidget {
//   final SevenDayForecastController ctrl;
//   final bool isDark;

//   const _HistoryTab({required this.ctrl, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text("Archived & Draft Forecasts", style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//               ElevButton(
//                 onPressed: () => ctrl.tabController.animateTo(1),
//                 icon: PhosphorIcons.plus(),
//                 label: "NEW FORECAST",
//                 color: isDark ? Colors.blueAccent : const Color(0xFF0B4EA2),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
          
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // Table Header
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     decoration: BoxDecoration(
//                       color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
//                       border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(flex: 2, child: Text("ID", style: _colStyle())),
//                         Expanded(flex: 3, child: Text("DATE RANGE", style: _colStyle())),
//                         Expanded(flex: 2, child: Text("AUTHOR", style: _colStyle())),
//                         Expanded(flex: 2, child: Text("STATUS", style: _colStyle())),
//                         Expanded(flex: 2, child: Text("ACTIONS", style: _colStyle(), textAlign: TextAlign.right)),
//                       ],
//                     ),
//                   ),
                  
//                   // Table Rows
//                   Expanded(
//                     child: Obx(() => ListView.separated(
//                       itemCount: ctrl.forecastHistory.length,
//                       separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
//                       itemBuilder: (context, index) {
//                         final item = ctrl.forecastHistory[index];
//                         final isPublished = item['status'] == 'Published';
                        
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                           child: Row(
//                             children: [
//                               Expanded(flex: 2, child: Text(item['id'], style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
//                               Expanded(flex: 3, child: Text(item['dateRange'], style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade800))),
//                               Expanded(flex: 2, child: Text(item['author'], style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade800))),
//                               Expanded(flex: 2, child: Row(
//                                 children: [
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                     decoration: BoxDecoration(
//                                       color: isPublished ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
//                                       borderRadius: BorderRadius.circular(4),
//                                       border: Border.all(color: isPublished ? Colors.green : Colors.orange),
//                                     ),
//                                     child: Text(item['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPublished ? Colors.green : Colors.orange)),
//                                   ),
//                                 ],
//                               )),
//                               Expanded(flex: 2, child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.end,
//                                 children: [
//                                   IconButton(icon: Icon(PhosphorIcons.eye(), size: 18, color: Colors.blue), onPressed: () {}),
//                                   if (!isPublished) IconButton(icon: Icon(PhosphorIcons.pencilSimple(), size: 18, color: Colors.orange), onPressed: () {}),
//                                 ],
//                               )),
//                             ],
//                           ),
//                         );
//                       },
//                     )),
//                   ),

//                   // Pagination Footer
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300))),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text("Showing recent forecasts", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
//                         Obx(() => Row(
//                           children: [
//                             IconButton(icon: const Icon(Icons.chevron_left), onPressed: ctrl.previousPage),
//                             Text("Page ${ctrl.currentPage.value} of ${ctrl.totalPages}", style: const TextStyle(fontWeight: FontWeight.bold)),
//                             IconButton(icon: const Icon(Icons.chevron_right), onPressed: ctrl.nextPage),
//                           ],
//                         )),
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   TextStyle _colStyle() => const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey);
// }

// // ============================================================================
// // TAB 2: DATA ENTRY TABLE
// // ============================================================================
// class _CreateForecastTab extends StatelessWidget {
//   final SevenDayForecastController ctrl;
//   final bool isDark;

//   const _CreateForecastTab({required this.ctrl, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header & Date Picker
//         Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("Provide 7-Day Forecast", style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//                   const SizedBox(height: 4),
//                   Text("Fill in the weather condition, probability, and min/max temperatures.", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 13)),
//                 ],
//               ),
//               InkWell(
//                 onTap: () async {
//                   final date = await showDatePicker(
//                     context: context, initialDate: ctrl.startDate.value,
//                     firstDate: DateTime(2020), lastDate: DateTime(2030),
//                   );
//                   if (date != null) ctrl.updateStartDate(date);
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   decoration: BoxDecoration(
//                     color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
//                     border: Border.all(color: Colors.blue), borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.calendar_month, color: Colors.blue, size: 20),
//                       const SizedBox(width: 8),
//                       Obx(() => Text(
//                         "START DATE: ${DateFormat('dd MMM yyyy').format(ctrl.startDate.value)}",
//                         style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, color: Colors.blue),
//                       )),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         // The Scrollable Data Grid
//         Expanded(
//           child: SingleChildScrollView(
//             scrollDirection: Axis.vertical,
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//               child: Container(
//                 decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.5)),
//                 child: Obx(() {
//                   final dates = ctrl.dynamicDates;
//                   return Table(
//                     border: TableBorder.all(color: Colors.black, width: 1),
//                     columnWidths: const {
//                       0: FixedColumnWidth(110), // Location Column
//                       1: FixedColumnWidth(170), // Day 1
//                       2: FixedColumnWidth(170),
//                       3: FixedColumnWidth(170),
//                       4: FixedColumnWidth(170),
//                       5: FixedColumnWidth(170),
//                       6: FixedColumnWidth(170),
//                       7: FixedColumnWidth(170), // Day 7
//                     },
//                     defaultVerticalAlignment: TableCellVerticalAlignment.middle,
//                     children: [
//                       // HEADER ROW
//                       TableRow(
//                         decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200),
//                         children: [
//                           _headerCell("CITY", isDark),
//                           ...dates.map((d) => _headerCell(DateFormat('EEE, dd MMM').format(d).toUpperCase(), isDark)),
//                         ],
//                       ),
                      
//                       // DATA ROWS
//                       ...ctrl.locations.map((city) {
//                         return TableRow(
//                           decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white),
//                           children: [
//                             // City Name
//                             Container(
//                               height: 100, alignment: Alignment.center,
//                               child: Text(city, style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 12, color: isDark ? Colors.white : Colors.black)),
//                             ),
                            
//                             // 7 Days of Inputs
//                             ...List.generate(7, (dayIndex) {
//                               return _DayEntryCell(ctrl: ctrl, city: city, dayIndex: dayIndex, isDark: isDark);
//                             })
//                           ],
//                         );
//                       }),
//                     ],
//                   );
//                 }),
//               ),
//             ),
//           ),
//         ),

//         // Publish Button Area
//         Container(
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//             border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
//           ),
//           child: Center(
//             child: Obx(() {
//               return ElevatedButton.icon(
//                 onPressed: ctrl.isPublishing.value ? null : ctrl.publishForecast,
//                 icon: ctrl.isPublishing.value 
//                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                     : Icon(PhosphorIcons.cloudArrowUp(PhosphorIconsStyle.fill), size: 22),
//                 label: Text(ctrl.isPublishing.value ? "PUBLISHING..." : "PUBLISH 7-DAY FORECAST", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: isDark ? Colors.green.shade600 : Colors.green.shade700,
//                   foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//               );
//             }),
//           ),
//         )
//       ],
//     );
//   }

//   Widget _headerCell(String text, bool isDark) {
//     return Container(
//       height: 50, padding: const EdgeInsets.all(4), alignment: Alignment.center,
//       child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white : Colors.black)),
//     );
//   }
// }

// // --- COMPLEX INPUT CELL WIDGET ---
//  // --- COMPLEX INPUT CELL WIDGET ---
// class _DayEntryCell extends StatelessWidget {
//   final SevenDayForecastController ctrl;
//   final String city;
//   final int dayIndex;
//   final bool isDark;

//   const _DayEntryCell({required this.ctrl, required this.city, required this.dayIndex, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     final borderCol = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

//     return Container(
//       height: 100, padding: const EdgeInsets.all(4),
//       child: Column(
//         children: [
//           // 1. Weather Condition (Searchable)
//           Expanded(
//             child: Autocomplete<String>(
//               initialValue: TextEditingValue(text: ctrl.forecastGrid[city]![dayIndex]['cond']),
//               optionsBuilder: (tv) => tv.text.isEmpty ? ctrl.weatherOptions : ctrl.weatherOptions.where((opt) => opt.toLowerCase().contains(tv.text.toLowerCase())),
//               onSelected: (val) => ctrl.forecastGrid[city]![dayIndex]['cond'] = val,
//               fieldViewBuilder: (ctx, tCtrl, focus, onEdit) => TextFormField(
//                 controller: tCtrl, focusNode: focus, textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.blueAccent : Colors.blue.shade800),
//                 decoration: InputDecoration(hintText: "Condition...", hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
//                 onChanged: (val) => ctrl.forecastGrid[city]![dayIndex]['cond'] = val,
//               ),
//               optionsViewBuilder: (ctx, onSelected, options) => Align(
//                 alignment: Alignment.topLeft,
//                 child: Material(
//                   elevation: 4, color: isDark ? Colors.grey.shade800 : Colors.white,
//                   child: ConstrainedBox(
//                     constraints: const BoxConstraints(maxHeight: 200, maxWidth: 120),
//                     child: ListView.builder(
//                       padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length,
//                       itemBuilder: (c, i) => InkWell(onTap: () => onSelected(options.elementAt(i)), child: Padding(padding: const EdgeInsets.all(8.0), child: Text(options.elementAt(i), style: TextStyle(fontSize: 10, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)))),
//                     )
//                   )
//                 )
//               ),
//             ),
//           ),
//           Divider(height: 1, color: borderCol),
          
//           // 2. Min & Max Temps
//           Expanded(
//             child: Row(
//               children: [
//                 Expanded(child: _tempInput(city, dayIndex, 'min', 'Min°')),
//                 Container(width: 1, color: borderCol),
//                 Expanded(child: _tempInput(city, dayIndex, 'max', 'Max°')),
//               ],
//             ),
//           ),
//           Divider(height: 1, color: borderCol),
          
//           // 3. Probability (FIXED: Now wrapped in Obx)
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text("Prob: ", style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
//                 Expanded(
//                   child: Obx(() {
//                     // Extracting the value INSIDE the Obx registers the listener
//                     final currentProb = ctrl.forecastGrid[city]![dayIndex]['prob'];
                    
//                     return DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: currentProb == "" ? null : currentProb,
//                         isExpanded: true, iconSize: 14,
//                         hint: Text("-", style: TextStyle(fontSize: 10, color: Colors.grey.shade400), textAlign: TextAlign.center),
//                         dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
//                         style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
//                         // Added the % sign back for better UI display
//                         items: ctrl.probOptions.map((val) => DropdownMenuItem(value: val, child: Center(child: Text("$val%")))).toList(),
//                         onChanged: (val) { 
//                           if (val != null) { 
//                             ctrl.forecastGrid[city]![dayIndex]['prob'] = val; 
//                             ctrl.forecastGrid.refresh(); // Tells GetX to redraw this specific dropdown
//                           } 
//                         },
//                       ),
//                     );
//                   }),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Refactored helper to directly update the controller's grid
//   Widget _tempInput(String city, int dayIndex, String key, String hint) {
//     return TextFormField(
//       initialValue: ctrl.forecastGrid[city]![dayIndex][key], textAlign: TextAlign.center,
//       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//       inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
//       style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
//       decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(fontSize: 9, color: Colors.grey.shade400), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.only(top: 8)),
//       onChanged: (val) => ctrl.forecastGrid[city]![dayIndex][key] = val,
//     );
//   }
// }

// // Helper Button Widget
// class ElevButton extends StatelessWidget {
//   final VoidCallback onPressed;
//   final IconData icon;
//   final String label;
//   final Color color;

//   const ElevButton({super.key, required this.onPressed, required this.icon, required this.label, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//       style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
//     );
//   }
// }