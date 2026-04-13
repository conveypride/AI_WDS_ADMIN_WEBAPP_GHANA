import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/controllers/coastline_forecast_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'package:weather_admin_dashboard/app/views/marine_forecast/coastline/smart_forecastInput_cell.dart';
import 'package:weather_admin_dashboard/app/views/widgets/risk_InfoSidePanel.dart'; 
import '../../widgets/coastline_map_widget.dart';

class CoastlineForecastView extends StatelessWidget {
  const CoastlineForecastView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CoastlineForecastController());
    final wc = context.wColors;

    return Obx(() {
      if (!ctrl.isMarineUser) {
        return const Center(
          child: Text(
            "ACCESS DENIED\nOnly the Marine Department can access this section.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── MODERN TAB BAR ───────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: wc.card,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: TabBar(
              controller: ctrl.tabController, 
              labelColor: AppTheme.accentBlue, 
              unselectedLabelColor: wc.textMuted, 
              indicatorColor: AppTheme.accentBlue, 
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(height: 56, icon: Icon(PhosphorIcons.clockCounterClockwise(), size: 20), text: "HISTORY"),
                Tab(height: 56, icon: Icon(PhosphorIcons.table(), size: 20), text: "DAILY TABLE"), 
                Tab(height: 56, icon: Icon(PhosphorIcons.anchor(), size: 20), text: "COASTLINE IBF"), 
              ],
            ),
          ),
          
          // ── TAB CONTENT ──────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: ctrl.tabController,
              physics: const NeverScrollableScrollPhysics(), // Enforces "Next" button validation
              children: [
                _CoastlineHistoryTab(ctrl: ctrl),
                _DailyTableTab(ctrl: ctrl),
                _CoastlineInputTab(ctrl: ctrl),
              ],
            ),
          )
        ],
      );
    });
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
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "FORECAST ANALYTICS", 
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: wc.textPrimary,
                  letterSpacing: 0.5,
                )
              ),
              if (ctrl.canCreate)
                ElevatedButton.icon(
                  onPressed: ctrl.createNewForecast,
                  icon: Icon(PhosphorIcons.plus(), size: 16),
                  label: const Text(
                    "New Forecast",
                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          Obx(() => Row(
            children: [
              Expanded(child: _buildKpiCard("TOTAL FORECASTS", ctrl.kpiTotal.value.toString(), PhosphorIcons.files(PhosphorIconsStyle.fill), Colors.blueAccent, isDark)),
              const SizedBox(width: 16),
              Expanded(child: _buildKpiCard("DRAFTED", ctrl.kpiDraft.value.toString(), PhosphorIcons.floppyDisk(PhosphorIconsStyle.fill), Colors.grey.shade600, isDark)),
              const SizedBox(width: 16),
              Expanded(child: _buildKpiCard("PENDING APPROVAL", ctrl.kpiPending.value.toString(), PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill), Colors.amber.shade700, isDark)),
              const SizedBox(width: 16),
              Expanded(child: _buildKpiCard("PUBLISHED", ctrl.kpiPublished.value.toString(), PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), Colors.green.shade600, isDark)),
            ],
          )),

          const SizedBox(height: 32),
          Text("RECENT FORECASTS", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: wc.textPrimary, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: wc.card, 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: wc.border)
            ),
            child: Obx(() {
              if (ctrl.isLoadingHistory.value && ctrl.coastlineHistory.isEmpty) {
                return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
              }
              if (ctrl.coastlineHistory.isEmpty) {
                return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text("No coastline forecasts found. Start creating one!")));
              }

              return Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ctrl.coastlineHistory.length, 
                    separatorBuilder: (_, __) => Divider(height: 1, color: wc.borderSoft),
                    itemBuilder: (ctx, idx) {
                      final item = ctrl.coastlineHistory[idx];
                      final status = item['status'] ?? 'draft';
                      final author = item['author'] ?? {};
                      final docId = item['id'];
                      
                      String formattedDate = "Unknown Date";
                      if (item['updatedAt'] != null) {
                        try {
                          DateTime dt = (item['updatedAt'] as Timestamp).toDate();
                          formattedDate = DateFormat('MMM dd, yyyy').format(dt);
                        } catch (_) {}
                      }

                      String validityStr = "Unknown";
                      if (item['validDate'] != null) {
                        try {
                          DateTime vDate = DateTime.parse(item['validDate']);
                          validityStr = "${DateFormat('dd MMM').format(vDate)} - ${item['validTime']}";
                        } catch (_) {}
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        leading: CircleAvatar(backgroundColor: isDark ? Colors.grey.shade800 : Colors.blue.shade50, child: Icon(PhosphorIcons.anchor(), color: isDark ? Colors.white70 : AppTheme.accentBlue, size: 20)),
                        title: Text("Coastline Forecast (Issue: ${item['issueTime'] ?? '--'})", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary, fontSize: 14)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.calendarBlank(), size: 14, color: wc.textMuted), const SizedBox(width: 4),
                              Text(formattedDate, style: TextStyle(color: wc.textMuted, fontSize: 12)), const SizedBox(width: 16),
                              Icon(PhosphorIcons.clock(), size: 14, color: wc.textMuted), const SizedBox(width: 4),
                              Text("Validity: $validityStr", style: TextStyle(color: wc.textMuted, fontSize: 12)), const SizedBox(width: 16),
                              Icon(PhosphorIcons.user(), size: 14, color: wc.textMuted), const SizedBox(width: 4),
                              Text(author['name'] ?? 'Unknown', style: TextStyle(color: wc.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatusChip(status),
                            const SizedBox(width: 16),
                            Theme(
                              data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                              child: PopupMenuButton<String>(
                                icon: Icon(PhosphorIcons.dotsThreeVertical(), color: wc.textSecondary),
                                color: isDark ? Colors.grey.shade800 : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                offset: const Offset(0, 40),
                                tooltip: "Forecast Options",
                                onSelected: (value) => _handleMenuSelection(context, value, docId, item),
                                itemBuilder: (context) => [
                                  if (ctrl.canApprove && status == 'pending_approval') ...[
                                    PopupMenuItem(value: 'approve', child: Row(children: [Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), size: 18, color: Colors.green), const SizedBox(width: 12), Text("Approve Forecast", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))])),
                                    const PopupMenuDivider(),
                                  ],
                                  if (ctrl.canApprove && status == 'published') ...[
                                    PopupMenuItem(value: 'revoke', child: Row(children: [Icon(PhosphorIcons.xCircle(PhosphorIconsStyle.fill), size: 18, color: Colors.orange), const SizedBox(width: 12), Text("Revoke Approval", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))])),
                                    const PopupMenuDivider(),
                                  ],
                                  PopupMenuItem(value: 'view', child: Row(children: [Icon(PhosphorIcons.eye(), size: 18, color: isDark ? Colors.white : Colors.black87), const SizedBox(width: 12), Text("View", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))])),
                                  PopupMenuItem(value: 'edit', child: Row(children: [Icon(PhosphorIcons.pencilSimple(), size: 18, color: isDark ? Colors.white : Colors.black87), const SizedBox(width: 12), Text("Edit / Update", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))])),
                                  const PopupMenuDivider(),
                               // --- NEW DOWNLOAD BUTTON ADDED HERE ---
                                  PopupMenuItem(value: 'download_table', child: Row(children: [Icon(PhosphorIcons.filePdf(), size: 18, color: isDark ? Colors.white : Colors.red.shade700), const SizedBox(width: 12), Text("Download Table", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))])),
                                  PopupMenuItem(value: 'download_ibf', child: Row(children: [Icon(PhosphorIcons.filePdf(), size: 18, color: isDark ? Colors.white : Colors.red.shade700), const SizedBox(width: 12), Text("Download IBF", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))])),
                               
                                ],
                              ),
                            ),
                          ],
                        )
                      );
                    }
                  ),
                  Obx(() {
                    if (!ctrl.hasMore.value) return Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text("End of results", style: TextStyle(color: wc.textMuted, fontSize: 12)));
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: ctrl.isFetchingMore.value
                          ? const CircularProgressIndicator()
                          : TextButton.icon(
                              onPressed: ctrl.fetchMoreForecasts,
                              icon: Icon(PhosphorIcons.caretDown(), size: 16),
                              label: const Text("LOAD MORE", style: TextStyle(fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(foregroundColor: AppTheme.accentBlue),
                            ),
                    );
                  })
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String count, IconData icon, Color iconColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.5)), const SizedBox(height: 4), Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87))])
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor; Color textColor;
    String displayStatus = status.toUpperCase().replaceAll('_', ' ');

    if (status == 'draft') { bgColor = Colors.grey.shade200; textColor = Colors.grey.shade700; } 
    else if (status == 'pending_approval') { bgColor = Colors.amber.shade100; textColor = Colors.amber.shade900; } 
    else if (status == 'published') { bgColor = Colors.green.shade100; textColor = Colors.green.shade800; } 
    else { bgColor = Colors.blue.shade100; textColor = Colors.blue.shade800; }

    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)), child: Text(displayStatus, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)));
  }

  void _handleMenuSelection(BuildContext context, String value, String docId, Map<String, dynamic> item) {
    switch (value) {
      case 'approve': ctrl.updateForecastStatus(docId, 'published'); break;
      case 'revoke': ctrl.updateForecastStatus(docId, 'pending_approval'); break;
      case 'view': ctrl.loadForecastForEditing(item, isViewOnly: true); break;
      case 'edit': ctrl.loadForecastForEditing(item, isViewOnly: false); break;
      case 'download_table': ctrl.downloadTableForecastPdfImage(docId); break;
      case 'download_ibf': ctrl.downloadIbfForecastPdfImage(docId, context); break; // PASSED CONTEXT HERE
    }
  }
}

// ============================================================================
// TAB 2: DAILY TABLE TAB
// ============================================================================
class _DailyTableTab extends StatelessWidget {
  final CoastlineForecastController ctrl;

  const _DailyTableTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Daily Coastline / Maritime Forecast", 
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: wc.textPrimary,
            ) ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // --- 1. DAILY TIME & SUMMARY SECTION ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDateTimeSelector(
                      context: context, 
                      label: "ISSUE TIME", 
                      dateObs: ctrl.dailyIssueDate, 
                      timeObs: ctrl.dailyIssueTime, 
                      themeColor: AppTheme.accentBlue,
                      options: ctrl.zTimeOptions,
                      onTimeChanged: ctrl.updateDailyIssueTime
                    )),
                    const SizedBox(width: 24),
                    Expanded(child: _buildLockedDateTimeSelector(
                      context: context, 
                      label: "VALID TIME (AUTO +1HR)", 
                      dateObs: ctrl.dailyValidDate, 
                      timeObs: ctrl.dailyValidTime, 
                      themeColor: AppTheme.successGreen
                    )),
                  ],
                ),
                const SizedBox(height: 32),
                
                Text("Daily Weather Summary", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary)),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey('${ctrl.currentForecastId.value}_daily_summary'),
                  initialValue: ctrl.dailyWeatherSummary.value,
                  maxLines: 3,
                  onChanged: (v) => ctrl.dailyWeatherSummary.value = v,
                  decoration: _inputDecoration("Enter the daily weather summary...", wc),
                  style: TextStyle(color: wc.textPrimary, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- 2. DAILY SEA STATE & WARNINGS ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("State of the Sea", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary)),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<String>(
                  value: ctrl.dailyStateOfSea.value,
                  dropdownColor: wc.elevated,
                  style: TextStyle(fontWeight: FontWeight.w600, color: wc.textPrimary, fontSize: 14),
                  decoration: _inputDecoration("", wc, isDropdown: true),
                  icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
                  items: ctrl.seaStateOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (val) { if(val != null) ctrl.dailyStateOfSea.value = val; },
                )),
                const SizedBox(height: 24),
                
                Text("Important Notes / Remarks", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.warningAmber)),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey('${ctrl.currentForecastId.value}_daily_warning'),
                  initialValue: ctrl.dailyWarningText.value,
                  onChanged: (v) => ctrl.dailyWarningText.value = v,
                  decoration: InputDecoration(
                    hintText: "Enter 'NIL' if no warnings...",
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

          // --- 3. SMART INPUT TABLE (MATCHES IBF STRUCTURE) ---
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: wc.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: wc.border)),
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
                    2: FlexColumnWidth(1),   
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: wc.elevated),
                      children: [
                        _headerCell("PARAMETER", context),
                        _headerCell("12 HOURS", context),
                        _headerCell("24 HOURS", context),
                      ],
                    ),
                    ...ctrl.parameters.asMap().entries.map((entry) {
                      final index = entry.key;
                      final param = entry.value;
                      final data = ctrl.dailyTableData[param]!;

                      return TableRow(
                        decoration: BoxDecoration(color: index.isEven ? Colors.transparent : wc.elevated.withOpacity(0.3)),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(child: Text(param, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: wc.textPrimary))),
                              ],
                            ),
                          ),
                          SmartForecastInputCell(parameter: param, period: '12h', value: data['12h']!, ctrl: ctrl, context: context, isDaily: true),
                          SmartForecastInputCell(parameter: param, period: '24h', value: data['24h']!, ctrl: ctrl, context: context, isDaily: true),
                        ],
                      );
                    })
                  ],
                );
              }),
            ),
          ),
          
          const SizedBox(height: 48),

         // --- NEXT BUTTON (WITH SMART VALIDATION) ---
          Center(
            child: Tooltip(
              message: "Proceed to Impact Based Forecast",
              child: ElevatedButton.icon(
                // Button is always active now, validation happens on tap!
                onPressed: ctrl.validateAndGoToIbfTab, 
                icon:  Icon(PhosphorIcons.arrowRight()),
                label: const Text("NEXT: COASTLINE IBF", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 3: COASTLINE IBF
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
            "Impact Based Forecast", 
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: wc.textPrimary,
            ) ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDateTimeSelector(
                      context: context, 
                      label: "ISSUE TIME", 
                      dateObs: ctrl.issueDate, 
                      timeObs: ctrl.issueTime, 
                      themeColor: AppTheme.accentBlue,
                      options: ctrl.zTimeOptions,
                      onTimeChanged: ctrl.updateIssueTime
                    )),
                    const SizedBox(width: 24),
                    Expanded(child: _buildLockedDateTimeSelector(
                      context: context, 
                      label: "VALID TIME (AUTO +1HR)", 
                      dateObs: ctrl.validDate, 
                      timeObs: ctrl.validTime, 
                      themeColor: AppTheme.successGreen
                    )),
                  ],
                ),
                const SizedBox(height: 32),
                
                Text("Weather Summary", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary)),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey(ctrl.currentForecastId.value ?? 'new_summary'),
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

          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("State of the Sea", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary)),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<String>(
                  value: ctrl.stateOfSea.value,
                  dropdownColor: wc.elevated,
                  style: TextStyle(fontWeight: FontWeight.w600, color: wc.textPrimary, fontSize: 14),
                  decoration: _inputDecoration("", wc, isDropdown: true),
                  icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
                  items: ctrl.seaStateOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (val) { if(val != null) ctrl.stateOfSea.value = val; },
                )),
                const SizedBox(height: 24),
                
                Text("Warning / Important Notes", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.warningAmber)),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey(ctrl.currentForecastId.value ?? 'new_warning'),
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

          Column(
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
                    child: const Text("EEZ Limit: 200NM", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.accentBlue)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 540, 
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: wc.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  // FIXED: Wrapped with RepaintBoundary and assigned the mapKey
                  child: RepaintBoundary(
                    key: ctrl.mapKey,
                    child: CoastlineMapWidget(ctrl: ctrl, isDark: isDark), 
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          buildEnhancedForecastTable(
            context: context,
            ctrl: ctrl,
          ),
          
          const SizedBox(height: 32),
          InfoSidePanel(ctrl: ctrl, isDark: isDark),

          const SizedBox(height: 48),
          
          // ── SPLIT PUBLISH / DRAFT BUTTON ───────────────────────────────────
          Center(
            child: Obx(() {
              if (ctrl.isPublishing.value) {
                 return ElevatedButton.icon(
                   onPressed: null,
                   icon: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                   label: const Text("SAVING...", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                   style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                 );
              }

              final btnText = ctrl.isAdmin ? "PUBLISH COASTLINE" : "SUBMIT FOR APPROVAL";
              final btnColor = ctrl.isAdmin ? AppTheme.successGreen : AppTheme.warningAmber;

              return Container(
                decoration: BoxDecoration(
                  color: btnColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: btnColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => ctrl.saveForecast('published'),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill), size: 20, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(btnText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                    
                    Container(width: 1, height: 60, color: Colors.white.withOpacity(0.3)),
                    
                    Theme(
                      data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        color: wc.card,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        offset: const Offset(0, -60), 
                        onSelected: (val) {
                          if (val == 'draft') ctrl.saveForecast('draft');
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'draft',
                            child: Row(
                              children: [
                                Icon(PhosphorIcons.floppyDisk(PhosphorIconsStyle.bold), size: 18, color: wc.textPrimary),
                                const SizedBox(width: 12),
                                Text("Save as Draft", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// --- GLOBAL UI HELPERS ---

BoxDecoration _cardDecoration(BuildContext context) {
  final wc = context.wColors;
  final isDark = context.isDark;
  return BoxDecoration(
    color: wc.card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: wc.border),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.06), blurRadius: 12, offset: const Offset(0, 4)),
    ],
  );
}

InputDecoration _inputDecoration(String hint, WColors wc, {bool isDropdown = false}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: wc.textMuted, fontSize: 13),
    filled: true, fillColor: wc.elevated,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5))),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isDropdown ? 14 : 16),
  );
}

Widget _buildDateTimeSelector({required BuildContext context, required String label, required Rx<DateTime> dateObs, required RxString timeObs, required Color themeColor, required List<String> options, required Function(String) onTimeChanged}) {
  final wc = context.wColors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: themeColor, letterSpacing: 1)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: dateObs.value, firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) dateObs.value = d;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: themeColor.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: themeColor.withOpacity(0.3))),
                child: Row(children: [
                  Icon(PhosphorIcons.calendarBlank(), color: themeColor, size: 18), const SizedBox(width: 10),
                  Obx(() => Text(DateFormat('dd MMM yyyy').format(dateObs.value), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: wc.textPrimary))),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Obx(() => DropdownButtonFormField<String>(
              value: timeObs.value,
              dropdownColor: wc.elevated,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: wc.textPrimary),
              icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
              decoration: InputDecoration(
                filled: true, fillColor: wc.elevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (val) { if(val != null) onTimeChanged(val); },
            )),
          ),
        ],
      ),
    ],
  );
}

Widget _buildLockedDateTimeSelector({required BuildContext context, required String label, required Rx<DateTime> dateObs, required RxString timeObs, required Color themeColor}) {
  final wc = context.wColors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: themeColor, letterSpacing: 1)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: wc.elevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: wc.borderSoft)),
              child: Row(children: [
                Icon(PhosphorIcons.calendarBlank(), color: wc.textMuted, size: 18), const SizedBox(width: 10),
                Obx(() => Text(DateFormat('dd MMM yyyy').format(dateObs.value), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: wc.textMuted))),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: wc.elevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: wc.borderSoft)),
              child: Obx(() => Text(timeObs.value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: wc.textMuted))),
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
      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: context.wColors.textSecondary, letterSpacing: 0.5),
    ),
  );
}
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:weather_admin_dashboard/app/controllers/coastline_forecast_controller.dart';
// import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
// import 'package:weather_admin_dashboard/app/views/marine_forecast/smart_forecastInput_cell.dart';
// import 'package:weather_admin_dashboard/app/views/widgets/risk_InfoSidePanel.dart'; 
// import '../widgets/coastline_map_widget.dart';

// class CoastlineForecastView extends StatelessWidget {
//   const CoastlineForecastView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ctrl = Get.put(CoastlineForecastController());
//     final wc = context.wColors;

//     // Security check wrapper
//     return Obx(() {
//       if (!ctrl.isMarineUser) {
//         return const Center(
//           child: Text(
//             "ACCESS DENIED\nOnly the Marine Department can access this section.",
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//         );
//       }

//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── MODERN TAB BAR ───────────────────────────────────────────────────
//           Container(
//             decoration: BoxDecoration(
//               color: wc.card,
//               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
//             ),
//             child: TabBar(
//               controller: ctrl.tabController, 
//               labelColor: AppTheme.accentBlue, 
//               unselectedLabelColor: wc.textMuted, 
//               indicatorColor: AppTheme.accentBlue, 
//               indicatorWeight: 3,
//               indicatorSize: TabBarIndicatorSize.tab,
//               labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
//               unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
//               tabs: [
//                 Tab(height: 56, icon: Icon(PhosphorIcons.clockCounterClockwise(), size: 20), text: "COASTLINE HISTORY"),
//                 Tab(height: 56, icon: Icon(PhosphorIcons.anchor(), size: 20), text: "COASTLINE INPUT"),
//               ],
//             ),
//           ),
          
//           // ── TAB CONTENT ──────────────────────────────────────────────────────
//           Expanded(
//             child: TabBarView(
//               controller: ctrl.tabController,
//               physics: const NeverScrollableScrollPhysics(),
//               children: [
//                 _CoastlineHistoryTab(ctrl: ctrl),
//                 _CoastlineInputTab(ctrl: ctrl),
//               ],
//             ),
//           )
//         ],
//       );
//     });
//   }
// }

// // ============================================================================
// // TAB 1: COASTLINE HISTORY (WITH MID-WEEK ANALYTICS STYLE)
// // ============================================================================
//  // ============================================================================
// // TAB 1: COASTLINE HISTORY (WITH CAFO STYLE POPUP MENU)
// // ============================================================================
// class _CoastlineHistoryTab extends StatelessWidget {
//   final CoastlineForecastController ctrl;

//   const _CoastlineHistoryTab({required this.ctrl});

//   @override
//   Widget build(BuildContext context) {
//     final wc = context.wColors;
//     final isDark = context.isDark;
    
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(28.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "FORECAST ANALYTICS", 
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.w800,
//                   color: wc.textPrimary,
//                   letterSpacing: 0.5,
//                 )
//               ),
//               if (ctrl.canCreate)
//                 ElevatedButton.icon(
//                   onPressed: ctrl.createNewForecast,
//                   icon: Icon(PhosphorIcons.plus(), size: 16),
//                   label: const Text(
//                     "New Forecast",
//                     style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppTheme.accentBlue,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 16),
          
//           // KPI CARDS
//           Obx(() => Row(
//             children: [
//               Expanded(child: _buildKpiCard("TOTAL FORECASTS", ctrl.kpiTotal.value.toString(), PhosphorIcons.files(PhosphorIconsStyle.fill), Colors.blueAccent, isDark)),
//               const SizedBox(width: 16),
//               Expanded(child: _buildKpiCard("DRAFTED", ctrl.kpiDraft.value.toString(), PhosphorIcons.floppyDisk(PhosphorIconsStyle.fill), Colors.grey.shade600, isDark)),
//               const SizedBox(width: 16),
//               Expanded(child: _buildKpiCard("PENDING APPROVAL", ctrl.kpiPending.value.toString(), PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill), Colors.amber.shade700, isDark)),
//               const SizedBox(width: 16),
//               Expanded(child: _buildKpiCard("PUBLISHED", ctrl.kpiPublished.value.toString(), PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), Colors.green.shade600, isDark)),
//             ],
//           )),

//           const SizedBox(height: 32),
//           Text("RECENT FORECASTS", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: wc.textPrimary, letterSpacing: 0.5)),
//           const SizedBox(height: 16),
          
//           // LIST VIEW
//           Container(
//             decoration: BoxDecoration(
//               color: wc.card, 
//               borderRadius: BorderRadius.circular(12), 
//               border: Border.all(color: wc.border)
//             ),
//             child: Obx(() {
//               if (ctrl.isLoadingHistory.value && ctrl.coastlineHistory.isEmpty) {
//                 return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
//               }
//               if (ctrl.coastlineHistory.isEmpty) {
//                 return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text("No coastline forecasts found. Start creating one!")));
//               }

//               return Column(
//                 children: [
//                   ListView.separated(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: ctrl.coastlineHistory.length, 
//                     separatorBuilder: (_, __) => Divider(height: 1, color: wc.borderSoft),
//                     itemBuilder: (ctx, idx) {
//                       final item = ctrl.coastlineHistory[idx];
//                       final status = item['status'] ?? 'draft';
//                       final author = item['author'] ?? {};
//                       final docId = item['id'];
                      
//                       String formattedDate = "Unknown Date";
//                       if (item['updatedAt'] != null) {
//                         try {
//                           DateTime dt = (item['updatedAt'] as Timestamp).toDate();
//                           formattedDate = DateFormat('MMM dd, yyyy').format(dt);
//                         } catch (_) {}
//                       }

//                       String validityStr = "Unknown";
//                       if (item['validDate'] != null) {
//                         try {
//                           DateTime vDate = DateTime.parse(item['validDate']);
//                           validityStr = "${DateFormat('dd MMM').format(vDate)} - ${item['validTime']}";
//                         } catch (_) {}
//                       }

//                       return ListTile(
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         leading: CircleAvatar(backgroundColor: isDark ? Colors.grey.shade800 : Colors.blue.shade50, child: Icon(PhosphorIcons.anchor(), color: isDark ? Colors.white70 : AppTheme.accentBlue, size: 20)),
//                         title: Text("Coastline Forecast (Issue: ${item['issueTime'] ?? '--'})", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary, fontSize: 14)),
//                         subtitle: Padding(
//                           padding: const EdgeInsets.only(top: 6.0),
//                           child: Row(
//                             children: [
//                               Icon(PhosphorIcons.calendarBlank(), size: 14, color: wc.textMuted), const SizedBox(width: 4),
//                               Text(formattedDate, style: TextStyle(color: wc.textMuted, fontSize: 12)), const SizedBox(width: 16),
//                               Icon(PhosphorIcons.clock(), size: 14, color: wc.textMuted), const SizedBox(width: 4),
//                               Text("Validity: $validityStr", style: TextStyle(color: wc.textMuted, fontSize: 12)), const SizedBox(width: 16),
//                               Icon(PhosphorIcons.user(), size: 14, color: wc.textMuted), const SizedBox(width: 4),
//                               Text(author['name'] ?? 'Unknown', style: TextStyle(color: wc.textMuted, fontSize: 12)),
//                             ],
//                           ),
//                         ),
//                         trailing: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             _buildStatusChip(status),
//                             const SizedBox(width: 16),
//                             Theme(
//                               data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
//                               child: PopupMenuButton<String>(
//                                 icon: Icon(PhosphorIcons.dotsThreeVertical(), color: wc.textSecondary),
//                                 color: isDark ? Colors.grey.shade800 : Colors.white,
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                 offset: const Offset(0, 40),
//                                 tooltip: "Forecast Options",
//                                 onSelected: (value) => _handleMenuSelection(context, value, docId, item),
//                                 itemBuilder: (context) => [
//                                   if (ctrl.canApprove && status == 'pending_approval') ...[
//                                     PopupMenuItem(value: 'approve', child: Row(children: [Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), size: 18, color: Colors.green), const SizedBox(width: 12), Text("Approve Forecast", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))])),
//                                     const PopupMenuDivider(),
//                                   ],
//                                   if (ctrl.canApprove && status == 'published') ...[
//                                     PopupMenuItem(value: 'revoke', child: Row(children: [Icon(PhosphorIcons.xCircle(PhosphorIconsStyle.fill), size: 18, color: Colors.orange), const SizedBox(width: 12), Text("Revoke Approval", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))])),
//                                     const PopupMenuDivider(),
//                                   ],
//                                   PopupMenuItem(value: 'view', child: Row(children: [Icon(PhosphorIcons.eye(), size: 18, color: isDark ? Colors.white : Colors.black87), const SizedBox(width: 12), Text("View", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))])),
//                                   PopupMenuItem(value: 'edit', child: Row(children: [Icon(PhosphorIcons.pencilSimple(), size: 18, color: isDark ? Colors.white : Colors.black87), const SizedBox(width: 12), Text("Edit / Update", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))])),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         )
//                       );
//                     }
//                   ),
//                   Obx(() {
//                     if (!ctrl.hasMore.value) return Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text("End of results", style: TextStyle(color: wc.textMuted, fontSize: 12)));
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 20),
//                       child: ctrl.isFetchingMore.value
//                           ? const CircularProgressIndicator()
//                           : TextButton.icon(
//                               onPressed: ctrl.fetchMoreForecasts,
//                               icon: Icon(PhosphorIcons.caretDown(), size: 16),
//                               label: const Text("LOAD MORE", style: TextStyle(fontWeight: FontWeight.bold)),
//                               style: TextButton.styleFrom(foregroundColor: AppTheme.accentBlue),
//                             ),
//                     );
//                   })
//                 ],
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildKpiCard(String title, String count, IconData icon, Color iconColor, bool isDark) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 24)),
//           const SizedBox(width: 16),
//           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.5)), const SizedBox(height: 4), Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87))])
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusChip(String status) {
//     Color bgColor; Color textColor;
//     String displayStatus = status.toUpperCase().replaceAll('_', ' ');

//     if (status == 'draft') { bgColor = Colors.grey.shade200; textColor = Colors.grey.shade700; } 
//     else if (status == 'pending_approval') { bgColor = Colors.amber.shade100; textColor = Colors.amber.shade900; } 
//     else if (status == 'published') { bgColor = Colors.green.shade100; textColor = Colors.green.shade800; } 
//     else { bgColor = Colors.blue.shade100; textColor = Colors.blue.shade800; }

//     return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)), child: Text(displayStatus, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)));
//   }

//   void _handleMenuSelection(BuildContext context, String value, String docId, Map<String, dynamic> item) {
//     switch (value) {
//       case 'approve': 
//         ctrl.updateForecastStatus(docId, 'published'); 
//         break;
//       case 'revoke': 
//         ctrl.updateForecastStatus(docId, 'pending_approval'); 
//         break;
//       case 'view': 
//         ctrl.loadForecastForEditing(item, isViewOnly: true); 
//         break;
//       case 'edit': 
//         ctrl.loadForecastForEditing(item, isViewOnly: false); 
//         break;
//     }
//   }
// }

// // ============================================================================
// // TAB 2: COASTLINE INPUT
// // ============================================================================
// class _CoastlineInputTab extends StatelessWidget {
//   final CoastlineForecastController ctrl;

//   const _CoastlineInputTab({required this.ctrl});

//   @override
//   Widget build(BuildContext context) {
//     final wc = context.wColors;
//     final isDark = context.isDark;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(32.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Coastline & Maritime Forecast", 
//             style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//               fontWeight: FontWeight.w800,
//               color: wc.textPrimary,
//             ) ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 24),

//           // 1. DATE, TIME & SUMMARY SECTION
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: _cardDecoration(context),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Issue & Validity Selectors
//                 Row(
//                   children: [
//                     // ISSUE TIME (Editable Dropdown)
//                     Expanded(child: _buildDateTimeSelector(
//                       context: context, 
//                       label: "ISSUE TIME", 
//                       dateObs: ctrl.issueDate, 
//                       timeObs: ctrl.issueTime, 
//                       themeColor: AppTheme.accentBlue,
//                       options: ctrl.zTimeOptions,
//                       onTimeChanged: ctrl.updateIssueTime
//                     )),
//                     const SizedBox(width: 24),
                    
//                     // VALID TIME (Locked, driven by Issue Time)
//                     Expanded(child: _buildLockedDateTimeSelector(
//                       context: context, 
//                       label: "VALID TIME (AUTO +1HR)", 
//                       dateObs: ctrl.validDate, 
//                       timeObs: ctrl.validTime, 
//                       themeColor: AppTheme.successGreen
//                     )),
//                   ],
//                 ),
//                 const SizedBox(height: 32),
                
//                 // Weather Summary Textbox
//                 Text("Weather Summary", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary)),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   key: ValueKey(ctrl.currentForecastId.value ?? 'new_summary'),
//                   initialValue: ctrl.weatherSummary.value,
//                   maxLines: 4,
//                   onChanged: (v) => ctrl.weatherSummary.value = v,
//                   decoration: _inputDecoration("Enter the general weather summary for the coastline...", wc),
//                   style: TextStyle(color: wc.textPrimary, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
//                 )
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),

//           // 2. SEA STATE & WARNINGS
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: _cardDecoration(context),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("State of the Sea", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary)),
//                 const SizedBox(height: 8),
//                 Obx(() => DropdownButtonFormField<String>(
//                   value: ctrl.stateOfSea.value,
//                   dropdownColor: wc.elevated,
//                   style: TextStyle(fontWeight: FontWeight.w600, color: wc.textPrimary, fontSize: 14),
//                   decoration: _inputDecoration("", wc, isDropdown: true),
//                   icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
//                   items: ctrl.seaStateOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
//                   onChanged: (val) { if(val != null) ctrl.stateOfSea.value = val; },
//                 )),
//                 const SizedBox(height: 24),
                
//                 Text("Warning / Important Notes", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.warningAmber)),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   key: ValueKey(ctrl.currentForecastId.value ?? 'new_warning'),
//                   initialValue: ctrl.warningText.value,
//                   onChanged: (v) => ctrl.warningText.value = v,
//                   decoration: InputDecoration(
//                     hintText: "e.g. WARNING: MAX WAVE CURRENT RANGE...",
//                     hintStyle: TextStyle(color: AppTheme.warningAmber.withOpacity(0.5)),
//                     filled: true, 
//                     fillColor: AppTheme.warningAmber.withOpacity(0.05),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.warningAmber.withOpacity(0.3))),
//                     enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.warningAmber.withOpacity(0.3))),
//                     focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.warningAmber, width: 1.5)),
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   ),
//                   style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
//                 )
//               ],
//             ),
//           ),
//           const SizedBox(height: 32),

//           // 3. TABLE & MAP ROW
//           // 3. IBF MAP (Now on Top, Full Width)
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text("Impact-Based Map", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: wc.textPrimary)),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: AppTheme.accentBlue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: const Text("EEZ Limit: 200NM", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.accentBlue)),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Container(
//                 height: 540, 
//                 width: double.infinity, // Forces the map to take the full width of the screen
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: wc.border),
//                   boxShadow: [
//                     BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 16, offset: const Offset(0, 6)),
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(16),
//                   child: CoastlineMapWidget(ctrl: ctrl, isDark: isDark), 
//                 ),
//               ),
//             ],
//           ),
          
//           const SizedBox(height: 32),

//           // 4. FORECAST PARAMETERS TABLE (Now at the Bottom, Full Width)
//          buildEnhancedForecastTable(
//   context: context,
//   ctrl: ctrl,
// ),
          
          
//           const SizedBox(height: 32),
//           InfoSidePanel(ctrl: ctrl, isDark: isDark),

//           const SizedBox(height: 48),
          
//           // ── SPLIT PUBLISH / DRAFT BUTTON ───────────────────────────────────
//           Center(
//             child: Obx(() {
//               if (ctrl.isPublishing.value) {
//                  return ElevatedButton.icon(
//                    onPressed: null,
//                    icon: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
//                    label: const Text("SAVING...", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
//                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
//                  );
//               }

//               final btnText = ctrl.isAdmin ? "PUBLISH COASTLINE" : "SUBMIT FOR APPROVAL";
//               final btnColor = ctrl.isAdmin ? AppTheme.successGreen : AppTheme.warningAmber;

//               return Container(
//                 decoration: BoxDecoration(
//                   color: btnColor,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(color: btnColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
//                   ],
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Main Publish Action
//                     InkWell(
//                       onTap: () => ctrl.saveForecast('published'),
//                       borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
//                         child: Row(
//                           children: [
//                             Icon(PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill), size: 20, color: Colors.white),
//                             const SizedBox(width: 12),
//                             Text(btnText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5)),
//                           ],
//                         ),
//                       ),
//                     ),
                    
//                     // Divider Line
//                     Container(width: 1, height: 60, color: Colors.white.withOpacity(0.3)),
                    
//                     // Dropdown Arrow for Drafts
//                     Theme(
//                       data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
//                       child: PopupMenuButton<String>(
//                         icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
//                         color: wc.card,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         offset: const Offset(0, -60), // Opens slightly above the button
//                         onSelected: (val) {
//                           if (val == 'draft') ctrl.saveForecast('draft');
//                         },
//                         itemBuilder: (ctx) => [
//                           PopupMenuItem(
//                             value: 'draft',
//                             child: Row(
//                               children: [
//                                 Icon(PhosphorIcons.floppyDisk(PhosphorIconsStyle.bold), size: 18, color: wc.textPrimary),
//                                 const SizedBox(width: 12),
//                                 Text("Save as Draft", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary)),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }),
//           ),
//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }

//   // --- UI HELPERS ---

//   BoxDecoration _cardDecoration(BuildContext context) {
//     final wc = context.wColors;
//     final isDark = context.isDark;
//     return BoxDecoration(
//       color: wc.card,
//       borderRadius: BorderRadius.circular(16),
//       border: Border.all(color: wc.border),
//       boxShadow: [
//         BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.06), blurRadius: 12, offset: const Offset(0, 4)),
//       ],
//     );
//   }

//   InputDecoration _inputDecoration(String hint, WColors wc, {bool isDropdown = false}) {
//     return InputDecoration(
//       hintText: hint,
//       hintStyle: TextStyle(color: wc.textMuted, fontSize: 13),
//       filled: true, fillColor: wc.elevated,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
//       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
//       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5))),
//       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isDropdown ? 14 : 16),
//     );
//   }

//   // Editable Dropdown (Issue Time)
//   Widget _buildDateTimeSelector({required BuildContext context, required String label, required Rx<DateTime> dateObs, required RxString timeObs, required Color themeColor, required List<String> options, required Function(String) onTimeChanged}) {
//     final wc = context.wColors;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: themeColor, letterSpacing: 1)),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Expanded(
//               flex: 3,
//               child: InkWell(
//                 onTap: () async {
//                   final d = await showDatePicker(context: context, initialDate: dateObs.value, firstDate: DateTime(2020), lastDate: DateTime(2030));
//                   if (d != null) dateObs.value = d;
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                   decoration: BoxDecoration(color: themeColor.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: themeColor.withOpacity(0.3))),
//                   child: Row(children: [
//                     Icon(PhosphorIcons.calendarBlank(), color: themeColor, size: 18), const SizedBox(width: 10),
//                     Obx(() => Text(DateFormat('dd MMM yyyy').format(dateObs.value), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: wc.textPrimary))),
//                   ]),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               flex: 2,
//               child: Obx(() => DropdownButtonFormField<String>(
//                 value: timeObs.value,
//                 dropdownColor: wc.elevated,
//                 style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: wc.textPrimary),
//                 icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
//                 decoration: InputDecoration(
//                   filled: true, fillColor: wc.elevated,
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
//                   enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                 ),
//                 items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
//                 onChanged: (val) { if(val != null) onTimeChanged(val); },
//               )),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   // Locked Input (Valid Time)
//   Widget _buildLockedDateTimeSelector({required BuildContext context, required String label, required Rx<DateTime> dateObs, required RxString timeObs, required Color themeColor}) {
//     final wc = context.wColors;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: themeColor, letterSpacing: 1)),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Expanded(
//               flex: 3,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                 decoration: BoxDecoration(color: wc.elevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: wc.borderSoft)),
//                 child: Row(children: [
//                   Icon(PhosphorIcons.calendarBlank(), color: wc.textMuted, size: 18), const SizedBox(width: 10),
//                   Obx(() => Text(DateFormat('dd MMM yyyy').format(dateObs.value), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: wc.textMuted))),
//                 ]),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               flex: 2,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                 decoration: BoxDecoration(color: wc.elevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: wc.borderSoft)),
//                 child: Obx(() => Text(timeObs.value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: wc.textMuted))),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

  
   
// }

// class _ActionBtn extends StatefulWidget {
//   final IconData icon;
//   final Color color;
//   final VoidCallback? onTap;
  
//   const _ActionBtn({required this.icon, required this.color, this.onTap});

//   @override
//   State<_ActionBtn> createState() => _ActionBtnState();
// }

// class _ActionBtnState extends State<_ActionBtn> {
//   bool _hovered = false;

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       onEnter: (_) => setState(() => _hovered = true),
//       onExit: (_) => setState(() => _hovered = false),
//       child: GestureDetector(
//         onTap: widget.onTap ?? (){},
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 150),
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: _hovered ? widget.color.withOpacity(0.1) : Colors.transparent,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: _hovered ? widget.color.withOpacity(0.3) : Colors.transparent),
//           ),
//           child: Icon(widget.icon, size: 18, color: widget.color),
//         ),
//       ),
//     );
//   }
// }