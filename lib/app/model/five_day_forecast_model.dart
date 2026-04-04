// lib/app/model/five_day_forecast_model.dart

class FiveDayForecast {
  final String id;
  final DateTime createdAt;
  final DateTime validFrom;
  final DateTime validTo;
  final String forecasterName;
  final String summary;
  final List<DailyForecast> dailyForecasts;
  final List<RegionForecast> regionForecasts;
  final List<WeatherWarning> warnings;
  final Map<String, dynamic> metadata;

  FiveDayForecast({
    String? id,
    DateTime? createdAt,
    required this.validFrom,
    required this.validTo,
    required this.forecasterName,
    this.summary = '',
    List<DailyForecast>? dailyForecasts,
    List<RegionForecast>? regionForecasts,
    List<WeatherWarning>? warnings,
    Map<String, dynamic>? metadata,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        dailyForecasts = dailyForecasts ?? List.generate(5, (index) {
          final date = DateTime.now().add(Duration(days: index));
          return DailyForecast(
            date: date,
            day: _getDayName(date.weekday),
          );
        }),
        regionForecasts = regionForecasts ?? [],
        warnings = warnings ?? [],
        metadata = metadata ?? {};

  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'forecasterName': forecasterName,
      'summary': summary,
      'dailyForecasts': dailyForecasts.map((f) => f.toJson()).toList(),
      'regionForecasts': regionForecasts.map((f) => f.toJson()).toList(),
      'warnings': warnings.map((w) => w.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory FiveDayForecast.fromJson(Map<String, dynamic> json) {
    return FiveDayForecast(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      validFrom: DateTime.parse(json['validFrom']),
      validTo: DateTime.parse(json['validTo']),
      forecasterName: json['forecasterName'],
      summary: json['summary'],
      dailyForecasts: (json['dailyForecasts'] as List)
          .map((f) => DailyForecast.fromJson(f))
          .toList(),
      regionForecasts: (json['regionForecasts'] as List)
          .map((f) => RegionForecast.fromJson(f))
          .toList(),
      warnings: (json['warnings'] as List)
          .map((w) => WeatherWarning.fromJson(w))
          .toList(),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

class DailyForecast {
  final DateTime date;
  final String day;
  String weatherCondition;
  int minTemperature;
  int maxTemperature;
  String windDirection;
  String windSpeed;
  int humidity;
  int precipitationChance;
  String sunrise;
  String sunset;
  String moonPhase;
  String specialNotes;

  DailyForecast({
    required this.date,
    required this.day,
    this.weatherCondition = 'Sunny',
    this.minTemperature = 24,
    this.maxTemperature = 32,
    this.windDirection = 'SW',
    this.windSpeed = '10-15 km/h',
    this.humidity = 65,
    this.precipitationChance = 20,
    this.sunrise = '06:00',
    this.sunset = '18:00',
    this.moonPhase = 'Waxing Crescent',
    this.specialNotes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'day': day,
      'weatherCondition': weatherCondition,
      'minTemperature': minTemperature,
      'maxTemperature': maxTemperature,
      'windDirection': windDirection,
      'windSpeed': windSpeed,
      'humidity': humidity,
      'precipitationChance': precipitationChance,
      'sunrise': sunrise,
      'sunset': sunset,
      'moonPhase': moonPhase,
      'specialNotes': specialNotes,
    };
  }

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: DateTime.parse(json['date']),
      day: json['day'],
      weatherCondition: json['weatherCondition'],
      minTemperature: json['minTemperature'],
      maxTemperature: json['maxTemperature'],
      windDirection: json['windDirection'],
      windSpeed: json['windSpeed'],
      humidity: json['humidity'],
      precipitationChance: json['precipitationChance'],
      sunrise: json['sunrise'],
      sunset: json['sunset'],
      moonPhase: json['moonPhase'],
      specialNotes: json['specialNotes'],
    );
  }
}

class RegionForecast {
  final String regionName;
  final String weatherPattern;
  final String temperatureRange;
  final String rainfallOutlook;
  final String windConditions;
  final String visibility;
  final List<String> alerts;

  RegionForecast({
    required this.regionName,
    this.weatherPattern = 'Partly Cloudy',
    this.temperatureRange = '25-32°C',
    this.rainfallOutlook = 'Isolated showers',
    this.windConditions = 'Light to moderate',
    this.visibility = 'Good',
    List<String>? alerts,
  }) : alerts = alerts ?? [];

  Map<String, dynamic> toJson() {
    return {
      'regionName': regionName,
      'weatherPattern': weatherPattern,
      'temperatureRange': temperatureRange,
      'rainfallOutlook': rainfallOutlook,
      'windConditions': windConditions,
      'visibility': visibility,
      'alerts': alerts,
    };
  }

  factory RegionForecast.fromJson(Map<String, dynamic> json) {
    return RegionForecast(
      regionName: json['regionName'],
      weatherPattern: json['weatherPattern'],
      temperatureRange: json['temperatureRange'],
      rainfallOutlook: json['rainfallOutlook'],
      windConditions: json['windConditions'],
      visibility: json['visibility'],
      alerts: List<String>.from(json['alerts']),
    );
  }
}

class WeatherWarning {
  final String type;
  final String level;
  final String affectedRegions;
  final DateTime validFrom;
  final DateTime validTo;
  final String description;
  final String precautions;

  WeatherWarning({
    required this.type,
    required this.level,
    required this.affectedRegions,
    required this.validFrom,
    required this.validTo,
    required this.description,
    required this.precautions,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'level': level,
      'affectedRegions': affectedRegions,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'description': description,
      'precautions': precautions,
    };
  }

  factory WeatherWarning.fromJson(Map<String, dynamic> json) {
    return WeatherWarning(
      type: json['type'],
      level: json['level'],
      affectedRegions: json['affectedRegions'],
      validFrom: DateTime.parse(json['validFrom']),
      validTo: DateTime.parse(json['validTo']),
      description: json['description'],
      precautions: json['precautions'],
    );
  }
}