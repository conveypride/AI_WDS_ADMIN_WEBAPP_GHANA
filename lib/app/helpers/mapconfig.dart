

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/weather_service.dart';

class WestAfricaConstants {
  static const double centerLat = 7.94;
  static const double centerLon = -1.02;
  static const double northBorder = 20.0;
  static const double southBorder = 4.0;
  static const double westBorder = -18.0;
  static const double eastBorder = 15.0;
}

class FastaConfig {
  static const String baseUri = "https://dev.fastaweather.com";
  static const String token = "YL0XfvchO2YXMMUAflZMUyFNhwGVSOEIYQGzMJYfx34";
}

class CRRFeature {
  final String type;
  final Geometry geometry;
  final CRRProperties properties;

  CRRFeature({
    required this.type,
    required this.geometry,
    required this.properties,
  });

  factory CRRFeature.fromJson(Map<String, dynamic> json) {
    try {
      return CRRFeature(
        type: json['type'] as String? ?? 'Feature',
        geometry: Geometry.fromJson(
          json['geometry'] as Map<String, dynamic>? ?? {},
        ),
        properties: CRRProperties.fromJson(
          json['properties'] as Map<String, dynamic>? ?? {},
        ),
      );
    } catch (_) {
      return CRRFeature(
        type: 'Feature',
        geometry: Geometry(type: 'Point', coordinates: []),
        properties: CRRProperties(objectType: '', rainRate: ''),
      );
    }
  }
}

class RDTFeature {
  final String type;
  final Geometry geometry;
  final RDTProperties properties;

  RDTFeature({
    required this.type,
    required this.geometry,
    required this.properties,
  });

  factory RDTFeature.fromJson(Map<String, dynamic> json) {
    try {
      return RDTFeature(
        type: json['type'] as String? ?? 'Feature',
        geometry: Geometry.fromJson(
          json['geometry'] as Map<String, dynamic>? ?? {},
        ),
        properties: RDTProperties.fromJson(
          json['properties'] as Map<String, dynamic>? ?? {},
        ),
      );
    } catch (_) {
      return RDTFeature(
        type: 'Feature',
        geometry: Geometry(type: 'Point', coordinates: []),
        properties: RDTProperties(objectType: ''),
      );
    }
  }
}

class Geometry {
  final String type;
  final dynamic coordinates;

  Geometry({required this.type, required this.coordinates});

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      type: json['type'] as String? ?? 'Point',
      coordinates: json['coordinates'],
    );
  }
}

class CRRProperties {
  final String objectType;
  final String? rainRate;
  final int? level;

  CRRProperties({required this.objectType, this.rainRate, this.level});

  factory CRRProperties.fromJson(Map<String, dynamic> json) {
    return CRRProperties(
      objectType: json['object_type'] as String? ?? '',
      rainRate: json['rain_rate'] as String?,
      level: json['level'] as int?,
    );
  }
}

class RDTProperties {
  final String objectType;
  final int? phaseLife;
  final String? phaseLifeValue;
  final int? severityIntensity;
  final String? severityIntensityValue;
  final int? level;

  RDTProperties({
    required this.objectType,
    this.phaseLife,
    this.phaseLifeValue,
    this.severityIntensity,
    this.severityIntensityValue,
    this.level,
  });

  factory RDTProperties.fromJson(Map<String, dynamic> json) {
    return RDTProperties(
      objectType: json['object_type'] as String? ?? '',
      phaseLife: json['phase_life'] as int?,
      phaseLifeValue: json['phase_life_value'] as String?,
      severityIntensity: json['severity_intensity'] as int?,
      severityIntensityValue: json['severity_intensity_value'] as String?,
      level: json['level'] as int?,
    );
  }
}


class WestAfricaCities {
  static const List<Map<String, dynamic>> cities = [
    {"name": "Accra", "region": "Greater Accra", "lat": 5.6037, "lon": -0.187},
    {"name": "Kumasi", "region": "Ashanti", "lat": 6.6666, "lon": -1.6163},
    {"name": "Tamale", "region": "Northern", "lat": 9.4075, "lon": -0.853},
    {
      "name": "Sekondi-Takoradi",
      "region": "Western",
      "lat": 4.9349,
      "lon": -1.7542,
    },
    {"name": "Lagos", "region": "Nigeria", "lat": 6.5244, "lon": 3.3792},
    {"name": "Abuja", "region": "Nigeria", "lat": 9.0765, "lon": 7.3986},
    {"name": "Dakar", "region": "Senegal", "lat": 14.6928, "lon": -17.4467},
    {"name": "Bamako", "region": "Mali", "lat": 12.6392, "lon": -8.0029},
    {"name": "Lomé", "region": "Togo", "lat": 6.1375, "lon": 1.2123},
    {"name": "Cotonou", "region": "Benin", "lat": 6.3703, "lon": 2.3912},
  ];
}


class CityWeatherService {
  static const String _baseUrl =
      'https://api.met.no/weatherapi/locationforecast/2.0/compact';
  static const Duration _timeout = Duration(seconds: 15);
  static const Map<String, String> _headers = {
    'User-Agent': 'WeatherAdminDashboard/1.0 (servicedesk@met.no)',
    'Cache-Control': 'no-cache',
  };

  static Future<CityWeatherData?> fetchCityWeatherData(
    String name,
    String region,
    double lat,
    double lon,
  ) async {
    try {
      final url = '$_baseUrl?lat=$lat&lon=$lon';
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return CityWeatherData.fromJson(data, name, region, lat, lon);
      }
    } catch (e) {
      debugPrint('Error fetching weather data for $name: $e');
    }
    return null;
  }
}

class WeatherIconUtils {
  static String getWeatherEmoji(String symbolCode) {
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour >= 18;

    switch (symbolCode.toLowerCase()) {
      case 'clearsky_day':
      case 'clearsky':
        return isNight ? '🌙' : '☀️';
      case 'clearsky_night':
        return '🌙';
      case 'fair_day':
      case 'fair':
        return isNight ? '☁️' : '🌤️';
      case 'fair_night':
        return '☁️';
      case 'partlycloudy_day':
      case 'partlycloudy':
        return isNight ? '☁️' : '⛅';
      case 'partlycloudy_night':
        return '☁️';
      case 'cloudy':
      case 'overcast':
        return '☁️';
      case 'lightrain':
      case 'rain':
        return '🌧️';
      case 'heavyrain':
        return '🌧️';
      case 'rainshowers_day':
      case 'rainshowers':
        return '🌦️';
      case 'rainshowers_night':
        return '🌧️';
      case 'thunderstorm':
      case 'heavyrainandthunder':
        return '⛈️';
      case 'fog':
      case 'mist':
        return '🌫️';
      case 'snow':
        return '❄️';
      default:
        return isNight ? '🌙' : '☀️';
    }
  }
}
