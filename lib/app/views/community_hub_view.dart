// lib/app/views/admin_community_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; 
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';

import 'package:weather_admin_dashboard/app/controllers/admin_community_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

class AdminCommunityView extends StatelessWidget {
  const AdminCommunityView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AdminCommunityController());
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
              Tab(icon: Icon(PhosphorIcons.usersThree()), text: "GROUPS MANAGEMENT"),
              Tab(icon: Icon(PhosphorIcons.chartLineUp()), text: "INTELLIGENCE & ANALYTICS"),
            ],
          ),
        ),
        
        // ── TAB CONTENT ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: ctrl.tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _GroupsManagementTab(ctrl: ctrl),
              _MapAnalyticsTab(ctrl: ctrl),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 1: GROUPS MANAGEMENT (MASTER-DETAIL)
// ============================================================================
class _GroupsManagementTab extends StatelessWidget {
  final AdminCommunityController ctrl;
  const _GroupsManagementTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;

    return Row(
      children: [
        // ── LEFT PANEL: List of Groups ────────────────────────────────────────
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: wc.card,
            border: Border(right: BorderSide(color: wc.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Community Channels", 
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: wc.textPrimary,
                      ),
                ),
              ),
              Expanded(
                child: Obx(() => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: ctrl.groups.length + 1, // +1 for the Create Button
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildCreateGroupButton(context);
                    
                    final group = ctrl.groups[index - 1];
                    final isSelected = ctrl.selectedGroupId.value == group['id'];
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (group['color'] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(group['icon'], color: group['color'], size: 20),
                        ),
                        title: Text(
                          group['name'], 
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, 
                            color: wc.textPrimary,
                            fontSize: 14,
                          ), 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "${group['subscribers']} members", 
                          style: TextStyle(fontSize: 12, color: wc.textMuted, fontWeight: FontWeight.w500),
                        ),
                        selected: isSelected,
                        selectedTileColor: AppTheme.accentBlue.withOpacity(0.08),
                        hoverColor: wc.elevated,
                        onTap: () => ctrl.selectGroup(group['id']),
                      ),
                    );
                  },
                )),
              ),
            ],
          ),
        ),

        // ── RIGHT PANEL: Active Group Feed & Controls ─────────────────────────
        Expanded(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Obx(() {
              if (ctrl.selectedGroupId.value == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill), size: 48, color: wc.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        "Select a group to manage", 
                        style: TextStyle(color: wc.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }
              if (ctrl.isChatLoading.value) {
                return Center(child: CircularProgressIndicator(color: AppTheme.accentBlue));
              }

              final group = ctrl.groups.firstWhere((g) => g['id'] == ctrl.selectedGroupId.value);

              return Column(
                children: [
                  // Chat Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: wc.card, 
                      border: Border(bottom: BorderSide(color: wc.borderSoft)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (group['color'] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(group['icon'], color: group['color'], size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group['name'], 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: wc.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Official Control Center", 
                                style: TextStyle(fontSize: 12, color: wc.textMuted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        // Global Group Actions
                        OutlinedButton.icon(
                          onPressed: (){}, 
                          icon: Icon(PhosphorIcons.gearSix(), size: 16), 
                          label: const Text("Group Settings", style: TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: wc.textPrimary,
                            side: BorderSide(color: wc.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chat Feed
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(32),
                      reverse: true,
                      itemCount: ctrl.activeChatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = ctrl.activeChatMessages[index];
                        return _buildAdminMessageCard(msg, context);
                      },
                    ),
                  ),

                  // Admin Input Area
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: wc.card,
                      border: Border(top: BorderSide(color: wc.borderSoft)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(PhosphorIcons.paperclip(), color: wc.textMuted), 
                          onPressed: (){},
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: ctrl.chatTextController,
                            style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: "Broadcast official message or reply...",
                              hintStyle: TextStyle(color: wc.textMuted),
                              filled: true, 
                              fillColor: wc.elevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton(
                          elevation: 0,
                          backgroundColor: AppTheme.accentBlue,
                          onPressed: ctrl.sendMessage,
                          child:  Icon(PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill), color: Colors.white, size: 20),
                        )
                      ],
                    ),
                  )
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateGroupButton(BuildContext context) {
    final wc = context.wColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0, left: 4, right: 4),
      child: InkWell(
        onTap: () => _showCreateGroupDialog(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.accentBlue.withOpacity(0.5), style: BorderStyle.solid, width: 1.5), 
            borderRadius: BorderRadius.circular(10), 
            color: AppTheme.accentBlue.withOpacity(0.05),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.plusCircle(), color: AppTheme.accentBlue),
              const SizedBox(width: 8),
              Text(
                "Create New Group", 
                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accentBlue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final wc = context.wColors;
    String name = "";
    String type = "Official";
    
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: wc.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: wc.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Create Community Group", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: wc.textPrimary)),
              const SizedBox(height: 24),
              TextField(
                decoration: _inputDecoration("Group Name", wc), 
                style: TextStyle(color: wc.textPrimary),
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type, 
                dropdownColor: wc.elevated,
                style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                items: ["Official", "Marine", "Agro", "Social"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => type = v!, 
                decoration: _inputDecoration("Category", wc),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(), 
                    style: TextButton.styleFrom(foregroundColor: wc.textSecondary),
                    child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      ctrl.createNewGroup(name, type);
                      Get.back();
                    }, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Create", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              )
            ],
          ),
        ),
      )
    );
  }

  Widget _buildAdminMessageCard(Map<String, dynamic> msg, BuildContext context) {
    final wc = context.wColors;
    bool isAdminMsg = msg['is_admin'];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAdminMsg ? AppTheme.accentBlue.withOpacity(0.15) : wc.elevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAdminMsg ? PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill) : PhosphorIcons.user(PhosphorIconsStyle.fill), 
              color: isAdminMsg ? AppTheme.accentBlue : wc.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      msg['author'], 
                      style: TextStyle(
                        fontWeight: FontWeight.w700, 
                        color: isAdminMsg ? AppTheme.accentBlue : wc.textPrimary,
                        fontSize: 14,
                      )
                    ),
                    const SizedBox(width: 12),
                    Text(
                      msg['time'], 
                      style: TextStyle(fontSize: 11, color: wc.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isAdminMsg ? AppTheme.accentBlue.withOpacity(0.08) : wc.card, 
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ), 
                    border: Border.all(color: isAdminMsg ? AppTheme.accentBlue.withOpacity(0.3) : wc.borderSoft),
                  ),
                  child: Text(
                    msg['content'], 
                    style: TextStyle(color: wc.textPrimary, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ADMIN POWER CONTROLS
          PopupMenuButton<String>(
            icon: Icon(PhosphorIcons.dotsThreeVertical(), color: wc.textMuted),
            color: wc.elevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: wc.borderSoft)),
            onSelected: (action) {
              if (action == 'delete') ctrl.deleteMessage(msg['id']);
              if (action == 'ban') ctrl.banUser(msg['author']);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'reply', child: Text("Reply to Post", style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500))),
              if (!isAdminMsg) PopupMenuItem(value: 'delete', child: Text("Delete Post", style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.w600))),
              if (!isAdminMsg) PopupMenuItem(value: 'ban', child: Text("Ban User", style: TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.w600))),
            ],
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, WColors wc) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: wc.textSecondary),
      filled: true,
      fillColor: wc.elevated,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: wc.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5), width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: wc.borderSoft),
      ),
    );
  }
}

// ============================================================================
// TAB 2: INTELLIGENCE MAP & ADVANCED ANALYTICS 
// ============================================================================
class _MapAnalyticsTab extends StatelessWidget {
  final AdminCommunityController ctrl;
  const _MapAnalyticsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Stack(
      children: [
        // 1. FULL-SCREEN IMMERSIVE MAP
        Positioned.fill(
          child: Obx(() => FlutterMap(
            mapController: ctrl.mapController,
            options: const MapOptions(initialCenter: LatLng(7.9465, -1.0232), initialZoom: 6.5),
            children: [
              // Dark Mode Map Tile simulation
              ColorFiltered(
                colorFilter: isDark 
                  ? const ColorFilter.matrix([
                      0.28, 0.28, 0.28, 0, -30,
                      0.28, 0.28, 0.28, 0, -30,
                      0.28, 0.28, 0.28, 0, -30,
                      0,    0,    0,    1,   0,
                    ]) 
                  : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                child: TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', 
                  userAgentPackageName: 'com.gmet.weather'
                ),
              ),
              
              // HEATMAP (Glowing Orbs)
              if (ctrl.showHeatmap.value)
                MarkerLayer(
                  markers: ctrl.userDensity.map((density) => Marker(
                    point: LatLng(density['lat'], density['lng']),
                    width: density['radius'] * 2, height: density['radius'] * 2,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.dangerRed.withOpacity(density['intensity']),
                            AppTheme.dangerRed.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  )).toList(),
                ),

              // LIVE USERS (Avatars)
              if (ctrl.showLiveUsers.value)
                MarkerLayer(
                  markers: ctrl.liveUsers.map((user) => Marker(
                    point: LatLng(user['lat'], user['lng']),
                    width: 40, height: 40,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: user['color'], 
                            shape: BoxShape.circle, 
                            border: Border.all(color: Colors.white, width: 2), 
                            boxShadow: [BoxShadow(color: (user['color'] as Color).withOpacity(0.6), blurRadius: 8, spreadRadius: 2)],
                          ),
                          child:  Icon(PhosphorIcons.user(PhosphorIconsStyle.fill), color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  )).toList(),
                ),

              // REPORTED EVENTS (Glowing Pins)
              if (ctrl.showReports.value)
                MarkerLayer(
                  markers: ctrl.citizenReports.map((report) => Marker(
                    point: LatLng(report['lat'], report['lng']), width: 60, height: 60,
                    child: Tooltip(
                      message: "${report['type']}: ${report['desc']} (${report['time']})",
                      preferBelow: false,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getReportColor(report['type']).withOpacity(0.6),
                              blurRadius: 12, spreadRadius: 4,
                            )
                          ]
                        ),
                        child: CircleAvatar(
                          backgroundColor: _getReportColor(report['type']),
                          child: Icon(_getReportIcon(report['type']), color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  )).toList(),
                )
            ],
          )),
        ),

        // 2. FLOATING MAP CONTROLS (Top Left)
        Positioned(
          top: 24, left: 24,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.85), 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: wc.border.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    _buildMapToggle("Heatmap", PhosphorIcons.fire(), ctrl.showHeatmap, context),
                    _buildMapToggle("Live Activity", PhosphorIcons.users(), ctrl.showLiveUsers, context),
                    _buildMapToggle("Reports", PhosphorIcons.warningCircle(), ctrl.showReports, context),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3. FLOATING ADVANCED ANALYTICS PANEL (Right Side)
        Positioned(
          top: 24, bottom: 24, right: 24,
          width: 380, 
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151E32).withOpacity(0.85) : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: wc.borderSoft.withOpacity(0.5), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Live Intelligence", 
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: wc.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 28),
                      
                      // KPIs
                      Row(
                        children: [
                          Expanded(child: _buildMiniKPI("Total Users", ctrl.totalUsers.value, AppTheme.accentBlue, context)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildMiniKPI("Active Now", ctrl.activeReporters.value, AppTheme.successGreen, context)),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // LINE CHART (Engagement Trend)
                      Text("Engagement Trend (7 Days)", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary, fontSize: 13)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false), 
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: ctrl.engagementTrend.map((e) => FlSpot(e['day']!, e['value']!)).toList(),
                                isCurved: true,
                                color: AppTheme.accentBlue,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppTheme.accentBlue.withOpacity(0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // DOUGHNUT CHART (Report Distribution)
                      Text("Citizen Report Types", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary, fontSize: 13)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 2, centerSpaceRadius: 55,
                                sections: [
                                  PieChartSectionData(color: AppTheme.accentBlue, value: ctrl.reportDistribution['Flood'], title: '45%', radius: 22, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  PieChartSectionData(color: AppTheme.warningAmber, value: ctrl.reportDistribution['Storm/Wind'], title: '30%', radius: 22, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  PieChartSectionData(color: AppTheme.dangerRed, value: ctrl.reportDistribution['Heat/Drought'], title: '15%', radius: 22, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  PieChartSectionData(color: AppTheme.darkTextSecondary, value: ctrl.reportDistribution['Other'], title: '10%', radius: 22, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            ),
                            // Center Text
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("87", style: TextStyle(fontFamily: 'Syne', fontSize: 28, fontWeight: FontWeight.w900, color: wc.textPrimary)),
                                Text("Reports", style: TextStyle(fontSize: 11, color: wc.textMuted, fontWeight: FontWeight.w600)),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      // Chart Legend
                      Wrap(
                        spacing: 16, runSpacing: 12,
                        children: [
                          _buildLegendItem(AppTheme.accentBlue, "Flood", context),
                          _buildLegendItem(AppTheme.warningAmber, "Storm", context),
                          _buildLegendItem(AppTheme.dangerRed, "Drought", context),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildMapToggle(String label, IconData icon, RxBool toggle, BuildContext context) {
    final wc = context.wColors;
    return Obx(() {
      final isSelected = toggle.value;
      return InkWell(
        onTap: () => toggle.value = !toggle.value,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4), 
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentBlue.withOpacity(0.15) : Colors.transparent, 
            borderRadius: BorderRadius.circular(10)
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? AppTheme.accentBlue : wc.textMuted), 
              const SizedBox(width: 8),
              Text(
                label, 
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, 
                  color: isSelected ? AppTheme.accentBlue : wc.textSecondary,
                )
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMiniKPI(String title, String value, Color color, BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: wc.elevated.withOpacity(0.5), 
        border: Border.all(color: wc.borderSoft),
        borderRadius: BorderRadius.circular(16)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: wc.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.wColors.textSecondary)),
      ],
    );
  }

  Color _getReportColor(String type) {
    if (type == 'Flood') return AppTheme.accentBlue;
    if (type == 'Storm') return AppTheme.warningAmber;
    return AppTheme.dangerRed;
  }

  IconData _getReportIcon(String type) {
    if (type == 'Flood') return PhosphorIcons.waves(PhosphorIconsStyle.fill);
    if (type == 'Storm') return PhosphorIcons.wind(PhosphorIconsStyle.fill);
    return PhosphorIcons.sun(PhosphorIconsStyle.fill);
  }
}
// // lib/app/views/admin_community_view.dart

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart'; 
// import 'package:fl_chart/fl_chart.dart';
// import 'dart:ui';

// import 'package:weather_admin_dashboard/app/controllers/admin_community_controller.dart'; // Needed for ImageFilter.blur

// class AdminCommunityView extends StatelessWidget {
//   const AdminCommunityView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ctrl = Get.put(AdminCommunityController());
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final primaryColor = isDark ? Colors.blueAccent : const Color(0xFF0B4EA2);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // TAB BAR
//         Container(
//           decoration: BoxDecoration(color: isDark ? const Color(0xFF252525) : Colors.white, border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300))),
//           child: TabBar(
//             controller: ctrl.tabController, labelColor: primaryColor, unselectedLabelColor: Colors.grey, indicatorColor: primaryColor, indicatorWeight: 3,
//             labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 13),
//             tabs: [
//               Tab(icon: Icon(PhosphorIcons.usersThree()), text: "GROUPS MANAGEMENT"),
//               Tab(icon: Icon(PhosphorIcons.chartLineUp()), text: "INTELLIGENCE & ANALYTICS"),
//             ],
//           ),
//         ),
        
//         // TAB CONTENT
//         Expanded(
//           child: TabBarView(
//             controller: ctrl.tabController,
//             physics: const NeverScrollableScrollPhysics(),
//             children: [
//               _GroupsManagementTab(ctrl: ctrl, isDark: isDark),
//               _MapAnalyticsTab(ctrl: ctrl, isDark: isDark),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ============================================================================
// // TAB 1: GROUPS MANAGEMENT (MASTER-DETAIL)
// // ============================================================================
// class _GroupsManagementTab extends StatelessWidget {
//   final AdminCommunityController ctrl;
//   final bool isDark;
//   const _GroupsManagementTab({required this.ctrl, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         // LEFT PANEL: List of Groups
//         Container(
//           width: 320,
//           decoration: BoxDecoration(
//             color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//             border: Border(right: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
//           ),
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text("Community Channels", style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//               ),
//               Expanded(
//                 child: Obx(() => ListView.builder(
//                   itemCount: ctrl.groups.length + 1, // +1 for the Create Button
//                   itemBuilder: (context, index) {
//                     if (index == 0) return _buildCreateGroupButton(context);
//                     final group = ctrl.groups[index - 1];
//                     final isSelected = ctrl.selectedGroupId.value == group['id'];
                    
//                     return ListTile(
//                       leading: CircleAvatar(backgroundColor: group['color'].withOpacity(0.2), child: Icon(group['icon'], color: group['color'], size: 20)),
//                       title: Text(group['name'], style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
//                       subtitle: Text("${group['subscribers']} members", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
//                       selected: isSelected,
//                       selectedTileColor: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50,
//                       onTap: () => ctrl.selectGroup(group['id']),
//                     );
//                   },
//                 )),
//               ),
//             ],
//           ),
//         ),

//         // RIGHT PANEL: Active Group Feed & Controls
//         Expanded(
//           child: Container(
//             color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
//             child: Obx(() {
//               if (ctrl.selectedGroupId.value == null) {
//                 return Center(child: Text("Select a group to manage", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)));
//               }
//               if (ctrl.isChatLoading.value) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               final group = ctrl.groups.firstWhere((g) => g['id'] == ctrl.selectedGroupId.value);

//               return Column(
//                 children: [
//                   // Chat Header
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//                     decoration: BoxDecoration(color: isDark ? const Color(0xFF252525) : Colors.white, border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300))),
//                     child: Row(
//                       children: [
//                         CircleAvatar(backgroundColor: group['color'].withOpacity(0.2), child: Icon(group['icon'], color: group['color'])),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(group['name'], style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//                               Text("Official Control Center", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
//                             ],
//                           ),
//                         ),
//                         // Global Group Actions
//                         OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.settings, size: 16), label: const Text("Group Settings")),
//                       ],
//                     ),
//                   ),

//                   // Chat Feed
//                   Expanded(
//                     child: ListView.builder(
//                       padding: const EdgeInsets.all(24),
//                       reverse: true,
//                       itemCount: ctrl.activeChatMessages.length,
//                       itemBuilder: (context, index) {
//                         final msg = ctrl.activeChatMessages[index];
//                         return _buildAdminMessageCard(msg);
//                       },
//                     ),
//                   ),

//                   // Admin Input Area
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//                     child: Row(
//                       children: [
//                         IconButton(icon: Icon(Icons.attach_file, color: Colors.grey.shade500), onPressed: (){}),
//                         Expanded(
//                           child: TextField(
//                             controller: ctrl.chatTextController,
//                             style: TextStyle(color: isDark ? Colors.white : Colors.black),
//                             decoration: InputDecoration(
//                               hintText: "Broadcast official message or reply...",
//                               hintStyle: TextStyle(color: Colors.grey.shade500),
//                               filled: true, fillColor: isDark ? Colors.black : Colors.grey.shade100,
//                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
//                               contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         FloatingActionButton(
//                           elevation: 0, mini: true,
//                           backgroundColor: Colors.blue.shade600,
//                           onPressed: ctrl.sendMessage,
//                           child: const Icon(Icons.send, color: Colors.white, size: 18),
//                         )
//                       ],
//                     ),
//                   )
//                 ],
//               );
//             }),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCreateGroupButton(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: InkWell(
//         onTap: () => _showCreateGroupDialog(context),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(border: Border.all(color: Colors.blue.shade300, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8), color: Colors.blue.withOpacity(0.05)),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(PhosphorIcons.plusCircle(), color: Colors.blue.shade700),
//               const SizedBox(width: 8),
//               Text("Create New Group", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showCreateGroupDialog(BuildContext context) {
//     String name = "";
//     String type = "Official";
//     Get.dialog(
//       AlertDialog(
//         backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
//         title: const Text("Create Community Group"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(decoration: const InputDecoration(labelText: "Group Name"), onChanged: (v) => name = v),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: type, items: ["Official", "Marine", "Agro", "Social"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//               onChanged: (v) => type = v!, decoration: const InputDecoration(labelText: "Category"),
//             )
//           ],
//         ),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
//           ElevatedButton(onPressed: () => ctrl.createNewGroup(name, type), child: const Text("Create")),
//         ],
//       )
//     );
//   }

//   Widget _buildAdminMessageCard(Map<String, dynamic> msg) {
//     bool isAdminMsg = msg['is_admin'];
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CircleAvatar(
//             backgroundColor: isAdminMsg ? Colors.blue.shade100 : Colors.grey.shade200,
//             child: Icon(isAdminMsg ? Icons.verified_user : Icons.person, color: isAdminMsg ? Colors.blue : Colors.grey),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(msg['author'], style: TextStyle(fontWeight: FontWeight.bold, color: isAdminMsg ? Colors.blue : (isDark ? Colors.white : Colors.black))),
//                     const SizedBox(width: 8),
//                     Text(msg['time'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(color: isAdminMsg ? (isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50) : (isDark ? Colors.grey.shade800 : Colors.white), borderRadius: BorderRadius.circular(8), border: Border.all(color: isAdminMsg ? Colors.blue.shade200 : Colors.transparent)),
//                   child: Text(msg['content'], style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
//                 ),
//               ],
//             ),
//           ),
//           // ADMIN POWER CONTROLS
//           PopupMenuButton<String>(
//             icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
//             color: isDark ? Colors.grey.shade800 : Colors.white,
//             onSelected: (action) {
//               if (action == 'delete') ctrl.deleteMessage(msg['id']);
//               if (action == 'ban') ctrl.banUser(msg['author']);
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem(value: 'reply', child: Text("Reply to Post")),
//               if (!isAdminMsg) const PopupMenuItem(value: 'delete', child: Text("Delete Post", style: TextStyle(color: Colors.red))),
//               if (!isAdminMsg) const PopupMenuItem(value: 'ban', child: Text("Ban User", style: TextStyle(color: Colors.orange))),
//             ],
//           )
//         ],
//       ),
//     );
//   }
// }

//  // ============================================================================
// // TAB 2: INTELLIGENCE MAP & ADVANCED ANALYTICS (SNAPCHAT / COMMAND CENTER STYLE)
// // ============================================================================
// class _MapAnalyticsTab extends StatelessWidget {
//   final AdminCommunityController ctrl;
//   final bool isDark;
//   const _MapAnalyticsTab({required this.ctrl, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         // 1. FULL-SCREEN IMMERSIVE MAP
//         Positioned.fill(
//           child: Obx(() => FlutterMap(
//             mapController: ctrl.mapController,
//             options: const MapOptions(initialCenter: LatLng(7.9465, -1.0232), initialZoom: 6.5),
//             children: [
//               // Dark Mode Map Tile simulation (Inverts colors if in dark mode for a sleek look)
//               ColorFiltered(
//                 colorFilter: isDark 
//                   ? const ColorFilter.matrix([-1, 0, 0, 0, 255,  0, -1, 0, 0, 255,  0, 0, -1, 0, 255,  0, 0, 0, 1, 0]) // Invert colors
//                   : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
//                 child: TileLayer(
//                   urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', 
//                   userAgentPackageName: 'com.gmet.weather'
//                 ),
//               ),
              
//               // HEATMAP (Glowing Orbs)
//               if (ctrl.showHeatmap.value)
//                 MarkerLayer(
//                   markers: ctrl.userDensity.map((density) => Marker(
//                     point: LatLng(density['lat'], density['lng']),
//                     width: density['radius'] * 2, height: density['radius'] * 2,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         gradient: RadialGradient(
//                           colors: [
//                             Colors.red.withOpacity(density['intensity']),
//                             Colors.red.withOpacity(0.0),
//                           ],
//                         ),
//                       ),
//                     ),
//                   )).toList(),
//                 ),

//               // LIVE USERS (Snapchat style Bitmoji/Avatars)
//               if (ctrl.showLiveUsers.value)
//                 MarkerLayer(
//                   markers: ctrl.liveUsers.map((user) => Marker(
//                     point: LatLng(user['lat'], user['lng']),
//                     width: 40, height: 40,
//                     child: Column(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(4),
//                           decoration: BoxDecoration(color: user['color'], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: user['color'].withOpacity(0.6), blurRadius: 8, spreadRadius: 2)]),
//                           child: const Icon(Icons.person, color: Colors.white, size: 16),
//                         ),
//                       ],
//                     ),
//                   )).toList(),
//                 ),

//               // REPORTED EVENTS (Glowing Pins)
//               if (ctrl.showReports.value)
//                 MarkerLayer(
//                   markers: ctrl.citizenReports.map((report) => Marker(
//                     point: LatLng(report['lat'], report['lng']), width: 60, height: 60,
//                     child: Tooltip(
//                       message: "${report['type']}: ${report['desc']} (${report['time']})",
//                       preferBelow: false,
//                       textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//                       decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
//                       child: Container(
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: _getReportColor(report['type']).withOpacity(0.6),
//                               blurRadius: 12, spreadRadius: 4,
//                             )
//                           ]
//                         ),
//                         child: CircleAvatar(
//                           backgroundColor: _getReportColor(report['type']),
//                           child: Icon(_getReportIcon(report['type']), color: Colors.white, size: 20),
//                         ),
//                       ),
//                     ),
//                   )).toList(),
//                 )
//             ],
//           )),
//         ),

//         // 2. FLOATING MAP CONTROLS (Top Left)
//         Positioned(
//           top: 20, left: 20,
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//               child: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.2))),
//                 child: Row(
//                   children: [
//                     _buildMapToggle("Heatmap", PhosphorIcons.fire(), ctrl.showHeatmap),
//                     _buildMapToggle("Live Activity", PhosphorIcons.users(), ctrl.showLiveUsers),
//                     _buildMapToggle("Reports", PhosphorIcons.warningCircle(), ctrl.showReports),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),

//         // 3. FLOATING ADVANCED ANALYTICS PANEL (Right Side)
//         Positioned(
//           top: 20, bottom: 20, right: 20,
//           width: 380, // Fixed width for the glass panel
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(24),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//               child: Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: isDark ? const Color(0xFF121212).withOpacity(0.7) : Colors.white.withOpacity(0.85),
//                   borderRadius: BorderRadius.circular(24),
//                   border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
//                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
//                 ),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text("Live Intelligence", style: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//                       const SizedBox(height: 24),
                      
//                       // KPIs
//                       Row(
//                         children: [
//                           Expanded(child: _buildMiniKPI("Total Users", ctrl.totalUsers.value, Colors.blue)),
//                           const SizedBox(width: 16),
//                           Expanded(child: _buildMiniKPI("Active Now", ctrl.activeReporters.value, Colors.green)),
//                         ],
//                       ),
//                       const SizedBox(height: 32),

//                       // LINE CHART (Engagement Trend)
//                       Text("Engagement Trend (7 Days)", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
//                       const SizedBox(height: 16),
//                       SizedBox(
//                         height: 180,
//                         child: LineChart(
//                           LineChartData(
//                             gridData: const FlGridData(show: false),
//                             titlesData: const FlTitlesData(show: false), // Hide axis labels for a sleek look
//                             borderData: FlBorderData(show: false),
//                             lineBarsData: [
//                               LineChartBarData(
//                                 spots: ctrl.engagementTrend.map((e) => FlSpot(e['day']!, e['value']!)).toList(),
//                                 isCurved: true,
//                                 color: Colors.blueAccent,
//                                 barWidth: 4,
//                                 isStrokeCapRound: true,
//                                 dotData: const FlDotData(show: false),
//                                 belowBarData: BarAreaData(
//                                   show: true,
//                                   color: Colors.blueAccent.withOpacity(0.2),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 32),

//                       // DOUGHNUT CHART (Report Distribution)
//                       Text("Citizen Report Types", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
//                       const SizedBox(height: 16),
//                       SizedBox(
//                         height: 180,
//                         child: Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             PieChart(
//                               PieChartData(
//                                 sectionsSpace: 2, centerSpaceRadius: 50,
//                                 sections: [
//                                   PieChartSectionData(color: Colors.blue, value: ctrl.reportDistribution['Flood'], title: '45%', radius: 20, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
//                                   PieChartSectionData(color: Colors.orange, value: ctrl.reportDistribution['Storm/Wind'], title: '30%', radius: 20, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
//                                   PieChartSectionData(color: Colors.red, value: ctrl.reportDistribution['Heat/Drought'], title: '15%', radius: 20, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
//                                   PieChartSectionData(color: Colors.grey, value: ctrl.reportDistribution['Other'], title: '10%', radius: 20, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
//                                 ],
//                               ),
//                             ),
//                             // Center Text
//                             Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text("87", style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
//                                 Text("Reports", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
//                               ],
//                             )
//                           ],
//                         ),
//                       ),
                      
//                       const SizedBox(height: 16),
//                       // Chart Legend
//                       Wrap(
//                         spacing: 12, runSpacing: 8,
//                         children: [
//                           _buildLegendItem(Colors.blue, "Flood"),
//                           _buildLegendItem(Colors.orange, "Storm"),
//                           _buildLegendItem(Colors.red, "Drought"),
//                         ],
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // --- HELPERS ---

//   Widget _buildMapToggle(String label, IconData icon, RxBool toggle) {
//     return Obx(() {
//       final isSelected = toggle.value;
//       return InkWell(
//         onTap: () => toggle.value = !toggle.value,
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           decoration: BoxDecoration(color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
//           child: Row(
//             children: [
//               Icon(icon, size: 16, color: isSelected ? Colors.blueAccent : Colors.grey), const SizedBox(width: 8),
//               Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.blueAccent : Colors.grey)),
//             ],
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildMiniKPI(String title, String value, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 4),
//           Text(value, style: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
//         ],
//       ),
//     );
//   }

//   Widget _buildLegendItem(Color color, String label) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
//         const SizedBox(width: 6),
//         Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade800)),
//       ],
//     );
//   }

//   Color _getReportColor(String type) {
//     if (type == 'Flood') return Colors.blue;
//     if (type == 'Storm') return Colors.orange;
//     return Colors.red;
//   }

//   IconData _getReportIcon(String type) {
//     if (type == 'Flood') return PhosphorIcons.waves();
//     if (type == 'Storm') return PhosphorIcons.wind();
//     return PhosphorIcons.sun();
//   }
// }