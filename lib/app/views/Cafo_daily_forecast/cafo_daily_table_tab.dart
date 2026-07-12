import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:weather_admin_dashboard/app/controllers/cafo_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

class DailyTableTab extends StatelessWidget {
  final CAFOController ctrl;
  final VoidCallback onNext;

  const DailyTableTab({
    super.key, 
    required this.ctrl, 
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    // FIX: Changed from Padding to SingleChildScrollView to allow the whole screen to scroll
    // if the browser window is shrunk or viewed on a small laptop.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── SUMMARY AND TIME CONTROLS ──────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SUMMARY:", 
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: wc.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: wc.elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: wc.border),
                      ),
                      child: TextField(
                        controller: ctrl.summaryController,
                        maxLines: 3, 
                        style: TextStyle(
                          fontSize: 14, 
                          height: 1.6, 
                          color: wc.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: "Mist or fog patches are expected to develop...",
                          hintStyle: TextStyle(color: wc.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              
              // Issue Time Panel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.08),
                  border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ISSUE TIME (UTC)", 
                      style: TextStyle(
                        fontWeight: FontWeight.w700, 
                        fontSize: 11, 
                        color: AppTheme.accentBlue,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(() => DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: ctrl.selectedIssueTime.value,
                        icon: Icon(PhosphorIcons.caretDown(), size: 13, color: AppTheme.accentBlue),
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w800, 
                          fontSize: 18, 
                          color: AppTheme.accentBlue,
                        ),
                        dropdownColor: wc.elevated,
                        items:  ctrl.issueTimeOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value, 
                            child: Text("$value UTC"),
                          );
                        }).toList(),
                        onChanged: (newValue) { 
                          if (newValue != null) ctrl.updateIssueTime(newValue);
                        },
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // ── NB FIELD ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.infoCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.infoCyan.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.info(), size: 18, color: AppTheme.infoCyan),
                const SizedBox(width: 8),
                Text(
                  "NB: ", 
                  style: TextStyle(
                    fontWeight: FontWeight.w800, 
                    fontSize: 14, 
                    color: AppTheme.infoCyan,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: ctrl.nbController,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600, 
                      color: wc.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: "Relatively cool night and early morning temperatures...",
                      hintStyle: TextStyle(color: wc.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── EXCEL IMPORT / EXPORT ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: ctrl.downloadCSVTemplate,
                child: Row(
                  children: [
                    Icon(PhosphorIcons.downloadSimple(), size: 16, color: AppTheme.accentBlue),
                    const SizedBox(width: 6),
                    Text(
                      "DOWNLOAD THE TEMPLATE EXCEL TO USE FOR UPLOADING DATA HERE...",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reads a GMet forecast bulletin PDF straight into the table.
                  Obx(() => ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: wc.elevated,
                      foregroundColor: AppTheme.accentBlue,
                      side: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: ctrl.isImporting.value ? null : ctrl.importPDFData,
                    icon: ctrl.isImporting.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : Icon(PhosphorIcons.filePdf(), size: 18),
                    label: Text(
                      ctrl.isImporting.value ? "READING..." : "IMPORT PDF",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  )),
                  const SizedBox(width: 10),
                  Obx(() => ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: wc.elevated,
                      foregroundColor: AppTheme.accentBlue,
                      side: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: ctrl.isImporting.value ? null : ctrl.importCSVData,
                    icon: ctrl.isImporting.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : Icon(PhosphorIcons.fileCsv(), size: 18),
                    label: Text(
                      ctrl.isImporting.value ? "IMPORTING..." : "IMPORT CSV",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── LAZY SCROLLING MAIN FORECAST TABLE ─────────────────────────────
          // FIX: Instead of `Expanded`, we use a Container with a dynamic height boundary.
          // This stops RenderFlex crashes on small screens while preserving lazy loading inside.
          Container(
            height: MediaQuery.of(context).size.height * 0.55 < 450 
                ? 450 // Minimum height so it doesn't get crushed
                : MediaQuery.of(context).size.height * 0.55, // Takes up 55% of the screen otherwise
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
                if (ctrl.isLoadingSettings.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (ctrl.cityData.isEmpty) {
                  return const Center(child: Text("No cities configured for this department."));
                }
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1400, // Forces horizontal scroll width
                    child: Column(
                      children: [
                        // STICKY HEADER ROW
                        Container(
                          decoration: BoxDecoration(
                            color: wc.elevated,
                            border: Border(bottom: BorderSide(color: wc.borderSoft)),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 12, child: _tableHeaderCell("CITIES", context)),
                              _verticalDivider(wc.borderSoft),
                              Expanded(flex: 14, child: _dynamicHeaderCell(ctrl, 0, context)),
                              _verticalDivider(wc.borderSoft),
                              SizedBox(width: 65, child: _tableHeaderCell("PROB\n(%)", context)),
                              _verticalDivider(wc.borderSoft),
                              SizedBox(width: 65, child: _tableHeaderCell("TEMP\n(°C)", context)),
                              _verticalDivider(wc.borderSoft),
                              Expanded(flex: 14, child: _dynamicHeaderCell(ctrl, 1, context)),
                              _verticalDivider(wc.borderSoft),
                              SizedBox(width: 65, child: _tableHeaderCell("PROB\n(%)", context)),
                              _verticalDivider(wc.borderSoft),
                              SizedBox(width: 65, child: _tableHeaderCell("TEMP\n(°C)", context)),
                              _verticalDivider(wc.borderSoft),
                              Expanded(flex: 14, child: _dynamicHeaderCell(ctrl, 2, context)),
                              _verticalDivider(wc.borderSoft),
                              SizedBox(width: 65, child: _tableHeaderCell("PROB\n(%)", context)),
                              _verticalDivider(wc.borderSoft),
                              SizedBox(width: 65, child: _tableHeaderCell("TEMP\n(°C)", context)),
                            ],
                          ),
                        ),
                        
                        // LAZY DATA ROWS 
                        Expanded(
                          child: ListView.builder(
                            key: ctrl.tableRefreshTrigger.value, 
                            itemCount: ctrl.cityData.length,
                            itemBuilder: (context, index) {
                              final city = ctrl.cityData[index];
                              
                              return Container(
                                decoration: BoxDecoration(
                                  color: index.isEven ? Colors.transparent : wc.elevated.withOpacity(0.3),
                                  border: Border(bottom: BorderSide(color: wc.borderSoft)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 12, child: _tableDataCell(city['name'], isBold: true, context: context)),
                                    _verticalDivider(wc.borderSoft),
                                    Expanded(flex: 14, child: _tableSearchCell(ctrl, index, 'slot1_weather', context)),
                                    _verticalDivider(wc.borderSoft),
                                    SizedBox(width: 65, child: _tableProbCell(ctrl, index, 'slot1_prob', context)),
                                    _verticalDivider(wc.borderSoft),
                                    SizedBox(width: 65, child: _tableInputCell(ctrl, index, 'slot1_temp', context)),
                                    _verticalDivider(wc.borderSoft),
                                    Expanded(flex: 14, child: _tableSearchCell(ctrl, index, 'slot2_weather', context)),
                                    _verticalDivider(wc.borderSoft),
                                    SizedBox(width: 65, child: _tableProbCell(ctrl, index, 'slot2_prob', context)),
                                    _verticalDivider(wc.borderSoft),
                                    SizedBox(width: 65, child: _tableInputCell(ctrl, index, 'slot2_temp', context)),
                                    _verticalDivider(wc.borderSoft),
                                    Expanded(flex: 14, child: _tableSearchCell(ctrl, index, 'slot3_weather', context)),
                                    _verticalDivider(wc.borderSoft),
                                    SizedBox(width: 65, child: _tableProbCell(ctrl, index, 'slot3_prob', context)),
                                    _verticalDivider(wc.borderSoft),
                                    SizedBox(width: 65, child: _tableInputCell(ctrl, index, 'slot3_temp', context)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 24),

          // ── NEXT BUTTON ────────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: AppTheme.accentBlue.withOpacity(0.4),
              ),
              onPressed: onNext, 
              icon: Icon(PhosphorIcons.arrowRight(), size: 18),
              label: const Text(
                "NEXT: IMPACT-BASED FORECAST", 
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Sub-Widgets for the Lazy Loading Table Layout ---

  Widget _verticalDivider(Color color) {
    return Container(
      height: 55,
      width: 1,
      color: color,
    );
  }

  Widget _tableHeaderCell(String text, BuildContext context) {
    return Container(
      height: 55, padding: const EdgeInsets.all(4), alignment: Alignment.center,
      child: Text(
        text, 
        textAlign: TextAlign.center, 
        style: TextStyle(
          fontWeight: FontWeight.w800, 
          fontSize: 10, 
          color: context.wColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _dynamicHeaderCell(CAFOController ctrl, int index, BuildContext context) {
    return Container(
      height: 55, padding: const EdgeInsets.all(4), alignment: Alignment.center,
      child: Obx(() => Text(
        "${ctrl.dynamicHeaders[index]}\n(${ctrl.dynamicDates[index]})", 
        textAlign: TextAlign.center, 
        style: TextStyle(
          fontWeight: FontWeight.w800, 
          fontSize: 10, 
          color: AppTheme.accentBlue,
          letterSpacing: 0.5,
        ),
      )),
    );
  }

  Widget _tableDataCell(String text, {bool isBold = false, required BuildContext context}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text, 
        style: TextStyle(
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, 
          fontSize: 12, 
          color: context.wColors.textPrimary,
        ),
      ),
    );
  }

  Widget _tableSearchCell(CAFOController ctrl, int index, String key, BuildContext context) {
    final wc = context.wColors;
    return Container(
      height: 55, padding: const EdgeInsets.symmetric(horizontal: 6), alignment: Alignment.center,
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: ctrl.cityData[index][key]?.toString() ?? ''),
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) return ctrl.weatherOptions;
          return ctrl.weatherOptions.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
        },
        onSelected: (selection) => ctrl.cityData[index][key] = selection,
        fieldViewBuilder: (context, textController, focusNode, onEditingComplete) {
          return TextFormField(
            controller: textController, 
            focusNode: focusNode, 
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.w600, 
              color: wc.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: "Search...", 
              hintStyle: TextStyle(fontSize: 11, color: wc.textMuted), 
              border: InputBorder.none, 
              isDense: true, 
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) => ctrl.cityData[index][key] = val,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8, 
              borderRadius: BorderRadius.circular(8),
              color: wc.elevated,
              shadowColor: Colors.black.withOpacity(0.3),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220, maxWidth: 160),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8), 
                  shrinkWrap: true, 
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final option = options.elementAt(i);
                    return InkWell(
                      onTap: () => onSelected(option), 
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
                        child: Text(
                          option, 
                          style: TextStyle(
                            fontSize: 11, 
                            color: wc.textPrimary, 
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                )
              )
            )
          );
        }
      ),
    );
  }

  Widget _tableProbCell(CAFOController ctrl, int index, String key, BuildContext context) {
    final wc = context.wColors;
    return SizedBox(
      height: 55,
      child: TextFormField(
        initialValue: ctrl.cityData[index][key]?.toString() ?? '',
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Only numbers
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.w700, 
          color: AppTheme.accentBlue,
        ),
        decoration: InputDecoration(
          border: InputBorder.none, 
          contentPadding: const EdgeInsets.only(bottom: 4), 
          hintText: "—", 
          hintStyle: TextStyle(color: wc.textMuted, fontSize: 11),
        ),
        onChanged: (val) {
          ctrl.cityData[index][key] = val;
        },
      ),
    );
  }

  Widget _tableInputCell(CAFOController ctrl, int index, String key, BuildContext context) {
    final wc = context.wColors;
    return SizedBox(
      height: 55,
      child: TextFormField(
        initialValue: ctrl.cityData[index][key]?.toString() ?? '',
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        // Robust regex format that only allows valid numbers/decimals
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*'))],
        style: TextStyle(
          fontSize: 13, 
          fontWeight: FontWeight.w700, 
          color: wc.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none, 
          contentPadding: const EdgeInsets.only(bottom: 4), 
          hintText: "—", 
          hintStyle: TextStyle(color: wc.textMuted, fontSize: 11),
        ),
        onChanged: (val) {
          ctrl.cityData[index][key] = val; 
        },
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
// import 'package:weather_admin_dashboard/app/controllers/cafo_controller.dart';
// import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

// class DailyTableTab extends StatelessWidget {
//   final CAFOController ctrl;
//   final VoidCallback onNext;

//   const DailyTableTab({
//     super.key, 
//     required this.ctrl, 
//     required this.onNext,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final wc = context.wColors;
//     final isDark = context.isDark;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(28),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── SUMMARY AND TIME CONTROLS ──────────────────────────────────────
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "SUMMARY:", 
//                       style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                         fontWeight: FontWeight.w800,
//                         color: wc.textPrimary,
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Container(
//                       decoration: BoxDecoration(
//                         color: wc.elevated,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: wc.border),
//                       ),
//                       child: TextField(
//                         controller: ctrl.summaryController,
//                         maxLines: 4,
//                         style: TextStyle(
//                           fontSize: 14, 
//                           height: 1.6, 
//                           color: wc.textPrimary,
//                         ),
//                         decoration: InputDecoration(
//                           hintText: "Mist or fog patches are expected to develop...",
//                           hintStyle: TextStyle(color: wc.textMuted),
//                           border: InputBorder.none,
//                           contentPadding: const EdgeInsets.all(16),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 24),
              
//               // Issue Time Panel
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                 decoration: BoxDecoration(
//                   color: AppTheme.accentBlue.withOpacity(0.08),
//                   border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "ISSUE TIME (UTC)", 
//                       style: TextStyle(
//                         fontWeight: FontWeight.w700, 
//                         fontSize: 11, 
//                         color: AppTheme.accentBlue,
//                         letterSpacing: 0.8,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Obx(() => DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: ctrl.selectedIssueTime.value,
//                         icon: Icon(PhosphorIcons.caretDown(), size: 13, color: AppTheme.accentBlue),
//                         style: TextStyle(
//                           fontFamily: 'Syne',
//                           fontWeight: FontWeight.w800, 
//                           fontSize: 18, 
//                           color: AppTheme.accentBlue,
//                         ),
//                         dropdownColor: wc.elevated,
//                         items:  ctrl.issueTimeOptions.map((String value) {
//   return DropdownMenuItem<String>(
//     value: value, 
//     child: Text("$value UTC"),
//   );
// }).toList(),
//                         onChanged: (newValue) { 
//                           if (newValue != null) ctrl.updateIssueTime(newValue);
//                         },
//                       ),
//                     ),),
//                   ],
//                 ),
//               ),
//             ],
//           ),
          
//           const SizedBox(height: 20),

//           // ── NB FIELD ───────────────────────────────────────────────────────
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: AppTheme.infoCyan.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: AppTheme.infoCyan.withOpacity(0.3)),
//             ),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Icon(PhosphorIcons.info(), size: 18, color: AppTheme.infoCyan),
//                 const SizedBox(width: 8),
//                 Text(
//                   "NB: ", 
//                   style: TextStyle(
//                     fontWeight: FontWeight.w800, 
//                     fontSize: 14, 
//                     color: AppTheme.infoCyan,
//                   ),
//                 ),
//                 Expanded(
//                   child: TextField(
//                     controller: ctrl.nbController,
//                     maxLines: 1,
//                     style: TextStyle(
//                       fontSize: 14, 
//                       fontWeight: FontWeight.w600, 
//                       color: wc.textPrimary,
//                     ),
//                     decoration: InputDecoration(
//                       hintText: "Relatively cool night and early morning temperatures...",
//                       hintStyle: TextStyle(color: wc.textMuted),
//                       border: InputBorder.none,
//                       isDense: true,
//                       contentPadding: EdgeInsets.zero,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 28),

//           // ── EXCEL IMPORT / EXPORT ──────────────────────────────────────────
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // Download Template Text Button
//               InkWell(
//                 onTap: ctrl.downloadCSVTemplate,
//                 child: Row(
//                   children: [
//                     Icon(PhosphorIcons.downloadSimple(), size: 16, color: AppTheme.accentBlue),
//                     const SizedBox(width: 6),
//                     Text(
//                       "DOWNLOAD THE TEMPLATE EXCEL TO USE FOR UPLOADING DATA HERE...",
//                       style: TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w700,
//                         color: AppTheme.accentBlue,
//                         decoration: TextDecoration.underline,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               // Import Button 
//               Obx(() => ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: wc.elevated,
//                   foregroundColor: AppTheme.accentBlue,
//                   side: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5)),
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                   elevation: 0,
//                 ),
//                 // Disable the button if it's currently importing
//                 onPressed: ctrl.isImporting.value ? null : ctrl.importCSVData,
                
//                 // Show a spinner if importing, otherwise show the Excel icon
//                 icon: ctrl.isImporting.value
//                     ? const SizedBox(
//                         width: 18, 
//                         height: 18, 
//                         child: CircularProgressIndicator(strokeWidth: 2)
//                       )
//                     : Icon(PhosphorIcons.fileCsv(), size: 18),
                
//                 // Change the text based on the state
//                 label: Text(
//                   ctrl.isImporting.value ? "IMPORTING..." : "IMPORT CSV", 
//                   style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
//                 ),
//               )),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // ── MAIN FORECAST TABLE ────────────────────────────────────────────
//           Container(
//             decoration: BoxDecoration(
//               color: wc.card,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: wc.border),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
//                   blurRadius: 12,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
            
//              child: ClipRRect(
//               borderRadius: BorderRadius.circular(16),
//               // Wrap the Table in Obx and add the key here:
//               child: Obx(() 
//               {
//               if (ctrl.isLoadingSettings.value) {
//                 return const Center(
//                   child: Padding(
//                     padding: EdgeInsets.all(40.0),
//                     child: CircularProgressIndicator(),
//                   ),
//                 );
//               }
              
//               if (ctrl.cityData.isEmpty) {
//                  return const Center(child: Text("No cities configured for this department."));
//               }
//               return
//                Table(
//                 key: ctrl.tableRefreshTrigger.value, 
//                 border: TableBorder(
//                   horizontalInside: BorderSide(color: wc.borderSoft, width: 1),
//                     verticalInside: BorderSide(color: wc.borderSoft, width: 1),
//                   ),
//                   columnWidths: const {
//                     0: FlexColumnWidth(1.2), 
//                     1: FlexColumnWidth(1.4), 
//                     2: FixedColumnWidth(65), 
//                     3: FixedColumnWidth(65),
//                     4: FlexColumnWidth(1.4), 
//                     5: FixedColumnWidth(65), 
//                     6: FixedColumnWidth(65),
//                     7: FlexColumnWidth(1.4), 
//                     8: FixedColumnWidth(65), 
//                     9: FixedColumnWidth(65),
//                   },
//                   defaultVerticalAlignment: TableCellVerticalAlignment.middle,
//                   children: [
//                     // Headers
//                     TableRow(
//                       decoration: BoxDecoration(color: wc.elevated),
//                       children: [
//                         _tableHeaderCell("CITIES", context), 
//                         _dynamicHeaderCell(ctrl, 0, context), 
//                         _tableHeaderCell("PROB\n(%)", context), 
//                         _tableHeaderCell("TEMP\n(°C)", context),
//                         _dynamicHeaderCell(ctrl, 1, context), 
//                         _tableHeaderCell("PROB\n(%)", context), 
//                         _tableHeaderCell("TEMP\n(°C)", context),
//                         _dynamicHeaderCell(ctrl, 2, context), 
//                         _tableHeaderCell("PROB\n(%)", context), 
//                         _tableHeaderCell("TEMP\n(°C)", context),
//                       ]
//                     ),
//                     // City Data Rows
//                     ...ctrl.cityData.asMap().entries.map((entry) {
//                       final index = entry.key;
//                       final city = entry.value;
                
//                       return TableRow(
//                         decoration: BoxDecoration(
//                           color: index.isEven ? Colors.transparent : wc.elevated.withOpacity(0.3)
//                         ),
//                         children: [
//                           _tableDataCell(city['name'], isBold: true, context: context),
//                           _tableSearchCell(ctrl, index, 'slot1_weather', context), _tableProbCell(ctrl, index, 'slot1_prob', context), _tableInputCell(ctrl, index, 'slot1_temp', context),
//                           _tableSearchCell(ctrl, index, 'slot2_weather', context), _tableProbCell(ctrl, index, 'slot2_prob', context), _tableInputCell(ctrl, index, 'slot2_temp', context),
//                           _tableSearchCell(ctrl, index, 'slot3_weather', context), _tableProbCell(ctrl, index, 'slot3_prob', context), _tableInputCell(ctrl, index, 'slot3_temp', context),
//                         ]
//                       );
//                     }),
//                   ],
//                 );
//               }),
//             ),
//           ),
          
//           const SizedBox(height: 32),

//           // ── NEXT BUTTON ────────────────────────────────────────────────────
//           Align(
//             alignment: Alignment.centerRight,
//             child: ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppTheme.accentBlue,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 elevation: 4,
//                 shadowColor: AppTheme.accentBlue.withOpacity(0.4),
//               ),
//               onPressed: onNext, 
//               icon: Icon(PhosphorIcons.arrowRight(), size: 18),
//               label: const Text(
//                 "NEXT: IMPACT-BASED FORECAST", 
//                 style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
//               ),
//             ),
//           ),
//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }

//   // --- Sub-Widgets for the Table ---

//   Widget _tableHeaderCell(String text, BuildContext context) {
//     return Container(
//       height: 55, padding: const EdgeInsets.all(4), alignment: Alignment.center,
//       child: Text(
//         text, 
//         textAlign: TextAlign.center, 
//         style: TextStyle(
//           fontWeight: FontWeight.w800, 
//           fontSize: 10, 
//           color: context.wColors.textSecondary,
//           letterSpacing: 0.5,
//         ),
//       ),
//     );
//   }

//   Widget _dynamicHeaderCell(CAFOController ctrl, int index, BuildContext context) {
//     return Container(
//       height: 55, padding: const EdgeInsets.all(4), alignment: Alignment.center,
//       child: Obx(() => Text(
//         "${ctrl.dynamicHeaders[index]}\n(${ctrl.dynamicDates[index]})", 
//         textAlign: TextAlign.center, 
//         style: TextStyle(
//           fontWeight: FontWeight.w800, 
//           fontSize: 10, 
//           color: AppTheme.accentBlue,
//           letterSpacing: 0.5,
//         ),
//       )),
//     );
//   }

//   Widget _tableDataCell(String text, {bool isBold = false, required BuildContext context}) {
//     return Padding(
//       padding: const EdgeInsets.all(12.0),
//       child: Text(
//         text, 
//         style: TextStyle(
//           fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, 
//           fontSize: 12, 
//           color: context.wColors.textPrimary,
//         ),
//       ),
//     );
//   }

//   Widget _tableSearchCell(CAFOController ctrl, int index, String key, BuildContext context) {
//     final wc = context.wColors;
//     return Container(
//       height: 50, padding: const EdgeInsets.symmetric(horizontal: 6), alignment: Alignment.center,
//       child: Autocomplete<String>(
//         initialValue: TextEditingValue(text: ctrl.cityData[index][key]),
//         optionsBuilder: (textEditingValue) {
//           if (textEditingValue.text.isEmpty) return ctrl.weatherOptions;
//           return ctrl.weatherOptions.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
//         },
//         onSelected: (selection) => ctrl.cityData[index][key] = selection,
//         fieldViewBuilder: (context, textController, focusNode, onEditingComplete) {
//           return TextFormField(
//             controller: textController, 
//             focusNode: focusNode, 
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 11, 
//               fontWeight: FontWeight.w600, 
//               color: wc.textPrimary,
//             ),
//             decoration: InputDecoration(
//               hintText: "Search...", 
//               hintStyle: TextStyle(fontSize: 11, color: wc.textMuted), 
//               border: InputBorder.none, 
//               isDense: true, 
//               contentPadding: EdgeInsets.zero,
//             ),
//             onChanged: (val) => ctrl.cityData[index][key] = val,
//           );
//         },
//         optionsViewBuilder: (context, onSelected, options) {
//           return Align(
//             alignment: Alignment.topLeft,
//             child: Material(
//               elevation: 8, 
//               borderRadius: BorderRadius.circular(8),
//               color: wc.elevated,
//               shadowColor: Colors.black.withOpacity(0.3),
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxHeight: 220, maxWidth: 160),
//                 child: ListView.builder(
//                   padding: const EdgeInsets.symmetric(vertical: 8), 
//                   shrinkWrap: true, 
//                   itemCount: options.length,
//                   itemBuilder: (context, i) {
//                     final option = options.elementAt(i);
//                     return InkWell(
//                       onTap: () => onSelected(option), 
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
//                         child: Text(
//                           option, 
//                           style: TextStyle(
//                             fontSize: 11, 
//                             color: wc.textPrimary, 
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     );
//                   }
//                 )
//               )
//             )
//           );
//         }
//       ),
//     );
//   }

//   Widget _tableProbCell(CAFOController ctrl, int index, String key, BuildContext context) {
//     final wc = context.wColors;
//     return Container(
//       height: 50, alignment: Alignment.center,
//       child: Obx(() {
//         String val = ctrl.cityData[index][key].toString().trim();
        
//         // THE FIX: If the imported value isn't in our 1-100 list, ignore it safely!
//         if (!ctrl.probOptions.contains(val)) {
//           val = ""; 
//         }

//         return DropdownButtonHideUnderline(
//           child: DropdownButton<String>(
//             value: val == "" ? null : val, 
//             isExpanded: true,
//             icon: Icon(PhosphorIcons.caretDown(), size: 14, color: wc.textSecondary),
//             hint: Text("—", style: TextStyle(fontSize: 11, color: wc.textMuted), textAlign: TextAlign.center),
//             dropdownColor: wc.elevated,
//             borderRadius: BorderRadius.circular(8),
//             style: TextStyle(
//               fontSize: 12, 
//               fontWeight: FontWeight.w700, 
//               color: AppTheme.accentBlue,
//             ),
//             items: ctrl.probOptions.map((value) => DropdownMenuItem<String>(
//               value: value, 
//               child: Center(child: Text(value, textAlign: TextAlign.center))
//             )).toList(),
//             onChanged: (newValue) {
//               if (newValue != null) { 
//                 ctrl.cityData[index][key] = newValue; 
//                 ctrl.cityData.refresh(); 
              
//                 }
//             },
//           ),
//         );
//       }),
//     );
//   }

//   Widget _tableInputCell(CAFOController ctrl, int index, String key, BuildContext context) {
//     final wc = context.wColors;
//     return SizedBox(
//       height: 50,
//       child: TextFormField(
//         initialValue: ctrl.cityData[index][key],
//         textAlign: TextAlign.center,
//         keyboardType: const TextInputType.numberWithOptions(decimal: true),
//         inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
//         style: TextStyle(
//           fontSize: 13, 
//           fontWeight: FontWeight.w700, 
//           color: wc.textPrimary,
//         ),
//         decoration: InputDecoration(
//           border: InputBorder.none, 
//           contentPadding: const EdgeInsets.only(bottom: 6), 
//           hintText: "—", 
//           hintStyle: TextStyle(color: wc.textMuted, fontSize: 11),
//         ),
//         onChanged: (val) {
//           try {
//             if (val.isNotEmpty && val != '-' && val != '.') double.parse(val); 
//             ctrl.cityData[index][key] = val; 
//           } catch (e) {
//             debugPrint("Invalid Temperature Input: $val");
//           }
//         },
//       ),
//     );
//   }

  
// }