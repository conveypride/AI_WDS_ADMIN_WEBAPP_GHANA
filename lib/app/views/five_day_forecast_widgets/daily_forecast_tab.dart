import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:weather_admin_dashboard/app/controllers/five_day_forecast_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart'; 

class DailyForecastTab extends GetView<FiveDayForecastController> {
  const DailyForecastTab({super.key});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // ── DAY SELECTOR ───────────────────────────────────────────────────
          Obx(() {
            final forecast = controller.currentForecast.value;
            if (forecast == null) return const SizedBox.shrink();
            
            return Container(
              padding: const EdgeInsets.all(16),
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
                children: forecast.dailyForecasts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;
                  final isSelected = controller.selectedDayIndex.value == index;
                  
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => controller.selectDay(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.accentBlue : wc.elevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentBlue : wc.borderSoft,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.accentBlue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Text(
                              day.day,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : wc.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.formatDate(day.date),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white.withOpacity(0.8) : wc.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 24),
          
          // ── DAILY FORECAST FORM ────────────────────────────────────────────
          Obx(() {
            final forecast = controller.currentForecast.value;
            if (forecast == null) return const SizedBox.shrink();
            
            final dayIndex = controller.selectedDayIndex.value;
            final day = forecast.dailyForecasts[dayIndex];
            
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildWeatherConditionsCard(dayIndex, day, context),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildTemperatureAndWindCard(dayIndex, day, context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildHumidityAndPrecipitationCard(dayIndex, day, context),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildAstronomyCard(dayIndex, day, context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildNotesCard(dayIndex, day, context),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── HELPER WIDGETS ─────────────────────────────────────────────────────────

  Widget _buildWeatherConditionsCard(int dayIndex, dynamic day, BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(wc, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Weather Conditions', PhosphorIcons.cloud(), context),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: day.weatherCondition,
            dropdownColor: wc.elevated,
            style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: _inputDecoration('Weather Condition', wc),
            icon: Icon(PhosphorIcons.caretDown(), color: wc.textSecondary, size: 16),
            items: controller.weatherConditions.map((condition) {
              return DropdownMenuItem(
                value: condition,
                child: Text(condition),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.updateDailyWeather(dayIndex, value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureAndWindCard(int dayIndex, dynamic day, BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(wc, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Temperature & Wind', PhosphorIcons.thermometer(), context),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w600),
                  decoration: _inputDecoration('Min Temp (°C)', wc),
                  controller: TextEditingController(
                    text: day.minTemperature.toString(),
                  ),
                  onChanged: (value) {
                    final temp = int.tryParse(value) ?? day.minTemperature;
                    controller.updateDailyTemperature(dayIndex, temp, day.maxTemperature);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w600),
                  decoration: _inputDecoration('Max Temp (°C)', wc),
                  controller: TextEditingController(
                    text: day.maxTemperature.toString(),
                  ),
                  onChanged: (value) {
                    final temp = int.tryParse(value) ?? day.maxTemperature;
                    controller.updateDailyTemperature(dayIndex, day.minTemperature, temp);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: day.windDirection,
                  dropdownColor: wc.elevated,
                  style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration('Wind Direction', wc),
                  icon: Icon(PhosphorIcons.caretDown(), color: wc.textSecondary, size: 16),
                  items: controller.windDirections.map((direction) {
                    return DropdownMenuItem(
                      value: direction,
                      child: Text(direction),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateDailyWind(dayIndex, value, day.windSpeed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration('Wind Speed', wc, hintText: 'e.g., 10-15 km/h'),
                  controller: TextEditingController(text: day.windSpeed),
                  onChanged: (value) {
                    controller.updateDailyWind(dayIndex, day.windDirection, value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityAndPrecipitationCard(int dayIndex, dynamic day, BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(wc, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Humidity & Precipitation', PhosphorIcons.drop(), context),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Humidity: ${day.humidity}%',
                      style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: _sliderThemeData(),
                      child: Slider(
                        value: day.humidity.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: '${day.humidity}%',
                        onChanged: (value) {
                          controller.updateDailyHumidity(dayIndex, value.toInt());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precipitation Chance: ${day.precipitationChance}%',
                      style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: _sliderThemeData(),
                      child: Slider(
                        value: day.precipitationChance.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: '${day.precipitationChance}%',
                        onChanged: (value) {
                          controller.updateDailyPrecipitation(dayIndex, value.toInt());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAstronomyCard(int dayIndex, dynamic day, BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(wc, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Astronomy', PhosphorIcons.moonStars(), context),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration('Sunrise', wc, hintText: 'e.g., 06:00', icon: PhosphorIcons.sunHorizon()),
                  controller: TextEditingController(text: day.sunrise),
                  onChanged: (value) {
                    controller.updateDailySunrise(dayIndex, value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration('Sunset', wc, hintText: 'e.g., 18:00', icon: PhosphorIcons.sunDim()),
                  controller: TextEditingController(text: day.sunset),
                  onChanged: (value) {
                    controller.updateDailySunset(dayIndex, value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: day.moonPhase,
            dropdownColor: wc.elevated,
            style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: _inputDecoration('Moon Phase', wc, icon: PhosphorIcons.moon()),
            icon: Icon(PhosphorIcons.caretDown(), color: wc.textSecondary, size: 16),
            items: controller.moonPhases.map((phase) {
              return DropdownMenuItem(
                value: phase,
                child: Text(phase),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.updateDailyMoonPhase(dayIndex, value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(int dayIndex, dynamic day, BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(wc, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Special Notes', PhosphorIcons.notepad(), context),
          const SizedBox(height: 20),
          TextField(
            maxLines: 4,
            style: TextStyle(color: wc.textPrimary, fontSize: 14, height: 1.5),
            decoration: _inputDecoration('Add any special notes or advisories for this day...', wc, isMultiline: true),
            controller: TextEditingController(text: day.specialNotes),
            onChanged: (value) {
              controller.updateDailyNotes(dayIndex, value);
            },
          ),
        ],
      ),
    );
  }

  // ── REUSABLE COMPONENT BUILDERS ────────────────────────────────────────────

  BoxDecoration _cardDecoration(WColors wc, bool isDark) {
    return BoxDecoration(
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
    );
  }

  Widget _buildCardHeader(String title, IconData icon, BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentBlue),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.wColors.textPrimary,
              ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String labelText, WColors wc, {String? hintText, IconData? icon, bool isMultiline = false}) {
    return InputDecoration(
      labelText: isMultiline ? null : labelText,
      hintText: isMultiline ? labelText : hintText,
      labelStyle: TextStyle(color: wc.textSecondary),
      hintStyle: TextStyle(color: wc.textMuted),
      prefixIcon: icon != null ? Icon(icon, color: wc.textMuted, size: 20) : null,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  SliderThemeData _sliderThemeData() {
    return SliderThemeData(
      activeTrackColor: AppTheme.accentBlue,
      inactiveTrackColor: AppTheme.accentBlue.withOpacity(0.2),
      thumbColor: AppTheme.accentBlue,
      overlayColor: AppTheme.accentBlue.withOpacity(0.12),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      valueIndicatorShape: const RectangularSliderValueIndicatorShape(),
      valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
// import 'package:weather_admin_dashboard/app/controllers/five_day_forecast_controller.dart';
// import 'package:weather_admin_dashboard/app/theme/app_theme.dart'; 

// class DailyForecastTab extends GetView<FiveDayForecastController> {
//   const DailyForecastTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(32),
//       child: Column(
//         children: [
//           // Day selector
//           Obx(() {
//             final forecast = controller.currentForecast.value;
//             if (forecast == null) return const SizedBox.shrink();
            
//             return Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: forecast.dailyForecasts.asMap().entries.map((entry) {
//                     final index = entry.key;
//                     final day = entry.value;
//                     final isSelected = controller.selectedDayIndex.value == index;
                    
//                     return Expanded(
//                       child: GestureDetector(
//                         onTap: () => controller.selectDay(index),
//                         child: Container(
//                           margin: const EdgeInsets.symmetric(horizontal: 4),
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Column(
//                             children: [
//                               Text(
//                                 day.day,
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.bold,
//                                   color: isSelected ? Colors.white : Colors.black,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 controller.formatDate(day.date),
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: isSelected ? Colors.white70 : Colors.grey[600],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             );
//           }),
//           const SizedBox(height: 24),
//           // Daily forecast form
//           Obx(() {
//             final forecast = controller.currentForecast.value;
//             if (forecast == null) return const SizedBox.shrink();
            
//             final dayIndex = controller.selectedDayIndex.value;
//             final day = forecast.dailyForecasts[dayIndex];
            
//             return Column(
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: _buildWeatherConditionsCard(dayIndex, day),
//                     ),
//                     const SizedBox(width: 24),
//                     Expanded(
//                       child: _buildTemperatureAndWindCard(dayIndex, day),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: _buildHumidityAndPrecipitationCard(dayIndex, day),
//                     ),
//                     const SizedBox(width: 24),
//                     Expanded(
//                       child: _buildAstronomyCard(dayIndex, day),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 _buildNotesCard(dayIndex, day),
//               ],
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildWeatherConditionsCard(int dayIndex, dynamic day) {
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
//                 Icon(PhosphorIcons.cloud(), color: AppTheme.primaryColor),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Weather Conditions',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             DropdownButtonFormField<String>(
//               value: day.weatherCondition,
//               decoration: InputDecoration(
//                 labelText: 'Weather Condition',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               items: controller.weatherConditions.map((condition) {
//                 return DropdownMenuItem(
//                   value: condition,
//                   child: Text(condition),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 if (value != null) {
//                   controller.updateDailyWeather(dayIndex, value);
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTemperatureAndWindCard(int dayIndex, dynamic day) {
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
//                 Icon(PhosphorIcons.thermometer(), color: AppTheme.primaryColor),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Temperature & Wind',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       labelText: 'Min Temp (°C)',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     controller: TextEditingController(
//                       text: day.minTemperature.toString(),
//                     ),
//                     onChanged: (value) {
//                       final temp = int.tryParse(value) ?? day.minTemperature;
//                       controller.updateDailyTemperature(dayIndex, temp, day.maxTemperature);
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: TextField(
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       labelText: 'Max Temp (°C)',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     controller: TextEditingController(
//                       text: day.maxTemperature.toString(),
//                     ),
//                     onChanged: (value) {
//                       final temp = int.tryParse(value) ?? day.maxTemperature;
//                       controller.updateDailyTemperature(dayIndex, day.minTemperature, temp);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     value: day.windDirection,
//                     decoration: InputDecoration(
//                       labelText: 'Wind Direction',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     items: controller.windDirections.map((direction) {
//                       return DropdownMenuItem(
//                         value: direction,
//                         child: Text(direction),
//                       );
//                     }).toList(),
//                     onChanged: (value) {
//                       if (value != null) {
//                         controller.updateDailyWind(dayIndex, value, day.windSpeed);
//                       }
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       labelText: 'Wind Speed',
//                       hintText: 'e.g., 10-15 km/h',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     controller: TextEditingController(text: day.windSpeed),
//                     onChanged: (value) {
//                       controller.updateDailyWind(dayIndex, day.windDirection, value);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHumidityAndPrecipitationCard(int dayIndex, dynamic day) {
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
//                 Icon(PhosphorIcons.drop(), color: AppTheme.primaryColor),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Humidity & Precipitation',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Humidity: ${day.humidity}%',
//                         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//                       ),
//                       const SizedBox(height: 8),
//                       Slider(
//                         value: day.humidity.toDouble(),
//                         min: 0,
//                         max: 100,
//                         divisions: 100,
//                         label: '${day.humidity}%',
//                         onChanged: (value) {
//                           controller.updateDailyHumidity(dayIndex, value.toInt());
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Precipitation Chance: ${day.precipitationChance}%',
//                         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//                       ),
//                       const SizedBox(height: 8),
//                       Slider(
//                         value: day.precipitationChance.toDouble(),
//                         min: 0,
//                         max: 100,
//                         divisions: 100,
//                         label: '${day.precipitationChance}%',
//                         onChanged: (value) {
//                           controller.updateDailyPrecipitation(dayIndex, value.toInt());
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAstronomyCard(int dayIndex, dynamic day) {
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
//                 Icon(PhosphorIcons.moonStars(), color: AppTheme.primaryColor),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Astronomy',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       labelText: 'Sunrise',
//                       hintText: 'e.g., 06:00',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       prefixIcon: Icon(PhosphorIcons.sunHorizon()),
//                     ),
//                     controller: TextEditingController(text: day.sunrise),
//                     onChanged: (value) {
//                       controller.updateDailySunrise(dayIndex, value);
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       labelText: 'Sunset',
//                       hintText: 'e.g., 18:00',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       prefixIcon: Icon(PhosphorIcons.sunDim()),
//                     ),
//                     controller: TextEditingController(text: day.sunset),
//                     onChanged: (value) {
//                       controller.updateDailySunset(dayIndex, value);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: day.moonPhase,
//               decoration: InputDecoration(
//                 labelText: 'Moon Phase',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 prefixIcon: Icon(PhosphorIcons.moon()),
//               ),
//               items: controller.moonPhases.map((phase) {
//                 return DropdownMenuItem(
//                   value: phase,
//                   child: Text(phase),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 if (value != null) {
//                   controller.updateDailyMoonPhase(dayIndex, value);
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNotesCard(int dayIndex, dynamic day) {
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
//                   'Special Notes',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               maxLines: 4,
//               decoration: InputDecoration(
//                 hintText: 'Add any special notes or advisories for this day...',
//                 hintStyle: TextStyle(color: Colors.grey[400]),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[50],
//               ),
//               controller: TextEditingController(text: day.specialNotes),
//               onChanged: (value) {
//                 controller.updateDailyNotes(dayIndex, value);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }