// lib/app/views/reports_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class ReportsController extends GetxController {
  final selectedPeriod = 'This Month'.obs;
  final selectedReportType = 'Overview'.obs;
  
  final periods = ['Today', 'This Week', 'This Month', 'This Year', 'Custom'];
  final reportTypes = ['Overview', 'Forecast Accuracy', 'Alert Performance', 'User Engagement'];
  
  void changePeriod(String period) {
    selectedPeriod.value = period;
  }
  
  void changeReportType(String type) {
    selectedReportType.value = type;
  }
  
  void generateReport() {
    Get.snackbar(
      'Generating Report',
      'Your ${selectedReportType.value} report for ${selectedPeriod.value} is being generated...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppTheme.accentBlue.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }
  
  void exportReport(String format) {
    Get.snackbar(
      'Exporting Report',
      'Exporting report as $format...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppTheme.successGreen.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }
}

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportsController());
    final wc = context.wColors;
    final isDark = context.isDark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ────────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
                    size: 24,
                    color: AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports & Analytics',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: wc.textPrimary,
                            fontWeight: FontWeight.w800,
                          ) ?? const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last updated: ${DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.now())}',
                      style: TextStyle(
                        fontSize: 13,
                        color: wc.textMuted,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                
                // Export buttons
                _buildExportButton(
                  controller,
                  'PDF',
                  PhosphorIcons.filePdf(),
                  AppTheme.dangerRed,
                  wc,
                ),
                const SizedBox(width: 12),
                _buildExportButton(
                  controller,
                  'Excel',
                  PhosphorIcons.fileXls(),
                  AppTheme.successGreen,
                  wc,
                ),
                const SizedBox(width: 12),
                _buildExportButton(
                  controller,
                  'CSV',
                  PhosphorIcons.fileCsv(),
                  AppTheme.infoCyan,
                  wc,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // ── FILTERS ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Period selector
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Period',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: wc.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() => DropdownButtonFormField<String>(
                          value: controller.selectedPeriod.value,
                          dropdownColor: wc.elevated,
                          style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: wc.elevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: wc.borderSoft),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: wc.borderSoft),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: controller.periods.map((period) {
                            return DropdownMenuItem(
                              value: period,
                              child: Text(period),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.changePeriod(value);
                            }
                          },
                        )),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Report type selector
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Type',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: wc.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() => DropdownButtonFormField<String>(
                          value: controller.selectedReportType.value,
                          dropdownColor: wc.elevated,
                          style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: wc.elevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: wc.borderSoft),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: wc.borderSoft),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: controller.reportTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.changeReportType(value);
                            }
                          },
                        )),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Generate button
                  ElevatedButton.icon(
                    onPressed: () => controller.generateReport(),
                    icon: Icon(PhosphorIcons.chartLine(), size: 18),
                    label: const Text('Generate Report', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppTheme.accentBlue.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // ── KEY METRICS ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Forecasts',
                    '1,284',
                    '+12.5%',
                    true,
                    PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
                    AppTheme.accentBlue,
                    context,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Accuracy Rate',
                    '94.2%',
                    '+2.1%',
                    true,
                    PhosphorIcons.target(PhosphorIconsStyle.fill),
                    AppTheme.successGreen,
                    context,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Alerts Sent',
                    '342',
                    '-5.3%',
                    false,
                    PhosphorIcons.warning(PhosphorIconsStyle.fill),
                    AppTheme.warningAmber,
                    context,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Active Users',
                    '12,450',
                    '+18.7%',
                    true,
                    PhosphorIcons.users(PhosphorIconsStyle.fill),
                    AppTheme.infoCyan,
                    context,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // ── CHARTS AND TABLES ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildForecastAccuracyCard(context),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildAlertDistributionCard(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Reports Table
            _buildRecentReportsTable(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExportButton(
    ReportsController controller,
    String format,
    IconData icon,
    Color color,
    WColors wc,
  ) {
    return OutlinedButton.icon(
      onPressed: () => controller.exportReport(format),
      icon: Icon(icon, size: 16),
      label: Text(format, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    bool isPositive,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isPositive ? AppTheme.successGreen : AppTheme.dangerRed)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? PhosphorIcons.trendUp()
                          : PhosphorIcons.trendDown(),
                      size: 12,
                      color: isPositive
                          ? AppTheme.successGreen
                          : AppTheme.dangerRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isPositive
                            ? AppTheme.successGreen
                            : AppTheme.dangerRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: wc.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: wc.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildForecastAccuracyCard(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Forecast Accuracy Trend',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ),
              ),
              const Spacer(),
              Text(
                'Last 7 days',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: wc.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Placeholder for chart
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: wc.elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: wc.borderSoft, style: BorderStyle.solid, width: 1.5),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
                    size: 48,
                    color: wc.textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chart: 85% → 94.2%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: wc.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Integrate chart library for visualization',
                    style: TextStyle(
                      fontSize: 13,
                      color: wc.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAlertDistributionCard(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: wc.textPrimary,
                ),
          ),
          const SizedBox(height: 32),
          _buildAlertDistributionItem(
            'Heavy Rain',
            142,
            342,
            AppTheme.accentBlue,
            context,
          ),
          const SizedBox(height: 24),
          _buildAlertDistributionItem(
            'Thunderstorm',
            98,
            342,
            Colors.purpleAccent,
            context,
          ),
          const SizedBox(height: 24),
          _buildAlertDistributionItem(
            'High Wind',
            64,
            342,
            AppTheme.infoCyan,
            context,
          ),
          const SizedBox(height: 24),
          _buildAlertDistributionItem(
            'Heat Wave',
            38,
            342,
            AppTheme.warningAmber,
            context,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
  
  Widget _buildAlertDistributionItem(
    String type,
    int count,
    int total,
    Color color,
    BuildContext context,
  ) {
    final wc = context.wColors;
    final percentage = (count / total * 100).toStringAsFixed(1);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              type,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: wc.textPrimary,
              ),
            ),
            Text(
              '$count ($percentage%)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: wc.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: count / total,
            backgroundColor: wc.elevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentReportsTable(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Recent Generated Reports',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: wc.textPrimary,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentBlue,
                  ),
                  child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700)),
                )
              ],
            ),
          ),
          Container(
            color: wc.elevated,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildTableHeader('REPORT NAME', context)),
                Expanded(flex: 1, child: _buildTableHeader('GENERATED', context)),
                Expanded(flex: 1, child: _buildTableHeader('TYPE', context)),
                Expanded(flex: 1, child: _buildTableHeader('STATUS', context)),
                Expanded(flex: 1, child: _buildTableHeader('ACTIONS', context)),
              ],
            ),
          ),
          _buildTableRow(
            'Monthly Forecast Accuracy',
            'Jan 28, 2026',
            'Accuracy',
            'Completed',
            AppTheme.successGreen,
            context,
          ),
          Divider(height: 1, color: wc.borderSoft),
          _buildTableRow(
            'Weekly Alert Performance',
            'Jan 27, 2026',
            'Alerts',
            'Completed',
            AppTheme.successGreen,
            context,
          ),
          Divider(height: 1, color: wc.borderSoft),
          _buildTableRow(
            'User Engagement Analysis',
            'Jan 26, 2026',
            'Engagement',
            'Processing',
            AppTheme.warningAmber,
            context,
          ),
          Divider(height: 1, color: wc.borderSoft),
          _buildTableRow(
            'Q1 2026 Overview Report',
            'Jan 25, 2026',
            'Overview',
            'Completed',
            AppTheme.successGreen,
            context,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  Widget _buildTableHeader(String text, BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: context.wColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
  
  Widget _buildTableRow(
    String name,
    String date,
    String type,
    String status,
    Color statusColor,
    BuildContext context,
  ) {
    final wc = context.wColors;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(PhosphorIcons.fileText(), size: 16, color: AppTheme.accentBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: wc.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              date,
              style: TextStyle(fontSize: 13, color: wc.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              type,
              style: TextStyle(fontSize: 13, color: wc.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                _TableActionBtn(icon: PhosphorIcons.eye()),
                const SizedBox(width: 8),
                _TableActionBtn(icon: PhosphorIcons.downloadSimple()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _TableActionBtn extends StatefulWidget {
  final IconData icon;
  
  const _TableActionBtn({required this.icon});

  @override
  State<_TableActionBtn> createState() => _TableActionBtnState();
}

class _TableActionBtnState extends State<_TableActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hovered ? wc.elevated : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? wc.borderSoft : Colors.transparent,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _hovered ? AppTheme.accentBlue : wc.textMuted,
          ),
        ),
      ),
    );
  }
}
// // lib/app/views/reports_view.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
// import 'package:intl/intl.dart';
// import '../theme/app_theme.dart';

// class ReportsController extends GetxController {
//   final selectedPeriod = 'This Month'.obs;
//   final selectedReportType = 'Overview'.obs;
  
//   final periods = ['Today', 'This Week', 'This Month', 'This Year', 'Custom'];
//   final reportTypes = ['Overview', 'Forecast Accuracy', 'Alert Performance', 'User Engagement'];
  
//   void changePeriod(String period) {
//     selectedPeriod.value = period;
//   }
  
//   void changeReportType(String type) {
//     selectedReportType.value = type;
//   }
  
//   void generateReport() {
//     Get.snackbar(
//       'Generating Report',
//       'Your ${selectedReportType.value} report for ${selectedPeriod.value} is being generated...',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: AppTheme.primaryColor,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 3),
//     );
//   }
  
//   void exportReport(String format) {
//     Get.snackbar(
//       'Exporting Report',
//       'Exporting report as $format...',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: AppTheme.successColor,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 2),
//     );
//   }
// }

// class ReportsView extends StatelessWidget {
//   const ReportsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(ReportsController());
    
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header with controls
//             Row(
//               children: [
//                 Icon(
//                   PhosphorIcons.chartBar(PhosphorIconsStyle.bold),
//                   size: 32,
//                   color: AppTheme.primaryColor,
//                 ),
//                 const SizedBox(width: 16),
//                 const Text(
//                   'Reports & Analytics',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Spacer(),
//                 // Export buttons
//                 _buildExportButton(
//                   controller,
//                   'PDF',
//                   PhosphorIcons.filePdf(),
//                   Colors.red,
//                 ),
//                 const SizedBox(width: 12),
//                 _buildExportButton(
//                   controller,
//                   'Excel',
//                   PhosphorIcons.fileXls(),
//                   Colors.green,
//                 ),
//                 const SizedBox(width: 12),
//                 _buildExportButton(
//                   controller,
//                   'CSV',
//                   PhosphorIcons.fileCsv(),
//                   Colors.blue,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Last updated: ${DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.now())}',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
            
//             const SizedBox(height: 32),
            
//             // Filters
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Row(
//                   children: [
//                     // Period selector
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Time Period',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           Obx(() => DropdownButtonFormField<String>(
//                             value: controller.selectedPeriod.value,
//                             decoration: InputDecoration(
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 12,
//                               ),
//                             ),
//                             items: controller.periods.map((period) {
//                               return DropdownMenuItem(
//                                 value: period,
//                                 child: Text(period),
//                               );
//                             }).toList(),
//                             onChanged: (value) {
//                               if (value != null) {
//                                 controller.changePeriod(value);
//                               }
//                             },
//                           )),
//                         ],
//                       ),
//                     ),
                    
//                     const SizedBox(width: 24),
                    
//                     // Report type selector
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Report Type',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           Obx(() => DropdownButtonFormField<String>(
//                             value: controller.selectedReportType.value,
//                             decoration: InputDecoration(
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 12,
//                               ),
//                             ),
//                             items: controller.reportTypes.map((type) {
//                               return DropdownMenuItem(
//                                 value: type,
//                                 child: Text(type),
//                               );
//                             }).toList(),
//                             onChanged: (value) {
//                               if (value != null) {
//                                 controller.changeReportType(value);
//                               }
//                             },
//                           )),
//                         ],
//                       ),
//                     ),
                    
//                     const SizedBox(width: 24),
                    
//                     // Generate button
//                     Padding(
//                       padding: const EdgeInsets.only(top: 26),
//                       child: ElevatedButton.icon(
//                         onPressed: () => controller.generateReport(),
//                         icon: Icon(PhosphorIcons.chartLine()),
//                         label: const Text('Generate Report'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppTheme.primaryColor,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 24,
//                             vertical: 20,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
            
//             const SizedBox(height: 32),
            
//             // Key Metrics
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildMetricCard(
//                     'Total Forecasts',
//                     '1,284',
//                     '+12.5%',
//                     true,
//                     PhosphorIcons.cloudSun(),
//                     AppTheme.primaryColor,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildMetricCard(
//                     'Accuracy Rate',
//                     '94.2%',
//                     '+2.1%',
//                     true,
//                     PhosphorIcons.target(),
//                     AppTheme.successColor,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildMetricCard(
//                     'Alerts Sent',
//                     '342',
//                     '-5.3%',
//                     false,
//                     PhosphorIcons.warning(),
//                     AppTheme.warningColor,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildMetricCard(
//                     'Active Users',
//                     '12,450',
//                     '+18.7%',
//                     true,
//                     PhosphorIcons.users(),
//                     AppTheme.infoColor,
//                   ),
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 32),
            
//             // Charts and Tables
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Forecast Accuracy Chart
//                 Expanded(
//                   flex: 2,
//                   child: _buildForecastAccuracyCard(),
//                 ),
//                 const SizedBox(width: 16),
//                 // Alert Distribution
//                 Expanded(
//                   child: _buildAlertDistributionCard(),
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 16),
            
//             // Recent Reports Table
//             _buildRecentReportsTable(),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildExportButton(
//     ReportsController controller,
//     String format,
//     IconData icon,
//     Color color,
//   ) {
//     return OutlinedButton.icon(
//       onPressed: () => controller.exportReport(format),
//       icon: Icon(icon, size: 18),
//       label: Text(format),
//       style: OutlinedButton.styleFrom(
//         foregroundColor: color,
//         side: BorderSide(color: color),
//         padding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 12,
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }
  
//   Widget _buildMetricCard(
//     String title,
//     String value,
//     String change,
//     bool isPositive,
//     IconData icon,
//     Color color,
//   ) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(icon, color: color, size: 24),
//                 ),
//                 const Spacer(),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: (isPositive ? AppTheme.successColor : AppTheme.dangerColor)
//                         .withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         isPositive
//                             ? PhosphorIcons.trendUp()
//                             : PhosphorIcons.trendDown(),
//                         size: 14,
//                         color: isPositive
//                             ? AppTheme.successColor
//                             : AppTheme.dangerColor,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         change,
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           color: isPositive
//                               ? AppTheme.successColor
//                               : AppTheme.dangerColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildForecastAccuracyCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Forecast Accuracy Trend',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Last 7 days',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 24),
//             // Placeholder for chart
//             Container(
//               height: 200,
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       PhosphorIcons.chartLine(),
//                       size: 48,
//                       color: Colors.grey[400],
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'Chart: 85% → 94.2%',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Integrate chart library for visualization',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[500],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildAlertDistributionCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Alert Distribution',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 24),
//             _buildAlertDistributionItem(
//               'Heavy Rain',
//               142,
//               342,
//               Colors.blue,
//             ),
//             const SizedBox(height: 16),
//             _buildAlertDistributionItem(
//               'Thunderstorm',
//               98,
//               342,
//               Colors.purple,
//             ),
//             const SizedBox(height: 16),
//             _buildAlertDistributionItem(
//               'High Wind',
//               64,
//               342,
//               Colors.teal,
//             ),
//             const SizedBox(height: 16),
//             _buildAlertDistributionItem(
//               'Heat Wave',
//               38,
//               342,
//               Colors.orange,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildAlertDistributionItem(
//     String type,
//     int count,
//     int total,
//     Color color,
//   ) {
//     final percentage = (count / total * 100).toStringAsFixed(1);
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               type,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             Text(
//               '$count ($percentage%)',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         LinearProgressIndicator(
//           value: count / total,
//           backgroundColor: Colors.grey[200],
//           valueColor: AlwaysStoppedAnimation<Color>(color),
//           minHeight: 8,
//           borderRadius: BorderRadius.circular(4),
//         ),
//       ],
//     );
//   }
  
//   Widget _buildRecentReportsTable() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Recent Generated Reports',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Table(
//               columnWidths: const {
//                 0: FlexColumnWidth(2),
//                 1: FlexColumnWidth(1.5),
//                 2: FlexColumnWidth(1),
//                 3: FlexColumnWidth(1),
//                 4: FlexColumnWidth(1),
//               },
//               children: [
//                 // Header
//                 TableRow(
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(8),
//                     ),
//                   ),
//                   children: [
//                     _buildTableHeader('Report Name'),
//                     _buildTableHeader('Generated'),
//                     _buildTableHeader('Type'),
//                     _buildTableHeader('Status'),
//                     _buildTableHeader('Actions'),
//                   ],
//                 ),
//                 // Rows
//                 _buildTableRow(
//                   'Monthly Forecast Accuracy Report',
//                   'Jan 28, 2026',
//                   'Accuracy',
//                   'Completed',
//                   AppTheme.successColor,
//                 ),
//                 _buildTableRow(
//                   'Weekly Alert Performance',
//                   'Jan 27, 2026',
//                   'Alerts',
//                   'Completed',
//                   AppTheme.successColor,
//                 ),
//                 _buildTableRow(
//                   'User Engagement Analysis',
//                   'Jan 26, 2026',
//                   'Engagement',
//                   'Processing',
//                   AppTheme.warningColor,
//                 ),
//                 _buildTableRow(
//                   'Q1 2026 Overview Report',
//                   'Jan 25, 2026',
//                   'Overview',
//                   'Completed',
//                   AppTheme.successColor,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildTableHeader(String text) {
//     return Padding(
//       padding: const EdgeInsets.all(12),
//       child: Text(
//         text,
//         style: const TextStyle(
//           fontSize: 13,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }
  
//   TableRow _buildTableRow(
//     String name,
//     String date,
//     String type,
//     String status,
//     Color statusColor,
//   ) {
//     return TableRow(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Text(
//             name,
//             style: const TextStyle(fontSize: 13),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Text(
//             date,
//             style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Text(
//             type,
//             style: const TextStyle(fontSize: 13),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: statusColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Text(
//               status,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: statusColor,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               IconButton(
//                 icon: Icon(PhosphorIcons.eye(), size: 18),
//                 onPressed: () {},
//                 tooltip: 'View',
//                 padding: EdgeInsets.zero,
//                 constraints: const BoxConstraints(),
//               ),
//               const SizedBox(width: 8),
//               IconButton(
//                 icon: Icon(PhosphorIcons.downloadSimple(), size: 18),
//                 onPressed: () {},
//                 tooltip: 'Download',
//                 padding: EdgeInsets.zero,
//                 constraints: const BoxConstraints(),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }