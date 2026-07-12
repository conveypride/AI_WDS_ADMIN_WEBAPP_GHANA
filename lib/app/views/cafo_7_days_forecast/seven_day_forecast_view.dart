import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:weather_admin_dashboard/app/controllers/seven_day_forecast_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'package:weather_admin_dashboard/app/views/widgets/audio_summary_dialog.dart';

class SevenDayForecastView extends StatelessWidget {
  const SevenDayForecastView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(SevenDayForecastController());
    final wc = context.wColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Tab Bar with Glass Morphism Effect
        Container(
          decoration: BoxDecoration(
            color: wc.card,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TabBar(
            controller: ctrl.tabController,
            labelColor: AppTheme.accentBlue,
            unselectedLabelColor: wc.textMuted,
            indicatorColor: AppTheme.accentBlue,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: [
              Tab(
                height: 60,
                icon: Icon(PhosphorIcons.clockCounterClockwise(), size: 22),
                text: "History",
              ),
              Tab(
                height: 60,
                icon: Icon(PhosphorIcons.calendarPlus(), size: 22),
                text: "Create Forecast",
              ),
            ],
          ),
        ),

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
// TAB 1: HISTORY VIEW WITH ANALYTICS & IMPROVED UX
// ============================================================================
class _HistoryTab extends StatelessWidget {
  final SevenDayForecastController ctrl;

  const _HistoryTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Container(
      color: wc.background,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Better Hierarchy
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Forecast History",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: wc.textPrimary,
                            ) ??
                            const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Manage and review your weather predictions",
                        style: TextStyle(
                          color: wc.textMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Modern CTA Button
                ElevatedButton.icon(
                  onPressed: ctrl.createNewForecast,
                  icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 20),
                  label: const Text(
                    "New Forecast",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    shadowColor: AppTheme.accentBlue.withOpacity(0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Analytics Cards Row
            Obx(() => Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: "Total Records",
                        count: ctrl.totalCount.value,
                        icon: PhosphorIcons.database(PhosphorIconsStyle.bold),
                        color: Colors.blue,
                        wc: wc,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: "Published",
                        count: ctrl.approvedCount.value,
                        icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.bold),
                        color: AppTheme.successGreen,
                        wc: wc,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: "Pending",
                        count: ctrl.pendingCount.value,
                        icon: PhosphorIcons.clock(PhosphorIconsStyle.bold),
                        color: AppTheme.warningAmber,
                        wc: wc,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: "Revoked",
                        count: ctrl.revokedCount.value,
                        icon: PhosphorIcons.xCircle(PhosphorIconsStyle.bold),
                        color: Colors.redAccent,
                        wc: wc,
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 28),

            // Data Table with Modern Design
            Expanded(
              child: Obx(() {
                if (ctrl.isLoadingHistory.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.accentBlue),
                        const SizedBox(height: 16),
                        Text(
                          "Loading forecasts...",
                          style: TextStyle(color: wc.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                if (ctrl.forecastHistory.isEmpty) {
                  return _EmptyState(ctrl: ctrl, wc: wc);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: wc.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: wc.border.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(
                          color: wc.elevated.withOpacity(0.6),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text("FORECAST ID", style: _headerStyle(context))),
                            Expanded(flex: 3, child: Text("DATE RANGE", style: _headerStyle(context))),
                            Expanded(flex: 2, child: Text("AUTHOR", style: _headerStyle(context))),
                            Expanded(flex: 2, child: Text("STATUS", style: _headerStyle(context))),
                            Expanded(flex: 2, child: Text("ACTIONS", style: _headerStyle(context), textAlign: TextAlign.right)),
                          ],
                        ),
                      ),

                      // Table Body
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: ctrl.forecastHistory.length,
                          itemBuilder: (context, index) {
                            final item = ctrl.forecastHistory[index];
                            return _ForecastCard(
                              item: item,
                              ctrl: ctrl,
                              wc: wc,
                              isDark: isDark,
                            );
                          },
                        ),
                      ),

                      // Pagination Footer
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: wc.border.withOpacity(0.5))),
                        ),
                        child: Obx(() {
                          if (ctrl.hasMore.value && ctrl.forecastHistory.isNotEmpty) {
                            return Center(
                              child: OutlinedButton.icon(
                                onPressed: ctrl.isFetchingMore.value ? null : ctrl.loadMoreHistory,
                                icon: ctrl.isFetchingMore.value
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(PhosphorIcons.arrowDown(), size: 18),
                                label: Text(
                                  ctrl.isFetchingMore.value ? "Loading..." : "Load More",
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.accentBlue,
                                  side: BorderSide(color: AppTheme.accentBlue.withOpacity(0.3)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      )
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle(BuildContext context) => TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        color: context.wColors.textMuted,
        letterSpacing: 0.8,
      );
}

// Empty State Widget
class _EmptyState extends StatelessWidget {
  final SevenDayForecastController ctrl;
  final dynamic wc;

  const _EmptyState({required this.ctrl, required this.wc});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.cloudSlash(PhosphorIconsStyle.thin),
              size: 96,
              color: wc.textMuted.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              "No forecasts yet",
              style: TextStyle(
                color: wc.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Create your first 7-day forecast to get started",
              style: TextStyle(color: wc.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: ctrl.createNewForecast,
              icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 20),
              label: const Text("Create Forecast"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Analytics Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final dynamic wc;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.wc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: wc.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: wc.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: wc.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    color: wc.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}


// ============================================================================
// FORECAST CARD WIDGET (WITH 3-DOTS MENU & LOADING SPINNER)
// ============================================================================
class _ForecastCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final SevenDayForecastController ctrl;
  final dynamic wc;
  final bool isDark;

  const _ForecastCard({
    required this.item,
    required this.ctrl,
    required this.wc,
    required this.isDark,
  });

  @override
  State<_ForecastCard> createState() => _ForecastCardState();
}

class _ForecastCardState extends State<_ForecastCard> {
  bool _isHovered = false;
  bool _isProcessing = false; // Tracks if this specific card is running an action

  @override
  Widget build(BuildContext context) {
    final status = widget.item['status'] ?? '';
    Color statusColor = status == 'published'
        ? AppTheme.successGreen
        : (status == 'pending_approval' ? AppTheme.warningAmber : Colors.redAccent);

    // --- NEW: Safely extract existing audio data ---
    Map<String, dynamic> existingAudios = widget.item['audio_summaries'] ?? {};
    bool hasAnyAudio = existingAudios.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _isHovered ? widget.wc.elevated.withOpacity(0.8) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? widget.wc.border.withOpacity(0.8) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      PhosphorIcons.calendar(PhosphorIconsStyle.bold),
                      size: 18,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.item['id'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: widget.wc.textPrimary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.item['dateRange'] ?? '',
                style: TextStyle(
                  color: widget.wc.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.2),
                          statusColor.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (widget.item['author']?['name'] ?? 'System').substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.item['author']?['name'] ?? 'System',
                      style: TextStyle(
                        color: widget.wc.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.15),
                        statusColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status.toString().replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            
            // 3-DOTS MENU & SPINNER SECTION
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: _isProcessing 
                  ? Container(
                      padding: const EdgeInsets.only(right: 12),
                      child: const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2.5)
                      ),
                    )
                  : PopupMenuButton<String>(
                      icon: Icon(PhosphorIcons.dotsThreeVertical(PhosphorIconsStyle.bold), color: widget.wc.textPrimary),
                      color: widget.wc.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                      offset: const Offset(0, 40),
                      onSelected: (value) async {
                        if (value == 'view') {
                          widget.ctrl.viewForecast(widget.item);
                        } else if (value == 'edit') {
                          widget.ctrl.editForecast(widget.item);
                        } else if (value == 'approve') {
                          setState(() => _isProcessing = true);
                          await widget.ctrl.changeForecastStatus(widget.item['id'], 'published');
                          if (mounted) setState(() => _isProcessing = false);
                        } else if (value == 'revoke') {
                          setState(() => _isProcessing = true);
                          await widget.ctrl.changeForecastStatus(widget.item['id'], 'revoked');
                          if (mounted) setState(() => _isProcessing = false);
                        } else if (value == 'audio') { // --- NEW AUDIO HANDLER ---
                          // 7-Day forecasts might not have a simple string "summary", so we construct a placeholder
                          // or grab it if you add it later.
                          String summaryText = widget.item['summary'] ?? "7-Day General Forecast for ${widget.item['dateRange']}. Please summarize the upcoming week.";
                          
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AudioSummaryDialog(
                              forecastId: widget.item['id'],
                              collectionName: 'seven_day_forecast', // CRITICAL: Targeting the 7-day collection
                              summaryText: summaryText,
                              existingAudios: existingAudios,
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.eye(PhosphorIconsStyle.bold), size: 18, color: AppTheme.accentBlue),
                              const SizedBox(width: 12),
                              const Text("View Details", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (status == 'pending_approval' || status == 'revoked')
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold), size: 18, color: AppTheme.warningAmber),
                                const SizedBox(width: 12),
                                const Text("Edit Forecast", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              ],
                            ),
                          ),
                        
                        // --- NEW: AUDIO MENU ITEM ---
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'audio',
                          child: Row(
                            children: [
                              Icon(
                                hasAnyAudio ? PhosphorIcons.waveform(PhosphorIconsStyle.bold) : PhosphorIcons.microphone(PhosphorIconsStyle.bold), 
                                size: 18, 
                                color: hasAnyAudio ? AppTheme.successGreen : Colors.blueGrey
                              ),
                              const SizedBox(width: 12),
                              Text(hasAnyAudio ? "See/Edit Audios" : "Add Audio", 
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),

                        if ((widget.ctrl.isAdmin.value && status == 'pending_approval') ||
                            (widget.ctrl.isAdmin.value && status == 'revoked'))
                          PopupMenuItem(
                            value: 'approve',
                            child: Row(
                              children: [
                                Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.bold), size: 18, color: AppTheme.successGreen),
                                const SizedBox(width: 12),
                                Text(status == 'revoked' ? "Approve (Override)" : "Approve", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              ],
                            ),
                          ),
                        if (widget.ctrl.isAdmin.value && status != 'revoked')
                          PopupMenuItem(
                            value: 'revoke',
                            child: Row(
                              children: [
                                Icon(PhosphorIcons.xCircle(PhosphorIconsStyle.bold), size: 18, color: Colors.redAccent),
                                const SizedBox(width: 12),
                                const Text("Revoke", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              ],
                            ),
                          ),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DAY ENTRY CELL WIDGET (WITH STRICT NUMBER FORMATTING)
// ============================================================================
class _ModernDayEntryCell extends StatelessWidget {
  final SevenDayForecastController ctrl;
  final String city;
  final int dayIndex;

  const _ModernDayEntryCell({
    required this.ctrl,
    required this.city,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;

    return Container(
      height: 160, 
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Weather Condition
          Expanded(
            child: Autocomplete<String>(
              initialValue: TextEditingValue(text: ctrl.forecastGrid[city]![dayIndex]['cond']?.toString() ?? ''),
              optionsBuilder: (tv) => ctrl.weatherOptions.where((o) => o.toLowerCase().contains(tv.text.toLowerCase())),
              onSelected: (val) => ctrl.forecastGrid[city]![dayIndex]['cond'] = val,
              fieldViewBuilder: (ctx, tCtrl, focus, onEdit) => TextFormField(
                controller: tCtrl,
                focusNode: focus,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "Condition",
                  hintStyle: TextStyle(fontSize: 11, color: wc.textMuted.withOpacity(0.6)),
                  filled: true,
                  fillColor: wc.elevated.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
                onChanged: (val) => ctrl.forecastGrid[city]![dayIndex]['cond'] = val,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Temperature Range
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: ctrl.forecastGrid[city]![dayIndex]['min']?.toString() ?? '',
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    // Strictly allows only numbers, decimals, and a negative sign
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*'))],
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blue[700]),
                    decoration: InputDecoration(
                      hintText: "Min",
                      hintStyle: TextStyle(fontSize: 11, color: wc.textMuted.withOpacity(0.6)),
                      filled: true,
                      fillColor: Colors.blue.withOpacity(0.06),
                      border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    onChanged: (val) => ctrl.forecastGrid[city]![dayIndex]['min'] = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: ctrl.forecastGrid[city]![dayIndex]['max']?.toString() ?? '',
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    // Strictly allows only numbers, decimals, and a negative sign
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*'))],
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange[700]),
                    decoration: InputDecoration(
                      hintText: "Max",
                      hintStyle: TextStyle(fontSize: 11, color: wc.textMuted.withOpacity(0.6)),
                      filled: true,
                      fillColor: Colors.orange.withOpacity(0.06),
                      border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    onChanged: (val) => ctrl.forecastGrid[city]![dayIndex]['max'] = val,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Probability
          Expanded(
            child: TextFormField(
              initialValue: ctrl.forecastGrid[city]![dayIndex]['prob']?.toString() ?? '',
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Only pure digits
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: wc.textPrimary),
              decoration: InputDecoration(
                hintText: "Prob %",
                hintStyle: TextStyle(fontSize: 11, color: wc.textMuted.withOpacity(0.6)),
                filled: true,
                fillColor: wc.elevated.withOpacity(0.4),
                border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.all(10),
                suffixText: "%",
                suffixStyle: TextStyle(fontSize: 10, color: wc.textMuted, fontWeight: FontWeight.w600),
              ),
              onChanged: (val) => ctrl.forecastGrid[city]![dayIndex]['prob'] = val,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 2: CREATE FORECAST TAB
// ============================================================================
class _CreateForecastTab extends StatelessWidget {
  final SevenDayForecastController ctrl;

  const _CreateForecastTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Obx(() {
      if (ctrl.isLoadingSettings.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.accentBlue),
              const SizedBox(height: 16),
              Text("Loading settings...", style: TextStyle(color: wc.textMuted, fontSize: 14)),
            ],
          ),
        );
      }

      return Container(
        color: wc.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: wc.card,
                border: Border(bottom: BorderSide(color: wc.border.withOpacity(0.5))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Create 7-Day Forecast",
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: wc.textPrimary,
                                  ) ??
                                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Enter weather conditions, temperature ranges, and probability",
                              style: TextStyle(color: wc.textMuted, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: ctrl.downloadCSVTemplate,
                            icon: Icon(PhosphorIcons.downloadSimple(), size: 18),
                            label: const Text("Download Template", style: TextStyle(fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentBlue,
                              side: BorderSide(color: AppTheme.accentBlue.withOpacity(0.3)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: ctrl.isImporting.value ? null : ctrl.importCSVData,
                            icon: Icon(PhosphorIcons.fileCsv(PhosphorIconsStyle.bold), size: 18),
                            label: const Text("Import CSV", style: TextStyle(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Data Grid - NOW TAKES FULL AVAILABLE HEIGHT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: wc.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: wc.border.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1400,
                        child: Column(
                          children: [
                            // Header Row
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    wc.elevated.withOpacity(0.9),
                                    wc.elevated.withOpacity(0.6),
                                  ],
                                ),
                                border: Border(bottom: BorderSide(color: wc.border.withOpacity(0.3))),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 140, child: _headerCell("LOCATION", context)),
                                  ...ctrl.dynamicDates
                                      .map((d) => SizedBox(
                                            width: 180,
                                            child: _headerCell(DateFormat('EEE\ndd MMM').format(d).toUpperCase(), context),
                                          ))
                                      .toList(),
                                ],
                              ),
                            ),

                            // Data Rows (Lazy Loaded) - NOW EXPANDS TO FILL AVAILABLE SPACE
                            Expanded(
                              child: Obx(() => ListView.builder(
                                    key: ctrl.tableKey.value,
                                    itemCount: ctrl.locations.length + 1, // +1 for submit button row
                                    itemBuilder: (context, rowIndex) {
                                      // Last row is the submit button
                                      if (rowIndex == ctrl.locations.length) {
                                        return Container(
                                          padding: const EdgeInsets.all(32),
                                          decoration: BoxDecoration(
                                            color: wc.elevated.withOpacity(0.3),
                                            border: Border(top: BorderSide(color: wc.border.withOpacity(0.5), width: 2)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Review all entries before submitting",
                                                style: TextStyle(
                                                  color: wc.textMuted,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 24),
                                              ElevatedButton.icon(
                                                onPressed: ctrl.isPublishing.value ? null : ctrl.submitForecast,
                                                icon: Icon(PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill), size: 20),
                                                label: Text(
                                                  ctrl.isAdmin.value ? "Publish Forecast" : "Submit for Approval",
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.successGreen,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  elevation: 2,
                                                  shadowColor: AppTheme.successGreen.withOpacity(0.3),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      final city = ctrl.locations[rowIndex];

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: rowIndex.isEven ? Colors.transparent : wc.elevated.withOpacity(0.2),
                                          border: Border(bottom: BorderSide(color: wc.border.withOpacity(0.3))),
                                        ),
                                        child: Row(
                                          children: [
                                            // Location Cell
                                            SizedBox(
                                              width: 140,
                                              child: Container(
                                                height: 160, // INCREASED FROM 130
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.accentBlue.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Icon(
                                                        PhosphorIcons.mapPin(PhosphorIconsStyle.bold),
                                                        size: 18,
                                                        color: AppTheme.accentBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        city,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          color: wc.textPrimary,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Day Input Cells
                                            ...List.generate(
                                              7,
                                              (dayIdx) => SizedBox(
                                                width: 180,
                                                child: _ModernDayEntryCell(
                                                  ctrl: ctrl,
                                                  city: city,
                                                  dayIndex: dayIdx,
                                                ),
                                              ),
                                            ).toList()
                                          ],
                                        ),
                                      );
                                    },
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _headerCell(String text, BuildContext context) => Container(
        height: 70,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: context.wColors.textMuted,
            letterSpacing: 0.8,
            height: 1.3,
          ),
        ),
      );
}



// Modern Action Button
class _ModernActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ModernActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ModernActionButton> createState() => _ModernActionButtonState();
}

class _ModernActionButtonState extends State<_ModernActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: _hovered
                  ? LinearGradient(
                      colors: [
                        widget.color.withOpacity(0.15),
                        widget.color.withOpacity(0.08),
                      ],
                    )
                  : null,
              color: _hovered ? null : widget.color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered ? widget.color.withOpacity(0.5) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(widget.icon, size: 18, color: widget.color),
          ),
        ),
      ),
    );
  }
}
