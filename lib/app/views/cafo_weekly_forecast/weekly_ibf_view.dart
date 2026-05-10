import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'package:weather_admin_dashboard/app/views/cafo_weekly_forecast/weekly_map_widget.dart';
import 'package:weather_admin_dashboard/app/views/widgets/audio_summary_dialog.dart';
import 'package:weather_admin_dashboard/app/views/widgets/risk_InfoSidePanel.dart';
import 'package:weather_admin_dashboard/app/controllers/weekly_ibf_controller.dart';

class WeeklyIBFView extends StatelessWidget {
  const WeeklyIBFView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(WeeklyIBFController());
    final wc = context.wColors;

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
              Tab(height: 56, icon: Icon(PhosphorIcons.clockCounterClockwise(), size: 20), text: "FORECAST HISTORY"),
              Tab(height: 56, icon: Icon(PhosphorIcons.mapTrifold(), size: 20), text: "FORECAST INPUT"),
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
              _InputTab(ctrl: ctrl),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 1: HISTORY VIEW WITH LIST ANALYTICS
// ============================================================================
class _HistoryTab extends StatelessWidget {
  final WeeklyIBFController ctrl;
  const _HistoryTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;
 
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("FORECAST ANALYTICS", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: wc.textPrimary, letterSpacing: 0.5)),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: ctrl.createNewForecast, 
                icon: Icon(PhosphorIcons.plus(), size: 16), 
                label: const Text("New Forecast", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
            decoration: BoxDecoration(color: wc.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: wc.border)),
            child: Obx(() {
              if (ctrl.isLoadingList.value) {
                return const Padding(padding: EdgeInsets.all(40.0), child: Center(child: CircularProgressIndicator()));
              }

              if (ctrl.forecastsList.isEmpty) {
                return const Padding(padding: EdgeInsets.all(40.0), child: Center(child: Text("No forecasts found. Start creating one!")));
              }

              return Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ctrl.forecastsList.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: wc.borderSoft),
                     itemBuilder: (context, index) {
                      final forecast = ctrl.forecastsList[index];
                      final author = forecast['author'] ?? {};
                      final authorUid = author['uid'] ?? '';
                      
                      String formattedDate = "Unknown Date";
                      var updated = forecast['updatedAt'];
                      if (updated != null) {
                        DateTime dt;
                        if (updated is Timestamp) {
                          dt = updated.toDate();
                        } else if (updated is DateTime) {
                          dt = updated;
                        } else {
                          dt = DateTime.tryParse(updated.toString()) ?? DateTime.now();
                        }
                        formattedDate = DateFormat('MMM dd, yyyy').format(dt);
                      }

                      String validity = forecast['validity'] ?? '--';
                      String issueTime = forecast['issueTime'] ?? '--';
                      String areas = forecast['areas'] ?? '--';
                      String status = forecast['status'] ?? 'draft';
                      String docId = forecast['id'];

                      // --- NEW: Extract existing audio data ---
                      Map<String, dynamic> existingAudios = forecast['audio_summaries'] ?? {};
                      bool hasAnyAudio = existingAudios.isNotEmpty;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        leading: CircleAvatar(backgroundColor: isDark ? Colors.grey.shade800 : Colors.blue.shade50, child: Icon(PhosphorIcons.mapTrifold(), color: isDark ? Colors.white70 : AppTheme.accentBlue, size: 20)),
                        title: Text("Weekly Forecast (Issue: $issueTime UTC)", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary, fontSize: 14)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.calendarBlank(), size: 14, color: wc.textMuted), const SizedBox(width: 4),
                              Text(formattedDate, style: TextStyle(color: wc.textMuted, fontSize: 12)), const SizedBox(width: 16),
                              Icon(PhosphorIcons.clock(), size: 14, color: wc.textMuted), const SizedBox(width: 4),
                              Text("Validity: $validity", style: TextStyle(color: wc.textMuted, fontSize: 12)), const SizedBox(width: 16),
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
                                onSelected: (value) => _handleMenuSelection(context, value, docId, forecast, authorUid),
                               itemBuilder: (context) => [
                                  if (ctrl.isSuperAdmin.value && status == 'pending_approval') ...[
                                    PopupMenuItem(value: 'approve', child: Row(children: [Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), size: 18, color: Colors.green), const SizedBox(width: 12), Text("Approve Forecast", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))])),
                                    const PopupMenuDivider(),
                                  ],
                                  if (ctrl.isSuperAdmin.value && status == 'published') ...[
                                    PopupMenuItem(value: 'revoke', child: Row(children: [Icon(PhosphorIcons.xCircle(PhosphorIconsStyle.fill), size: 18, color: Colors.orange), const SizedBox(width: 12), Text("Revoke Approval", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))])),
                                    const PopupMenuDivider(),
                                  ],
                                  PopupMenuItem(value: 'view', child: Row(children: [Icon(PhosphorIcons.eye(), size: 18, color: isDark ? Colors.white : Colors.black87), const SizedBox(width: 12), Text("View", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))])),
                                  PopupMenuItem(value: 'edit', child: Row(children: [Icon(PhosphorIcons.pencilSimple(), size: 18, color: isDark ? Colors.white : Colors.black87), const SizedBox(width: 12), Text("Edit / Update", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))])),
                                  const PopupMenuDivider(),
                                  
                                  // --- NEW AUDIO MENU ITEM ---
                                  PopupMenuItem(
                                    value: 'audio',
                                    child: Row(
                                      children: [
                                        Icon(hasAnyAudio ? PhosphorIcons.waveform() : PhosphorIcons.microphone(), size: 18, color: hasAnyAudio ? Colors.green : Colors.blueGrey),
                                        const SizedBox(width: 12),
                                        Text(hasAnyAudio ? "See/Edit Audios" : "Add Audio", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),

                                  PopupMenuItem(value: 'download_pdf', child: Row(children: [Icon(PhosphorIcons.downloadSimple(), size: 18, color: isDark ? Colors.white : Colors.black87), const SizedBox(width: 12), Text("Download IBF", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
          )
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

 void _handleMenuSelection(BuildContext context, String value, String docId, Map<String, dynamic> item, String authorUid) {
    switch (value) {
      case 'approve': ctrl.changeForecastStatus(docId, 'published', authorUid); break;
      case 'revoke': ctrl.changeForecastStatus(docId, 'pending_approval', authorUid); break;
      case 'view': ctrl.loadForecastForEditing(item, isViewOnly: true); break;
      case 'edit': ctrl.loadForecastForEditing(item, isViewOnly: false); break;
      case 'download_pdf': 
        ctrl.downloadForecastPdfAndImage(context, item); 
        break;
      case 'audio': // --- NEW AUDIO HANDLER ---
        // Grab the caution/short description to use as the script
        String summaryText = item['shortDescription'] ?? "Weekly General Forecast for ${item['validity']}. Please summarize the impacts.";
        Map<String, dynamic> existingAudios = item['audio_summaries'] ?? {};
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AudioSummaryDialog(
            forecastId: docId,
            collectionName: 'weekly_forecasts', // <--- Update this to match your actual weekly Firestore collection name!
            summaryText: summaryText,
            existingAudios: existingAudios,
          ),
        );
        break;
    }
  
  }
}

// ============================================================================
// TAB 2: INPUT MAPS & TABLE
// ============================================================================
class _InputTab extends StatelessWidget {
  final WeeklyIBFController ctrl;
  const _InputTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header, Date Picker & NEW Issue Time Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Draw Weekly Impact Areas", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: wc.textPrimary)),
              
              Row(
                children: [
                  // Start Date Picker
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: ctrl.validFrom.value, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (date != null) ctrl.updateStartDate(date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(color: AppTheme.accentBlue.withOpacity(0.08), border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(PhosphorIcons.calendarCheck(PhosphorIconsStyle.bold), color: AppTheme.accentBlue, size: 20), const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("START DATE", style: TextStyle(fontSize: 10, color: AppTheme.accentBlue, fontWeight: FontWeight.w800)),
                          Obx(() => Text(DateFormat('dd MMM yyyy').format(ctrl.validFrom.value), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.accentBlue))),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // NEW ISSUE TIME PANEL
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.08),
                      border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ISSUE TIME (UTC)", style: TextStyle(fontSize: 10, color: AppTheme.accentBlue, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        Obx(() => DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: ctrl.selectedIssueTime.value,
                            icon: Icon(PhosphorIcons.caretDown(), size: 14, color: AppTheme.accentBlue),
                            isDense: true,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.accentBlue),
                            dropdownColor: wc.card,
                            items: ctrl.issueTimeOptions.map((String val) {
                              return DropdownMenuItem<String>(value: val, child: Text(val));
                            }).toList(),
                            onChanged: (val) { if (val != null) ctrl.selectedIssueTime.value = val; },
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          // 3 MAPS ROW
          Container(
            height: 480,
            decoration: BoxDecoration(color: wc.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: wc.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Obx(() {
                final dates = ctrl.dynamicDates;
                return Row(
                  children: [
                    Expanded(child: WeeklyMapWidget(ctrl: ctrl, period: 'day1', dateLabel: "24 HOURS", isDark: isDark)),
                    Container(width: 1, color: wc.border),
                    Expanded(child: WeeklyMapWidget(ctrl: ctrl, period: 'day2', dateLabel: "MIDWEEK", isDark: isDark)),
                    Container(width: 1, color: wc.border),
                    Expanded(child: WeeklyMapWidget(ctrl: ctrl, period: 'day3', dateLabel: "WEEKEND", isDark: isDark)),
                  ],
                );
              }),
            ),
          ),
          
          const SizedBox(height: 40),
          InfoSidePanel(ctrl: ctrl, isDark: isDark),
          const SizedBox(height: 32),
          Text("Weekly Impact-Based Forecast Details", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: wc.textPrimary)),
          const SizedBox(height: 16),

          // IBF MATRIX TABLE (3 Conditions Layout)
          Container(
            decoration: BoxDecoration(color: wc.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: wc.border)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Obx(() {
                final dates = ctrl.dynamicDates;
                return Table(
                  border: TableBorder(horizontalInside: BorderSide(color: wc.borderSoft, width: 1), verticalInside: BorderSide(color: wc.borderSoft, width: 1)),
                  columnWidths: const {0: FixedColumnWidth(160), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1)},
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: wc.elevated),
                      children: [
                        _headerCell("SECTOR", context), 
                        _headerCell("24 HOURS", context), 
                        _headerCell("MIDWEEK", context),
                        _headerCell("WEEKEND", context), 
                      ],
                    ),
                    ...ctrl.sectors.asMap().entries.map((entry) {
                      int idx = entry.key; String sector = entry.value;
                      return TableRow(
                        decoration: BoxDecoration(color: idx.isEven ? Colors.transparent : wc.elevated.withOpacity(0.3)),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16), 
                            alignment: Alignment.center, 
                            child: Text(
                              sector.toUpperCase(), 
                              textAlign: TextAlign.center, 
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: wc.textPrimary, height: 1.3)
                            )
                          ),
                          _structuredInputCell(ctrl, sector, 0, context),
                          _structuredInputCell(ctrl, sector, 1, context),
                          _structuredInputCell(ctrl, sector, 2, context),
                        ],
                      );
                    })
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 32),
          
          // CAUTION FIELD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.warningAmber.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.warningAmber.withOpacity(0.3))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.fill), size: 24, color: AppTheme.warningAmber),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SHORT DESCRIPTION / CAUTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.warningAmber, letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: ctrl.shortDescription.value,
                        maxLines: 3, onChanged: (val) => ctrl.shortDescription.value = val,
                        style: TextStyle(color: wc.textPrimary, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(hintText: "Type a short description here...", hintStyle: TextStyle(color: wc.textMuted), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          
          // PUBLISH BUTTON
          // ── PUBLISH / DRAFT SPLIT BUTTON ───────────────────────────────────
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

              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppTheme.successGreen.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main Publish Action
                    InkWell(
                      onTap: () => ctrl.publishForecast(isDraft: false),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill), size: 20, color: Colors.white),
                            const SizedBox(width: 12),
                            const Text("PUBLISH WEEKLY IBF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                    
                    // Divider Line
                    Container(width: 1, height: 60, color: Colors.white.withOpacity(0.3)),
                    
                    // Dropdown Arrow for Drafts
                    Theme(
                      data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        color: wc.card,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        offset: const Offset(0, -60), // Opens slightly above the button
                        onSelected: (val) {
                          if (val == 'draft') ctrl.publishForecast(isDraft: true);
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

  Widget _headerCell(String text, BuildContext context) => Container(
    height: 65, padding: const EdgeInsets.all(8), alignment: Alignment.center, 
    child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: context.wColors.textSecondary, letterSpacing: 0.5, height: 1.4))
  );

  // 3-Input Cell with "Condition" Labels
  Widget _structuredInputCell(WeeklyIBFController ctrl, String sector, int dayIndex, BuildContext context) {
    final wc = context.wColors;
    final data = ctrl.ibfDetails[sector]![dayIndex];

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: data['risk'],
            decoration: InputDecoration(
              isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true, fillColor: _getRiskColor(data['risk']).withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _getRiskColor(data['risk'])),
            icon: Icon(PhosphorIcons.caretDown(), size: 14, color: _getRiskColor(data['risk'])),
            items: ctrl.riskLevels.map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl))).toList(),
            onChanged: (val) {
              if (val != null) { data['risk'] = val; ctrl.ibfDetails.refresh(); }
            },
          ),
          const SizedBox(height: 8),
          
          _buildMiniField(label: "Condition:", hint: "e.g. Expected weather...", val: data['cond1'], onChanged: (v) => data['cond1'] = v, wc: wc),
          const SizedBox(height: 6),
          _buildMiniField(label: "Condition:", hint: "e.g. Potential impacts...", val: data['cond2'], onChanged: (v) => data['cond2'] = v, wc: wc),
          const SizedBox(height: 6),
          _buildMiniField(label: "Condition:", hint: "e.g. Recommended actions...", val: data['cond3'], onChanged: (v) => data['cond3'] = v, wc: wc),
        ],
      ),
    );
  }

  Widget _buildMiniField({required String label, required String hint, required String val, required Function(String) onChanged, required dynamic wc}) {
    return TextFormField(
      initialValue: val,
      style: TextStyle(fontSize: 12, color: wc.textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixText: "$label ", prefixStyle: TextStyle(fontWeight: FontWeight.w800, color: wc.textSecondary, fontSize: 11),
        hintText: hint, hintStyle: TextStyle(fontSize: 11, color: wc.textMuted),
        filled: true, fillColor: wc.elevated.withOpacity(0.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
        isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }

  Color _getRiskColor(String level) {
    if (level.contains('Yellow')) return const Color.fromARGB(255, 245, 229, 11);
    if (level.contains('Orange')) return Colors.orange;
    if (level.contains('Red')) return Colors.redAccent;
    if (level.contains('White')) return Colors.grey.shade600;
    return AppTheme.successGreen;
  }
}