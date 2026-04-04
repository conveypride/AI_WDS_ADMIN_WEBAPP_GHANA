// lib/app/controllers/five_day_forecast_controller.dart
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../model/five_day_forecast_model.dart';

class FiveDayForecastController extends GetxController {
  final currentForecast = Rx<FiveDayForecast?>(null);
  final selectedTab = 0.obs;
  final selectedDayIndex = 0.obs;
  
  // Weather options
  final weatherConditions = <String>[
    'Sunny',
    'Partly Cloudy',
    'Cloudy',
    'Overcast',
    'Light Rain',
    'Rain',
    'Heavy Rain',
    'Thunderstorms',
    'Scattered Showers',
    'Fog',
    'Mist',
    'Hazy',
    'Windy',
  ].obs;
  
  final windDirections = <String>[
    'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'Variable'
  ].obs;
  
  final moonPhases = <String>[
    'New Moon',
    'Waxing Crescent',
    'First Quarter',
    'Waxing Gibbous',
    'Full Moon',
    'Waning Gibbous',
    'Last Quarter',
    'Waning Crescent',
  ].obs;
  
  final regions = <String>[
    'Coastal Region',
    'Forest Region',
    'Transition Region',
    'Northern Region',
    'Upper East Region',
    'Upper West Region',
  ].obs;
  
  final warningTypes = <String>[
    'Heat Wave',
    'Heavy Rain',
    'Thunderstorm',
    'Strong Winds',
    'Fog',
    'Dust Storm',
    'Flooding',
    'Drought',
  ].obs;
  
  final warningLevels = <String>[
    'Low Risk',
    'Be Aware',
    'Be Prepared',
    'Take Action',
  ].obs;
  
  @override
  void onInit() {
    super.onInit();
    initializeForecast();
  }
  
  void initializeForecast() {
    final now = DateTime.now();
    final validFrom = DateTime(now.year, now.month, now.day);
    final validTo = validFrom.add(const Duration(days: 5));
    
    // Initialize region forecasts
    final regionForecasts = regions.map((region) {
      return RegionForecast(
        regionName: region,
        weatherPattern: 'Partly Cloudy',
        temperatureRange: '24-32°C',
        rainfallOutlook: 'Isolated showers possible',
        windConditions: 'Light to moderate SW winds',
        visibility: 'Good',
      );
    }).toList();
    
    currentForecast.value = FiveDayForecast(
      validFrom: validFrom,
      validTo: validTo,
      forecasterName: '',
      summary: '',
      regionForecasts: regionForecasts,
    );
  }
  
  void changeTab(int index) {
    selectedTab.value = index;
  }
  
  void selectDay(int index) {
    selectedDayIndex.value = index;
  }
  
  // Daily forecast updates
  void updateDailyWeather(int dayIndex, String condition) {
    if (currentForecast.value != null && dayIndex < currentForecast.value!.dailyForecasts.length) {
      currentForecast.value!.dailyForecasts[dayIndex].weatherCondition = condition;
      currentForecast.refresh();
    }
  }
  
  void updateDailyTemperature(int dayIndex, int min, int max) {
    if (currentForecast.value != null && dayIndex < currentForecast.value!.dailyForecasts.length) {
      currentForecast.value!.dailyForecasts[dayIndex].minTemperature = min;
      currentForecast.value!.dailyForecasts[dayIndex].maxTemperature = max;
      currentForecast.refresh();
    }
  }
  
  void updateDailyWind(int dayIndex, String direction, String speed) {
    if (currentForecast.value != null && dayIndex < currentForecast.value!.dailyForecasts.length) {
      currentForecast.value!.dailyForecasts[dayIndex].windDirection = direction;
      currentForecast.value!.dailyForecasts[dayIndex].windSpeed = speed;
      currentForecast.refresh();
    }
  }
  
  void updateDailyHumidity(int dayIndex, int humidity) {
    if (currentForecast.value != null && dayIndex < currentForecast.value!.dailyForecasts.length) {
      currentForecast.value!.dailyForecasts[dayIndex].humidity = humidity;
      currentForecast.refresh();
    }
  }
  
  void updateDailyPrecipitation(int dayIndex, int chance) {
    if (currentForecast.value != null && dayIndex < currentForecast.value!.dailyForecasts.length) {
      currentForecast.value!.dailyForecasts[dayIndex].precipitationChance = chance;
      currentForecast.refresh();
    }
  }
  
  void updateDailySunrise(int dayIndex, String time) {
    if (currentForecast.value != null && dayIndex < currentForecast.value!.dailyForecasts.length) {
      currentForecast.value!.dailyForecasts[dayIndex].sunrise = time;
      currentForecast.refresh();
    }
  }
  
  void updateDailySunset(int dayIndex, String time) {
    if (currentForecast.value != null && dayIndex < currentForecast.value!.dailyForecasts.length) {
      currentForecast.value!.dailyForecasts[dayIndex].sunset = time;
      currentForecast.refresh();
    }
  }
  
  void updateDailyMoonPhase(int dayIndex, String phase) {
    if (currentForecast.value != null && dayIndex < currentForecast.value!.dailyForecasts.length) {
      currentForecast.value!.dailyForecasts[dayIndex].moonPhase = phase;
      currentForecast.refresh();
    }
  }
  
  void updateDailyNotes(int dayIndex, String notes) {
    if (currentForecast.value != null && dayIndex < currentForecast.value!.dailyForecasts.length) {
      currentForecast.value!.dailyForecasts[dayIndex].specialNotes = notes;
      currentForecast.refresh();
    }
  }
  
  // Regional forecast updates
  void updateRegionWeatherPattern(String regionName, String pattern) {
    if (currentForecast.value != null) {
      final region = currentForecast.value!.regionForecasts
          .firstWhere((r) => r.regionName == regionName);
      final index = currentForecast.value!.regionForecasts.indexOf(region);
      
      currentForecast.value!.regionForecasts[index] = RegionForecast(
        regionName: region.regionName,
        weatherPattern: pattern,
        temperatureRange: region.temperatureRange,
        rainfallOutlook: region.rainfallOutlook,
        windConditions: region.windConditions,
        visibility: region.visibility,
        alerts: region.alerts,
      );
      currentForecast.refresh();
    }
  }
  
  void updateRegionTemperatureRange(String regionName, String range) {
    if (currentForecast.value != null) {
      final region = currentForecast.value!.regionForecasts
          .firstWhere((r) => r.regionName == regionName);
      final index = currentForecast.value!.regionForecasts.indexOf(region);
      
      currentForecast.value!.regionForecasts[index] = RegionForecast(
        regionName: region.regionName,
        weatherPattern: region.weatherPattern,
        temperatureRange: range,
        rainfallOutlook: region.rainfallOutlook,
        windConditions: region.windConditions,
        visibility: region.visibility,
        alerts: region.alerts,
      );
      currentForecast.refresh();
    }
  }
  
  void updateRegionRainfallOutlook(String regionName, String outlook) {
    if (currentForecast.value != null) {
      final region = currentForecast.value!.regionForecasts
          .firstWhere((r) => r.regionName == regionName);
      final index = currentForecast.value!.regionForecasts.indexOf(region);
      
      currentForecast.value!.regionForecasts[index] = RegionForecast(
        regionName: region.regionName,
        weatherPattern: region.weatherPattern,
        temperatureRange: region.temperatureRange,
        rainfallOutlook: outlook,
        windConditions: region.windConditions,
        visibility: region.visibility,
        alerts: region.alerts,
      );
      currentForecast.refresh();
    }
  }
  
  void updateRegionWindConditions(String regionName, String conditions) {
    if (currentForecast.value != null) {
      final region = currentForecast.value!.regionForecasts
          .firstWhere((r) => r.regionName == regionName);
      final index = currentForecast.value!.regionForecasts.indexOf(region);
      
      currentForecast.value!.regionForecasts[index] = RegionForecast(
        regionName: region.regionName,
        weatherPattern: region.weatherPattern,
        temperatureRange: region.temperatureRange,
        rainfallOutlook: region.rainfallOutlook,
        windConditions: conditions,
        visibility: region.visibility,
        alerts: region.alerts,
      );
      currentForecast.refresh();
    }
  }
  
  void updateRegionVisibility(String regionName, String visibility) {
    if (currentForecast.value != null) {
      final region = currentForecast.value!.regionForecasts
          .firstWhere((r) => r.regionName == regionName);
      final index = currentForecast.value!.regionForecasts.indexOf(region);
      
      currentForecast.value!.regionForecasts[index] = RegionForecast(
        regionName: region.regionName,
        weatherPattern: region.weatherPattern,
        temperatureRange: region.temperatureRange,
        rainfallOutlook: region.rainfallOutlook,
        windConditions: region.windConditions,
        visibility: visibility,
        alerts: region.alerts,
      );
      currentForecast.refresh();
    }
  }
  
  // Warning management
  void addWarning(WeatherWarning warning) {
    if (currentForecast.value != null) {
      currentForecast.value!.warnings.add(warning);
      currentForecast.refresh();
    }
  }
  
  void removeWarning(int index) {
    if (currentForecast.value != null && index < currentForecast.value!.warnings.length) {
      currentForecast.value!.warnings.removeAt(index);
      currentForecast.refresh();
    }
  }
  
  // Summary and metadata
  void updateSummary(String summary) {
    if (currentForecast.value != null) {
      currentForecast.value = FiveDayForecast(
        id: currentForecast.value!.id,
        createdAt: currentForecast.value!.createdAt,
        validFrom: currentForecast.value!.validFrom,
        validTo: currentForecast.value!.validTo,
        forecasterName: currentForecast.value!.forecasterName,
        summary: summary,
        dailyForecasts: currentForecast.value!.dailyForecasts,
        regionForecasts: currentForecast.value!.regionForecasts,
        warnings: currentForecast.value!.warnings,
        metadata: currentForecast.value!.metadata,
      );
    }
  }
  
  void updateForecasterName(String name) {
    if (currentForecast.value != null) {
      currentForecast.value = FiveDayForecast(
        id: currentForecast.value!.id,
        createdAt: currentForecast.value!.createdAt,
        validFrom: currentForecast.value!.validFrom,
        validTo: currentForecast.value!.validTo,
        forecasterName: name,
        summary: currentForecast.value!.summary,
        dailyForecasts: currentForecast.value!.dailyForecasts,
        regionForecasts: currentForecast.value!.regionForecasts,
        warnings: currentForecast.value!.warnings,
        metadata: currentForecast.value!.metadata,
      );
    }
  }
  
  // Save and generate
  Future<void> saveForecast() async {
    if (currentForecast.value == null) return;
    
    if (currentForecast.value!.forecasterName.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter forecaster name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    Get.snackbar(
      'Success',
      '5-Day Forecast saved successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
    );
  }
  
  void generatePDF() {
    Get.snackbar(
      'PDF Generation',
      'Generating 5-Day Forecast PDF...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.primaryColor,
      colorText: Get.theme.colorScheme.onPrimary,
    );
    // Will implement PDF generation service
  }
  
  String formatDate(DateTime date) {
    return DateFormat('EEE, MMM dd').format(date);
  }
  
  String formatDateFull(DateTime date) {
    return DateFormat('EEEE, MMMM dd, yyyy').format(date);
  }
}