// lib/app/views/five_day_forecast_widgets/warnings_tab.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import '../../controllers/five_day_forecast_controller.dart';
import '../../theme/app_theme.dart';
import '../../model/five_day_forecast_model.dart';

class WarningsTab extends GetView<FiveDayForecastController> {
  const WarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER & ACTIONS ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warningAmber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.warningAmber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.warning(), color: AppTheme.warningAmber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add weather warnings and advisories for the 5-day forecast period',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warningAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddWarningDialog(context),
                icon: Icon(PhosphorIcons.plus(), size: 18),
                label: const Text(
                  'Add Warning',
                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningAmber,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppTheme.warningAmber.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── WARNINGS LIST ──────────────────────────────────────────────────
          Obx(() {
            final forecast = controller.currentForecast.value;
            if (forecast == null) return const SizedBox.shrink();
            
            if (forecast.warnings.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: wc.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: wc.border, style: BorderStyle.solid, width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(
                      PhosphorIcons.clipboardText(),
                      size: 64,
                      color: wc.textMuted.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No warnings added yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: wc.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click "Add Warning" to create a new weather warning',
                      style: TextStyle(
                        fontSize: 14,
                        color: wc.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              children: forecast.warnings.asMap().entries.map((entry) {
                final index = entry.key;
                final warning = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildWarningCard(index, warning, context),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWarningCard(int index, WeatherWarning warning, BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;
    final levelColor = _getWarningLevelColor(warning.level);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: wc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: levelColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.05),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: levelColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  warning.level.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                _getWarningIcon(warning.type),
                color: levelColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                warning.type,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: levelColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(PhosphorIcons.trash(), color: AppTheme.dangerRed.withOpacity(0.8)),
                onPressed: () => _confirmDelete(index, context),
                tooltip: 'Delete warning',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(PhosphorIcons.mapPin(), size: 16, color: wc.textMuted),
              const SizedBox(width: 8),
              Text(
                'Affected: ${warning.affectedRegions}',
                style: TextStyle(
                  fontSize: 14,
                  color: wc.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 24),
              Icon(PhosphorIcons.calendar(), size: 16, color: wc.textMuted),
              const SizedBox(width: 8),
              Text(
                '${controller.formatDate(warning.validFrom)} - ${controller.formatDate(warning.validTo)}',
                style: TextStyle(
                  fontSize: 14,
                  color: wc.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: wc.elevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: wc.borderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: wc.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  warning.description,
                  style: TextStyle(fontSize: 14, color: wc.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: levelColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.shieldWarning(),
                      size: 18,
                      color: levelColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Precautions:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: levelColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  warning.precautions,
                  style: TextStyle(
                    fontSize: 14,
                    color: wc.textPrimary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWarningDialog(BuildContext context) {
    final typeController = TextEditingController();
    final levelController = TextEditingController(text: 'Be Aware');
    final regionsController = TextEditingController();
    final descriptionController = TextEditingController();
    final precautionsController = TextEditingController();
    
    DateTime validFrom = DateTime.now();
    DateTime validTo = DateTime.now().add(const Duration(days: 1));

    final wc = context.wColors;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: wc.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: wc.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.warning(), color: AppTheme.accentBlue),
                    const SizedBox(width: 12),
                    Text(
                      'Add Weather Warning',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: wc.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(PhosphorIcons.x(), color: wc.textMuted),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Warning Type', wc),
                  dropdownColor: wc.elevated,
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                  items: controller.warningTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    typeController.text = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: 'Be Aware',
                  decoration: _inputDecoration('Warning Level', wc),
                  dropdownColor: wc.elevated,
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                  items: controller.warningLevels.map((level) {
                    return DropdownMenuItem(value: level, child: Text(level));
                  }).toList(),
                  onChanged: (value) {
                    levelController.text = value ?? 'Be Aware';
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: regionsController,
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration('Affected Regions', wc, hintText: 'e.g., Coastal Region, Forest Region'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration('Description', wc, hintText: 'Describe the weather warning...'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: precautionsController,
                  maxLines: 3,
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration('Precautions', wc, hintText: 'Recommended safety measures...'),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: wc.textPrimary,
                          side: BorderSide(color: wc.borderSoft, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (typeController.text.isEmpty ||
                              regionsController.text.isEmpty ||
                              descriptionController.text.isEmpty ||
                              precautionsController.text.isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Please fill in all fields',
                              backgroundColor: AppTheme.dangerRed.withOpacity(0.9),
                              colorText: Colors.white,
                              snackPosition: SnackPosition.TOP,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 10,
                            );
                            return;
                          }
                          
                          final warning = WeatherWarning(
                            type: typeController.text,
                            level: levelController.text,
                            affectedRegions: regionsController.text,
                            validFrom: validFrom,
                            validTo: validTo,
                            description: descriptionController.text,
                            precautions: precautionsController.text,
                          );
                          
                          controller.addWarning(warning);
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Add Warning', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(int index, BuildContext context) {
    final wc = context.wColors;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: wc.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: wc.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(PhosphorIcons.warningCircle(), color: AppTheme.dangerRed),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Warning',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this warning? This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: wc.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      foregroundColor: wc.textSecondary,
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      controller.removeWarning(index);
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPER METHODS ─────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String labelText, WColors wc, {String? hintText}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(color: wc.textSecondary),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: wc.borderSoft),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Color _getWarningLevelColor(String level) {
    switch (level) {
      case 'Low Risk':
        return AppTheme.successGreen;
      case 'Be Aware':
        return AppTheme.warningAmber;
      case 'Be Prepared':
        return Colors.orange; // Custom intermediate orange
      case 'Take Action':
        return AppTheme.dangerRed;
      default:
        return AppTheme.darkTextSecondary;
    }
  }

  IconData _getWarningIcon(String type) {
    switch (type) {
      case 'Heat Wave':
        return PhosphorIcons.thermometerHot();
      case 'Heavy Rain':
        return PhosphorIcons.cloudRain();
      case 'Thunderstorm':
        return PhosphorIcons.cloudLightning();
      case 'Strong Winds':
        return PhosphorIcons.wind();
      case 'Fog':
        return PhosphorIcons.cloudFog();
      case 'Dust Storm':
        return PhosphorIcons.tornado();
      case 'Flooding':
        return PhosphorIcons.waves();
      case 'Drought':
        return PhosphorIcons.dropSlash();
      default:
        return PhosphorIcons.warning();
    }
  }
}

// // lib/app/views/five_day_forecast_widgets/warnings_tab.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
// import '../../controllers/five_day_forecast_controller.dart';
// import '../../theme/app_theme.dart';
// import '../../model/five_day_forecast_model.dart';

// class WarningsTab extends GetView<FiveDayForecastController> {
//   const WarningsTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(32),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.orange[50],
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(PhosphorIcons.warning(), color: Colors.orange[700]),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           'Add weather warnings and advisories for the 5-day forecast period',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.orange[900],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               ElevatedButton.icon(
//                 onPressed: () => _showAddWarningDialog(context),
//                 icon: Icon(PhosphorIcons.plus()),
//                 label: const Text('Add Warning'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orange,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 24,
//                     vertical: 16,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           Obx(() {
//             final forecast = controller.currentForecast.value;
//             if (forecast == null) return const SizedBox.shrink();
            
//             if (forecast.warnings.isEmpty) {
//               return Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(48),
//                   child: Center(
//                     child: Column(
//                       children: [
//                         Icon(
//                           PhosphorIcons.clipboardText(),
//                           size: 64,
//                           color: Colors.grey[400],
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'No warnings added yet',
//                           style: TextStyle(
//                             fontSize: 18,
//                             color: Colors.grey[600],
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Click "Add Warning" to create a new weather warning',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[500],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             }
            
//             return Column(
//               children: forecast.warnings.asMap().entries.map((entry) {
//                 final index = entry.key;
//                 final warning = entry.value;
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 16),
//                   child: _buildWarningCard(index, warning),
//                 );
//               }).toList(),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildWarningCard(int index, WeatherWarning warning) {
//     final levelColor = _getWarningLevelColor(warning.level);
    
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: levelColor, width: 2),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: levelColor,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     warning.level.toUpperCase(),
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Icon(
//                   _getWarningIcon(warning.type),
//                   color: levelColor,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   warning.type,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: levelColor,
//                   ),
//                 ),
//                 const Spacer(),
//                 IconButton(
//                   icon: Icon(PhosphorIcons.trash(), color: Colors.red),
//                   onPressed: () => _confirmDelete(index),
//                   tooltip: 'Delete warning',
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Icon(PhosphorIcons.mapPin(), size: 16, color: Colors.grey[600]),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Affected: ${warning.affectedRegions}',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[700],
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(width: 24),
//                 Icon(PhosphorIcons.calendar(), size: 16, color: Colors.grey[600]),
//                 const SizedBox(width: 8),
//                 Text(
//                   '${controller.formatDate(warning.validFrom)} - ${controller.formatDate(warning.validTo)}',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Description:',
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     warning.description,
//                     style: const TextStyle(fontSize: 14),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: levelColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(
//                         PhosphorIcons.shieldWarning(),
//                         size: 16,
//                         color: levelColor,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Precautions:',
//                         style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.bold,
//                           color: levelColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     warning.precautions,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[800],
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

//   void _showAddWarningDialog(BuildContext context) {
//     final typeController = TextEditingController();
//     final levelController = TextEditingController(text: 'Be Aware');
//     final regionsController = TextEditingController();
//     final descriptionController = TextEditingController();
//     final precautionsController = TextEditingController();
    
//     DateTime validFrom = DateTime.now();
//     DateTime validTo = DateTime.now().add(const Duration(days: 1));

//     Get.dialog(
//       Dialog(
//         child: Container(
//           width: 600,
//           padding: const EdgeInsets.all(24),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(PhosphorIcons.warning(), color: AppTheme.primaryColor),
//                     const SizedBox(width: 12),
//                     const Text(
//                       'Add Weather Warning',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const Spacer(),
//                     IconButton(
//                       icon: Icon(PhosphorIcons.x()),
//                       onPressed: () => Get.back(),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 DropdownButtonFormField<String>(
//                   decoration: InputDecoration(
//                     labelText: 'Warning Type',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   items: controller.warningTypes.map((type) {
//                     return DropdownMenuItem(value: type, child: Text(type));
//                   }).toList(),
//                   onChanged: (value) {
//                     typeController.text = value ?? '';
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 DropdownButtonFormField<String>(
//                   value: 'Be Aware',
//                   decoration: InputDecoration(
//                     labelText: 'Warning Level',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   items: controller.warningLevels.map((level) {
//                     return DropdownMenuItem(value: level, child: Text(level));
//                   }).toList(),
//                   onChanged: (value) {
//                     levelController.text = value ?? 'Be Aware';
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: regionsController,
//                   decoration: InputDecoration(
//                     labelText: 'Affected Regions',
//                     hintText: 'e.g., Coastal Region, Forest Region',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: descriptionController,
//                   maxLines: 3,
//                   decoration: InputDecoration(
//                     labelText: 'Description',
//                     hintText: 'Describe the weather warning...',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: precautionsController,
//                   maxLines: 3,
//                   decoration: InputDecoration(
//                     labelText: 'Precautions',
//                     hintText: 'Recommended safety measures...',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () => Get.back(),
//                         child: const Text('Cancel'),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () {
//                           if (typeController.text.isEmpty ||
//                               regionsController.text.isEmpty ||
//                               descriptionController.text.isEmpty ||
//                               precautionsController.text.isEmpty) {
//                             Get.snackbar(
//                               'Error',
//                               'Please fill in all fields',
//                               backgroundColor: Colors.red,
//                               colorText: Colors.white,
//                             );
//                             return;
//                           }
                          
//                           final warning = WeatherWarning(
//                             type: typeController.text,
//                             level: levelController.text,
//                             affectedRegions: regionsController.text,
//                             validFrom: validFrom,
//                             validTo: validTo,
//                             description: descriptionController.text,
//                             precautions: precautionsController.text,
//                           );
                          
//                           controller.addWarning(warning);
//                           Get.back();
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppTheme.primaryColor,
//                         ),
//                         child: const Text('Add Warning'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _confirmDelete(int index) {
//     Get.dialog(
//       AlertDialog(
//         title: const Text('Delete Warning'),
//         content: const Text('Are you sure you want to delete this warning?'),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               controller.removeWarning(index);
//               Get.back();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//             ),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getWarningLevelColor(String level) {
//     switch (level) {
//       case 'Low Risk':
//         return Colors.green;
//       case 'Be Aware':
//         return Colors.yellow[700]!;
//       case 'Be Prepared':
//         return Colors.orange;
//       case 'Take Action':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getWarningIcon(String type) {
//     switch (type) {
//       case 'Heat Wave':
//         return PhosphorIcons.thermometerHot();
//       case 'Heavy Rain':
//         return PhosphorIcons.cloudRain();
//       case 'Thunderstorm':
//         return PhosphorIcons.cloudLightning();
//       case 'Strong Winds':
//         return PhosphorIcons.wind();
//       case 'Fog':
//         return PhosphorIcons.cloudFog();
//       case 'Dust Storm':
//         return PhosphorIcons.tornado();
//       case 'Flooding':
//         return PhosphorIcons.waves();
//       case 'Drought':
//         return PhosphorIcons.dropSlash();
//       default:
//         return PhosphorIcons.warning();
//     }
//   }
// }