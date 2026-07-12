// lib/app/views/forecast_view.dart
import 'package:flutter/material.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import '../theme/app_theme.dart';

class ForecastView extends StatelessWidget {
  const ForecastView({super.key});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
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
                Text(
                  'Manual Forecast Input',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: wc.textPrimary,
                      ) ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter weather forecast data manually or import from API',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: wc.textMuted,
                      ),
                ),
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField('Location', 'Enter city or region', context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField('Date', 'Select date', context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField('Temperature (°C)', 'e.g., 28', context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField('Humidity (%)', 'e.g., 75', context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField('Wind Speed (km/h)', 'e.g., 15', context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                _buildInputField('Weather Condition', 'e.g., Partly Cloudy', context),
                
                const SizedBox(height: 20),
                
                _buildInputField('Description', 'Detailed weather description', context, maxLines: 3),
                
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(PhosphorIcons.downloadSimple(), size: 18),
                        label: const Text(
                          'Import from API',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: wc.textPrimary,
                          side: BorderSide(color: wc.border, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(PhosphorIcons.floppyDisk(), size: 18),
                        label: const Text(
                          'Save Forecast',
                          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 4,
                          shadowColor: AppTheme.accentBlue.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String hint, BuildContext context, {int maxLines = 1}) {
    final wc = context.wColors;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: wc.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          style: TextStyle(
            color: wc.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: wc.textMuted, fontSize: 13),
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
            filled: true,
            fillColor: wc.elevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}