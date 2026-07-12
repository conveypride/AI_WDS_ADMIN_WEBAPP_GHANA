// lib/app/helpers/weather_icon_helper.dart
import 'package:flutter/material.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';

class WeatherIconHelper {
  static IconData getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'rain':
        return PhosphorIcons.cloudRain(PhosphorIconsStyle.fill);
      case 'wind':
        return PhosphorIcons.wind(PhosphorIconsStyle.fill);
      case 'cloud':
        return PhosphorIcons.cloud(PhosphorIconsStyle.fill);
      case 'sun':
        return PhosphorIcons.sun(PhosphorIconsStyle.fill);
      case 'storm':
        return PhosphorIcons.cloudLightning(PhosphorIconsStyle.fill);
      case 'fog':
        return PhosphorIcons.cloudFog(PhosphorIconsStyle.fill);
      case 'dust':
        return PhosphorIcons.wind(PhosphorIconsStyle.fill);
      case 'hail':
        return PhosphorIcons.cloudSnow(PhosphorIconsStyle.fill);
      case 'mist':
        return PhosphorIcons.cloudFog(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.question(PhosphorIconsStyle.fill);
    }
  }
}