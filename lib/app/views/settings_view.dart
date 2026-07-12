import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import '../theme/app_theme.dart';

class SettingsController extends GetxController {
  // General Settings
  final enableNotifications = true.obs;
  final enableEmailAlerts = true.obs;
  final enableSMSAlerts = false.obs;
  final autoRefresh = true.obs;
  final darkMode = false.obs;
  
  // Forecast Settings
  final defaultUnit = 'Celsius'.obs;
  final windSpeedUnit = 'km/h'.obs;
  final pressureUnit = 'hPa'.obs;
  final forecastDays = 5.obs;
  
  // Alert Settings
  final alertThreshold = 'Medium'.obs;
  final alertSound = true.obs;
  final alertVibration = true.obs;
  
  // Data Settings
  final dataRetention = '90 days'.obs;
  final autoBackup = true.obs;
  final backupFrequency = 'Daily'.obs;
  
  void toggleNotifications(bool value) {
    enableNotifications.value = value;
    _showSavedSnackbar();
  }
  
  void toggleEmailAlerts(bool value) {
    enableEmailAlerts.value = value;
    _showSavedSnackbar();
  }
  
  void toggleSMSAlerts(bool value) {
    enableSMSAlerts.value = value;
    _showSavedSnackbar();
  }
  
  void toggleAutoRefresh(bool value) {
    autoRefresh.value = value;
    _showSavedSnackbar();
  }
  
  void toggleDarkMode(bool value) {
    darkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    _showSavedSnackbar();
  }
  
  void toggleAlertSound(bool value) {
    alertSound.value = value;
    _showSavedSnackbar();
  }
  
  void toggleAlertVibration(bool value) {
    alertVibration.value = value;
    _showSavedSnackbar();
  }
  
  void toggleAutoBackup(bool value) {
    autoBackup.value = value;
    _showSavedSnackbar();
  }
  
  void updateDefaultUnit(String value) {
    defaultUnit.value = value;
    _showSavedSnackbar();
  }
  
  void updateWindSpeedUnit(String value) {
    windSpeedUnit.value = value;
    _showSavedSnackbar();
  }
  
  void updatePressureUnit(String value) {
    pressureUnit.value = value;
    _showSavedSnackbar();
  }
  
  void updateForecastDays(int value) {
    forecastDays.value = value;
    _showSavedSnackbar();
  }
  
  void updateAlertThreshold(String value) {
    alertThreshold.value = value;
    _showSavedSnackbar();
  }
  
  void updateDataRetention(String value) {
    dataRetention.value = value;
    _showSavedSnackbar();
  }
  
  void updateBackupFrequency(String value) {
    backupFrequency.value = value;
    _showSavedSnackbar();
  }
  
  void resetSettings() {
    Get.defaultDialog(
      title: 'Reset Settings',
      titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      middleText: 'Are you sure you want to reset all settings to default?',
      middleTextStyle: const TextStyle(fontSize: 14),
      textConfirm: 'Reset',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      cancelTextColor: AppTheme.dangerRed,
      buttonColor: AppTheme.dangerRed,
      radius: 12,
      onConfirm: () {
        // Reset to defaults
        enableNotifications.value = true;
        enableEmailAlerts.value = true;
        enableSMSAlerts.value = false;
        autoRefresh.value = true;
        darkMode.value = false;
        Get.changeThemeMode(ThemeMode.light);
        defaultUnit.value = 'Celsius';
        windSpeedUnit.value = 'km/h';
        pressureUnit.value = 'hPa';
        forecastDays.value = 5;
        alertThreshold.value = 'Medium';
        alertSound.value = true;
        alertVibration.value = true;
        dataRetention.value = '90 days';
        autoBackup.value = true;
        backupFrequency.value = 'Daily';
        
        Get.back();
        Get.snackbar(
          'Settings Reset',
          'All settings have been reset to defaults',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppTheme.successGreen.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      },
    );
  }
  
  void _showSavedSnackbar() {
    Get.snackbar(
      'Saved',
      'Settings updated successfully',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppTheme.successGreen.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());
    final wc = context.wColors;
    
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
                    PhosphorIcons.gear(PhosphorIconsStyle.fill),
                    size: 24,
                    color: AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: wc.textPrimary,
                            fontWeight: FontWeight.w800,
                          ) ?? const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure your weather admin dashboard preferences',
                      style: TextStyle(
                        fontSize: 13,
                        color: wc.textMuted,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => controller.resetSettings(),
                  icon: Icon(PhosphorIcons.arrowCounterClockwise(), size: 18),
                  label: const Text('Reset to Defaults', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.dangerRed,
                    side: BorderSide(color: AppTheme.dangerRed.withOpacity(0.5), width: 1.5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // ── SETTINGS SECTIONS ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    children: [
                      _buildGeneralSettingsCard(controller, context),
                      const SizedBox(height: 24),
                      _buildForecastSettingsCard(controller, context),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column
                Expanded(
                  child: Column(
                    children: [
                      _buildAlertSettingsCard(controller, context),
                      const SizedBox(height: 24),
                      _buildDataSettingsCard(controller, context),
                      const SizedBox(height: 24),
                      _buildAccountCard(context),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── REUSABLE CARD DECORATION ──────────────────────────────────────────────
  BoxDecoration _cardDecoration(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;
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

  InputDecoration _inputDecoration(BuildContext context, {Widget? prefixIcon}) {
    final wc = context.wColors;
    return InputDecoration(
      filled: true,
      fillColor: wc.elevated,
      prefixIcon: prefixIcon,
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
    );
  }
  
  // ── SETTINGS CARDS ────────────────────────────────────────────────────────
  
  Widget _buildGeneralSettingsCard(SettingsController controller, BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIcons.sliders(), color: AppTheme.accentBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'General Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Obx(() => _buildSwitchTile(
            'Enable Notifications',
            'Receive push notifications for weather updates',
            controller.enableNotifications.value,
            (value) => controller.toggleNotifications(value),
            PhosphorIcons.bell(),
            context,
          )),
          Divider(height: 32, color: wc.borderSoft),
          
          Obx(() => _buildSwitchTile(
            'Email Alerts',
            'Receive weather alerts via email',
            controller.enableEmailAlerts.value,
            (value) => controller.toggleEmailAlerts(value),
            PhosphorIcons.envelope(),
            context,
          )),
          Divider(height: 32, color: wc.borderSoft),
          
          Obx(() => _buildSwitchTile(
            'SMS Alerts',
            'Receive critical alerts via SMS',
            controller.enableSMSAlerts.value,
            (value) => controller.toggleSMSAlerts(value),
            PhosphorIcons.chatCircle(),
            context,
          )),
          Divider(height: 32, color: wc.borderSoft),
          
          Obx(() => _buildSwitchTile(
            'Auto Refresh',
            'Automatically refresh weather data',
            controller.autoRefresh.value,
            (value) => controller.toggleAutoRefresh(value),
            PhosphorIcons.arrowsClockwise(),
            context,
          )),
          Divider(height: 32, color: wc.borderSoft),
          
          Obx(() => _buildSwitchTile(
            'Dark Mode',
            'Use dark theme for the dashboard',
            controller.darkMode.value,
            (value) => controller.toggleDarkMode(value),
            PhosphorIcons.moon(),
            context,
          )),
        ],
      ),
    );
  }
  
  Widget _buildForecastSettingsCard(SettingsController controller, BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.infoCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIcons.cloudSun(), color: AppTheme.infoCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Forecast Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Temperature Unit
          Text('Temperature Unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: wc.textSecondary)),
          const SizedBox(height: 8),
          Obx(() => DropdownButtonFormField<String>(
            value: controller.defaultUnit.value,
            dropdownColor: wc.elevated,
            style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
            decoration: _inputDecoration(context, prefixIcon: Icon(PhosphorIcons.thermometer(), color: wc.textMuted)),
            items: ['Celsius', 'Fahrenheit', 'Kelvin'].map((unit) {
              return DropdownMenuItem(value: unit, child: Text(unit));
            }).toList(),
            onChanged: (value) {
              if (value != null) controller.updateDefaultUnit(value);
            },
          )),
          
          const SizedBox(height: 20),
          
          // Wind Speed Unit
          Text('Wind Speed Unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: wc.textSecondary)),
          const SizedBox(height: 8),
          Obx(() => DropdownButtonFormField<String>(
            value: controller.windSpeedUnit.value,
            dropdownColor: wc.elevated,
            style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
            decoration: _inputDecoration(context, prefixIcon: Icon(PhosphorIcons.wind(), color: wc.textMuted)),
            items: ['km/h', 'mph', 'm/s', 'knots'].map((unit) {
              return DropdownMenuItem(value: unit, child: Text(unit));
            }).toList(),
            onChanged: (value) {
              if (value != null) controller.updateWindSpeedUnit(value);
            },
          )),
          
          const SizedBox(height: 20),
          
          // Pressure Unit
          Text('Pressure Unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: wc.textSecondary)),
          const SizedBox(height: 8),
          Obx(() => DropdownButtonFormField<String>(
            value: controller.pressureUnit.value,
            dropdownColor: wc.elevated,
            style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
            decoration: _inputDecoration(context, prefixIcon: Icon(PhosphorIcons.gauge(), color: wc.textMuted)),
            items: ['hPa', 'mbar', 'inHg', 'mmHg'].map((unit) {
              return DropdownMenuItem(value: unit, child: Text(unit));
            }).toList(),
            onChanged: (value) {
              if (value != null) controller.updatePressureUnit(value);
            },
          )),
          
          const SizedBox(height: 20),
          
          // Forecast Days
          Text('Default Forecast Days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: wc.textSecondary)),
          const SizedBox(height: 12),
          Obx(() => Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.accentBlue,
                  inactiveTrackColor: AppTheme.accentBlue.withOpacity(0.2),
                  thumbColor: AppTheme.accentBlue,
                  overlayColor: AppTheme.accentBlue.withOpacity(0.12),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: controller.forecastDays.value.toDouble(),
                  min: 1,
                  max: 14,
                  divisions: 13,
                  label: '${controller.forecastDays.value} days',
                  onChanged: (value) => controller.updateForecastDays(value.toInt()),
                ),
              ),
              Text(
                '${controller.forecastDays.value} days',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.accentBlue),
              ),
            ],
          )),
        ],
      ),
    );
  }
  
  Widget _buildAlertSettingsCard(SettingsController controller, BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIcons.warning(), color: AppTheme.warningAmber, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Alert Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Text('Alert Threshold', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: wc.textSecondary)),
          const SizedBox(height: 8),
          Obx(() => DropdownButtonFormField<String>(
            value: controller.alertThreshold.value,
            dropdownColor: wc.elevated,
            style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
            decoration: _inputDecoration(context, prefixIcon: Icon(PhosphorIcons.bellRinging(), color: wc.textMuted)),
            items: ['Low', 'Medium', 'High', 'Critical'].map((threshold) {
              return DropdownMenuItem(value: threshold, child: Text(threshold));
            }).toList(),
            onChanged: (value) {
              if (value != null) controller.updateAlertThreshold(value);
            },
          )),
          
          const SizedBox(height: 24),
          
          Obx(() => _buildSwitchTile(
            'Alert Sound',
            'Play sound for notifications',
            controller.alertSound.value,
            (value) => controller.toggleAlertSound(value),
            PhosphorIcons.speakerHigh(),
            context,
          )),
          Divider(height: 32, color: wc.borderSoft),
          
          Obx(() => _buildSwitchTile(
            'Alert Vibration',
            'Vibrate device for alerts',
            controller.alertVibration.value,
            (value) => controller.toggleAlertVibration(value),
            PhosphorIcons.vibrate(),
            context,
          )),
        ],
      ),
    );
  }
  
  Widget _buildDataSettingsCard(SettingsController controller, BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:   Icon(PhosphorIcons.database(), color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Data & Storage',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Text('Data Retention Period', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: wc.textSecondary)),
          const SizedBox(height: 8),
          Obx(() => DropdownButtonFormField<String>(
            value: controller.dataRetention.value,
            dropdownColor: wc.elevated,
            style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
            decoration: _inputDecoration(context, prefixIcon: Icon(PhosphorIcons.clockClockwise(), color: wc.textMuted)),
            items: ['30 days', '60 days', '90 days', '180 days', '1 year'].map((period) {
              return DropdownMenuItem(value: period, child: Text(period));
            }).toList(),
            onChanged: (value) {
              if (value != null) controller.updateDataRetention(value);
            },
          )),
          
          const SizedBox(height: 24),
          
          Obx(() => _buildSwitchTile(
            'Automatic Backup',
            'Automatically backup data',
            controller.autoBackup.value,
            (value) => controller.toggleAutoBackup(value),
            PhosphorIcons.cloudArrowUp(),
            context,
          )),
          
          Obx(() {
            if (!controller.autoBackup.value) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text('Backup Frequency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: wc.textSecondary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: controller.backupFrequency.value,
                  dropdownColor: wc.elevated,
                  style: TextStyle(color: wc.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
                  decoration: _inputDecoration(context, prefixIcon: Icon(PhosphorIcons.calendar(), color: wc.textMuted)),
                  items: ['Hourly', 'Daily', 'Weekly', 'Monthly'].map((freq) {
                    return DropdownMenuItem(value: freq, child: Text(freq));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) controller.updateBackupFrequency(value);
                  },
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildAccountCard(BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIcons.user(), color: AppTheme.successGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: wc.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildAccountButton('Change Password', 'Update your account password', PhosphorIcons.lockKey(), () {}, context),
          const SizedBox(height: 12),
          _buildAccountButton('Manage API Keys', 'View and manage API access', PhosphorIcons.key(), () {}, context),
          const SizedBox(height: 12),
          _buildAccountButton('Export Data', 'Download all your data', PhosphorIcons.downloadSimple(), () {}, context),
          
          const SizedBox(height: 24),
          Divider(height: 1, color: wc.borderSoft),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.defaultDialog(
                  title: 'Sign Out',
                  titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  middleText: 'Are you sure you want to sign out?',
                  textConfirm: 'Sign Out',
                  textCancel: 'Cancel',
                  confirmTextColor: Colors.white,
                  cancelTextColor: AppTheme.dangerRed,
                  buttonColor: AppTheme.dangerRed,
                  radius: 12,
                  onConfirm: () {
                    Get.back();
                    Get.snackbar(
                      'Signed Out',
                      'You have been signed out successfully',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppTheme.successGreen.withOpacity(0.9),
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                    );
                  },
                );
              },
              icon: Icon(PhosphorIcons.signOut(), size: 18),
              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ── HELPER WIDGETS ────────────────────────────────────────────────────────
  
  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged, IconData icon, BuildContext context) {
    final wc = context.wColors;
    return Row(
      children: [
        Icon(icon, size: 22, color: wc.textMuted),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: wc.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: wc.textMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: AppTheme.accentBlue,
          inactiveThumbColor: wc.textMuted,
          inactiveTrackColor: wc.borderSoft,
        ),
      ],
    );
  }
  
  Widget _buildAccountButton(String title, String subtitle, IconData icon, VoidCallback onTap, BuildContext context) {
    final wc = context.wColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: wc.elevated,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: wc.borderSoft),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.accentBlue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: wc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: wc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIcons.caretRight(),
                size: 16,
                color: wc.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// // lib/app/views/settings_view.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
// import '../theme/app_theme.dart';

// class SettingsController extends GetxController {
//   // General Settings
//   final enableNotifications = true.obs;
//   final enableEmailAlerts = true.obs;
//   final enableSMSAlerts = false.obs;
//   final autoRefresh = true.obs;
//   final darkMode = false.obs;
  
//   // Forecast Settings
//   final defaultUnit = 'Celsius'.obs;
//   final windSpeedUnit = 'km/h'.obs;
//   final pressureUnit = 'hPa'.obs;
//   final forecastDays = 5.obs;
  
//   // Alert Settings
//   final alertThreshold = 'Medium'.obs;
//   final alertSound = true.obs;
//   final alertVibration = true.obs;
  
//   // Data Settings
//   final dataRetention = '90 days'.obs;
//   final autoBackup = true.obs;
//   final backupFrequency = 'Daily'.obs;
  
//   void toggleNotifications(bool value) {
//     enableNotifications.value = value;
//     _showSavedSnackbar();
//   }
  
//   void toggleEmailAlerts(bool value) {
//     enableEmailAlerts.value = value;
//     _showSavedSnackbar();
//   }
  
//   void toggleSMSAlerts(bool value) {
//     enableSMSAlerts.value = value;
//     _showSavedSnackbar();
//   }
  
//   void toggleAutoRefresh(bool value) {
//     autoRefresh.value = value;
//     _showSavedSnackbar();
//   }
  
//   void toggleDarkMode(bool value) {
//     darkMode.value = value;
//     Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
//     _showSavedSnackbar();
//   }
  
//   void toggleAlertSound(bool value) {
//     alertSound.value = value;
//     _showSavedSnackbar();
//   }
  
//   void toggleAlertVibration(bool value) {
//     alertVibration.value = value;
//     _showSavedSnackbar();
//   }
  
//   void toggleAutoBackup(bool value) {
//     autoBackup.value = value;
//     _showSavedSnackbar();
//   }
  
//   void updateDefaultUnit(String value) {
//     defaultUnit.value = value;
//     _showSavedSnackbar();
//   }
  
//   void updateWindSpeedUnit(String value) {
//     windSpeedUnit.value = value;
//     _showSavedSnackbar();
//   }
  
//   void updatePressureUnit(String value) {
//     pressureUnit.value = value;
//     _showSavedSnackbar();
//   }
  
//   void updateForecastDays(int value) {
//     forecastDays.value = value;
//     _showSavedSnackbar();
//   }
  
//   void updateAlertThreshold(String value) {
//     alertThreshold.value = value;
//     _showSavedSnackbar();
//   }
  
//   void updateDataRetention(String value) {
//     dataRetention.value = value;
//     _showSavedSnackbar();
//   }
  
//   void updateBackupFrequency(String value) {
//     backupFrequency.value = value;
//     _showSavedSnackbar();
//   }
  
//   void resetSettings() {
//     Get.defaultDialog(
//       title: 'Reset Settings',
//       middleText: 'Are you sure you want to reset all settings to default?',
//       textConfirm: 'Reset',
//       textCancel: 'Cancel',
//       confirmTextColor: Colors.white,
//       buttonColor: AppTheme.dangerColor,
//       onConfirm: () {
//         // Reset to defaults
//         enableNotifications.value = true;
//         enableEmailAlerts.value = true;
//         enableSMSAlerts.value = false;
//         autoRefresh.value = true;
//         darkMode.value = false;
//         defaultUnit.value = 'Celsius';
//         windSpeedUnit.value = 'km/h';
//         pressureUnit.value = 'hPa';
//         forecastDays.value = 5;
//         alertThreshold.value = 'Medium';
//         alertSound.value = true;
//         alertVibration.value = true;
//         dataRetention.value = '90 days';
//         autoBackup.value = true;
//         backupFrequency.value = 'Daily';
        
//         Get.back();
//         Get.snackbar(
//           'Settings Reset',
//           'All settings have been reset to defaults',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: AppTheme.successColor,
//           colorText: Colors.white,
//         );
//       },
//     );
//   }
  
//   void _showSavedSnackbar() {
//     Get.snackbar(
//       'Saved',
//       'Settings updated successfully',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: AppTheme.successColor,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 1),
//     );
//   }
// }

// class SettingsView extends StatelessWidget {
//   const SettingsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(SettingsController());
    
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Row(
//               children: [
//                 Icon(
//                   PhosphorIcons.gear(PhosphorIconsStyle.bold),
//                   size: 32,
//                   color: AppTheme.primaryColor,
//                 ),
//                 const SizedBox(width: 16),
//                 const Text(
//                   'Settings',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Spacer(),
//                 OutlinedButton.icon(
//                   onPressed: () => controller.resetSettings(),
//                   icon: Icon(PhosphorIcons.arrowCounterClockwise()),
//                   label: const Text('Reset to Defaults'),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: AppTheme.dangerColor,
//                     side: BorderSide(color: AppTheme.dangerColor),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 16,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Configure your weather admin dashboard preferences',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
            
//             const SizedBox(height: 32),
            
//             // Settings Sections
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Left Column
//                 Expanded(
//                   child: Column(
//                     children: [
//                       _buildGeneralSettingsCard(controller),
//                       const SizedBox(height: 16),
//                       _buildForecastSettingsCard(controller),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 // Right Column
//                 Expanded(
//                   child: Column(
//                     children: [
//                       _buildAlertSettingsCard(controller),
//                       const SizedBox(height: 16),
//                       _buildDataSettingsCard(controller),
//                       const SizedBox(height: 16),
//                       _buildAccountCard(),
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
  
//   Widget _buildGeneralSettingsCard(SettingsController controller) {
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
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: AppTheme.primaryColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(
//                     PhosphorIcons.sliders(),
//                     color: AppTheme.primaryColor,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'General Settings',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
            
//             // Notifications
//             Obx(() => _buildSwitchTile(
//               'Enable Notifications',
//               'Receive push notifications for weather updates',
//               controller.enableNotifications.value,
//               (value) => controller.toggleNotifications(value),
//               PhosphorIcons.bell(),
//             )),
            
//             const Divider(height: 32),
            
//             // Email Alerts
//             Obx(() => _buildSwitchTile(
//               'Email Alerts',
//               'Receive weather alerts via email',
//               controller.enableEmailAlerts.value,
//               (value) => controller.toggleEmailAlerts(value),
//               PhosphorIcons.envelope(),
//             )),
            
//             const Divider(height: 32),
            
//             // SMS Alerts
//             Obx(() => _buildSwitchTile(
//               'SMS Alerts',
//               'Receive critical alerts via SMS',
//               controller.enableSMSAlerts.value,
//               (value) => controller.toggleSMSAlerts(value),
//               PhosphorIcons.chatCircle(),
//             )),
            
//             const Divider(height: 32),
            
//             // Auto Refresh
//             Obx(() => _buildSwitchTile(
//               'Auto Refresh',
//               'Automatically refresh weather data',
//               controller.autoRefresh.value,
//               (value) => controller.toggleAutoRefresh(value),
//               PhosphorIcons.arrowsClockwise(),
//             )),
            
//             const Divider(height: 32),
            
//             // Dark Mode
//             Obx(() => _buildSwitchTile(
//               'Dark Mode',
//               'Use dark theme for the dashboard',
//               controller.darkMode.value,
//               (value) => controller.toggleDarkMode(value),
//               PhosphorIcons.moon(),
//             )),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildForecastSettingsCard(SettingsController controller) {
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
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: AppTheme.infoColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(
//                     PhosphorIcons.cloudSun(),
//                     color: AppTheme.infoColor,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Forecast Settings',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
            
//             // Temperature Unit
//             const Text(
//               'Temperature Unit',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Obx(() => DropdownButtonFormField<String>(
//               value: controller.defaultUnit.value,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 prefixIcon: Icon(PhosphorIcons.thermometer()),
//               ),
//               items: ['Celsius', 'Fahrenheit', 'Kelvin'].map((unit) {
//                 return DropdownMenuItem(
//                   value: unit,
//                   child: Text(unit),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 if (value != null) {
//                   controller.updateDefaultUnit(value);
//                 }
//               },
//             )),
            
//             const SizedBox(height: 20),
            
//             // Wind Speed Unit
//             const Text(
//               'Wind Speed Unit',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Obx(() => DropdownButtonFormField<String>(
//               value: controller.windSpeedUnit.value,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 prefixIcon: Icon(PhosphorIcons.wind()),
//               ),
//               items: ['km/h', 'mph', 'm/s', 'knots'].map((unit) {
//                 return DropdownMenuItem(
//                   value: unit,
//                   child: Text(unit),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 if (value != null) {
//                   controller.updateWindSpeedUnit(value);
//                 }
//               },
//             )),
            
//             const SizedBox(height: 20),
            
//             // Pressure Unit
//             const Text(
//               'Pressure Unit',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Obx(() => DropdownButtonFormField<String>(
//               value: controller.pressureUnit.value,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 prefixIcon: Icon(PhosphorIcons.gauge()),
//               ),
//               items: ['hPa', 'mbar', 'inHg', 'mmHg'].map((unit) {
//                 return DropdownMenuItem(
//                   value: unit,
//                   child: Text(unit),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 if (value != null) {
//                   controller.updatePressureUnit(value);
//                 }
//               },
//             )),
            
//             const SizedBox(height: 20),
            
//             // Forecast Days
//             const Text(
//               'Default Forecast Days',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Obx(() => Column(
//               children: [
//                 Slider(
//                   value: controller.forecastDays.value.toDouble(),
//                   min: 1,
//                   max: 14,
//                   divisions: 13,
//                   label: '${controller.forecastDays.value} days',
//                   activeColor: AppTheme.primaryColor,
//                   onChanged: (value) {
//                     controller.updateForecastDays(value.toInt());
//                   },
//                 ),
//                 Text(
//                   '${controller.forecastDays.value} days',
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             )),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildAlertSettingsCard(SettingsController controller) {
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
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: AppTheme.warningColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(
//                     PhosphorIcons.warning(),
//                     color: AppTheme.warningColor,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Alert Settings',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
            
//             // Alert Threshold
//             const Text(
//               'Alert Threshold',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Obx(() => DropdownButtonFormField<String>(
//               value: controller.alertThreshold.value,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 prefixIcon: Icon(PhosphorIcons.bellRinging()),
//               ),
//               items: ['Low', 'Medium', 'High', 'Critical'].map((threshold) {
//                 return DropdownMenuItem(
//                   value: threshold,
//                   child: Text(threshold),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 if (value != null) {
//                   controller.updateAlertThreshold(value);
//                 }
//               },
//             )),
            
//             const SizedBox(height: 24),
            
//             // Alert Sound
//             Obx(() => _buildSwitchTile(
//               'Alert Sound',
//               'Play sound for notifications',
//               controller.alertSound.value,
//               (value) => controller.toggleAlertSound(value),
//               PhosphorIcons.speakerHigh(),
//             )),
            
//             const Divider(height: 32),
            
//             // Alert Vibration
//             Obx(() => _buildSwitchTile(
//               'Alert Vibration',
//               'Vibrate device for alerts',
//               controller.alertVibration.value,
//               (value) => controller.toggleAlertVibration(value),
//               PhosphorIcons.vibrate(),
//             )),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildDataSettingsCard(SettingsController controller) {
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
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: AppTheme.secondaryColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(
//                     PhosphorIcons.database(),
//                     color: AppTheme.secondaryColor,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Data & Storage',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
            
//             // Data Retention
//             const Text(
//               'Data Retention Period',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Obx(() => DropdownButtonFormField<String>(
//               value: controller.dataRetention.value,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 prefixIcon: Icon(PhosphorIcons.clockClockwise()),
//               ),
//               items: ['30 days', '60 days', '90 days', '180 days', '1 year']
//                   .map((period) {
//                 return DropdownMenuItem(
//                   value: period,
//                   child: Text(period),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 if (value != null) {
//                   controller.updateDataRetention(value);
//                 }
//               },
//             )),
            
//             const SizedBox(height: 24),
            
//             // Auto Backup
//             Obx(() => _buildSwitchTile(
//               'Automatic Backup',
//               'Automatically backup data',
//               controller.autoBackup.value,
//               (value) => controller.toggleAutoBackup(value),
//               PhosphorIcons.cloudArrowUp(),
//             )),
            
//             const SizedBox(height: 20),
            
//             // Backup Frequency
//             if (controller.autoBackup.value) ...[
//               const Text(
//                 'Backup Frequency',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Obx(() => DropdownButtonFormField<String>(
//                 value: controller.backupFrequency.value,
//                 decoration: InputDecoration(
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   prefixIcon: Icon(PhosphorIcons.calendar()),
//                 ),
//                 items: ['Hourly', 'Daily', 'Weekly', 'Monthly'].map((freq) {
//                   return DropdownMenuItem(
//                     value: freq,
//                     child: Text(freq),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   if (value != null) {
//                     controller.updateBackupFrequency(value);
//                   }
//                 },
//               )),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildAccountCard() {
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
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: AppTheme.successColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(
//                     PhosphorIcons.user(),
//                     color: AppTheme.successColor,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Account',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
            
//             _buildAccountButton(
//               'Change Password',
//               'Update your account password',
//               PhosphorIcons.lockKey(),
//               () {},
//             ),
            
//             const SizedBox(height: 12),
            
//             _buildAccountButton(
//               'Manage API Keys',
//               'View and manage API access',
//               PhosphorIcons.key(),
//               () {},
//             ),
            
//             const SizedBox(height: 12),
            
//             _buildAccountButton(
//               'Export Data',
//               'Download all your data',
//               PhosphorIcons.downloadSimple(),
//               () {},
//             ),
            
//             const SizedBox(height: 24),
//             const Divider(),
//             const SizedBox(height: 24),
            
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   Get.defaultDialog(
//                     title: 'Sign Out',
//                     middleText: 'Are you sure you want to sign out?',
//                     textConfirm: 'Sign Out',
//                     textCancel: 'Cancel',
//                     confirmTextColor: Colors.white,
//                     buttonColor: AppTheme.dangerColor,
//                     onConfirm: () {
//                       Get.back();
//                       Get.snackbar(
//                         'Signed Out',
//                         'You have been signed out successfully',
//                         snackPosition: SnackPosition.BOTTOM,
//                         backgroundColor: AppTheme.successColor,
//                         colorText: Colors.white,
//                       );
//                     },
//                   );
//                 },
//                 icon: Icon(PhosphorIcons.signOut()),
//                 label: const Text('Sign Out'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppTheme.dangerColor,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildSwitchTile(
//     String title,
//     String subtitle,
//     bool value,
//     Function(bool) onChanged,
//     IconData icon,
//   ) {
//     return Row(
//       children: [
//         Icon(icon, size: 20, color: Colors.grey[600]),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Switch(
//           value: value,
//           onChanged: onChanged,
//           activeColor: AppTheme.primaryColor,
//         ),
//       ],
//     );
//   }
  
//   Widget _buildAccountButton(
//     String title,
//     String subtitle,
//     IconData icon,
//     VoidCallback onTap,
//   ) {
//     return Material(
//       color: Colors.grey[50],
//       borderRadius: BorderRadius.circular(8),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(8),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Icon(icon, size: 20, color: AppTheme.primaryColor),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(
//                 PhosphorIcons.caretRight(),
//                 size: 16,
//                 color: Colors.grey[400],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }