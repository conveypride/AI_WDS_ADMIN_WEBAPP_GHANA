import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_admin_dashboard/app/controllers/map_controller.dart';
import 'package:weather_admin_dashboard/app/services/weather_service.dart'; 
import 'package:weather_admin_dashboard/app/views/map_view.dart'
    show MapViewController, CityWeatherData, WeatherIconUtils, WestAfricaConstants;
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/controllers/dashboard_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

import '../helpers/mapconfig.dart';

class HomeView extends GetView<DashboardController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── WELCOME BANNER ────────────────────────
              _WelcomeBanner(),
              SizedBox(height: isMobile ? 20 : 24),

              // ── KPI CARDS ─────────────────────────────
              _KpiGrid(isMobile: isMobile),
              SizedBox(height: isMobile ? 20 : 24),

              // ── MAP + ANALYTICS ───────────────────────
              if (isMobile) ...[
                _MapCard(),
                const SizedBox(height: 20),
                _ChatTrendsCard(),
              ] else
                SizedBox(
                  height: 440,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _MapCard()),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: _ChatTrendsCard()),
                    ],
                  ),
                ),

              SizedBox(height: isMobile ? 20 : 24),

              // ── BOTTOM ROW ────────────────────────────
              if (isMobile) ...[
                _RecentForecastsCard(),
                const SizedBox(height: 20),
                _ActiveAlertsCard(),
              ] else
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _RecentForecastsCard()),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: _ActiveAlertsCard()),
                    ],
                  ),
                ),

              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WELCOME BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F2044), const Color(0xFF0C1830)]
              : [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppTheme.accentBlue.withOpacity(0.2)
              : Colors.white.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentBlue.withOpacity(isDark ? 0.12 : 0.35),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.successGreen
                                          .withOpacity(0.7),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Systems Operational',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Good Morning, Admin 👋',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here\'s what\'s happening across the meteorology unit today.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      children: [
                        _BannerAction(
                          icon: PhosphorIcons.plus(),
                          label: 'New Forecast',
                          primary: true,
                        ),
                        _BannerAction(
                          icon: PhosphorIcons.warning(),
                          label: 'Issue Alert',
                          primary: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              _WeatherWidget(),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool primary;

  const _BannerAction({
    required this.icon,
    required this.label,
    required this.primary,
  });

  @override
  State<_BannerAction> createState() => _BannerActionState();
}

class _BannerActionState extends State<_BannerAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.primary
                ? (_hovered
                    ? Colors.white
                    : Colors.white.withOpacity(0.9))
                : Colors.white.withOpacity(_hovered ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(9),
            border: widget.primary
                ? null
                : Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.primary
                    ? AppTheme.accentBlue
                    : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.primary ? AppTheme.accentBlue : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          const Text(
            '28°C',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Partly Cloudy',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accra, GH',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI GRID
// ─────────────────────────────────────────────────────────────────────────────
class _KpiGrid extends GetView<DashboardController> {
  final bool isMobile;
  const _KpiGrid({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final kpis = [
      _KpiData(
        label: 'Active Users',
        valueBuilder: () => '${controller.totalActiveChats}',
        icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
        color: AppTheme.accentBlue,
        subtext: '+12% this week',
        trend: true,
      ),
      _KpiData(
        label: 'Alert Reach',
        valueBuilder: () => controller.alertReach.value,
        icon: PhosphorIcons.broadcast(PhosphorIconsStyle.fill),
        color: AppTheme.successGreen,
        subtext: 'Citizens reached',
        trend: true,
      ),
      _KpiData(
        label: 'Pending Approvals',
        valueBuilder: () => '${controller.pendingApprovals}',
        icon: PhosphorIcons.fileText(PhosphorIconsStyle.fill),
        color: AppTheme.warningAmber,
        subtext: 'Action needed',
        trend: null,
      ),
      _KpiData(
        label: 'Critical Reports',
        valueBuilder: () => '${controller.criticalReports}',
        icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
        color: AppTheme.dangerRed,
        subtext: 'Hotspots found',
        trend: false,
      ),
    ];

    if (isMobile) {
      return Column(
        children: kpis
            .map((k) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _KpiCard(data: k),
                ))
            .toList(),
      );
    }

    return Row(
      children: kpis
          .map((k) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: k == kpis.last ? 0 : 16,
                  ),
                  child: _KpiCard(data: k),
                ),
              ))
          .toList(),
    );
  }
}

class _KpiData {
  final String label;
  final String Function() valueBuilder;
  final IconData icon;
  final Color color;
  final String subtext;
  final bool? trend; // true=up, false=down, null=neutral

  const _KpiData({
    required this.label,
    required this.valueBuilder,
    required this.icon,
    required this.color,
    required this.subtext,
    required this.trend,
  });
}

class _KpiCard extends StatefulWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;
    final d = widget.data;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _hovered ? wc.card : wc.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? d.color.withOpacity(0.3) : wc.border,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? d.color.withOpacity(0.08)
                  : Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: _hovered ? 24 : 10,
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: d.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(d.icon, size: 20, color: d.color),
                ),
                const Spacer(),
                if (d.trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (d.trend! ? AppTheme.successGreen : AppTheme.dangerRed)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          d.trend!
                              ? PhosphorIcons.trendUp()
                              : PhosphorIcons.trendDown(),
                          size: 12,
                          color: d.trend!
                              ? AppTheme.successGreen
                              : AppTheme.dangerRed,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          d.trend! ? '+12%' : '-3%',
                          style: TextStyle(
                            color: d.trend!
                                ? AppTheme.successGreen
                                : AppTheme.dangerRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.clock(),
                          size: 11,
                          color: AppTheme.warningAmber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Pending',
                          style: TextStyle(
                            color: AppTheme.warningAmber,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => Text(
                  d.valueBuilder(),
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: wc.textPrimary,
                    letterSpacing: -0.5,
                  ),
                )),
            const SizedBox(height: 4),
            Text(
              d.label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: wc.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              d.subtext,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: wc.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAP CARD  (live — powered by MapViewController)
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in replacement for the placeholder _MapCard.
/// Registers [MapViewController] if not already present, then renders
/// the full FlutterMap + overlay controls + forecast timeline inside
/// the standard _Card shell used by the rest of the dashboard.
class _MapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Ensure controller is available (idempotent — Get.put returns
    // the existing instance if it was already registered).
    final ctrl = Get.put(MapViewController());

    return _Card(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ── CARD HEADER ───────────────────────────────────────
            _MapCardHeader(ctrl: ctrl),

            // ── OVERLAY TOGGLE STRIP ──────────────────────────────
            _MapOverlayStrip(ctrl: ctrl),

            // ── MAP BODY ──────────────────────────────────────────
            Expanded(child: _MapBody(ctrl: ctrl)),

            // ── FORECAST TIMELINE (shown only when CRR/RDT active) ─
            Obx(() {
              final show = ctrl.forecastFrames.isNotEmpty &&
                  (ctrl.showCRR.value || ctrl.showRDT.value);
              return show
                  ? _MapTimeline(ctrl: ctrl)
                  : const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}

// ── HEADER ────────────────────────────────────────────────────────────────────
class _MapCardHeader extends StatelessWidget {
  final MapViewController ctrl;
  const _MapCardHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: wc.card,
        border: Border(bottom: BorderSide(color: wc.border)),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              PhosphorIcons.mapTrifold(PhosphorIconsStyle.fill),
              size: 17,
              color: AppTheme.accentBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'West Africa Weather Map',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Obx(() => Text(
                      'Updated ${ctrl.lastUpdated.value.isNotEmpty ? ctrl.lastUpdated.value : "--:--"} · Live',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: wc.textMuted),
                    )),
              ],
            ),
          ),

          // Live dot
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.successGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successGreen.withOpacity(0.55),
                  blurRadius: 6,
                ),
              ],
            ),
          ),

          // Refresh button
          Obx(() => _MapHeaderBtn(
                icon: ctrl.isRefreshing.value
                    ? PhosphorIcons.spinner()
                    : PhosphorIcons.arrowsClockwise(),
                spinning: ctrl.isRefreshing.value,
                onTap: ctrl.isRefreshing.value ? null : ctrl.refreshData,
              )),
        ],
      ),
    );
  }
}

class _MapHeaderBtn extends StatefulWidget {
  final IconData icon;
  final bool spinning;
  final VoidCallback? onTap;
  const _MapHeaderBtn(
      {required this.icon, required this.spinning, required this.onTap});

  @override
  State<_MapHeaderBtn> createState() => _MapHeaderBtnState();
}

class _MapHeaderBtnState extends State<_MapHeaderBtn>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    if (widget.spinning) _spin.repeat();
  }

  @override
  void didUpdateWidget(_MapHeaderBtn old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.spinning && _spin.isAnimating) {
      _spin.stop();
      _spin.reset();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _hovered ? wc.elevated : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hovered ? wc.borderSoft : Colors.transparent,
            ),
          ),
          child: RotationTransition(
            turns: _spin,
            child: Icon(widget.icon,
                size: 16,
                color: widget.onTap == null
                    ? wc.textMuted
                    : (_hovered ? AppTheme.accentBlue : wc.textSecondary)),
          ),
        ),
      ),
    );
  }
}

// ── OVERLAY STRIP ─────────────────────────────────────────────────────────────
class _MapOverlayStrip extends StatelessWidget {
  final MapViewController ctrl;
  const _MapOverlayStrip({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: wc.elevated.withOpacity(0.6),
        border: Border(bottom: BorderSide(color: wc.border)),
      ),
      child: Row(
        children: [
          Text(
            'OVERLAY',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: wc.textMuted, letterSpacing: 0.9),
          ),
          const SizedBox(width: 12),

          // Rain & Storm chip
          Obx(() => _OverlayChip(
                label: 'Rain & Storm',
                icon: PhosphorIcons.cloudRain(),
                active: ctrl.showCRR.value || ctrl.showRDT.value,
                activeColor: AppTheme.accentBlue,
                onTap: ctrl.toggleCRRRDT,
                loading: ctrl.isLoadingWeather.value || ctrl.isForecastLoading.value,
              )),
          const SizedBox(width: 8),

          // Weather Icons chip
          Obx(() => _OverlayChip(
                label: 'City Weather',
                icon: PhosphorIcons.thermometer(),
                active: ctrl.showWeatherIcons.value,
                activeColor: AppTheme.warningAmber,
                onTap: ctrl.toggleWeatherIcons,
                loading: ctrl.isLoadingCityWeather.value,
              )),

          const Spacer(),

          // Stats badge
          Obx(() {
            final crrN = ctrl.crrPolygons.length;
            final rdtN = ctrl.rdtPolygons.length + ctrl.rdtPolylines.length;
            final citN = ctrl.cityWeatherData.length;
            final hasData = crrN + rdtN + citN > 0;
            if (!hasData) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.accentBlue.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (crrN > 0) ...[
                    Text('CRR $crrN',
                        style: TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        )),
                    if (rdtN > 0) ...[
                      Container(
                          width: 1,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          color: AppTheme.accentBlue.withOpacity(0.3)),
                    ],
                  ],
                  if (rdtN > 0)
                    Text('RDT $rdtN',
                        style: TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        )),
                  if (citN > 0)
                    Text('${citN} cities',
                        style: TextStyle(
                          color: AppTheme.warningAmber,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _OverlayChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  final bool loading;
  const _OverlayChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
    this.loading = false,
  });

  @override
  State<_OverlayChip> createState() => _OverlayChipState();
}

class _OverlayChipState extends State<_OverlayChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final active = widget.active;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? widget.activeColor
                : (_hovered ? wc.elevated : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? widget.activeColor
                  : (_hovered ? wc.borderSoft : wc.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // spinner or icon
              widget.loading
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          active ? Colors.white : wc.textSecondary,
                        ),
                      ),
                    )
                  : Icon(
                      active
                          ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                          : widget.icon,
                      size: 13,
                      color: active ? Colors.white : wc.textSecondary,
                    ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: active ? Colors.white : wc.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── MAP BODY ──────────────────────────────────────────────────────────────────
class _MapBody extends StatelessWidget {
  final MapViewController ctrl;
  const _MapBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return Stack(
      children: [
        // ── FLUTTER MAP ─────────────────────────────────────────
        Obx(() => FlutterMap(
              mapController: ctrl.mapController,
              options: MapOptions(
                initialCenter: ctrl.initialPosition,
                initialZoom: ctrl.initialZoom,
                minZoom: 4.0,
                maxZoom: 18.0,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.all),
                onMapReady: () => ctrl.isMapReady.value = true,
              ),
              children: [
                // Base tile layer — desaturated to match dark theme
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.weather.admin.dashboard',
                  tileBuilder: (ctx, tile, _) => ColorFiltered(
                    colorFilter: ColorFilter.matrix(
                      context.isDark
                          // Dark mode: desaturate + darken
                          ? [
                              0.28, 0.28, 0.28, 0, -30,
                              0.28, 0.28, 0.28, 0, -30,
                              0.28, 0.28, 0.28, 0, -30,
                              0,    0,    0,    1,   0,
                            ]
                          // Light mode: mild desaturate only
                          : [
                              0.85, 0.10, 0.05, 0, 0,
                              0.05, 0.85, 0.10, 0, 0,
                              0.05, 0.10, 0.85, 0, 0,
                              0,    0,    0,    1, 0,
                            ],
                    ),
                    child: tile,
                  ),
                ),

                // CRR rain polygons
                if (ctrl.crrPolygons.isNotEmpty)
                  PolygonLayer(polygons: ctrl.crrPolygons),

                // RDT storm polygons + forecast polylines
                if (ctrl.rdtPolygons.isNotEmpty)
                  PolygonLayer(polygons: ctrl.rdtPolygons),
                if (ctrl.rdtPolylines.isNotEmpty)
                  PolylineLayer(polylines: ctrl.rdtPolylines),

                // City weather markers
                if (ctrl.showWeatherIcons.value &&
                    ctrl.cityWeatherData.isNotEmpty)
                  MarkerLayer(
                    markers: ctrl.cityWeatherData
                        .map((city) => Marker(
                              point: LatLng(city.lat, city.lon),
                              width: 80,
                              height: 64,
                              child: _CityMarker(city: city),
                            ))
                        .toList(),
                  ),
              ],
            )),

        // ── LOADING OVERLAY ─────────────────────────────────────
        Obx(() {
          final loading = ctrl.isLoadingWeather.value ||
              ctrl.isForecastLoading.value ||
              ctrl.isLoadingCityWeather.value;
          if (!loading) return const SizedBox.shrink();
          return Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: wc.card.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: wc.border),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2), blurRadius: 12)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.accentBlue),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Obx(() => Text(
                          ctrl.isForecastLoading.value
                              ? 'Loading timeline…'
                              : ctrl.isLoadingCityWeather.value
                                  ? 'Fetching city data…'
                                  : 'Loading ${ctrl.completedRequests.value}/${ctrl.totalCoveragePoints.value * 2}',
                          style: TextStyle(
                            color: wc.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                  ],
                ),
              ),
            ),
          );
        }),

        // ── CRR RAIN LEGEND ─────────────────────────────────────
        Obx(() {
          if (!ctrl.showCRR.value && !ctrl.showRDT.value) {
            return const SizedBox.shrink();
          }
          return Positioned(
            bottom: 12,
            left: 12,
            child: _RainLegend(),
          );
        }),

        // ── ZOOM CONTROLS ────────────────────────────────────────
        Positioned(
          bottom: 12,
          right: 12,
          child: _ZoomControls(ctrl: ctrl),
        ),
      ],
    );
  }
}

// ── CITY WEATHER MARKER ───────────────────────────────────────────────────────
class _CityMarker extends StatelessWidget {
  final CityWeatherData city;
  const _CityMarker({required this.city});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return GestureDetector(
      onTap: () => _showWeatherPopup(context, city),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: wc.card.withOpacity(0.92),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.accentBlue.withOpacity(0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.25), blurRadius: 6),
              ],
            ),
            child: Text(
              WeatherIconUtils.getWeatherEmoji(city.icon),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: wc.card.withOpacity(0.88),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: wc.border),
            ),
            child: Text(
              '${city.temperature.round()}°',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: wc.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeatherPopup(BuildContext context, CityWeatherData city) {
    final wc = context.wColors;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: wc.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: wc.borderSoft),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.35), blurRadius: 24)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: wc.elevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(PhosphorIcons.x(),
                          size: 12, color: wc.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(WeatherIconUtils.getWeatherEmoji(city.icon),
                    style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text(city.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(city.region,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: wc.textMuted)),
                const SizedBox(height: 12),
                Text(
                  '${city.temperature.round()}°C',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(city.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: wc.textSecondary)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: wc.elevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: wc.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _WeatherDetail(
                        icon: PhosphorIcons.wind(),
                        label: 'Wind',
                        value: '${city.windSpeed.toStringAsFixed(1)} m/s',
                      ),
                      Container(width: 1, height: 28, color: wc.border),
                      _WeatherDetail(
                        icon: PhosphorIcons.drop(),
                        label: 'Humidity',
                        value: '${city.humidity.round()}%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _WeatherDetail(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.accentBlue),
        const SizedBox(height: 3),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: wc.textMuted)),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: wc.textPrimary)),
      ],
    );
  }
}

// ── RAIN LEGEND ───────────────────────────────────────────────────────────────
class _RainLegend extends StatelessWidget {
  static const _entries = [
    (color: Color(0xFF87CEEB), label: '0.2–1'),
    (color: Color(0xFF32CD32), label: '3–5'),
    (color: Color(0xFFFFD700), label: '10–15'),
    (color: Color(0xFFFFA500), label: '15–20'),
    (color: Color(0xFFFF0000), label: '30–50'),
    (color: Color(0xFF8B0000), label: '50+'),
  ];

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: wc.card.withOpacity(0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: wc.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'RAIN RATE (mm/h)',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: wc.textMuted, letterSpacing: 0.7),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _entries
                .map((e) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: e.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            e.label,
                            style: TextStyle(
                              color: wc.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── ZOOM CONTROLS ─────────────────────────────────────────────────────────────
class _ZoomControls extends StatelessWidget {
  final MapViewController ctrl;
  const _ZoomControls({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomBtn(
          icon: PhosphorIcons.plus(),
          onTap: () {
            final cam = ctrl.mapController.camera;
            ctrl.mapController.move(cam.center, cam.zoom + 1);
          },
          isTop: true,
        ),
        Container(width: 32, height: 1, color: wc.border),
        _ZoomBtn(
          icon: PhosphorIcons.minus(),
          onTap: () {
            final cam = ctrl.mapController.camera;
            ctrl.mapController.move(cam.center, cam.zoom - 1);
          },
          isTop: false,
        ),
      ],
    );
  }
}

class _ZoomBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isTop;
  const _ZoomBtn(
      {required this.icon, required this.onTap, required this.isTop});

  @override
  State<_ZoomBtn> createState() => _ZoomBtnState();
}

class _ZoomBtnState extends State<_ZoomBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.accentBlue : wc.card.withOpacity(0.9),
            borderRadius: BorderRadius.only(
              topLeft: widget.isTop
                  ? const Radius.circular(8)
                  : Radius.zero,
              topRight: widget.isTop
                  ? const Radius.circular(8)
                  : Radius.zero,
              bottomLeft: !widget.isTop
                  ? const Radius.circular(8)
                  : Radius.zero,
              bottomRight: !widget.isTop
                  ? const Radius.circular(8)
                  : Radius.zero,
            ),
            border: Border.all(color: wc.border),
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: _hovered ? Colors.white : wc.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── FORECAST TIMELINE ─────────────────────────────────────────────────────────
class _MapTimeline extends StatelessWidget {
  final MapViewController ctrl;
  const _MapTimeline({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: wc.card,
        border: Border(top: BorderSide(color: wc.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Controls row
          Row(
            children: [
              // Play/Pause
              Obx(() => _TimelineBtn(
                    icon: ctrl.isPlaying.value
                        ? PhosphorIcons.pause(PhosphorIconsStyle.fill)
                        : PhosphorIcons.play(PhosphorIconsStyle.fill),
                    onTap: ctrl.isForecastLoading.value
                        ? null
                        : () => ctrl.isPlaying.value
                            ? ctrl.stopPlayback()
                            : ctrl.startPlayback(),
                    primary: true,
                  )),
              const SizedBox(width: 4),

              // Reset
              _TimelineBtn(
                icon: PhosphorIcons.skipBack(),
                onTap: ctrl.isForecastLoading.value ? null : ctrl.resetPlayback,
              ),
              const SizedBox(width: 12),

              // Time label
              Obx(() {
                final frames = ctrl.forecastFrames;
                final idx = ctrl.currentFrameIndex.value;
                final timeStr = frames.isNotEmpty
                    ? ctrl.formatTime(frames[idx].timeslot)
                    : '--:--';
                final offsetStr = frames.isNotEmpty
                    ? ctrl.getOffsetLabel(frames[idx].offset)
                    : 'Now';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: wc.textPrimary,
                      ),
                    ),
                    Text(
                      offsetStr,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.accentBlue),
                    ),
                  ],
                );
              }),

              const Spacer(),

              // Loading indicator
              Obx(() => ctrl.isForecastLoading.value
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.accentBlue),
                      ),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: 8),

          // Slider
          Obx(() {
            final total = ctrl.forecastFrames.length;
            if (total < 2) return const SizedBox.shrink();
            return SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                activeTrackColor: AppTheme.accentBlue,
                inactiveTrackColor: wc.border,
                thumbColor: AppTheme.accentBlue,
                overlayColor: AppTheme.accentBlue.withOpacity(0.12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: ctrl.currentFrameIndex.value.toDouble(),
                min: 0,
                max: (total - 1).toDouble(),
                divisions: total - 1,
                onChanged: (v) => ctrl.onFrameChanged(v),
              ),
            );
          }),

          // Frame tick labels
          Obx(() {
            final frames = ctrl.forecastFrames;
            if (frames.isEmpty) return const SizedBox.shrink();
            // Show ~5 evenly spaced labels
            final step = (frames.length / 5).ceil().clamp(1, frames.length);
            final labels = <int>[];
            for (int i = 0; i < frames.length; i += step) {
              labels.add(i);
            }
            if (!labels.contains(frames.length - 1)) {
              labels.add(frames.length - 1);
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: labels
                    .map((i) => Text(
                          ctrl.getOffsetLabel(frames[i].offset),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: i == ctrl.currentFrameIndex.value
                                ? AppTheme.accentBlue
                                : wc.textMuted,
                          ),
                        ))
                    .toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  const _TimelineBtn(
      {required this.icon, required this.onTap, this.primary = false});

  @override
  State<_TimelineBtn> createState() => _TimelineBtnState();
}

class _TimelineBtnState extends State<_TimelineBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final enabled = widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: widget.primary ? 36 : 30,
          height: widget.primary ? 36 : 30,
          decoration: BoxDecoration(
            color: widget.primary
                ? (enabled
                    ? AppTheme.accentBlue
                    : wc.elevated)
                : (_hovered ? wc.elevated : Colors.transparent),
            borderRadius: BorderRadius.circular(widget.primary ? 10 : 8),
            border: widget.primary
                ? null
                : Border.all(
                    color: _hovered ? wc.borderSoft : Colors.transparent),
            boxShadow: widget.primary && enabled
                ? [
                    BoxShadow(
                      color: AppTheme.accentBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Icon(
            widget.icon,
            size: widget.primary ? 16 : 14,
            color: widget.primary
                ? Colors.white
                : (enabled
                    ? (_hovered ? AppTheme.accentBlue : wc.textSecondary)
                    : wc.textMuted),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: context.wColors.textSecondary),
        ),
      ],
    );
  }
}

class _ChatTrendsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final bars = [
      _BarData('Rain', 0.82, AppTheme.accentBlue),
      _BarData('Flood', 0.65, AppTheme.infoCyan),
      _BarData('Heat', 0.44, AppTheme.warningAmber),
      _BarData('Wind', 0.38, AppTheme.successGreen),
      _BarData('Storm', 0.55, AppTheme.dangerRed),
    ];

    return _Card(
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
                      'Chat Trends',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Most discussed weather topics',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: wc.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: wc.elevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: wc.border),
                ),
                child: Text(
                  'This week',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: wc.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bar chart
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.map((b) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _AnimatedBar(data: b),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: wc.border, height: 1),
          const SizedBox(height: 14),

          // Summary row
          Row(
            children: [
              Icon(PhosphorIcons.chatCircle(PhosphorIconsStyle.fill),
                  size: 16, color: AppTheme.accentBlue),
              const SizedBox(width: 6),
              Text(
                '2,847 total discussions',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: wc.textSecondary),
              ),
              const Spacer(),
              Text(
                '↑ 18% vs last week',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarData {
  final String label;
  final double pct;
  final Color color;
  const _BarData(this.label, this.pct, this.color);
}

class _AnimatedBar extends StatefulWidget {
  final _BarData data;
  const _AnimatedBar({required this.data});

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_hovered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: widget.data.color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${(widget.data.pct * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Expanded(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => FractionallySizedBox(
                heightFactor: widget.data.pct * _anim.value,
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.data.color.withOpacity(_hovered ? 0.9 : 0.55),
                        widget.data.color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _hovered
                        ? [
                            BoxShadow(
                              color: widget.data.color.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.data.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _hovered ? widget.data.color : wc.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECENT FORECASTS TABLE
// ─────────────────────────────────────────────────────────────────────────────
class _RecentForecastsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final forecasts = [
      _ForecastRow(
        date: 'Oct 24, 2024',
        type: 'Daily Forecast (24H)',
        typeIcon: PhosphorIcons.sun(),
        author: 'J. Mensah',
        status: 'Approved',
        statusColor: AppTheme.successGreen,
      ),
      _ForecastRow(
        date: 'Oct 25, 2024',
        type: '7-Day Outlook',
        typeIcon: PhosphorIcons.calendarCheck(),
        author: 'A. Boateng',
        status: 'Pending',
        statusColor: AppTheme.warningAmber,
      ),
      _ForecastRow(
        date: 'Oct 26, 2024',
        type: 'Seasonal Forecast',
        typeIcon: PhosphorIcons.cloudRain(),
        author: 'S. Owusu',
        status: 'Draft',
        statusColor: AppTheme.darkTextSecondary,
      ),
      _ForecastRow(
        date: 'Oct 26, 2024',
        type: 'Marine Coastline',
        typeIcon: PhosphorIcons.waves(),
        author: 'K. Asante',
        status: 'Approved',
        statusColor: AppTheme.successGreen,
      ),
    ];

    return _Card(
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
                      'Recent Forecasts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Latest submitted forecast documents',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: wc.textMuted),
                    ),
                  ],
                ),
              ),
              _TextBtn(label: 'View all', onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: wc.elevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: _TableHeader(label: 'DATE')),
                Expanded(
                    flex: 3,
                    child: _TableHeader(label: 'FORECAST TYPE')),
                Expanded(
                    flex: 2,
                    child: _TableHeader(label: 'AUTHOR')),
                Expanded(
                    flex: 2,
                    child: _TableHeader(label: 'STATUS')),
                const SizedBox(width: 60, child: _TableHeader(label: '')),
              ],
            ),
          ),

          const SizedBox(height: 6),

          ...forecasts.map((f) => _ForecastRowWidget(row: f)),
        ],
      ),
    );
  }
}

class _ForecastRow {
  final String date;
  final String type;
  final IconData typeIcon;
  final String author;
  final String status;
  final Color statusColor;
  const _ForecastRow({
    required this.date,
    required this.type,
    required this.typeIcon,
    required this.author,
    required this.status,
    required this.statusColor,
  });
}

class _ForecastRowWidget extends StatefulWidget {
  final _ForecastRow row;
  const _ForecastRowWidget({required this.row});

  @override
  State<_ForecastRowWidget> createState() => _ForecastRowWidgetState();
}

class _ForecastRowWidgetState extends State<_ForecastRowWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final r = widget.row;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _hovered ? wc.elevated : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered ? wc.borderSoft : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                r.date,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: wc.textSecondary),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Icon(r.typeIcon,
                      size: 15, color: AppTheme.accentBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.type,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        r.author.split(' ').map((s) => s[0]).take(2).join(),
                        style: const TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.author,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: wc.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: r.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  r.status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: r.statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _RowAction(
                      icon: PhosphorIcons.pencilSimple(),
                      color: wc.textMuted),
                  const SizedBox(width: 4),
                  _RowAction(
                      icon: PhosphorIcons.trash(),
                      color: AppTheme.dangerRed.withOpacity(0.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  const _TableHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.wColors.textMuted,
            letterSpacing: 0.8,
          ),
    );
  }
}

class _RowAction extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _RowAction({required this.icon, required this.color});

  @override
  State<_RowAction> createState() => _RowActionState();
}

class _RowActionState extends State<_RowAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(widget.icon,
              size: 15,
              color: _hovered ? widget.color : context.wColors.textMuted),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE ALERTS CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveAlertsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final alerts = [
      _AlertData(
        title: 'Heavy Rainfall Warning',
        region: 'Western Region',
        severity: 'High',
        severityColor: AppTheme.dangerRed,
        icon: PhosphorIcons.cloudRain(PhosphorIconsStyle.fill),
        time: '2h ago',
      ),
      _AlertData(
        title: 'Strong Winds Advisory',
        region: 'Coastal Areas',
        severity: 'Moderate',
        severityColor: AppTheme.warningAmber,
        icon: PhosphorIcons.wind(),
        time: '4h ago',
      ),
      _AlertData(
        title: 'Marine Gale Warning',
        region: 'Gulf of Guinea',
        severity: 'High',
        severityColor: AppTheme.dangerRed,
        icon: PhosphorIcons.waves(),
        time: '6h ago',
      ),
      _AlertData(
        title: 'Harmattan Outlook',
        region: 'Northern Region',
        severity: 'Low',
        severityColor: AppTheme.infoCyan,
        icon: PhosphorIcons.sun(PhosphorIconsStyle.fill),
        time: '1d ago',
      ),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.dangerRed.withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Active Alerts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${alerts.length} active',
                  style: TextStyle(
                    color: AppTheme.dangerRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Requires your attention',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: wc.textMuted),
          ),
          const SizedBox(height: 16),
          ...alerts.map((a) => _AlertItem(data: a)),
        ],
      ),
    );
  }
}

class _AlertData {
  final String title;
  final String region;
  final String severity;
  final Color severityColor;
  final IconData icon;
  final String time;
  const _AlertData({
    required this.title,
    required this.region,
    required this.severity,
    required this.severityColor,
    required this.icon,
    required this.time,
  });
}

class _AlertItem extends StatefulWidget {
  final _AlertData data;
  const _AlertItem({required this.data});

  @override
  State<_AlertItem> createState() => _AlertItemState();
}

class _AlertItemState extends State<_AlertItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hovered ? wc.elevated : wc.elevated.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? d.severityColor.withOpacity(0.3)
                : wc.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: d.severityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(d.icon, size: 18, color: d.severityColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: wc.textPrimary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(PhosphorIcons.mapPin(),
                          size: 11, color: wc.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        d.region,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: wc.textMuted),
                      ),
                      const Spacer(),
                      Text(
                        d.time,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: wc.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: d.severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                d.severity,
                style: TextStyle(
                  color: d.severityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;
    return Container(
      padding: padding ?? const EdgeInsets.all(22),
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
      child: child,
    );
  }
}

class _TextBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _TextBtn({required this.label, required this.onTap});

  @override
  State<_TextBtn> createState() => _TextBtnState();
}

class _TextBtnState extends State<_TextBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.accentBlue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hovered ? AppTheme.accentBlue : AppTheme.accentBlue.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}


// // lib/app/views/homeView.dart

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:weather_admin_dashboard/app/controllers/dashboard_controller.dart';
// import 'package:weather_admin_dashboard/app/views/kpi_card.dart';
// import 'package:weather_admin_dashboard/app/views/widgets/InteractiveWeatherMapWidget.dart'; 

// class HomeView extends GetView<DashboardController> {
//   const HomeView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isMobile = constraints.maxWidth < 900;

//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // A. STATS OVERVIEW (KPIs)
//               _buildResponsiveKpiRow(context, isMobile),
              
//               const SizedBox(height: 24),

//               // B. MAP & ANALYTICS ROW
//               if (isMobile) ...[
//                 // Stacked for Mobile
//                 SizedBox(height: 400, child: _buildMapSection(context)),
//                 const SizedBox(height: 24),
//                 SizedBox(height: 350, child: _buildAnalyticsCard(context)),
//               ] else ...[
//                 // Side-by-Side for Desktop
//                 SizedBox(
//                   height: 450, // Slightly taller for better map view
//                   child: Row(
//                     children: [
//                       Expanded(flex: 2, child: _buildMapSection(context)),
//                       const SizedBox(width: 24),
//                       Expanded(flex: 1, child: _buildAnalyticsCard(context)),
//                     ],
//                   ),
//                 ),
//               ],

//               const SizedBox(height: 24),

//               // C. RECENT FORECASTS TABLE
//               _buildRecentForecastsTable(context),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // --- WIDGETS ---

//   Widget _buildResponsiveKpiRow(BuildContext context, bool isMobile) {
//     // If mobile, use a GridView or Column. If desktop, use a Row.
//     // Here we use a Wrap/Grid approach for flexibility.
    
//     final List<Widget> kpis = [
//       Obx(() => KpiCard(
//         title: "Active Public Users",
//         value: "${controller.totalActiveChats}",
//         icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
//         color: Colors.blue,
//         subtext: "+12% this week",
//       )),
//       Obx(() => KpiCard(
//         title: "Alert Reach",
//         value: controller.alertReach.value,
//         icon: PhosphorIcons.broadcast(PhosphorIconsStyle.fill),
//         color: Colors.green,
//       )),
//       Obx(() => KpiCard(
//         title: "Pending Approvals",
//         value: "${controller.pendingApprovals}",
//         icon: PhosphorIcons.fileText(PhosphorIconsStyle.fill),
//         color: Colors.orange,
//         subtext: "Action Needed",
//       )),
//       Obx(() => KpiCard(
//         title: "Public Reports",
//         value: "${controller.criticalReports}",
//         icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
//         color: Colors.red,
//         subtext: "Hotspots identified",
//       )),
//     ];

//     if (isMobile) {
//       return Column(
//         children: kpis.map((kpi) => Padding(
//           padding: const EdgeInsets.only(bottom: 16), 
//           child: kpi
//         )).toList(),
//       );
//     }

//     return Row(
//       children: kpis.map((kpi) => Expanded(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8), 
//           child: kpi
//         )
//       )).toList(),
//     );
//   }

//   Widget _buildMapSection(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: const InteractiveWeatherMapWidget(),
//       ),
//     );
//   }

//   Widget _buildAnalyticsCard(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text("Chat Trends", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
//           const SizedBox(height: 4),
//           Text("Most discussed topics", style: Theme.of(context).textTheme.bodySmall),
//           const SizedBox(height: 20),
//           Expanded(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _bar("Rain", 0.8, Colors.blue),
//                 _bar("Heat", 0.4, Colors.orange),
//                 _bar("Flood", 0.6, Colors.red),
//                 _bar("Wind", 0.3, Colors.teal),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _bar(String label, double pct, Color color) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         // Responsive Bar Height
//         Flexible(
//           child: FractionallySizedBox(
//             heightFactor: pct,
//             child: Container(
//               width: 40,
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: color),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold)),
//       ],
//     );
//   }

//   Widget _buildRecentForecastsTable(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
//       ),
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text("Recent Forecasts", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
//               TextButton(onPressed: () {}, child: const Text("View All")),
//             ],
//           ),
//           const SizedBox(height: 16),
          
//           // Responsive Table Wrapper
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(minWidth: 800), // Min width to prevent squashing
//               child: Table(
//                 defaultVerticalAlignment: TableCellVerticalAlignment.middle,
//                 columnWidths: const {
//                   0: FlexColumnWidth(1),
//                   1: FlexColumnWidth(1.5),
//                   2: FlexColumnWidth(1),
//                   3: FlexColumnWidth(1),
//                   4: FixedColumnWidth(100),
//                 },
//                 children: [
//                   TableRow(
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3), 
//                       borderRadius: BorderRadius.circular(4)
//                     ),
//                     children: [
//                       _tableHeader(context, "Date"),
//                       _tableHeader(context, "Type"),
//                       _tableHeader(context, "Author"),
//                       _tableHeader(context, "Status"),
//                       _tableHeader(context, "Action"),
//                     ],
//                   ),
//                   _tableRow(context, "Oct 24, 2023", "Daily Forecast", "John Doe", "Approved", Colors.green),
//                   _tableRow(context, "Oct 25, 2023", "5-Day Outlook", "Sarah Smith", "Pending", Colors.orange),
//                   _tableRow(context, "Oct 26, 2023", "Seasonal", "You", "Draft", Colors.grey),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _tableHeader(BuildContext context, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//       child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
//     );
//   }

//   TableRow _tableRow(BuildContext context, String date, String type, String author, String status, Color statusColor) {
//     return TableRow(
//       children: [
//         Padding(padding: const EdgeInsets.all(12), child: Text(date)),
//         Padding(padding: const EdgeInsets.all(12), child: Text(type, style: const TextStyle(fontWeight: FontWeight.w500))),
//         Padding(padding: const EdgeInsets.all(12), child: Text(author)),
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
//             child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
//           ),
//         ),
//         // FIX: Wrapped actions in a constrained Box or simply centered them to avoid Row overflow
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Wrap( // Changed from Row to Wrap to handle overflow gracefully
//             spacing: 8,
//             children: [
//               InkWell(
//                 onTap: () {},
//                 child: const Icon(Icons.edit, size: 18, color: Colors.grey),
//               ),
//               InkWell(
//                 onTap: () {},
//                 child: const Icon(Icons.delete, size: 18, color: Colors.red),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }