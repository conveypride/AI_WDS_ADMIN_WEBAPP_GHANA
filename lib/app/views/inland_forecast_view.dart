import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'package:weather_admin_dashboard/app/views/widgets/risk_InfoSidePanel.dart';
import '../controllers/inland_forecast_controller.dart';
import 'widgets/inland_map_widget.dart';

class InlandForecastView extends StatelessWidget {
  const InlandForecastView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(InlandForecastController());
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
              Tab(icon: Icon(PhosphorIcons.clockCounterClockwise()), text: "HISTORY"),
              Tab(icon: Icon(PhosphorIcons.table()), text: "INPUT TABLE"),
              Tab(icon: Icon(PhosphorIcons.mapTrifold()), text: "IBF MAPS"),
            ],
          ),
        ),
        
        // ── TAB CONTENT ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: ctrl.tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _HistoryTab(ctrl: ctrl),
              _InputTableTab(ctrl: ctrl),
              _IbfMapsTab(ctrl: ctrl),
            ],
          ),
        )
      ],
    );
  }
}

// ============================================================================
// TAB 1: HISTORY
// ============================================================================
class _HistoryTab extends StatelessWidget {
  final InlandForecastController ctrl;
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
          Text(
            "Inland Forecast Archives", 
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: wc.textPrimary,
            ) ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                      itemCount: ctrl.history.length, 
                      separatorBuilder: (_, __) => Divider(height: 1, color: wc.borderSoft),
                      itemBuilder: (ctx, idx) {
                        final item = ctrl.history[idx];
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
                                )
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
// TAB 2: INPUT TABLE (STRICT VALIDATION REQUIRED)
// ============================================================================
class _InputTableTab extends StatelessWidget {
  final InlandForecastController ctrl;
  const _InputTableTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CYCLE & SUMMARY
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Forecast Cycle:", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary, fontSize: 14)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: ctrl.activeCycleIndex.value,
                        dropdownColor: wc.elevated,
                        icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
                        style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary, fontSize: 14),
                        decoration: _inputDecoration("", wc, isDropdown: true),
                        items: ctrl.forecastCycles.asMap().entries.map((e) => DropdownMenuItem(
                          value: e.key, 
                          child: Text("${e.value['label']} (Issue: ${e.value['issue']} | Valid: ${e.value['valid']})")
                        )).toList(),
                        onChanged: (val) { if(val != null) ctrl.setCycle(val); },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text("Weather Summary", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: ctrl.weatherSummary.value, 
                  maxLines: 3, 
                  onChanged: (v) => ctrl.weatherSummary.value = v,
                  decoration: _inputDecoration("Enter the general inland weather summary...", wc),
                  style: TextStyle(color: wc.textPrimary, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // 3. DISTRICTS MATRIX TABLE (Searchable Dropdowns)
          Text("Districts Forecast Matrix", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: wc.textPrimary)),
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
                final periods = ctrl.currentPeriods; 
                return Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(color: wc.borderSoft, width: 1),
                    verticalInside: BorderSide(color: wc.borderSoft, width: 1),
                  ),
                  columnWidths: const { 
                    0: FixedColumnWidth(140), 
                    1: FlexColumnWidth(1), 
                    2: FlexColumnWidth(1), 
                    3: FlexColumnWidth(1), 
                    4: FlexColumnWidth(1) 
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: wc.elevated), 
                      children: [
                        _headerCell("DISTRICTS", context), 
                        _headerCell(periods[0], context), 
                        _headerCell(periods[1], context), 
                        _headerCell(periods[2], context), 
                        _headerCell("WIND DIR/SPEED", context)
                      ]
                    ),
                    ...ctrl.districts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final dist = entry.value;

                      return TableRow(
                        decoration: BoxDecoration(
                          color: index.isEven ? Colors.transparent : wc.elevated.withOpacity(0.3)
                        ),
                        children: [
                          Container(
                            height: 60, 
                            padding: const EdgeInsets.all(8), 
                            alignment: Alignment.center, 
                            child: Text(
                              dist, 
                              textAlign: TextAlign.center, 
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: wc.textPrimary)
                            )
                          ),
                          _weatherAutocompleteCell(dist, 'p1', context),
                          _weatherAutocompleteCell(dist, 'p2', context),
                          _weatherAutocompleteCell(dist, 'p3', context),
                          _textInputCellGeneralDist(dist, 'wind', context), 
                        ],
                      );
                    })
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 40),

          // PROCEED BUTTON
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: ctrl.proceedToMaps,
              icon: Icon(PhosphorIcons.arrowRight(), size: 18), 
              label: const Text("PROCEED TO IBF MAPS", style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue, 
                foregroundColor: Colors.white, 
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: AppTheme.accentBlue.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- UI Helpers ---
  Widget _headerCell(String text, BuildContext context) {
    return Container(
      height: 50, 
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

  Widget _textInputCellGeneralDist(String dist, String key, BuildContext context) {
    final wc = context.wColors;
    return Padding(
      padding: const EdgeInsets.all(8.0), 
      child: TextFormField(
        initialValue: ctrl.districtData[dist]![key], 
        textAlign: TextAlign.center, 
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: wc.textPrimary), 
        decoration: InputDecoration(
          hintText: "e.g. NE/08KT", 
          hintStyle: TextStyle(fontSize: 10, color: wc.textMuted), 
          border: InputBorder.none, 
          isDense: true, 
          contentPadding: EdgeInsets.zero
        ), 
        onChanged: (v) => ctrl.updateDistrictData(dist, key, v)
      )
    );
  }

  // SEARCHABLE WEATHER DROPDOWN
  Widget _weatherAutocompleteCell(String district, String key, BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: ctrl.districtData[district]![key]),
        optionsBuilder: (tv) => tv.text.isEmpty ? ctrl.weatherOptions : ctrl.weatherOptions.where((opt) => opt.toLowerCase().contains(tv.text.toLowerCase())),
        onSelected: (val) => ctrl.updateDistrictData(district, key, val),
        fieldViewBuilder: (ctx, tCtrl, focus, onEdit) => TextFormField(
          controller: tCtrl, 
          focusNode: focus, 
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accentBlue),
          decoration: InputDecoration(
            hintText: "Condition...", 
            hintStyle: TextStyle(fontSize: 10, color: wc.textMuted), 
            border: InputBorder.none, 
            isDense: true, 
            contentPadding: EdgeInsets.zero
          ),
          onChanged: (val) => ctrl.updateDistrictData(district, key, val),
        ),
        optionsViewBuilder: (ctx, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8, 
            color: wc.elevated,
            borderRadius: BorderRadius.circular(8),
            shadowColor: Colors.black.withOpacity(0.3),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 160),
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
                      style: TextStyle(fontSize: 11, color: wc.textPrimary, fontWeight: FontWeight.w600)
                    )
                  )
                ),
              )
            )
          )
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 3: IBF MAPS (3 MAPS dynamically labeled)
// ============================================================================
class _IbfMapsTab extends StatelessWidget {
  final InlandForecastController ctrl;
  const _IbfMapsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. GENERAL 12/24 HR TABLE
          Text("General Forecast Parameters", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: wc.textPrimary)),
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
              child: Obx(() => Table(
                border: TableBorder(
                  horizontalInside: BorderSide(color: wc.borderSoft, width: 1),
                  verticalInside: BorderSide(color: wc.borderSoft, width: 1),
                ),
                columnWidths: const { 0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1) },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: wc.elevated), 
                    children: [_headerCell("PARAMETER", context), _headerCell("12 HOURS", context), _headerCell("24 HOURS", context)]
                  ),
                  ...ctrl.generalParams.asMap().entries.map((entry) {
                    final index = entry.key;
                    final param = entry.value;

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
                        _textInputCellGeneral(param, '12h', ctrl.generalTable[param]!['12h'], context),
                        _textInputCellGeneral(param, '24h', ctrl.generalTable[param]!['24h'], context),
                      ],
                    );
                  })
                ],
              )),
            ),
          ),

          const SizedBox(height: 48),

          Text("Inland Impact-Based Maps", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: wc.textPrimary)),
          const SizedBox(height: 24),
          
          // 3 MAPS ROW (Dynamically titled based on Cycle)
          SizedBox(
            height: 480, 
            child: Obx(() {
              final periods = ctrl.currentPeriods;
              if (periods.isEmpty) return const SizedBox(); // Safety check

              return Row(
                children: [
                  Expanded(child: _mapWrapper(InlandMapWidget(ctrl: ctrl, period: 'p1', title: periods[0], isDark: isDark), context)),
                  const SizedBox(width: 16),
                  Expanded(child: _mapWrapper(InlandMapWidget(ctrl: ctrl, period: 'p2', title: periods[1], isDark: isDark), context)),
                  const SizedBox(width: 16),
                  Expanded(child: _mapWrapper(InlandMapWidget(ctrl: ctrl, period: 'p3', title: periods[2], isDark: isDark), context)),
                ],
              );
            }),
          ),
          
          const SizedBox(height: 32),
          InfoSidePanel(ctrl: ctrl, isDark: isDark), // Keep existing panel implementation

          const SizedBox(height: 48),
          
          // PUBLISH BUTTON
          Center(
            child: Obx(() {
              return ElevatedButton.icon(
                onPressed: ctrl.isPublishing.value ? null : ctrl.publishForecast,
                icon: ctrl.isPublishing.value 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Icon(PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill), size: 22),
                label: Text(
                  ctrl.isPublishing.value ? "PUBLISHING..." : "PUBLISH INLAND FORECAST", 
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

  // --- UI Helpers ---
  Widget _mapWrapper(Widget child, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.wColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _headerCell(String text, BuildContext context) {
    return Container(
      height: 50, 
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
  
  Widget _textInputCellGeneral(String param, String period, String val, BuildContext context) {
    final wc = context.wColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), 
      child: TextFormField(
        initialValue: val, 
        textAlign: TextAlign.center, 
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: wc.textPrimary), 
        decoration: InputDecoration(
          border: InputBorder.none, 
          isDense: true, 
          hintText: "-",
          hintStyle: TextStyle(color: wc.textMuted),
        ), 
        onChanged: (v) => ctrl.updateGeneralTable(param, period, v)
      )
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE DECORATION AND WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
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
// import 'package:weather_admin_dashboard/app/views/widgets/risk_InfoSidePanel.dart';
// import '../controllers/inland_forecast_controller.dart';
// import 'widgets/inland_map_widget.dart';

// class InlandForecastView extends StatelessWidget {
//   const InlandForecastView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ctrl = Get.put(InlandForecastController());
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final primaryColor = isDark ? Colors.blueAccent : const Color(0xFF0B4EA2);

//     return Column(
//       children: [
//         Container(
//           color: isDark ? const Color(0xFF252525) : Colors.white,
//           child: TabBar(
//             controller: ctrl.tabController, labelColor: primaryColor, unselectedLabelColor: Colors.grey, indicatorColor: primaryColor, indicatorWeight: 3,
//             labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 13),
//             tabs: [
//               Tab(icon: Icon(PhosphorIcons.clockCounterClockwise()), text: "HISTORY"),
//               Tab(icon: Icon(PhosphorIcons.table()), text: "INPUT TABLE"),
//               Tab(icon: Icon(PhosphorIcons.mapTrifold()), text: "IBF MAPS"),
//             ],
//           ),
//         ),
//         Expanded(
//           child: TabBarView(
//             controller: ctrl.tabController,
//             physics: const NeverScrollableScrollPhysics(),
//             children: [
//               _HistoryTab(ctrl: ctrl, isDark: isDark),
//               _InputTableTab(ctrl: ctrl, isDark: isDark),
//               _IbfMapsTab(ctrl: ctrl, isDark: isDark),
//             ],
//           ),
//         )
//       ],
//     );
//   }
// }

// // ============================================================================
// // TAB 1: HISTORY
// // ============================================================================
// class _HistoryTab extends StatelessWidget {
//   final InlandForecastController ctrl;
//   final bool isDark;
//   const _HistoryTab({required this.ctrl, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     final headerStyle = GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey);
//     final cellStyle = TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13);

//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text("Inland Forecast Archives", style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
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
//                       itemCount: ctrl.history.length, separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
//                       itemBuilder: (ctx, idx) {
//                         final item = ctrl.history[idx];
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

// // ============================================================================
// // TAB 2: INPUT TABLE (STRICT VALIDATION REQUIRED)
// // ============================================================================
// class _InputTableTab extends StatelessWidget {
//   final InlandForecastController ctrl;
//   final bool isDark;
//   const _InputTableTab({required this.ctrl, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 1. CYCLE & SUMMARY
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text("Forecast Cycle:", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         decoration: BoxDecoration(border: Border.all(color: Colors.blue), borderRadius: BorderRadius.circular(8), color: Colors.blue.withOpacity(0.05)),
//                         child: DropdownButtonHideUnderline(
//                           child: Obx(() => DropdownButton<int>(
//                             isExpanded: true, value: ctrl.activeCycleIndex.value, dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
//                             style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, color: Colors.blue),
//                             items: ctrl.forecastCycles.asMap().entries.map((e) => DropdownMenuItem(value: e.key, child: Text("${e.value['label']} (Issue: ${e.value['issue']} | Valid: ${e.value['valid']})"))).toList(),
//                             onChanged: (val) { if(val != null) ctrl.setCycle(val); },
//                           )),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 Text("Weather Summary", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   initialValue: ctrl.weatherSummary.value, maxLines: 3, onChanged: (v) => ctrl.weatherSummary.value = v,
//                   decoration: InputDecoration(hintText: "Enter the general inland weather summary...", filled: true, fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
//                   style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13, height: 1.4),
//                 )
//               ],
//             ),
//           ),
         
//           const SizedBox(height: 32),

//           // 3. DISTRICTS MATRIX TABLE (Searchable Dropdowns)
//           Text("Districts Forecast Matrix", style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//           const SizedBox(height: 12),
//           Container(
//             decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.5)),
//             child: Obx(() {
//               final periods = ctrl.currentPeriods; // The dynamic headers
//               return Table(
//                 border: TableBorder.all(color: Colors.black, width: 1),
//                 columnWidths: const { 0: FixedColumnWidth(140), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(1) },
//                 defaultVerticalAlignment: TableCellVerticalAlignment.middle,
//                 children: [
//                   TableRow(
//                     decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200), 
//                     children: [_headerCell("DISTRICTS"), _headerCell(periods[0]), _headerCell(periods[1]), _headerCell(periods[2]), _headerCell("WIND DIR/SPEED")]
//                   ),
//                   ...ctrl.districts.map((dist) {
//                     return TableRow(
//                       decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white),
//                       children: [
//                         Container(height: 50, padding: const EdgeInsets.all(8), alignment: Alignment.center, child: Text(dist, textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 10, color: isDark ? Colors.white : Colors.black))),
//                         _weatherAutocompleteCell(dist, 'p1'),
//                         _weatherAutocompleteCell(dist, 'p2'),
//                         _weatherAutocompleteCell(dist, 'p3'),
//                         _textInputCellGeneralDist(dist, 'wind'), // Simple text field for Wind
//                       ],
//                     );
//                   })
//                 ],
//               );
//             }),
//           ),
//           const SizedBox(height: 40),

//           // PROCEED BUTTON
//           Center(
//             child: ElevatedButton.icon(
//               onPressed: ctrl.proceedToMaps,
//               icon:  Icon(PhosphorIcons.arrowRight()), label: const Text("PROCEED TO IBF MAPS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
//               style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.blue.shade600 : Colors.blue.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- UI Helpers ---
//   Widget _headerCell(String text) => Container(height: 50, padding: const EdgeInsets.all(4), alignment: Alignment.center, child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white : Colors.black)));
  
  

//   Widget _textInputCellGeneralDist(String dist, String key) {
//     return Padding(padding: const EdgeInsets.all(8.0), child: TextFormField(initialValue: ctrl.districtData[dist]![key], textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), decoration: InputDecoration(hintText: "e.g. NE/08KT", hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade500), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero), onChanged: (v) => ctrl.updateDistrictData(dist, key, v)));
//   }

//   // SEARCHABLE WEATHER DROPDOWN
//   Widget _weatherAutocompleteCell(String district, String key) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       child: Autocomplete<String>(
//         initialValue: TextEditingValue(text: ctrl.districtData[district]![key]),
//         optionsBuilder: (tv) => tv.text.isEmpty ? ctrl.weatherOptions : ctrl.weatherOptions.where((opt) => opt.toLowerCase().contains(tv.text.toLowerCase())),
//         onSelected: (val) => ctrl.updateDistrictData(district, key, val),
//         fieldViewBuilder: (ctx, tCtrl, focus, onEdit) => TextFormField(
//           controller: tCtrl, focusNode: focus, textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.blueAccent : Colors.blue.shade800),
//           decoration: InputDecoration(hintText: "Condition...", hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
//           onChanged: (val) => ctrl.updateDistrictData(district, key, val),
//         ),
//         optionsViewBuilder: (ctx, onSelected, options) => Align(
//           alignment: Alignment.topLeft,
//           child: Material(
//             elevation: 4, color: isDark ? Colors.grey.shade800 : Colors.white,
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxHeight: 200, maxWidth: 160),
//               child: ListView.builder(
//                 padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length,
//                 itemBuilder: (c, i) => InkWell(onTap: () => onSelected(options.elementAt(i)), child: Padding(padding: const EdgeInsets.all(8.0), child: Text(options.elementAt(i), style: TextStyle(fontSize: 10, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)))),
//               )
//             )
//           )
//         ),
//       ),
//     );
//   }
// }

// // ============================================================================
// // TAB 3: IBF MAPS (3 MAPS dynamically labeled)
// // ============================================================================
// class _IbfMapsTab extends StatelessWidget {
//   final InlandForecastController ctrl;
//   final bool isDark;
//   const _IbfMapsTab({required this.ctrl, required this.isDark});
// // --- UI Helpers ---
//   Widget _headerCell(String text) => Container(height: 50, padding: const EdgeInsets.all(4), alignment: Alignment.center, child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white : Colors.black)));
  
//   Widget _textInputCellGeneral(String param, String period, String val) {
//     return Padding(padding: const EdgeInsets.all(8.0), child: TextFormField(initialValue: val, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero), onChanged: (v) => ctrl.updateGeneralTable(param, period, v)));
//   }


//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [

//  const SizedBox(height: 32),

//           // 2. GENERAL 12/24 HR TABLE
//           Text("General Forecast Parameters", style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//           const SizedBox(height: 12),
//           Container(
//             decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.5)),
//             child: Obx(() => Table(
//               border: TableBorder.all(color: Colors.black, width: 1),
//               columnWidths: const { 0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1) },
//               defaultVerticalAlignment: TableCellVerticalAlignment.middle,
//               children: [
//                 TableRow(decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200), children: [_headerCell("PARAMETER"), _headerCell("12 HOURS"), _headerCell("24 HOURS")]),
//                 ...ctrl.generalParams.map((param) {
//                   return TableRow(
//                     decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white),
//                     children: [
//                       Container(padding: const EdgeInsets.all(12), child: Text(param, style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.white : Colors.black))),
//                       _textInputCellGeneral(param, '12h', ctrl.generalTable[param]!['12h']),
//                       _textInputCellGeneral(param, '24h', ctrl.generalTable[param]!['24h']),
//                     ],
//                   );
//                 })
//               ],
//             )),
//           ),

//           Text("Inland Impact-Based Maps", style: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//           const SizedBox(height: 24),
          
//           // 3 MAPS ROW (Dynamically titled based on Cycle)
//           SizedBox(
//             height: 480, 
//             child: Obx(() {
//               final periods = ctrl.currentPeriods;
//               if (periods.isEmpty) return const SizedBox(); // Safety check

//               return Row(
//                 children: [
//                   Expanded(child: InlandMapWidget(ctrl: ctrl, period: 'p1', title: periods[0], isDark: isDark)),
//                   const SizedBox(width: 16),
//                   Expanded(child: InlandMapWidget(ctrl: ctrl, period: 'p2', title: periods[1], isDark: isDark)),
//                   const SizedBox(width: 16),
//                   Expanded(child: InlandMapWidget(ctrl: ctrl, period: 'p3', title: periods[2], isDark: isDark)),
//                 ],
//               );
//             }),
//           ),
//             const SizedBox(height: 24),
// InfoSidePanel(ctrl: ctrl, isDark: isDark),

//           const SizedBox(height: 40),
          
//           Center(
//             child: Obx(() {
//               return ElevatedButton.icon(
//                 onPressed: ctrl.isPublishing.value ? null : ctrl.publishForecast,
//                 icon: ctrl.isPublishing.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill), size: 22),
//                 label: Text(ctrl.isPublishing.value ? "PUBLISHING..." : "PUBLISH INLAND FORECAST", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
//                 style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.green.shade600 : Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }
// }