import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:weather_admin_dashboard/app/controllers/seasonal_forecast_controller.dart';
import 'package:weather_admin_dashboard/app/data/models/seasonal_forecast_model.dart';
import 'package:weather_admin_dashboard/app/model/boundary.dart'; 

class SeasonalForecastView extends StatelessWidget {
  const SeasonalForecastView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(SeasonalForecastController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Colors.blueAccent : const Color(0xFF0B4EA2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tab bar ──────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
          ),
          child: TabBar(
            controller: ctrl.tabController,
            labelColor: primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.notoSans(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: [
              Tab(icon: Icon(PhosphorIcons.archive()), text: "FORECAST ARCHIVES"),
              Tab(icon: Icon(PhosphorIcons.plus()),    text: "CREATE NEW FORECAST"),
            ],
          ),
        ),

        // ── Global error banner ───────────────────────────────────────────────
        Obx(() {
          if (ctrl.errorMessage.value.isEmpty) return const SizedBox.shrink();
          return Container(
            width: double.infinity,
            color: Colors.red.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(PhosphorIcons.warning(), color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ctrl.errorMessage.value,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.x(), size: 16),
                  onPressed: () => ctrl.errorMessage.value = '',
                ),
              ],
            ),
          );
        }),

        Expanded(
          child: TabBarView(
            controller: ctrl.tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ArchivesTab(ctrl: ctrl, isDark: isDark),
              _CreateForecastTab(ctrl: ctrl, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 1: ARCHIVES
// ============================================================================
class _ArchivesTab extends StatelessWidget {
  final SeasonalForecastController ctrl;
  final bool isDark;
  const _ArchivesTab({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.archive(PhosphorIconsStyle.fill),
                size: 28,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Published Seasonal Forecasts",
                  style: GoogleFonts.notoSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(PhosphorIcons.arrowClockwise()),
                tooltip: "Refresh",
                onPressed: ctrl.refreshArchives,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: ctrl.startNewForecast,
                icon: Icon(PhosphorIcons.plus()),
                label: const Text("New Forecast"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4EA2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "View and manage all seasonal forecasts",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Obx(() {
              if (ctrl.isLoadingArchives.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (ctrl.archives.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.folderOpen(),
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "No forecasts yet",
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: ctrl.startNewForecast,
                        icon: Icon(PhosphorIcons.plus()),
                        label: const Text("Create First Forecast"),
                      ),
                    ],
                  ),
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification &&
                      n.metrics.extentAfter < 200) {
                    ctrl.loadMoreArchives();
                  }
                  return false;
                },
                child: ListView.separated(
                  itemCount: ctrl.archives.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, idx) {
                    if (idx == ctrl.archives.length) {
                      return Obx(() => ctrl.isLoadingMore.value
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            )
                          : ctrl.archivesExhausted.value
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      "All forecasts loaded",
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink());
                    }
                    final f = ctrl.archives[idx];
                    return _ArchiveCard(
                      forecast: f,
                      isDark: isDark,
                      onEdit: () => ctrl.loadForecastForEditing(f.id!),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final SeasonalForecastModel forecast;
  final bool isDark;
  final VoidCallback onEdit;
  const _ArchiveCard({
    required this.forecast,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isPublished = forecast.status == 'published';
    final statusColor = isPublished ? Colors.green : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forecast.title.isNotEmpty
                            ? forecast.title
                            : 'Untitled Forecast',
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID: ${forecast.id ?? '—'}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPublished
                            ? PhosphorIcons.checkCircle()
                            : PhosphorIcons.pencilSimple(),
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPublished ? "Published" : "Draft",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (forecast.issuedDate.isNotEmpty)
                  _InfoChip(
                    icon: PhosphorIcons.calendar(),
                    label: "Issued",
                    value: forecast.issuedDate,
                    isDark: isDark,
                  ),
                if (forecast.preparedBy.isNotEmpty)
                  _InfoChip(
                    icon: PhosphorIcons.user(),
                    label: "By",
                    value: forecast.preparedBy,
                    isDark: isDark,
                  ),
                _InfoChip(
                  icon: PhosphorIcons.tag(),
                  label: "Season",
                  value: "${forecast.season} ${forecast.year}",
                  isDark: isDark,
                ),
                if (forecast.accuracy != '--')
                  _InfoChip(
                    icon: PhosphorIcons.chartLine(),
                    label: "Accuracy",
                    value: forecast.accuracy,
                    isDark: isDark,
                    valueColor: Colors.blue,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: Icon(PhosphorIcons.pencilSimple(), size: 18),
                    label: Text(
                        isPublished ? "View / Edit" : "Continue Editing"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(PhosphorIcons.downloadSimple(), size: 18),
                  label: const Text("Download PDF"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          "$label: ",
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 2: CREATE / EDIT FORECAST
// ============================================================================
class _CreateForecastTab extends StatelessWidget {
  final SeasonalForecastController ctrl;
  final bool isDark;
  const _CreateForecastTab({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingConfig.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(
              number: 1,
              title: "Forecast Metadata",
              icon: PhosphorIcons.info(),
              isDark: isDark,
            ),
            _MetadataSection(ctrl: ctrl, isDark: isDark),
            const SizedBox(height: 40),

            _StepHeader(
              number: 2,
              title: "Zone-by-Zone Forecast",
              icon: PhosphorIcons.mapTrifold(),
              isDark: isDark,
            ),
            _ZoneForecasts(ctrl: ctrl, isDark: isDark),
            const SizedBox(height: 40),

            _StepHeader(
              number: 3,
              title: "Rainfall Distribution Map",
              icon: PhosphorIcons.mapPin(),
              isDark: isDark,
            ),
            _MapPreview(ctrl: ctrl, isDark: isDark),
            const SizedBox(height: 40),

            _StepHeader(
              number: 4,
              title: "Farmer Advisories & Recommendations",
              icon: PhosphorIcons.lightbulb(),
              isDark: isDark,
            ),
            _AdvisoriesSection(ctrl: ctrl, isDark: isDark),
            const SizedBox(height: 40),

            _ActionButtons(ctrl: ctrl, isDark: isDark),
          ],
        ),
      );
    });
  }
}

class _StepHeader extends StatelessWidget {
  final int number;
  final String title;
  final IconData icon;
  final bool isDark;

  const _StepHeader({
    required this.number,
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0B4EA2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              "$number",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 24, color: isDark ? Colors.white : Colors.black),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.notoSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// STEP 1: METADATA
// ============================================================================
class _MetadataSection extends StatelessWidget {
  final SeasonalForecastController ctrl;
  final bool isDark;
  const _MetadataSection({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final d = ctrl.draft.value;
      final cfg = ctrl.config.value;

      return _Card(
        isDark: isDark,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _FormField(
                    label: "Forecast Title",
                    hint: "e.g., 2025 Minor Season (SON) Forecast for Ghana",
                    initialValue: d.title,
                    onChanged: ctrl.setTitle,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("Season"),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: cfg.seasonOptions.contains(d.season)
                            ? d.season
                            : null,
                        decoration: _decor(),
                        items: cfg.seasonOptions
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) ctrl.setSeason(v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FormField(
                    label: "Year",
                    hint: "2025",
                    initialValue: d.year,
                    onChanged: ctrl.setYear,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    label: "Issued Date",
                    hint: "e.g., 15 Aug 2025",
                    initialValue: d.issuedDate,
                    onChanged: ctrl.setIssuedDate,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FormField(
                    label: "Prepared By",
                    hint: "Name of forecaster",
                    initialValue: d.preparedBy,
                    onChanged: ctrl.setPreparedBy,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _FormField(
              label: "Executive Summary (for farmers)",
              hint: "Brief overview of what to expect this season...",
              initialValue: d.executiveSummary,
              onChanged: ctrl.setExecutiveSummary,
              maxLines: 3,
              isDark: isDark,
            ),
          ],
        ),
      );
    });
  }
}

// ============================================================================
// STEP 2: ZONE FORECASTS
// ============================================================================
class _ZoneForecasts extends StatelessWidget {
  final SeasonalForecastController ctrl;
  final bool isDark;
  const _ZoneForecasts({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cfg = ctrl.config.value;
      final zonalForecasts = ctrl.draft.value.zonalForecasts;

      return Column(
        children: cfg.zones.map((zone) {
          final zf = zonalForecasts[zone];
          if (zf == null) return const SizedBox.shrink();

          return _Card(
            isDark: isDark,
            margin: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.mapPin(),
                        color: const Color(0xFF0B4EA2)),
                    const SizedBox(width: 8),
                    Text(
                      zone,
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _ForecastParam(
                  title: "ONSET",
                  icon: PhosphorIcons.play(),
                  options: cfg.onsetCategories,
                  selected: zf.onsetCategory,
                  rangeValue: zf.onsetDateRange,
                  rangeLabel: "Date Range",
                  onCategory: (v) =>
                      ctrl.updateZonalField(zone, 'onset_category', v),
                  onRange: (v) =>
                      ctrl.updateZonalField(zone, 'onset_date_range', v),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                _ForecastParam(
                  title: "CUMULATIVE RAINFALL",
                  icon: PhosphorIcons.cloudRain(),
                  options: cfg.rainfallCategories,
                  selected: zf.rainfallCategory,
                  rangeValue: zf.rainfallRangeMm,
                  rangeLabel: "Range (mm)",
                  onCategory: (v) =>
                      ctrl.updateZonalField(zone, 'rainfall_category', v),
                  onRange: (v) =>
                      ctrl.updateZonalField(zone, 'rainfall_range_mm', v),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _ForecastParam(
                        title: "EARLY DRY SPELL",
                        icon: PhosphorIcons.sun(),
                        options: cfg.drySpellCategories,
                        selected: zf.earlyDrySpellCategory,
                        rangeValue: zf.earlyDrySpellDays,
                        rangeLabel: "Days",
                        onCategory: (v) => ctrl.updateZonalField(
                            zone, 'early_dry_spell_category', v),
                        onRange: (v) => ctrl.updateZonalField(
                            zone, 'early_dry_spell_days', v),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ForecastParam(
                        title: "LATE DRY SPELL",
                        icon: PhosphorIcons.sun(),
                        options: cfg.drySpellCategories,
                        selected: zf.lateDrySpellCategory,
                        rangeValue: zf.lateDrySpellDays,
                        rangeLabel: "Days",
                        onCategory: (v) => ctrl.updateZonalField(
                            zone, 'late_dry_spell_category', v),
                        onRange: (v) => ctrl.updateZonalField(
                            zone, 'late_dry_spell_days', v),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _ForecastParam(
                  title: "CESSATION",
                  icon: PhosphorIcons.stop(),
                  options: cfg.cessationCategories,
                  selected: zf.cessationCategory,
                  rangeValue: zf.cessationDateRange,
                  rangeLabel: "Date Range",
                  onCategory: (v) =>
                      ctrl.updateZonalField(zone, 'cessation_category', v),
                  onRange: (v) =>
                      ctrl.updateZonalField(zone, 'cessation_date_range', v),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                _ForecastParam(
                  title: "LENGTH OF SEASON",
                  icon: PhosphorIcons.hourglass(),
                  options: cfg.seasonLengthCategories,
                  selected: zf.seasonLengthCategory,
                  rangeValue: zf.seasonLengthDays,
                  rangeLabel: "Days",
                  onCategory: (v) => ctrl.updateZonalField(
                      zone, 'season_length_category', v),
                  onRange: (v) =>
                      ctrl.updateZonalField(zone, 'season_length_days', v),
                  isDark: isDark,
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}

class _ForecastParam extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> options;
  final String selected;
  final String rangeValue;
  final String rangeLabel;
  final Function(String) onCategory;
  final Function(String) onRange;
  final bool isDark;

  const _ForecastParam({
    required this.title,
    required this.icon,
    required this.options,
    required this.selected,
    required this.rangeValue,
    required this.rangeLabel,
    required this.onCategory,
    required this.onRange,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final safe =
        options.contains(selected) ? selected : (options.isNotEmpty ? options.first : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: safe.isNotEmpty ? safe : null,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: options
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child: Text(o,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onCategory(v);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextFormField(
              key: ValueKey(title),
                initialValue: rangeValue,
                decoration: InputDecoration(
                  labelText: rangeLabel,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: onRange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// STEP 3: MAP PREVIEW
// ============================================================================
class _MapPreview extends StatelessWidget {
  final SeasonalForecastController ctrl;
  final bool isDark;
  const _MapPreview({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      height: 500,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Obx(() {
          // Reading draft.value inside Obx registers the dependency —
          // any rainfall_category change triggers a repaint.
          final _ = ctrl.draft.value;

          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(7.95, -1.02),
              initialZoom: 7.0,
              minZoom: 6.0,
              maxZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              PolygonLayer(
                polygons: regionPolygons.entries
                    .map((entry) {
                  final color = ctrl.getRegionColor(entry.key);
                  return Polygon(
                    points: entry.value,
                    color: color.withOpacity(0.40),
                    borderColor: color.withOpacity(0.85),
                    borderStrokeWidth: 1.8,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: [
                  _zoneLabel(const LatLng(9.80, -1.20),  "Northern Sector", isDark),
                  _zoneLabel(const LatLng(7.80, -1.10),  "Transition Zone", isDark),
                  _zoneLabel(const LatLng(6.55, -1.40),  "Forest Zone",     isDark),
                  _zoneLabel(const LatLng(5.55, -2.20),  "West Coast",      isDark),
                  _zoneLabel(const LatLng(5.60,  0.05),  "East Coast",      isDark),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

Marker _zoneLabel(LatLng pos, String label, bool isDark) {
  return Marker(
    point: pos,
    width: 130,
    height: 26,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.70)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

// ============================================================================
// STEP 4: ADVISORIES
// ============================================================================
class _AdvisoriesSection extends StatelessWidget {
  final SeasonalForecastController ctrl;
  final bool isDark;
  const _AdvisoriesSection({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textCtrl = TextEditingController();

    return _Card(
      isDark: isDark,
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Add practical advice for farmers based on this forecast",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textCtrl,
                  decoration: InputDecoration(
                    hintText:
                        "e.g., Farmers in East Coast should plant drought-resistant crops",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (v) {
                    ctrl.addAdvisory(v);
                    textCtrl.clear();
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ctrl.addAdvisory(textCtrl.text);
                  textCtrl.clear();
                },
                icon: Icon(PhosphorIcons.plus()),
                label: const Text("Add"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() => Column(
                children: ctrl.draft.value.advisories
                    .asMap()
                    .entries
                    .map(
                      (e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.lightbulb(),
                                size: 18, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(PhosphorIcons.x(), size: 18),
                              onPressed: () => ctrl.removeAdvisory(e.key),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              )),
        ],
      ),
    );
  }
}

// ============================================================================
// ACTION BUTTONS
// ============================================================================
class _ActionButtons extends StatelessWidget {
  final SeasonalForecastController ctrl;
  final bool isDark;
  const _ActionButtons({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed:
                  ctrl.isSavingDraft.value || ctrl.isPublishing.value
                      ? null
                      : ctrl.saveDraft,
              icon: ctrl.isSavingDraft.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(PhosphorIcons.floppyDisk()),
              label: const Text("Save Draft"),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed:
                  ctrl.isSavingDraft.value || ctrl.isPublishing.value
                      ? null
                      : ctrl.publishForecast,
              icon: ctrl.isPublishing.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(
                      PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill)),
              label: const Text("Publish Forecast"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B4EA2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ));
  }
}

// ============================================================================
// SHARED HELPERS
// ============================================================================

class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsets margin;
  const _Card({
    required this.isDark,
    required this.child,
    this.margin = const EdgeInsets.only(top: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final String initialValue;
  final Function(String) onChanged;
  final int maxLines;
  final bool isDark;

  const _FormField({
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.onChanged,
    this.maxLines = 1,
    required this.isDark,
  });

 @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        TextFormField(
          // CHANGE THIS LINE: Remove $initialValue from the key
          key: ValueKey(label), 
          initialValue: initialValue,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

Widget _label(String text) => Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
      ),
    );

InputDecoration _decor() => InputDecoration(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );