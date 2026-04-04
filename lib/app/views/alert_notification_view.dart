import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:weather_admin_dashboard/app/controllers/alert_notification_controller.dart'; 

class AlertNotificationView extends StatelessWidget {
  const AlertNotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AlertNotificationController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.blueAccent : const Color(0xFF0B4EA2);

    return Column(
      children: [
        // TAB BAR
        Container(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          child: TabBar(
            controller: ctrl.tabController, labelColor: primaryColor, unselectedLabelColor: Colors.grey, indicatorColor: primaryColor, indicatorWeight: 3,
            labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(icon: Icon(PhosphorIcons.paperPlaneTilt()), text: "COMPOSE ALERT"),
              Tab(icon: Icon(PhosphorIcons.chartBar()), text: "HISTORY & ANALYTICS"),
            ],
          ),
        ),
        
        Expanded(
          child: TabBarView(
            controller: ctrl.tabController,
            children: [
              _ComposeTab(ctrl: ctrl, isDark: isDark),
              _HistoryAnalyticsTab(ctrl: ctrl, isDark: isDark),
            ],
          ),
        )
      ],
    );
  }
}

// ============================================================================
// TAB 1: COMPOSE ALERT
// ============================================================================
class _ComposeTab extends StatelessWidget {
  final AlertNotificationController ctrl;
  final bool isDark;
  const _ComposeTab({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800), // Keep form readable on wide screens
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: Icon(PhosphorIcons.bellRinging(PhosphorIconsStyle.fill), color: Colors.red)),
                  const SizedBox(width: 16),
                  Text("Dispatch Critical Alert", style: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                ],
              ),
              const SizedBox(height: 32),

              // 1. URGENCY LEVEL
              Text("Urgency Level", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
              const SizedBox(height: 12),
              Obx(() => Row(
                children: [
                  _buildUrgencyCard("Information", PhosphorIcons.info(), Colors.blue),
                  const SizedBox(width: 16),
                  _buildUrgencyCard("Warning", PhosphorIcons.warning(), Colors.orange),
                  const SizedBox(width: 16),
                  _buildUrgencyCard("Critical", PhosphorIcons.warningOctagon(), Colors.red),
                ],
              )),
              const SizedBox(height: 32),

              // 2. TARGET AUDIENCE & REGION
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Target Audience (Role)", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Obx(() => Wrap(
                          spacing: 8, runSpacing: 8,
                          children: ctrl.audienceOptions.map((aud) => ChoiceChip(
                            label: Text(aud), selected: ctrl.selectedAudiences.contains(aud),
                            selectedColor: Colors.blue.withOpacity(0.2), checkmarkColor: Colors.blue, labelStyle: TextStyle(color: ctrl.selectedAudiences.contains(aud) ? Colors.blue : (isDark ? Colors.grey.shade400 : Colors.grey.shade800), fontWeight: FontWeight.bold, fontSize: 12),
                            onSelected: (_) => ctrl.toggleAudience(aud),
                          )).toList(),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Target Region (Location)", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Obx(() => Wrap(
                          spacing: 8, runSpacing: 8,
                          children: ctrl.regionOptions.map((reg) => ChoiceChip(
                            label: Text(reg), selected: ctrl.selectedRegions.contains(reg),
                            selectedColor: Colors.green.withOpacity(0.2), checkmarkColor: Colors.green, labelStyle: TextStyle(color: ctrl.selectedRegions.contains(reg) ? Colors.green : (isDark ? Colors.grey.shade400 : Colors.grey.shade800), fontWeight: FontWeight.bold, fontSize: 12),
                            onSelected: (_) => ctrl.toggleRegion(reg),
                          )).toList(),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 3. MESSAGE CONTENT
              Text("Alert Title", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: ctrl.alertTitle.value, onChanged: (v) => ctrl.alertTitle.value = v,
                decoration: InputDecoration(hintText: "e.g. Severe Thunderstorm Warning", filled: true, fillColor: isDark ? Colors.black : Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300))),
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              Text("Alert Message", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: ctrl.alertMessage.value, onChanged: (v) => ctrl.alertMessage.value = v, maxLines: 5,
                decoration: InputDecoration(hintText: "Type the detailed alert information and instructions here...", filled: true, fillColor: isDark ? Colors.black : Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300))),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 40),

              // 4. SEND BUTTON
              SizedBox(
                width: double.infinity, height: 55,
                child: Obx(() => ElevatedButton.icon(
                  onPressed: ctrl.isSending.value ? null : ctrl.sendPushNotification,
                  icon: ctrl.isSending.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) :  Icon(PhosphorIcons.paperPlaneRight(), size: 24),
                  label: Text(ctrl.isSending.value ? "DISPATCHING..." : "DISPATCH NOTIFICATION TO DEVICES", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(backgroundColor: _getBtnColor(), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                )),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyCard(String level, IconData icon, Color color) {
    final isSelected = ctrl.selectedUrgency.value == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.selectedUrgency.value = level,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.1) : (isDark ? Colors.grey.shade900 : Colors.white), borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? color : (isDark ? Colors.grey.shade800 : Colors.grey.shade300), width: isSelected ? 2 : 1)),
          child: Column(
            children: [
              Icon(icon, size: 32, color: isSelected ? color : Colors.grey.shade400), const SizedBox(height: 8),
              Text(level, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBtnColor() {
    if (ctrl.selectedUrgency.value == 'Critical') return Colors.red.shade600;
    if (ctrl.selectedUrgency.value == 'Warning') return Colors.orange.shade700;
    return Colors.blue.shade700;
  }
}

// ============================================================================
// TAB 2: HISTORY & ANALYTICS (Master-Detail)
// ============================================================================
class _HistoryAnalyticsTab extends StatelessWidget {
  final AlertNotificationController ctrl;
  final bool isDark;
  const _HistoryAnalyticsTab({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Select first item by default if nothing is selected
    if (ctrl.selectedHistoryId.value == null && ctrl.alertHistory.isNotEmpty) {
      ctrl.selectHistoryAlert(ctrl.alertHistory.first['id']);
    }

    return Row(
      children: [
        // LEFT: List of Past Alerts
        Container(
          width: 350,
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, border: Border(right: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.all(20), child: Text("Alert History", style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
              Expanded(
                child: Obx(() => ListView.builder(
                  itemCount: ctrl.alertHistory.length,
                  itemBuilder: (context, index) {
                    final alert = ctrl.alertHistory[index];
                    final isSelected = ctrl.selectedHistoryId.value == alert['id'];
                    Color uColor = alert['urgency'] == 'Critical' ? Colors.red : alert['urgency'] == 'Warning' ? Colors.orange : Colors.blue;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      selected: isSelected, selectedTileColor: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50,
                      title: Text(alert['title'], style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(alert['date'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: uColor, shape: BoxShape.circle)), const SizedBox(width: 6), Text(alert['urgency'], style: TextStyle(fontSize: 11, color: uColor, fontWeight: FontWeight.bold))]),
                        ],
                      ),
                      onTap: () => ctrl.selectHistoryAlert(alert['id']),
                    );
                  },
                )),
              )
            ],
          ),
        ),

        // RIGHT: Analytics Dashboard
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
            child: Obx(() {
              if (ctrl.selectedHistoryId.value == null) return const Center(child: Text("Select an alert to view analytics"));
              final alert = ctrl.alertHistory.firstWhere((a) => a['id'] == ctrl.selectedHistoryId.value);
              final stats = alert['stats'];
              Color uColor = alert['urgency'] == 'Critical' ? Colors.red : alert['urgency'] == 'Warning' ? Colors.orange : Colors.blue;

              // Calculate percentages for the chart
              double deliveryRate = stats['sent'] > 0 ? (stats['delivered'] / stats['sent']) * 100 : 0;
              double openRate = stats['delivered'] > 0 ? (stats['read'] / stats['delivered']) * 100 : 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alert Details Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: uColor, width: 6))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(alert['title'], style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: uColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(alert['urgency'], style: TextStyle(color: uColor, fontWeight: FontWeight.bold, fontSize: 12))),
                          ]),
                          const SizedBox(height: 16),
                          Text(alert['message'], style: TextStyle(fontSize: 15, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800, height: 1.5)),
                          const SizedBox(height: 24),
                          Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                          const SizedBox(height: 16),
                          Row(children: [
                            Icon(PhosphorIcons.users(), size: 16, color: Colors.grey.shade500), const SizedBox(width: 8),
                            Text("Target: ${alert['audience']}", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Icon(PhosphorIcons.calendar(), size: 16, color: Colors.grey.shade500), const SizedBox(width: 8),
                            Text("Dispatched: ${alert['date']}", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                          ])
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    Text("Delivery & Engagement Analytics", style: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 24),

                    // KPIs Row
                    Row(
                      children: [
                        Expanded(child: _buildStatCard("Total Sent", stats['sent'].toString(), PhosphorIcons.paperPlaneTilt(), Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard("Delivered", stats['delivered'].toString(), PhosphorIcons.checkCircle(), Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard("Opened / Read", stats['read'].toString(), PhosphorIcons.envelopeOpen(), Colors.purple)),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Conversion Funnel Chart (BarChart)
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Conversion Funnel", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                          const SizedBox(height: 24),
                          Expanded(
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 100,
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
                                    switch (val.toInt()) { case 0: return const Text('Sent (100%)'); case 1: return Text('Delivered (${deliveryRate.toStringAsFixed(1)}%)'); case 2: return Text('Read (${openRate.toStringAsFixed(1)}%)'); default: return const Text(''); }
                                  }, reservedSize: 30)),
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups: [
                                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 100, color: Colors.blue.withOpacity(0.5), width: 60, borderRadius: BorderRadius.circular(4))]),
                                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: deliveryRate, color: Colors.green.withOpacity(0.7), width: 60, borderRadius: BorderRadius.circular(4))]),
                                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: openRate, color: Colors.purple, width: 60, borderRadius: BorderRadius.circular(4))]),
                                ],
                              ),
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
        )
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF252525) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.notoSans(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}