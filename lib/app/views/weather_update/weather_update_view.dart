import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'package:weather_admin_dashboard/app/views/weather_update/weather_update_map_widget.dart';
import 'package:weather_admin_dashboard/app/views/widgets/audio_summary_dialog.dart';
import 'package:weather_admin_dashboard/app/controllers/weather_update_controller.dart';
import 'package:weather_admin_dashboard/app/model/affected_area_row.dart';

class WeatherUpdateView extends StatelessWidget {
  const WeatherUpdateView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(WeatherUpdateController());
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
              Tab(height: 56, icon: Icon(PhosphorIcons.clockCounterClockwise(), size: 20), text: "UPDATE HISTORY"),
              Tab(height: 56, icon: Icon(PhosphorIcons.plusCircle(), size: 20), text: "NEW UPDATE"),
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

class _HistoryTab extends StatelessWidget {
  final WeatherUpdateController ctrl;
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
              Text("WEATHER UPDATE ANALYTICS", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: wc.textPrimary, letterSpacing: 0.5)),
              ElevatedButton.icon(
                onPressed: ctrl.createNewForecast, 
                icon: Icon(PhosphorIcons.plus(), size: 16), 
                label: const Text("New Update", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Obx(() => Row(
            children: [
              Expanded(child: _buildKpiCard("TOTAL UPDATES", ctrl.kpiTotal.value.toString(), PhosphorIcons.files(PhosphorIconsStyle.fill), Colors.blueAccent, isDark)),
              const SizedBox(width: 16),
              Expanded(child: _buildKpiCard("DRAFTED", ctrl.kpiDraft.value.toString(), PhosphorIcons.floppyDisk(PhosphorIconsStyle.fill), Colors.grey.shade600, isDark)),
              const SizedBox(width: 16),
              Expanded(child: _buildKpiCard("PENDING APPROVAL", ctrl.kpiPending.value.toString(), PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill), Colors.amber.shade700, isDark)),
              const SizedBox(width: 16),
              Expanded(child: _buildKpiCard("PUBLISHED", ctrl.kpiPublished.value.toString(), PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), Colors.green.shade600, isDark)),
            ],
          )),
          const SizedBox(height: 32),
          Text("RECENT UPDATES", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: wc.textPrimary, letterSpacing: 0.5)),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(color: wc.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: wc.border)),
            child: Obx(() {
              if (ctrl.isLoadingList.value) {
                return const Padding(padding: EdgeInsets.all(40.0), child: Center(child: CircularProgressIndicator()));
              }

              if (ctrl.forecastsList.isEmpty) {
                return const Padding(padding: EdgeInsets.all(40.0), child: Center(child: Text("No updates found. Start creating one!")));
              }

              return Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ctrl.forecastsList.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: wc.borderSoft),
                    itemBuilder: (context, index) {
                      final item = ctrl.forecastsList[index];
                      final author = item['author'] ?? {};
                      final authorUid = author['uid'] ?? '';
                      final status = item['status'] ?? 'draft';
                      final docId = item['id'];

                      String formattedDate = "Unknown Date";
                      var updated = item['updatedAt'];
                      if (updated != null) {
                        DateTime dt;
                        if (updated is Timestamp) dt = updated.toDate();
                        else if (updated is DateTime) dt = updated;
                        else dt = DateTime.tryParse(updated.toString()) ?? DateTime.now();
                        formattedDate = DateFormat('MMM dd, yyyy').format(dt);
                      }

                      String issueTime = item['issueTime'] ?? '--';
                      Map<String, dynamic> existingAudios = item['audio_summaries'] ?? {};
                      bool hasAnyAudio = existingAudios.isNotEmpty;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        leading: CircleAvatar(backgroundColor: isDark ? Colors.grey.shade800 : Colors.blue.shade50, child: Icon(PhosphorIcons.cloudSun(), color: isDark ? Colors.white70 : AppTheme.accentBlue, size: 20)),
                        title: Text("Weather Update (Issue: $issueTime UTC)", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary, fontSize: 14)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.calendarBlank(), size: 14, color: wc.textMuted), const SizedBox(width: 4),
                              Text(formattedDate, style: TextStyle(color: wc.textMuted, fontSize: 12)), const SizedBox(width: 16),
                              Icon(PhosphorIcons.user(), size: 14, color: wc.textMuted), const SizedBox(width: 4),
                              Text(author['name'] ?? 'Unknown', style: TextStyle(color: wc.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatusChip(status, wc),
                            const SizedBox(width: 16),
                            Theme(
                              data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                              child: PopupMenuButton<String>(
                                icon: Icon(PhosphorIcons.dotsThreeVertical(), color: wc.textSecondary),
                                color: isDark ? Colors.grey.shade800 : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                offset: const Offset(0, 40),
                                tooltip: "Update Options",
                                onSelected: (val) => _handleMenuSelection(context, val, docId, item, authorUid),
                                itemBuilder: (context) => [
                                  if (ctrl.isSuperAdmin.value && status == 'pending_approval') ...[
                                    PopupMenuItem(value: 'approve', child: Row(children: [Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), size: 18, color: Colors.green), const SizedBox(width: 12), Text("Approve Update", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))])),
                                    const PopupMenuDivider(),
                                  ],
                                  if (ctrl.isSuperAdmin.value && status == 'published') ...[
                                    PopupMenuItem(value: 'revoke', child: Row(children: [Icon(PhosphorIcons.xCircle(PhosphorIconsStyle.fill), size: 18, color: Colors.orange), const SizedBox(width: 12), Text("Revoke Approval", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))])),
                                    const PopupMenuDivider(),
                                  ],
                                  PopupMenuItem(value: 'view', child: Row(children: [Icon(PhosphorIcons.eye(), size: 18, color: isDark ? Colors.white : Colors.black87), const SizedBox(width: 12), Text("View", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))])),
                                  PopupMenuItem(value: 'edit', child: Row(children: [Icon(PhosphorIcons.pencilSimple(), size: 18, color: isDark ? Colors.white : Colors.black87), const SizedBox(width: 12), Text("Edit / Update", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))])),
                                  const PopupMenuDivider(),
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
                                  PopupMenuItem(value: 'download_pdf', child: Row(children: [Icon(PhosphorIcons.downloadSimple(), size: 18, color: isDark ? Colors.white : Colors.black87), const SizedBox(width: 12), Text("Download PDF", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))])),
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
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.5)), const SizedBox(height: 4), Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87))])
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, dynamic wc) {
    Color bg; Color text;
    switch (status) {
      case 'published': bg = Colors.green.withOpacity(0.1); text = Colors.green.shade700; break;
      case 'pending_approval': bg = Colors.amber.withOpacity(0.1); text = Colors.amber.shade800; break;
      case 'draft': bg = Colors.grey.withOpacity(0.1); text = Colors.grey.shade700; break;
      default: bg = Colors.grey.withOpacity(0.1); text = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }

  void _handleMenuSelection(BuildContext context, String value, String docId, Map<String, dynamic> data, String authorUid) {
    switch (value) {
      case 'approve': ctrl.showApprovalGroupDialog(docId, data, authorUid); break;
      case 'revoke': ctrl.changeForecastStatus(docId, 'pending_approval', authorUid); break;
      case 'view': ctrl.loadForecastForEditing(data, isViewOnly: true); break;
      case 'edit': ctrl.loadForecastForEditing(data); break;
      case 'audio': Get.dialog(AudioSummaryDialog(forecastId: docId, collectionName: 'weather_updates', summaryText: data['summary'] ?? '', existingAudios: data['audio_summaries'] ?? {})); break;
      case 'download_pdf': ctrl.downloadForecastPdfAndImage(context, data); break;
    }
  }
}

class _InputTab extends StatelessWidget {
  final WeatherUpdateController ctrl;
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
          // Header & Date Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Create Weather Update", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: wc.textPrimary)),
              Row(
                children: [
                   // Start Date Picker
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: ctrl.validFrom.value, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (date != null) ctrl.updateStartDate(date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: AppTheme.accentBlue.withOpacity(0.08), border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(PhosphorIcons.calendarCheck(), color: AppTheme.accentBlue, size: 20), const SizedBox(width: 12),
                        Obx(() => Text(DateFormat('dd MMM yyyy').format(ctrl.validFrom.value), style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accentBlue))),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Issue Time Picker
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: int.parse(ctrl.selectedIssueTime.value.substring(0, 2)),
                          minute: int.parse(ctrl.selectedIssueTime.value.substring(2, 4)),
                        ),
                      );
                      if (time != null) ctrl.updateIssueTime(time);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: AppTheme.accentBlue.withOpacity(0.08), border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(PhosphorIcons.clock(), color: AppTheme.accentBlue, size: 20), const SizedBox(width: 12),
                        Obx(() {
                          final timeStr = ctrl.selectedIssueTime.value;
                          final formattedTime = "${timeStr.substring(0, 2)}:${timeStr.substring(2, 4)} UTC";
                          return Text(formattedTime, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accentBlue));
                        }),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Target Groups Selector
                  ElevatedButton.icon(
                    onPressed: ctrl.showGroupSelectionDialog,
                    icon: Icon(PhosphorIcons.usersThree(), size: 18),
                    label: Obx(() => Text("Groups (${ctrl.selectedGroupIds.length})", style: const TextStyle(fontWeight: FontWeight.bold))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.accentBlue,
                      elevation: 0,
                      side: BorderSide(color: AppTheme.accentBlue.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          // MAIN CONTENT AREA
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: MAP & MATRIX
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Container(
                      height: 500,
                      decoration: BoxDecoration(color: wc.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: wc.border)),
                      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: WeatherUpdateMapWidget(ctrl: ctrl, isDark: isDark)),
                    ),
                    const SizedBox(height: 24),
                    _buildRiskMatrix(context),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // RIGHT: SUMMARY & LEGEND
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryField(context),
                    const SizedBox(height: 24),
                    _buildRiskLegend(context),
                    const SizedBox(height: 24),
                    _buildIconLegend(context),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // BOTTOM: AFFECTED AREAS TABLE
          _buildAffectedAreasTable(context),
          const SizedBox(height: 48),

          // ACTIONS
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: () => ctrl.publishForecast(isDraft: true), child: const Text("SAVE AS DRAFT")),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () { if (!ctrl.isPublishing.value) ctrl.publishForecast(); }, 
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                child: Obx(() => ctrl.isPublishing.value 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("PUBLISH UPDATE", style: TextStyle(fontWeight: FontWeight.bold))),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSummaryField(BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: wc.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: wc.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("SUMMARY", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: wc.textMuted)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl.summaryController,
            maxLines: 8,
            onChanged: (v) => ctrl.summary.value = v,
            decoration: InputDecoration(
              hintText: "Enter weather update summary here...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              fillColor: context.isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMatrix(BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: wc.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: wc.border)),
      child: Column(
        children: [
          Text("WEATHER FORECAST RISK MATRIX", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: wc.textMuted)),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: wc.border),
            children: [
              _buildMatrixRow(["High", "G", "H", "I"]),
              _buildMatrixRow(["Med", "D", "E", "F"]),
              _buildMatrixRow(["Low", "A", "B", "C"]),
              _buildMatrixRow(["Likelihood / Impact", "Low", "Med", "High"], isHeader: true),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildMatrixRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      children: cells.map((cell) {
        final color = ctrl.getMatrixColor(cell);
        return Container(
          height: 40,
          color: color,
          alignment: Alignment.center,
          child: Text(cell, style: TextStyle(fontWeight: FontWeight.bold, color: color != Colors.transparent ? Colors.black : (isHeader ? Colors.grey : null))),
        );
      }).toList(),
    );
  }

  Widget _buildRiskLegend(BuildContext context) {
    final risks = [
      {'label': 'Take Action', 'color': Colors.red},
      {'label': 'Be Prepared', 'color': Colors.orange},
      {'label': 'Be aware', 'color': Colors.yellow},
      {'label': 'Low risk', 'color': Colors.green},
      {'label': 'No risk', 'color': Colors.white},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.wColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.wColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("NOWCASTING RISK", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: context.wColors.textMuted)),
          const SizedBox(height: 12),
          ...risks.map((risk) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(width: 20, height: 20, decoration: BoxDecoration(color: risk['color'] as Color, border: Border.all(color: Colors.grey))),
                const SizedBox(width: 12),
                Text(risk['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildIconLegend(BuildContext context) {
    final icons = [
      {'label': 'Rain', 'icon': PhosphorIcons.cloudRain(PhosphorIconsStyle.fill)},
      {'label': 'Wind', 'icon': PhosphorIcons.wind(PhosphorIconsStyle.fill)},
      {'label': 'Dust', 'icon': PhosphorIcons.dotsNine(PhosphorIconsStyle.fill)},
      {'label': 'Hail', 'icon': PhosphorIcons.cloudSnow(PhosphorIconsStyle.fill)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.wColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.wColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("WEATHER ICONS", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: context.wColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: icons.map((item) => Column(
              children: [
                Icon(item['icon'] as IconData, size: 24),
                const SizedBox(height: 4),
                Text(item['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAffectedAreasTable(BuildContext context) {
    final wc = context.wColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("AREAS TO BE AFFECTED / VALID TIME", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: wc.textPrimary)),
            TextButton.icon(onPressed: ctrl.addAffectedAreaRow, icon: const Icon(Icons.add), label: const Text("Add Row")),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() => Table(
          border: TableBorder.all(color: wc.border),
          columnWidths: const {
            0: FlexColumnWidth(4),
            1: FixedColumnWidth(80),
            2: FixedColumnWidth(80),
            3: FixedColumnWidth(80),
            4: FixedColumnWidth(80),
            5: FixedColumnWidth(40),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: wc.border.withOpacity(0.1)),
              children: ["Areas & Valid Time", "T+1hr", "T+2hr", "T+3hr", "Outlook", ""].map((h) => Padding(padding: const EdgeInsets.all(12), child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            ),
            ...ctrl.affectedAreas.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: row.areaController,
                          onChanged: (v) => row.areas = v,
                          decoration: const InputDecoration(hintText: "Areas (e.g. Aflao, Ho...)"),
                        ),
                        TextField(
                          controller: row.timeController,
                          onChanged: (v) => row.validTime = v,
                          decoration: const InputDecoration(hintText: "Time (e.g. 1445 UTC - 1600UTC)"),
                        ),
                      ],
                    ),
                  ),
                  _buildMatrixSelector(row, 't1'),
                  _buildMatrixSelector(row, 't2'),
                  _buildMatrixSelector(row, 't3'),
                  _buildMatrixSelector(row, 'outlook'),
                  IconButton(onPressed: () => ctrl.removeAffectedAreaRow(index), icon: const Icon(Icons.delete, color: Colors.red, size: 20)),
                ],
              );
            }),
          ],
        )),
      ],
    );
  }

  Widget _buildMatrixSelector(AffectedAreaRow row, String field) {
    String value = '';
    if (field == 't1') value = row.t1;
    else if (field == 't2') value = row.t2;
    else if (field == 't3') value = row.t3;
    else if (field == 'outlook') value = row.outlook;

    return Center(
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'].map((l) => DropdownMenuItem(
          value: l, 
          child: Container(
            width: 30, height: 30, color: ctrl.getMatrixColor(l), alignment: Alignment.center,
            child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          )
        )).toList(),
        onChanged: (v) {
          if (v != null) {
            if (field == 't1') row.t1 = v;
            else if (field == 't2') row.t2 = v;
            else if (field == 't3') row.t3 = v;
            else if (field == 'outlook') row.outlook = v;
            ctrl.affectedAreas.refresh();
          }
        },
      ),
    );
  }
}
