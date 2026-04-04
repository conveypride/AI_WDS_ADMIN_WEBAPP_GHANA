// lib/app/views/five_day_forecast_widgets/regional_forecast_tab.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../controllers/five_day_forecast_controller.dart';
import '../../theme/app_theme.dart';

class RegionalForecastTab extends GetView<FiveDayForecastController> {
  const RegionalForecastTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── INFO BANNER ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.info(), color: AppTheme.accentBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Define weather patterns and conditions for each region over the 5-day period',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // ── REGION CARDS ──────────────────────────────────────────────────
          Obx(() {
            final forecast = controller.currentForecast.value;
            if (forecast == null) return const SizedBox.shrink();
            
            return Column(
              children: forecast.regionForecasts.map((region) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildRegionCard(region, context),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRegionCard(dynamic region, BuildContext context) {
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
          // Card Header
          Row(
            children: [
              Icon(PhosphorIcons.mapPin(), color: AppTheme.accentBlue),
              const SizedBox(width: 12),
              Text(
                region.regionName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Row 1: Pattern & Temp
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration(
                    'Weather Pattern',
                    'e.g., Partly Cloudy',
                    PhosphorIcons.cloud(),
                    context,
                  ),
                  controller: TextEditingController(text: region.weatherPattern),
                  onChanged: (value) {
                    controller.updateRegionWeatherPattern(region.regionName, value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration(
                    'Temperature Range',
                    'e.g., 24-32°C',
                    PhosphorIcons.thermometer(),
                    context,
                  ),
                  controller: TextEditingController(text: region.temperatureRange),
                  onChanged: (value) {
                    controller.updateRegionTemperatureRange(region.regionName, value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Row 2: Rainfall Outlook
          TextField(
            maxLines: 2,
            style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
            decoration: _inputDecoration(
              'Rainfall Outlook',
              'e.g., Isolated showers possible, mainly in the afternoons',
              PhosphorIcons.cloudRain(),
              context,
            ),
            controller: TextEditingController(text: region.rainfallOutlook),
            onChanged: (value) {
              controller.updateRegionRainfallOutlook(region.regionName, value);
            },
          ),
          const SizedBox(height: 16),
          
          // Row 3: Wind & Visibility
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration(
                    'Wind Conditions',
                    'e.g., Light to moderate SW winds',
                    PhosphorIcons.wind(),
                    context,
                  ),
                  controller: TextEditingController(text: region.windConditions),
                  onChanged: (value) {
                    controller.updateRegionWindConditions(region.regionName, value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration(
                    'Visibility',
                    'e.g., Good',
                    PhosphorIcons.eye(),
                    context,
                  ),
                  controller: TextEditingController(text: region.visibility),
                  onChanged: (value) {
                    controller.updateRegionVisibility(region.regionName, value);
                  },
                ),
              ),
            ],
          ),
          
          // Row 4: Active Alerts
          if (region.alerts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warningAmber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.warning(), color: AppTheme.warningAmber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Active Alerts:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.warningAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...region.alerts.map<Widget>((alert) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 28, top: 4),
                      child: Text(
                        '• $alert',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningAmber,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── HELPER WIDGET ─────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String labelText, String hintText, IconData icon, BuildContext context) {
    final wc = context.wColors;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(color: wc.textSecondary),
      hintStyle: TextStyle(color: wc.textMuted),
      prefixIcon: Icon(icon, color: wc.textMuted, size: 20),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
// // lib/app/views/five_day_forecast_widgets/regional_forecast_tab.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import '../../controllers/five_day_forecast_controller.dart';
// import '../../theme/app_theme.dart';

// class RegionalForecastTab extends GetView<FiveDayForecastController> {
//   const RegionalForecastTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(32),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.blue[50],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               children: [
//                 Icon(PhosphorIcons.info(), color: Colors.blue[700]),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     'Define weather patterns and conditions for each region over the 5-day period',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.blue[900],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),
//           Obx(() {
//             final forecast = controller.currentForecast.value;
//             if (forecast == null) return const SizedBox.shrink();
            
//             return Column(
//               children: forecast.regionForecasts.map((region) {
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 24),
//                   child: _buildRegionCard(region),
//                 );
//               }).toList(),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildRegionCard(dynamic region) {
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
//                 Icon(PhosphorIcons.mapPin(), color: AppTheme.primaryColor),
//                 const SizedBox(width: 12),
//                 Text(
//                   region.regionName,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       labelText: 'Weather Pattern',
//                       hintText: 'e.g., Partly Cloudy',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       prefixIcon: Icon(PhosphorIcons.cloud()),
//                     ),
//                     controller: TextEditingController(text: region.weatherPattern),
//                     onChanged: (value) {
//                       controller.updateRegionWeatherPattern(region.regionName, value);
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       labelText: 'Temperature Range',
//                       hintText: 'e.g., 24-32°C',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       prefixIcon: Icon(PhosphorIcons.thermometer()),
//                     ),
//                     controller: TextEditingController(text: region.temperatureRange),
//                     onChanged: (value) {
//                       controller.updateRegionTemperatureRange(region.regionName, value);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               maxLines: 2,
//               decoration: InputDecoration(
//                 labelText: 'Rainfall Outlook',
//                 hintText: 'e.g., Isolated showers possible, mainly in the afternoons',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 prefixIcon: Icon(PhosphorIcons.cloudRain()),
//               ),
//               controller: TextEditingController(text: region.rainfallOutlook),
//               onChanged: (value) {
//                 controller.updateRegionRainfallOutlook(region.regionName, value);
//               },
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       labelText: 'Wind Conditions',
//                       hintText: 'e.g., Light to moderate SW winds',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       prefixIcon: Icon(PhosphorIcons.wind()),
//                     ),
//                     controller: TextEditingController(text: region.windConditions),
//                     onChanged: (value) {
//                       controller.updateRegionWindConditions(region.regionName, value);
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       labelText: 'Visibility',
//                       hintText: 'e.g., Good',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       prefixIcon: Icon(PhosphorIcons.eye()),
//                     ),
//                     controller: TextEditingController(text: region.visibility),
//                     onChanged: (value) {
//                       controller.updateRegionVisibility(region.regionName, value);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             if (region.alerts.isNotEmpty) ...[
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.orange[50],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.orange[300]!),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(PhosphorIcons.warning(), color: Colors.orange[700], size: 20),
//                         const SizedBox(width: 8),
//                         Text(
//                           'Active Alerts:',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.orange[900],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     ...region.alerts.map<Widget>((alert) {
//                       return Padding(
//                         padding: const EdgeInsets.only(left: 28, top: 4),
//                         child: Text(
//                           '• $alert',
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: Colors.orange[900],
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }