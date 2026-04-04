// lib/app/model/cafo_forecast_model.dart
import 'package:latlong2/latlong.dart';

class CAFOForecast {
  String date;
  int itdPosition;
  String timeIssued;
  String validFrom;
  
  Map<String, CityForecast> morningForecasts;
  Map<String, CityForecast> afternoonForecasts;
  Map<String, CityForecast> eveningForecasts;
  
  List<MapRegion> eveningMapRegions;
  List<MapRegion> morningMapRegions;
  List<MapRegion> afternoonMapRegions;
  
  String weatherSummary;
  String notaBene;
  String caution;
  String warningType;
  
  Map<String, TemperatureRange> sectorTemperatures;
  
  CAFOForecast({
    required this.date,
    required this.itdPosition,
    this.timeIssued = '1100 UTC',
    this.validFrom = '1200 UTC',
    Map<String, CityForecast>? morningForecasts,
    Map<String, CityForecast>? afternoonForecasts,
    Map<String, CityForecast>? eveningForecasts,
    List<MapRegion>? eveningMapRegions,
    List<MapRegion>? morningMapRegions,
    List<MapRegion>? afternoonMapRegions,
    this.weatherSummary = '',
    this.notaBene = '',
    this.caution = '',
    this.warningType = 'Low Risk',
    Map<String, TemperatureRange>? sectorTemperatures,
  })  : morningForecasts = morningForecasts ?? <String, CityForecast>{},
        afternoonForecasts = afternoonForecasts ?? <String, CityForecast>{},
        eveningForecasts = eveningForecasts ?? <String, CityForecast>{},
        eveningMapRegions = eveningMapRegions ?? <MapRegion>[],
        morningMapRegions = morningMapRegions ?? <MapRegion>[],
        afternoonMapRegions = afternoonMapRegions ?? <MapRegion>[],
        sectorTemperatures = sectorTemperatures ?? <String, TemperatureRange>{
          'Coast': TemperatureRange(min: 25, max: 33),
          'Forest': TemperatureRange(min: 23, max: 35),
          'Transition': TemperatureRange(min: 18, max: 36),
          'Northern': TemperatureRange(min: 19, max: 37),
        };
  
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'itdPosition': itdPosition,
      'timeIssued': timeIssued,
      'validFrom': validFrom,
      'weatherSummary': weatherSummary,
      'notaBene': notaBene,
      'caution': caution,
      'warningType': warningType,
    };
  }
}

class CityForecast {
  String city;
  String weather;
  int minTemp;
  int maxTemp;
  String windDirection;
  String windSpeed;
  String chanceOfOccurrence;
  String humidity;
  
  CityForecast({
    required this.city,
    required this.weather,
    this.minTemp = 25,
    this.maxTemp = 30,
    this.windDirection = '12SW',
    this.windSpeed = '',
    this.chanceOfOccurrence = '50% - 60%',
    this.humidity = '70% - 80%',
  });
  
  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'weather': weather,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'windDirection': windDirection,
      'windSpeed': windSpeed,
      'chanceOfOccurrence': chanceOfOccurrence,
      'humidity': humidity,
    };
  }
}

class MapRegion {
  List<LatLng> points;
  String color;
  String riskLevel;
  List<String> weatherIcons;
  
  MapRegion({
    required this.points,
    required this.color,
    required this.riskLevel,
    List<String>? weatherIcons,
  }) : weatherIcons = weatherIcons ?? <String>[];
  
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'color': color,
      'riskLevel': riskLevel,
      'weatherIcons': weatherIcons,
    };
  }
}

class TemperatureRange {
  int min;
  int max;
  
  TemperatureRange({required this.min, required this.max});
  
  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }
}