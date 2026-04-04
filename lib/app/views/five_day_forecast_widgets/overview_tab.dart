import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../controllers/five_day_forecast_controller.dart';
import '../../theme/app_theme.dart';

class OverviewTab extends GetView<FiveDayForecastController> {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildForecasterInfoCard(context),
                    const SizedBox(height: 24),
                    _buildSummaryCard(context),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildQuickStatsCard(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _build5DayOverviewCard(context),
        ],
      ),
    );
  }

  Widget _buildForecasterInfoCard(BuildContext context) {
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
              Icon(PhosphorIcons.user(), color: AppTheme.accentBlue),
              const SizedBox(width: 12),
              Text(
                'Forecaster Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() => TextField(
            style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Forecaster Name',
              labelStyle: TextStyle(color: wc.textSecondary),
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: wc.textMuted),
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
              prefixIcon: Icon(PhosphorIcons.userCircle(), color: wc.textMuted),
            ),
            controller: TextEditingController(
              text: controller.currentForecast.value?.forecasterName ?? '',
            ),
            onChanged: (value) => controller.updateForecasterName(value),
          )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.08),
              border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.info(), color: AppTheme.accentBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This name will appear on the generated forecast report',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
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
              Icon(PhosphorIcons.notepad(), color: AppTheme.accentBlue),
              const SizedBox(width: 12),
              Text(
                'Forecast Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() => TextField(
            maxLines: 8,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: wc.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter a general summary of the 5-day forecast outlook...\n\nExample: The next five days will feature mixed weather conditions across Ghana. Coastal areas can expect partly cloudy skies with occasional showers, particularly during afternoons. The northern regions will experience dry and hazy conditions with temperatures ranging from warm to hot.',
              hintStyle: TextStyle(color: wc.textMuted),
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
            ),
            controller: TextEditingController(
              text: controller.currentForecast.value?.summary ?? '',
            ),
            onChanged: (value) => controller.updateSummary(value),
          )),
          const SizedBox(height: 12),
          Obx(() {
            final length = controller.currentForecast.value?.summary.length ?? 0;
            final isOverLimit = length > 500;
            return Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Characters: $length / 500',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOverLimit ? AppTheme.dangerRed : wc.textSecondary,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard(BuildContext context) {
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
              Icon(PhosphorIcons.chartLine(), color: AppTheme.accentBlue),
              const SizedBox(width: 12),
              Text(
                'Quick Stats',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Obx(() {
            final forecast = controller.currentForecast.value;
            if (forecast == null) return const SizedBox.shrink();
            
            // Calculate averages
            int totalMin = 0;
            int totalMax = 0;
            int totalHumidity = 0;
            int totalPrecip = 0;
            
            for (var day in forecast.dailyForecasts) {
              totalMin += day.minTemperature;
              totalMax += day.maxTemperature;
              totalHumidity += day.humidity;
              totalPrecip += day.precipitationChance;
            }
            
            final count = forecast.dailyForecasts.isNotEmpty ? forecast.dailyForecasts.length : 1;
            final avgMin = (totalMin / count).round();
            final avgMax = (totalMax / count).round();
            final avgHumidity = (totalHumidity / count).round();
            final avgPrecip = (totalPrecip / count).round();
            
            return Column(
              children: [
                _buildStatItem(
                  icon: PhosphorIcons.thermometer(),
                  label: 'Avg Temperature Range',
                  value: '$avgMin°C - $avgMax°C',
                  color: AppTheme.warningAmber,
                  context: context,
                ),
                const SizedBox(height: 16),
                _buildStatItem(
                  icon: PhosphorIcons.drop(),
                  label: 'Avg Humidity',
                  value: '$avgHumidity%',
                  color: AppTheme.accentBlue,
                  context: context,
                ),
                const SizedBox(height: 16),
                _buildStatItem(
                  icon: PhosphorIcons.cloudRain(),
                  label: 'Avg Precipitation Chance',
                  value: '$avgPrecip%',
                  color: AppTheme.infoCyan,
                  context: context,
                ),
                const SizedBox(height: 16),
                _buildStatItem(
                  icon: PhosphorIcons.warning(),
                  label: 'Active Warnings',
                  value: '${forecast.warnings.length}',
                  color: AppTheme.dangerRed,
                  context: context,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required BuildContext context,
  }) {
    final wc = context.wColors;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: wc.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build5DayOverviewCard(BuildContext context) {
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
              Icon(PhosphorIcons.calendarBlank(), color: AppTheme.accentBlue),
              const SizedBox(width: 12),
              Text(
                '5-Day Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Obx(() {
            final forecast = controller.currentForecast.value;
            if (forecast == null) return const SizedBox.shrink();
            
            return Row(
              children: forecast.dailyForecasts.asMap().entries.map((entry) {
                return Expanded(
                  child: _buildDayCard(entry.key, entry.value, context),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayCard(int index, dynamic day, BuildContext context) {
    final wc = context.wColors;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: wc.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: wc.borderSoft),
      ),
      child: Column(
        children: [
          Text(
            day.day,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: wc.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.formatDate(day.date),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: wc.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Icon(
            _getWeatherIcon(day.weatherCondition),
            size: 36,
            color: AppTheme.accentBlue,
          ),
          const SizedBox(height: 12),
          Text(
            day.weatherCondition,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: wc.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${day.minTemperature}° / ${day.maxTemperature}°',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: wc.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return PhosphorIcons.sun(PhosphorIconsStyle.fill);
      case 'partly cloudy':
        return PhosphorIcons.cloudSun(PhosphorIconsStyle.fill);
      case 'cloudy':
      case 'overcast':
        return PhosphorIcons.cloud(PhosphorIconsStyle.fill);
      case 'rain':
      case 'light rain':
      case 'heavy rain':
        return PhosphorIcons.cloudRain(PhosphorIconsStyle.fill);
      case 'thunderstorms':
        return PhosphorIcons.cloudLightning(PhosphorIconsStyle.fill);
      case 'fog':
      case 'mist':
        return PhosphorIcons.cloudFog(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.cloudSun(PhosphorIconsStyle.fill);
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import '../../controllers/five_day_forecast_controller.dart';
// import '../../theme/app_theme.dart';

// class OverviewTab extends GetView<FiveDayForecastController> {
//   const OverviewTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(32),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 flex: 2,
//                 child: Column(
//                   children: [
//                     _buildForecasterInfoCard(),
//                     const SizedBox(height: 24),
//                     _buildSummaryCard(),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 24),
//               Expanded(
//                 child: _buildQuickStatsCard(),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           _build5DayOverviewCard(),
//         ],
//       ),
//     );
//   }

//   Widget _buildForecasterInfoCard() {
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
//                 Icon(PhosphorIcons.user(), color: AppTheme.primaryColor),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Forecaster Information',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Obx(() => TextField(
//               decoration: InputDecoration(
//                 labelText: 'Forecaster Name',
//                 hintText: 'Enter your name',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 prefixIcon: Icon(PhosphorIcons.userCircle()),
//               ),
//               controller: TextEditingController(
//                 text: controller.currentForecast.value?.forecasterName ?? '',
//               ),
//               onChanged: (value) => controller.updateForecasterName(value),
//             )),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.blue[50],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   Icon(PhosphorIcons.info(), color: Colors.blue[700], size: 20),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'This name will appear on the generated forecast report',
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.blue[900],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryCard() {
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
//                 Icon(PhosphorIcons.notepad(), color: AppTheme.primaryColor),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Forecast Summary',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Obx(() => TextField(
//               maxLines: 8,
//               decoration: InputDecoration(
//                 hintText: 'Enter a general summary of the 5-day forecast outlook...\n\nExample: The next five days will feature mixed weather conditions across Ghana. Coastal areas can expect partly cloudy skies with occasional showers, particularly during afternoons. The northern regions will experience dry and hazy conditions with temperatures ranging from warm to hot.',
//                 hintStyle: TextStyle(color: Colors.grey[400]),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[50],
//               ),
//               controller: TextEditingController(
//                 text: controller.currentForecast.value?.summary ?? '',
//               ),
//               onChanged: (value) => controller.updateSummary(value),
//             )),
//             const SizedBox(height: 12),
//             Obx(() {
//               final length = controller.currentForecast.value?.summary.length ?? 0;
//               return Text(
//                 'Characters: $length / 500',
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: length > 500 ? Colors.red : Colors.grey[600],
//                 ),
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickStatsCard() {
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
//                 Icon(PhosphorIcons.chartLine(), color: AppTheme.primaryColor),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Quick Stats',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             Obx(() {
//               final forecast = controller.currentForecast.value;
//               if (forecast == null) return const SizedBox.shrink();
              
//               // Calculate averages
//               int totalMin = 0;
//               int totalMax = 0;
//               int totalHumidity = 0;
//               int totalPrecip = 0;
              
//               for (var day in forecast.dailyForecasts) {
//                 totalMin += day.minTemperature;
//                 totalMax += day.maxTemperature;
//                 totalHumidity += day.humidity;
//                 totalPrecip += day.precipitationChance;
//               }
              
//               final count = forecast.dailyForecasts.length;
//               final avgMin = (totalMin / count).round();
//               final avgMax = (totalMax / count).round();
//               final avgHumidity = (totalHumidity / count).round();
//               final avgPrecip = (totalPrecip / count).round();
              
//               return Column(
//                 children: [
//                   _buildStatItem(
//                     icon: PhosphorIcons.thermometer(),
//                     label: 'Avg Temperature Range',
//                     value: '$avgMin°C - $avgMax°C',
//                     color: Colors.orange,
//                   ),
//                   const SizedBox(height: 16),
//                   _buildStatItem(
//                     icon: PhosphorIcons.drop(),
//                     label: 'Avg Humidity',
//                     value: '$avgHumidity%',
//                     color: Colors.blue,
//                   ),
//                   const SizedBox(height: 16),
//                   _buildStatItem(
//                     icon: PhosphorIcons.cloudRain(),
//                     label: 'Avg Precipitation Chance',
//                     value: '$avgPrecip%',
//                     color: Colors.cyan,
//                   ),
//                   const SizedBox(height: 16),
//                   _buildStatItem(
//                     icon: PhosphorIcons.warning(),
//                     label: 'Active Warnings',
//                     value: '${forecast.warnings.length}',
//                     color: Colors.red,
//                   ),
//                 ],
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatItem({
//     required PhosphorIconData icon,
//     required String label,
//     required String value,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 28),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _build5DayOverviewCard() {
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
//                 Icon(PhosphorIcons.calendarBlank(), color: AppTheme.primaryColor),
//                 const SizedBox(width: 12),
//                 const Text(
//                   '5-Day Overview',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             Obx(() {
//               final forecast = controller.currentForecast.value;
//               if (forecast == null) return const SizedBox.shrink();
              
//               return Row(
//                 children: forecast.dailyForecasts.asMap().entries.map((entry) {
//                   return Expanded(
//                     child: _buildDayCard(entry.key, entry.value),
//                   );
//                 }).toList(),
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDayCard(int index, dynamic day) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 4),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: Column(
//         children: [
//           Text(
//             day.day,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             controller.formatDate(day.date),
//             style: TextStyle(
//               fontSize: 11,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 12),
//           Icon(
//             _getWeatherIcon(day.weatherCondition),
//             size: 32,
//             color: AppTheme.primaryColor,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             day.weatherCondition,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '${day.minTemperature}° / ${day.maxTemperature}°',
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   IconData _getWeatherIcon(String condition) {
//     switch (condition.toLowerCase()) {
//       case 'sunny':
//         return PhosphorIcons.sun();
//       case 'partly cloudy':
//         return PhosphorIcons.cloudSun();
//       case 'cloudy':
//       case 'overcast':
//         return PhosphorIcons.cloud();
//       case 'rain':
//       case 'light rain':
//       case 'heavy rain':
//         return PhosphorIcons.cloudRain();
//       case 'thunderstorms':
//         return PhosphorIcons.cloudLightning();
//       case 'fog':
//       case 'mist':
//         return PhosphorIcons.cloudFog();
//       default:
//         return PhosphorIcons.cloudSun();
//     }
//   }
// }