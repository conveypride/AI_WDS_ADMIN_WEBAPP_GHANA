import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart'; 
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';
import 'package:weather_admin_dashboard/app/controllers/inland_forecast_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InlandListTab extends StatelessWidget {
  final InlandForecastController ctrl;
  
  const InlandListTab({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    // Determine if the logged-in user is a Super Admin
    final authCtrl = Get.find<AuthController>();
 
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
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
                ),
              ),
              const SizedBox(width: 12),
              // BUTTON TO CREATE NEW FORECAST
              ElevatedButton.icon(
                onPressed: ctrl.createNewForecast, 
                icon: Icon(PhosphorIcons.plus(), size: 16), 
                label: const Text("New Forecast", style: TextStyle(fontWeight: FontWeight.bold)),
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
          
          // ── REACTIVE KPI CARDS ─────────────────────────────────────────────
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
          Text(
            "RECENT FORECASTS", 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: wc.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // ── REACTIVE FORECAST LIST ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: wc.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: wc.border),
            ),
            child: Obx(() {
                 final currentUser = authCtrl.currentUser.value;
    final isSuperAdmin = currentUser != null && 
        (currentUser.role.contains('super_admin') || currentUser.role.contains('admin'));
print("Current User Role: ${currentUser?.role}, isSuperAdmin: $isSuperAdmin");
              if (ctrl.isLoadingList.value) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (ctrl.forecastsList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: Text("No forecasts found. Start creating one!")),
                );
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
                      final metadata = forecast['metadata'] ?? {};
                      final author = forecast['author'] ?? {};
                      
                      // Safe Date Formatting
                      String formattedDate = "Unknown Date";
                      if (forecast['updatedAt'] != null) {
                        DateTime dt = (forecast['updatedAt'] as Timestamp).toDate();
                        formattedDate = DateFormat('MMM dd, yyyy').format(dt);
                      }

                      String issueTime = metadata['issueTimeSlot'] ?? '--';
                      String status = forecast['status'] ?? 'draft';
                      String docId = forecast['id'];
                      String authorUid = author['uid'] ?? '';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
                          child: Icon(
                            PhosphorIcons.fileText(), 
                            color: isDark ? Colors.white70 : AppTheme.accentBlue, 
                            size: 20
                          ),
                        ),
                        title: Text(
                          "Daily Inland Forecast - ${metadata['date'] ?? ''}", 
                          style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary, fontSize: 14)
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.calendarBlank(), size: 14, color: wc.textMuted),
                              const SizedBox(width: 4),
                              Text(formattedDate, style: TextStyle(color: wc.textMuted, fontSize: 12)),
                              const SizedBox(width: 16),
                              Icon(PhosphorIcons.clock(), size: 14, color: wc.textMuted),
                              const SizedBox(width: 4),
                              Text("Slot: $issueTime UTC", style: TextStyle(color: wc.textMuted, fontSize: 12)),
                              const SizedBox(width: 16),
                              Icon(PhosphorIcons.user(), size: 14, color: wc.textMuted),
                              const SizedBox(width: 4),
                              Text(author['name'] ?? 'Unknown', style: TextStyle(color: wc.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatusChip(status),
                            const SizedBox(width: 16),
                            
                            // ── OPTIONS MENU ────────────
                            Theme(
                              data: Theme.of(context).copyWith(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                              ),
                              child: PopupMenuButton<String>(
                                icon: Icon(PhosphorIcons.dotsThreeVertical(), color: wc.textSecondary),
                                color: isDark ? Colors.grey.shade800 : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                offset: const Offset(0, 40),
                                tooltip: "Forecast Options",
                                onSelected: (value) => _handleMenuSelection(context, value, docId, authorUid),
                                itemBuilder: (context) => [
                                  // ── ADMIN APPROVAL BUTTONS ──
                                  if (isSuperAdmin && status == 'pending_approval') ...[
                                    PopupMenuItem(
                                      value: 'approve',
                                      child: Row(
                                        children: [
                                          Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), size: 18, color: Colors.green),
                                          const SizedBox(width: 12),
                                          Text("Approve Forecast", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                  ],
                                  if (isSuperAdmin && status == 'published') ...[
                                    PopupMenuItem(
                                      value: 'revoke',
                                      child: Row(
                                        children: [
                                          Icon(PhosphorIcons.xCircle(PhosphorIconsStyle.fill), size: 18, color: Colors.orange),
                                          const SizedBox(width: 12),
                                          Text("Revoke Approval", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                  ],
                                  
                                  // ── STANDARD BUTTONS ──
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(PhosphorIcons.eye(), size: 18, color: isDark ? Colors.white : Colors.black87),
                                        const SizedBox(width: 12),
                                        Text("View", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(PhosphorIcons.pencilSimple(), size: 18, color: isDark ? Colors.white : Colors.black87),
                                        const SizedBox(width: 12),
                                        Text("Edit / Update", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: 'download_pdf',
                                    child: Row(
                                      children: [
                                        Icon(PhosphorIcons.filePdf(), size: 18, color: AppTheme.dangerRed),
                                        const SizedBox(width: 12),
                                        Text("Download Table", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),

                                  PopupMenuItem(
                                    value: 'download_ibf',
                                    child: Row(
                                      children: [
                                        Icon(PhosphorIcons.mapTrifold(), size: 18, color: AppTheme.dangerRed),
                                        const SizedBox(width: 12),
                                        Text("Download IBF", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // ── PAGINATION 'LOAD MORE' BUTTON ──
                  Obx(() {
                    if (!ctrl.hasMore.value) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text("End of results", style: TextStyle(color: wc.textMuted, fontSize: 12)),
                      );
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: ctrl.isFetchingMore.value
                          ? const CircularProgressIndicator()
                          : TextButton.icon(
                              onPressed: ctrl.fetchMoreForecasts,
                              icon: Icon(PhosphorIcons.caretDown(), size: 16),
                              label: const Text("LOAD MORE", style: TextStyle(fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.accentBlue,
                              ),
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

  // --- Helper Widget: KPI Card ---
  Widget _buildKpiCard(String title, String count, IconData icon, Color iconColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.5)
              ),
              const SizedBox(height: 4),
              Text(
                count, 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- Helper Widget: Status Chip ---
  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String displayStatus = status.toUpperCase().replaceAll('_', ' ');

    if (status == 'draft') {
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
    } else if (status == 'pending_approval') {
      bgColor = Colors.amber.shade100;
      textColor = Colors.amber.shade900;
    } else if (status == 'published') {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    } else {
      bgColor = Colors.blue.shade100;
      textColor = Colors.blue.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.5
        ),
      ),
    );
  }

  // --- Helper Method: Handle Menu Clicks ---
 // --- Helper Method: Handle Menu Clicks ---
  void _handleMenuSelection(BuildContext context,String value, String docId, String authorUid) {
    switch (value) {
      case 'approve':
        ctrl.toggleForecastStatus(docId, 'published', authorUid);
        break;
      case 'revoke':
        ctrl.toggleForecastStatus(docId, 'pending_approval', authorUid);
        break;
      case 'view':
        // Find the exact forecast from our downloaded list
        final forecast = ctrl.forecastsList.firstWhere((f) => f['id'] == docId);
        ctrl.loadForecastForEditing(forecast, isViewOnly: true); // Trigger Load!
        break;
      case 'edit':
        final forecast = ctrl.forecastsList.firstWhere((f) => f['id'] == docId);
        ctrl.loadForecastForEditing(forecast, isViewOnly: false); // Trigger Load!
        break;
     case 'download_pdf':
        ctrl.downloadTableForecastPdfImage(docId); // Trigger the download!
        break;
      case 'download_ibf':
        ctrl.downloadForecastIbf(docId ); // Trigger the download! 
        break;

    }
  }
}