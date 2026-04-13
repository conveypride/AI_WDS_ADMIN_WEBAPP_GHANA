import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/controllers/inland_forecast_controller.dart';
import 'package:weather_admin_dashboard/app/views/marine_forecast/inland/enhancedMapCard.dart'; 
import 'package:weather_admin_dashboard/app/views/marine_forecast/inland/inland_ibf_components.dart';
 

class IBFContentTab extends StatelessWidget {
  final InlandForecastController ctrl;
  const IBFContentTab({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Forecast Details Card (Metadata inputs)
            ForecastDetailsCard(ctrl: ctrl, isDark: isDark),
            const SizedBox(height: 24),

            // ========================================================================
            // CRITICAL: Three Maps Section wrapped with RepaintBoundary for capture
            // ========================================================================
            _buildMapsWithCaptureKeys(ctrl, isDark),
            const SizedBox(height: 24),

            // Temperature Card
            TemperatureCard(ctrl: ctrl, isDark: isDark),
            const SizedBox(height: 24),

            // Summary Input
            WeatherSummaryCard(ctrl: ctrl, isDark: isDark),
            const SizedBox(height: 40),

            // Publish Button
            PublishForecastButton(ctrl: ctrl, isDark: isDark),
          ],
        ),
      ),
    );
  }

  /// Wraps each map with RepaintBoundary and assigns the appropriate GlobalKey
  /// This enables map capture for PDF generation
  Widget _buildMapsWithCaptureKeys(InlandForecastController ctrl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Header Row with Toggle Button
          Row(
            children: [
              Icon(
                Icons.map_outlined,
                color: isDark ? Colors.blueAccent : const Color(0xFF0B4EA2),
              ),
              const SizedBox(width: 12),
              Text(
                'WEATHER MAPS BY PERIOD',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              // Layout Toggle Button
              Obx(() => Tooltip(
                    message: ctrl.isVerticalMapLayout.value
                        ? "Switch to Row Layout"
                        : "Switch to Column Layout",
                    child: IconButton(
                      icon: Icon(
                        ctrl.isVerticalMapLayout.value
                            ? Icons.view_column
                            : Icons.view_agenda,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: ctrl.toggleMapLayout,
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 20),

          // Map Rendering with capture keys
          Obx(() {
            // ✅ LAZY LOADING: Only build maps if user is on the Map Tab
            if (ctrl.tabController.index != 2) {
               return const Padding(
                 padding: EdgeInsets.all(40),
                 child: Center(child: Text("Maps will load when this tab is active.")),
               );
            }
            final periods = ctrl.getOrderedPeriods();
            final dates = ctrl.dynamicDates;
            final isVertical = ctrl.isVerticalMapLayout.value;

            // Map period names to their GlobalKeys for capture
            final Map<String, GlobalKey> keyMap = {
              'MORNING': ctrl.morningMapKey,
              'AFTERNOON': ctrl.afternoonMapKey,
              'EVENING': ctrl.eveningMapKey,
              'NIGHT': ctrl.nightMapKey,
            };

            return Flex(
              direction: isVertical ? Axis.vertical : Axis.horizontal,
              children: List.generate(periods.length, (index) {
                final period = periods[index];
                final captureKey = keyMap[period.toUpperCase()];

                return Flexible(
                  flex: isVertical ? 0 : 1,
                  fit: isVertical ? FlexFit.loose : FlexFit.tight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isVertical ? 24.0 : 0.0,
                      left: isVertical ? 0.0 : 8.0,
                      right: isVertical ? 0.0 : 8.0,
                    ),
                    child: SizedBox(
                      height: isVertical ? 500 : null,
                      width: double.infinity,
                      // CRITICAL: RepaintBoundary with GlobalKey enables map capture
                      child: RepaintBoundary(
                        key: captureKey,
                        child: EnhancedMapCard(
                          key: ValueKey(period),
                          ctrl: ctrl,
                          period: period,
                          dateLabel: dates[index],
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}