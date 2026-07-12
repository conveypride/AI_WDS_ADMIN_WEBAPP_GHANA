// lib/app/views/five_day_forecast_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import '../controllers/five_day_forecast_controller.dart';
import '../theme/app_theme.dart';
import 'five_day_forecast_widgets/overview_tab.dart';
import 'five_day_forecast_widgets/daily_forecast_tab.dart';
import 'five_day_forecast_widgets/regional_forecast_tab.dart';
import 'five_day_forecast_widgets/warnings_tab.dart';

class FiveDayForecastView extends StatefulWidget {
  const FiveDayForecastView({super.key});

  @override
  State<FiveDayForecastView> createState() => _FiveDayForecastViewState();
}

class _FiveDayForecastViewState extends State<FiveDayForecastView> {
  late final FiveDayForecastController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<FiveDayForecastController>()) {
      Get.put(FiveDayForecastController());
    }
    controller = Get.find<FiveDayForecastController>();
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            decoration: BoxDecoration(
              color: wc.card,
              border: Border(bottom: BorderSide(color: wc.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), color: wc.textPrimary),
                      onPressed: () => Get.back(),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '5-Day Weather Forecast',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: wc.textPrimary,
                            fontWeight: FontWeight.w800,
                          ) ?? const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    
                    // Action Buttons
                    ElevatedButton.icon(
                      onPressed: () => controller.saveForecast(),
                      icon: Icon(PhosphorIcons.floppyDisk(), size: 18),
                      label: const Text(
                        'Save Forecast', 
                        style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => controller.generatePDF(),
                      icon: Icon(PhosphorIcons.filePdf(), size: 18),
                      label: const Text(
                        'Generate PDF', 
                        style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Forecast Period Info
                Obx(() {
                  final forecast = controller.currentForecast.value;
                  if (forecast == null) return const SizedBox.shrink();
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.calendar(), color: AppTheme.accentBlue, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Forecast Period: ${controller.formatDateFull(forecast.validFrom)} - ${controller.formatDateFull(forecast.validTo)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                
                // Tab Navigation
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(() => Row(
                    children: [
                      _buildTab('Overview', 0, context),
                      _buildTab('Daily Forecast', 1, context),
                      _buildTab('Regional Forecast', 2, context),
                      _buildTab('Warnings', 3, context),
                    ],
                  )),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Obx(() {
              switch (controller.selectedTab.value) {
                case 0:
                  return const OverviewTab();
                case 1:
                  return const DailyForecastTab();
                case 2:
                  return const RegionalForecastTab();
                case 3:
                  return const WarningsTab();
                default:
                  return const SizedBox.shrink();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index, BuildContext context) {
    final isSelected = controller.selectedTab.value == index;
    final wc = context.wColors;
    
    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.accentBlue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppTheme.accentBlue : wc.textMuted,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
// // lib/app/views/five_day_forecast_view.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
// import '../controllers/five_day_forecast_controller.dart';
// import '../theme/app_theme.dart';
// import 'five_day_forecast_widgets/overview_tab.dart';
// import 'five_day_forecast_widgets/daily_forecast_tab.dart';
// import 'five_day_forecast_widgets/regional_forecast_tab.dart';
// import 'five_day_forecast_widgets/warnings_tab.dart';

// class FiveDayForecastView extends StatefulWidget {
//   const FiveDayForecastView({super.key});

//   @override
//   State<FiveDayForecastView> createState() => _FiveDayForecastViewState();
// }

// class _FiveDayForecastViewState extends State<FiveDayForecastView> {
//   late final FiveDayForecastController controller;

//   @override
//   void initState() {
//     super.initState();
//     if (!Get.isRegistered<FiveDayForecastController>()) {
//       Get.put(FiveDayForecastController());
//     }
//     controller = Get.find<FiveDayForecastController>();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: Column(
//         children: [
//           // Header
//           Container(
//             padding: const EdgeInsets.all(32),
//             color: Colors.white,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     IconButton(
//                       icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
//                       onPressed: () => Get.back(),
//                     ),
//                     const SizedBox(width: 16),
//                     const Text(
//                       '5-Day Weather Forecast',
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const Spacer(),
//                     // Action Buttons
//                     ElevatedButton.icon(
//                       onPressed: () => controller.saveForecast(),
//                       icon: Icon(PhosphorIcons.floppyDisk()),
//                       label: const Text('Save Forecast'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 24,
//                           vertical: 16,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     ElevatedButton.icon(
//                       onPressed: () => controller.generatePDF(),
//                       icon: Icon(PhosphorIcons.filePdf()),
//                       label: const Text('Generate PDF'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppTheme.primaryColor,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 24,
//                           vertical: 16,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 // Forecast Period Info
//                 Obx(() {
//                   final forecast = controller.currentForecast.value;
//                   if (forecast == null) return const SizedBox.shrink();
                  
//                   return Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.blue[50],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(PhosphorIcons.calendar(), color: Colors.blue[700]),
//                         const SizedBox(width: 12),
//                         Text(
//                           'Forecast Period: ${controller.formatDateFull(forecast.validFrom)} - ${controller.formatDateFull(forecast.validTo)}',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.blue[900],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }),
//                 const SizedBox(height: 24),
//                 // Tab Navigation
//                 Obx(() => Row(
//                   children: [
//                     _buildTab('Overview', 0),
//                     _buildTab('Daily Forecast', 1),
//                     _buildTab('Regional Forecast', 2),
//                     _buildTab('Warnings', 3),
//                   ],
//                 )),
//               ],
//             ),
//           ),
//           // Content
//           Expanded(
//             child: Obx(() {
//               switch (controller.selectedTab.value) {
//                 case 0:
//                   return const OverviewTab();
//                 case 1:
//                   return const DailyForecastTab();
//                 case 2:
//                   return const RegionalForecastTab();
//                 case 3:
//                   return const WarningsTab();
//                 default:
//                   return Container();
//               }
//             }),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTab(String title, int index) {
//     final isSelected = controller.selectedTab.value == index;
//     return GestureDetector(
//       onTap: () => controller.changeTab(index),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(
//               color: isSelected ? AppTheme.primaryColor : Colors.transparent,
//               width: 3,
//             ),
//           ),
//         ),
//         child: Text(
//           title,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//             color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
//           ),
//         ),
//       ),
//     );
//   }
// }