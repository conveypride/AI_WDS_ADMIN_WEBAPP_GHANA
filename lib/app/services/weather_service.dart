// lib/app/services/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _baseUrl =
      'https://api.met.no/weatherapi/locationforecast/2.0/compact';
  static const Duration _timeout = Duration(seconds: 15);
  static const Map<String, String> _headers = {
    'User-Agent': 'GhanaWeatherApp/1.0 (contact@example.com)',
    'Cache-Control': 'no-cache',
  };

  // Ghana Cities with coordinates
  static const List<Map<String, dynamic>> _ghanaCities = [
    {"name": "Accra", "region": "Greater Accra", "lat": 5.6037, "lon": -0.187},
    {"name": "Kumasi", "region": "Ashanti", "lat": 6.6666, "lon": -1.6163},
    {"name": "Tamale", "region": "Northern", "lat": 9.4075, "lon": -0.853},
    {"name": "Sekondi-Takoradi", "region": "Western", "lat": 4.9349, "lon": -1.7542},
    {"name": "Cape Coast", "region": "Central", "lat": 5.1054, "lon": -1.2466},
    {"name": "Ho", "region": "Volta", "lat": 6.6008, "lon": 0.4713},
    {"name": "Sunyani", "region": "Bono", "lat": 7.333, "lon": -2.333},
    {"name": "Bolgatanga", "region": "Upper East", "lat": 10.7856, "lon": -0.8514},
    {"name": "Wa", "region": "Upper West", "lat": 10.06, "lon": -2.5},
    {"name": "Koforidua", "region": "Eastern", "lat": 6.0904, "lon": -0.2608},
  ];

  Future<List<CityWeatherData>> fetchAllCitiesWeather() async {
    final futures = _ghanaCities.map((city) {
      return _fetchCityWeather(
        city['name'] as String,
        city['region'] as String,
        city['lat'] as double,
        city['lon'] as double,
      );
    }).toList();

    final results = await Future.wait(futures);
    return results.whereType<CityWeatherData>().toList();
  }

  Future<CityWeatherData?> _fetchCityWeather(
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
        final data = json.decode(response.body);
        return _parseCityWeatherData(data, name, region, lat, lon);
      }
    } catch (e) {
      print('Error fetching weather data for $name: $e');
    }
    return null;
  }

  CityWeatherData _parseCityWeatherData(
    Map<String, dynamic> json,
    String cityName,
    String region,
    double lat,
    double lon,
  ) {
    final timeseries = json['properties']['timeseries'] as List;
    if (timeseries.isEmpty) {
      throw Exception('No weather data available');
    }

    final currentData = timeseries[0]['data'];
    final instant = currentData['instant']['details'];
    final next1Hour = currentData['next_1_hours'];
    final symbolCode = next1Hour?['summary']['symbol_code'] ?? 'clearsky_day';

    return CityWeatherData(
      name: cityName,
      region: region,
      lat: lat,
      lon: lon,
      temperature: (instant['air_temperature'] ?? 0.0).toDouble(),
      condition: symbolCode.replaceAll('_', ' '),
      icon: symbolCode,
      windSpeed: instant['wind_speed']?.toDouble() ?? 0.0,
      humidity: instant['relative_humidity']?.toDouble() ?? 0.0,
      description: _getWeatherDescription(symbolCode),
    );
  }

  String _getWeatherDescription(String symbolCode) {
    switch (symbolCode) {
      case 'clearsky_day':
      case 'clearsky_night':
        return 'Clear sky';
      case 'fair_day':
      case 'fair_night':
        return 'Fair weather';
      case 'partlycloudy_day':
      case 'partlycloudy_night':
        return 'Partly cloudy';
      case 'cloudy':
        return 'Cloudy';
      case 'lightrain':
        return 'Light rain';
      case 'heavyrain':
        return 'Heavy rain';
      case 'thunderstorm':
        return 'Thunderstorm';
      case 'fog':
        return 'Foggy';
      default:
        return symbolCode.replaceAll('_', ' ');
    }
  }
}

class CityWeatherData {
  final String name;
  final String region;
  final double lat;
  final double lon;
  final double temperature;
  final String condition;
  final String icon;
  final double windSpeed;
  final double humidity;
  final String description;

  CityWeatherData({
    required this.name,
    required this.region,
    required this.lat,
    required this.lon,
    required this.temperature,
    required this.condition,
    required this.icon,
    required this.windSpeed,
    required this.humidity,
    required this.description,
  });


 factory CityWeatherData.fromJson(
    Map<String, dynamic> json,
    String cityName,
    String region,
    double lat,
    double lon,
  ) {
    final properties = json['properties'] as Map<String, dynamic>?;
    if (properties == null) throw Exception('Missing properties in response');

    final timeseries = properties['timeseries'] as List?;
    if (timeseries == null || timeseries.isEmpty) {
      throw Exception('No weather timeseries data available');
    }

    final currentData =
        timeseries[0]['data'] as Map<String, dynamic>? ?? {};
    final instant =
        (currentData['instant'] as Map<String, dynamic>?)?['details']
            as Map<String, dynamic>? ??
            {};

    // Try next_1_hours → next_6_hours → next_12_hours
    final hourly = currentData['next_1_hours'] as Map<String, dynamic>? ??
        currentData['next_6_hours'] as Map<String, dynamic>? ??
        currentData['next_12_hours'] as Map<String, dynamic>?;

    final symbolCode = (hourly?['summary'] as Map<String, dynamic>?)?[
            'symbol_code'] as String? ??
        'clearsky_day';

    return CityWeatherData(
      name: cityName,
      region: region,
      lat: lat,
      lon: lon,
      temperature:
          ((instant['air_temperature'] as num?) ?? 0.0).toDouble(),
      condition: symbolCode.replaceAll('_', ' '),
      icon: symbolCode,
      windSpeed:
          ((instant['wind_speed'] as num?) ?? 0.0).toDouble(),
      humidity:
          ((instant['relative_humidity'] as num?) ?? 0.0).toDouble(),
      description: _getWeatherDescription(symbolCode),
    );
  }

 static String _getWeatherDescription(String symbolCode) {
    const map = {
      'clearsky_day': 'Clear sky',
      'clearsky_night': 'Clear sky',
      'fair_day': 'Fair weather',
      'fair_night': 'Fair weather',
      'partlycloudy_day': 'Partly cloudy',
      'partlycloudy_night': 'Partly cloudy',
      'cloudy': 'Cloudy',
      'overcast': 'Overcast',
      'lightrain': 'Light rain',
      'heavyrain': 'Heavy rain',
      'thunderstorm': 'Thunderstorm',
      'heavyrainandthunder': 'Thunderstorm',
      'fog': 'Foggy',
      'snow': 'Snow',
    };
    return map[symbolCode] ?? symbolCode.replaceAll('_', ' ');
  }



}

