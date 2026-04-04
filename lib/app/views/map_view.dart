// // lib/app/views/map_view.dart
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import '../theme/app_theme.dart';

// // ============================================================================
// // CONFIGURATION & CONSTANTS
// // ============================================================================

// class FastaConfig {
//   static const String baseUri = "https://dev.fastaweather.com";
//   static const String token = "YL0XfvchO2YXMMUAflZMUyFNhwGVSOEIYQGzMJYfx34";
// }

// class WestAfricaConstants {
//   static const double centerLat = 7.94;
//   static const double centerLon = -1.02;
//   static const double northBorder = 20.0;
//   static const double southBorder = 4.0;
//   static const double westBorder = -18.0;
//   static const double eastBorder = 15.0;
// }

// // ============================================================================
// // DATA MODELS
// // ============================================================================

// class ForecastFrame {
//   final String timeslot;
//   final int offset;
//   final String timeParam;

//   ForecastFrame({
//     required this.timeslot,
//     required this.offset,
//     required this.timeParam,
//   });

//   // ── FIX 1: All fields null-safe with fallbacks ──────────────────────────────
//   factory ForecastFrame.fromJson(Map<String, dynamic> json) {
//     // 'timeslot' may be keyed differently or null — try several keys
//     final rawTimeslot =
//         (json['timeslot'] ?? json['time'] ?? json['datetime'] ?? '')
//             .toString()
//             .trim();

//     // If we still have an empty string, use "now" as a sentinel
//     final timeslot =
//         rawTimeslot.isNotEmpty ? rawTimeslot : DateTime.now().toIso8601String();

//     DateTime date;
//     try {
//       date = DateTime.parse(timeslot);
//     } catch (_) {
//       date = DateTime.now();
//     }

//     final timeParam =
//         "${date.year}/"
//         "${date.month.toString().padLeft(2, '0')}/"
//         "${date.day.toString().padLeft(2, '0')}/"
//         "${date.hour.toString().padLeft(2, '0')}/"
//         "${date.minute.toString().padLeft(2, '0')}";

//     // 'offset' may be int, double, or null
//     final rawOffset = json['offset'];
//     final offset = rawOffset is int
//         ? rawOffset
//         : rawOffset is double
//             ? rawOffset.round()
//             : rawOffset is String
//                 ? int.tryParse(rawOffset) ?? 0
//                 : 0;

//     return ForecastFrame(
//       timeslot: timeslot,
//       offset: offset,
//       timeParam: timeParam,
//     );
//   }
// }

// class CachedFrame {
//   final List<Polygon> crrPolygons;
//   final List<Polygon> rdtPolygons;
//   final List<Polyline> rdtPolylines;
//   final DateTime timestamp;

//   CachedFrame({
//     required this.crrPolygons,
//     required this.rdtPolygons,
//     required this.rdtPolylines,
//     required this.timestamp,
//   });
// }

// class CRRFeature {
//   final String type;
//   final Geometry geometry;
//   final CRRProperties properties;

//   CRRFeature({
//     required this.type,
//     required this.geometry,
//     required this.properties,
//   });

//   factory CRRFeature.fromJson(Map<String, dynamic> json) {
//     try {
//       return CRRFeature(
//         type: json['type'] as String? ?? 'Feature',
//         geometry: Geometry.fromJson(
//           json['geometry'] as Map<String, dynamic>? ?? {},
//         ),
//         properties: CRRProperties.fromJson(
//           json['properties'] as Map<String, dynamic>? ?? {},
//         ),
//       );
//     } catch (_) {
//       return CRRFeature(
//         type: 'Feature',
//         geometry: Geometry(type: 'Point', coordinates: []),
//         properties: CRRProperties(objectType: '', rainRate: ''),
//       );
//     }
//   }
// }

// class RDTFeature {
//   final String type;
//   final Geometry geometry;
//   final RDTProperties properties;

//   RDTFeature({
//     required this.type,
//     required this.geometry,
//     required this.properties,
//   });

//   factory RDTFeature.fromJson(Map<String, dynamic> json) {
//     try {
//       return RDTFeature(
//         type: json['type'] as String? ?? 'Feature',
//         geometry: Geometry.fromJson(
//           json['geometry'] as Map<String, dynamic>? ?? {},
//         ),
//         properties: RDTProperties.fromJson(
//           json['properties'] as Map<String, dynamic>? ?? {},
//         ),
//       );
//     } catch (_) {
//       return RDTFeature(
//         type: 'Feature',
//         geometry: Geometry(type: 'Point', coordinates: []),
//         properties: RDTProperties(objectType: ''),
//       );
//     }
//   }
// }

// class Geometry {
//   final String type;
//   final dynamic coordinates;

//   Geometry({required this.type, required this.coordinates});

//   factory Geometry.fromJson(Map<String, dynamic> json) {
//     return Geometry(
//       type: json['type'] as String? ?? 'Point',
//       coordinates: json['coordinates'],
//     );
//   }
// }

// class CRRProperties {
//   final String objectType;
//   final String? rainRate;
//   final int? level;

//   CRRProperties({required this.objectType, this.rainRate, this.level});

//   factory CRRProperties.fromJson(Map<String, dynamic> json) {
//     return CRRProperties(
//       objectType: json['object_type'] as String? ?? '',
//       rainRate: json['rain_rate'] as String?,
//       level: json['level'] as int?,
//     );
//   }
// }

// class RDTProperties {
//   final String objectType;
//   final int? phaseLife;
//   final String? phaseLifeValue;
//   final int? severityIntensity;
//   final String? severityIntensityValue;
//   final int? level;

//   RDTProperties({
//     required this.objectType,
//     this.phaseLife,
//     this.phaseLifeValue,
//     this.severityIntensity,
//     this.severityIntensityValue,
//     this.level,
//   });

//   factory RDTProperties.fromJson(Map<String, dynamic> json) {
//     return RDTProperties(
//       objectType: json['object_type'] as String? ?? '',
//       phaseLife: json['phase_life'] as int?,
//       phaseLifeValue: json['phase_life_value'] as String?,
//       severityIntensity: json['severity_intensity'] as int?,
//       severityIntensityValue: json['severity_intensity_value'] as String?,
//       level: json['level'] as int?,
//     );
//   }
// }

// class CityWeatherData {
//   final String name;
//   final String region;
//   final double lat;
//   final double lon;
//   final double temperature;
//   final String condition;
//   final String icon;
//   final double windSpeed;
//   final double humidity;
//   final String description;

//   CityWeatherData({
//     required this.name,
//     required this.region,
//     required this.lat,
//     required this.lon,
//     required this.temperature,
//     required this.condition,
//     required this.icon,
//     required this.windSpeed,
//     required this.humidity,
//     required this.description,
//   });

//   // ── FIX 2: next_1_hours can be null — fall back to next_6_hours then next_12_hours ─
//   factory CityWeatherData.fromJson(
//     Map<String, dynamic> json,
//     String cityName,
//     String region,
//     double lat,
//     double lon,
//   ) {
//     final properties = json['properties'] as Map<String, dynamic>?;
//     if (properties == null) throw Exception('Missing properties in response');

//     final timeseries = properties['timeseries'] as List?;
//     if (timeseries == null || timeseries.isEmpty) {
//       throw Exception('No weather timeseries data available');
//     }

//     final currentData =
//         timeseries[0]['data'] as Map<String, dynamic>? ?? {};
//     final instant =
//         (currentData['instant'] as Map<String, dynamic>?)?['details']
//             as Map<String, dynamic>? ??
//             {};

//     // Try next_1_hours → next_6_hours → next_12_hours
//     final hourly = currentData['next_1_hours'] as Map<String, dynamic>? ??
//         currentData['next_6_hours'] as Map<String, dynamic>? ??
//         currentData['next_12_hours'] as Map<String, dynamic>?;

//     final symbolCode = (hourly?['summary'] as Map<String, dynamic>?)?[
//             'symbol_code'] as String? ??
//         'clearsky_day';

//     return CityWeatherData(
//       name: cityName,
//       region: region,
//       lat: lat,
//       lon: lon,
//       temperature:
//           ((instant['air_temperature'] as num?) ?? 0.0).toDouble(),
//       condition: symbolCode.replaceAll('_', ' '),
//       icon: symbolCode,
//       windSpeed:
//           ((instant['wind_speed'] as num?) ?? 0.0).toDouble(),
//       humidity:
//           ((instant['relative_humidity'] as num?) ?? 0.0).toDouble(),
//       description: _getWeatherDescription(symbolCode),
//     );
//   }

//   static String _getWeatherDescription(String symbolCode) {
//     const map = {
//       'clearsky_day': 'Clear sky',
//       'clearsky_night': 'Clear sky',
//       'fair_day': 'Fair weather',
//       'fair_night': 'Fair weather',
//       'partlycloudy_day': 'Partly cloudy',
//       'partlycloudy_night': 'Partly cloudy',
//       'cloudy': 'Cloudy',
//       'overcast': 'Overcast',
//       'lightrain': 'Light rain',
//       'heavyrain': 'Heavy rain',
//       'thunderstorm': 'Thunderstorm',
//       'heavyrainandthunder': 'Thunderstorm',
//       'fog': 'Foggy',
//       'snow': 'Snow',
//     };
//     return map[symbolCode] ?? symbolCode.replaceAll('_', ' ');
//   }
// }

// // ============================================================================
// // SERVICES
// // ============================================================================

// class CityWeatherService {
//   static const String _baseUrl =
//       'https://api.met.no/weatherapi/locationforecast/2.0/compact';
//   static const Duration _timeout = Duration(seconds: 15);
//   static const Map<String, String> _headers = {
//     'User-Agent': 'WeatherAdminDashboard/1.0 (servicedesk@met.no)',
//     'Cache-Control': 'no-cache',
//   };

//   static Future<CityWeatherData?> fetchCityWeatherData(
//     String name,
//     String region,
//     double lat,
//     double lon,
//   ) async {
//     try {
//       final url = '$_baseUrl?lat=$lat&lon=$lon';
//       final response = await http
//           .get(Uri.parse(url), headers: _headers)
//           .timeout(_timeout);

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body) as Map<String, dynamic>;
//         return CityWeatherData.fromJson(data, name, region, lat, lon);
//       }
//     } catch (e) {
//       debugPrint('Error fetching weather data for $name: $e');
//     }
//     return null;
//   }
// }

// class WeatherIconUtils {
//   static String getWeatherEmoji(String symbolCode) {
//     final hour = DateTime.now().hour;
//     final isNight = hour < 6 || hour >= 18;

//     switch (symbolCode.toLowerCase()) {
//       case 'clearsky_day':
//       case 'clearsky':
//         return isNight ? '🌙' : '☀️';
//       case 'clearsky_night':
//         return '🌙';
//       case 'fair_day':
//       case 'fair':
//         return isNight ? '☁️' : '🌤️';
//       case 'fair_night':
//         return '☁️';
//       case 'partlycloudy_day':
//       case 'partlycloudy':
//         return isNight ? '☁️' : '⛅';
//       case 'partlycloudy_night':
//         return '☁️';
//       case 'cloudy':
//       case 'overcast':
//         return '☁️';
//       case 'lightrain':
//       case 'rain':
//         return '🌧️';
//       case 'heavyrain':
//         return '🌧️';
//       case 'rainshowers_day':
//       case 'rainshowers':
//         return '🌦️';
//       case 'rainshowers_night':
//         return '🌧️';
//       case 'thunderstorm':
//       case 'heavyrainandthunder':
//         return '⛈️';
//       case 'fog':
//       case 'mist':
//         return '🌫️';
//       case 'snow':
//         return '❄️';
//       default:
//         return isNight ? '🌙' : '☀️';
//     }
//   }
// }

// class WestAfricaCities {
//   static const List<Map<String, dynamic>> cities = [
//     {"name": "Accra", "region": "Greater Accra", "lat": 5.6037, "lon": -0.187},
//     {"name": "Kumasi", "region": "Ashanti", "lat": 6.6666, "lon": -1.6163},
//     {"name": "Tamale", "region": "Northern", "lat": 9.4075, "lon": -0.853},
//     {
//       "name": "Sekondi-Takoradi",
//       "region": "Western",
//       "lat": 4.9349,
//       "lon": -1.7542,
//     },
//     {"name": "Lagos", "region": "Nigeria", "lat": 6.5244, "lon": 3.3792},
//     {"name": "Abuja", "region": "Nigeria", "lat": 9.0765, "lon": 7.3986},
//     {"name": "Dakar", "region": "Senegal", "lat": 14.6928, "lon": -17.4467},
//     {"name": "Bamako", "region": "Mali", "lat": 12.6392, "lon": -8.0029},
//     {"name": "Lomé", "region": "Togo", "lat": 6.1375, "lon": 1.2123},
//     {"name": "Cotonou", "region": "Benin", "lat": 6.3703, "lon": 2.3912},
//   ];
// }

// // ============================================================================
// // CONTROLLER
// // ============================================================================

// class MapViewController extends GetxController {
//   final MapController mapController = MapController();

//   final showCRR = false.obs;
//   final showRDT = false.obs;
//   final showWeatherIcons = false.obs;

//   final isMapReady = false.obs;
//   final isRefreshing = false.obs;
//   final isForecastLoading = false.obs;
//   final isLoadingCityWeather = false.obs;
//   final isLoadingWeather = false.obs;

//   final initialPosition =
//       LatLng(WestAfricaConstants.centerLat, WestAfricaConstants.centerLon);
//   final initialZoom = 6.5;

//   final crrPolygons = <Polygon>[].obs;
//   final rdtPolygons = <Polygon>[].obs;
//   final rdtPolylines = <Polyline>[].obs;
//   final cityWeatherData = <CityWeatherData>[].obs;

//   final List<CRRFeature> _crrData = [];
//   final List<RDTFeature> _rdtData = [];

//   final forecastFrames = <ForecastFrame>[].obs;
//   final currentFrameIndex = 0.obs;
//   final Map<int, CachedFrame> _frameCache = {};
//   static const int _maxCacheSize = 8;
//   static const int _prefetchWindow = 2;

//   final isPlaying = false.obs;
//   Timer? _playbackTimer;

//   final lastUpdated = ''.obs;
//   final loadedItemsCount = 0.obs;
//   final totalCoveragePoints = 0.obs;
//   final completedRequests = 0.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     _updateTimestamp();
//     Future.delayed(const Duration(milliseconds: 500), () {
//       isMapReady.value = true;
//     });
//   }

//   void _updateTimestamp() {
//     lastUpdated.value = DateFormat('HH:mm').format(DateTime.now());
//   }

//   // ============================================================================
//   // Toggle & Fetch
//   // ============================================================================

//   Future<void> toggleCRRRDT() async {
//     final newState = !(showCRR.value || showRDT.value);

//     showCRR.value = newState;
//     showRDT.value = newState;
//     showWeatherIcons.value = false;

//     crrPolygons.clear();
//     rdtPolygons.clear();
//     rdtPolylines.clear();
//     cityWeatherData.clear();
//     _crrData.clear();
//     _rdtData.clear();
//     _frameCache.clear();

//     if (newState) {
//       await _fetchForecastTimeline();
//     } else {
//       forecastFrames.clear();
//       currentFrameIndex.value = 0;
//       stopPlayback();
//     }
//   }

//   Future<void> toggleWeatherIcons() async {
//     final newState = !showWeatherIcons.value;

//     showWeatherIcons.value = newState;
//     showCRR.value = false;
//     showRDT.value = false;

//     crrPolygons.clear();
//     rdtPolygons.clear();
//     rdtPolylines.clear();
//     _crrData.clear();
//     _rdtData.clear();
//     forecastFrames.clear();
//     currentFrameIndex.value = 0;
//     _frameCache.clear();
//     stopPlayback();

//     if (newState) {
//       await _fetchCityWeatherData();
//     } else {
//       cityWeatherData.clear();
//     }
//   }

//   // ── FIX 3: Robust timeline fetch ──────────────────────────────────────────
//   Future<void> _fetchForecastTimeline() async {
//     isForecastLoading.value = true;

//     final point =
//         "${WestAfricaConstants.centerLon},${WestAfricaConstants.centerLat}";
//     final url =
//         "${FastaConfig.baseUri}/api/v1/quicklook/?point=$point&token=${FastaConfig.token}";

//     try {
//       final response = await http
//           .get(Uri.parse(url))
//           .timeout(const Duration(seconds: 15));

//       if (response.statusCode != 200) {
//         _showError('Server returned ${response.statusCode}');
//         return;
//       }

//       // ── Safely decode JSON ─────────────────────────────────────
//       dynamic decoded;
//       try {
//         decoded = json.decode(response.body);
//       } catch (e) {
//         _showError('Invalid JSON response from server');
//         return;
//       }

//       if (decoded == null || decoded is! Map<String, dynamic>) {
//         _showError('Unexpected response format');
//         return;
//       }

//       // ── Try both 'slots' and 'results' keys ────────────────────
//       final rawSlots =
//           decoded['slots'] ?? decoded['results'] ?? decoded['data'];

//       if (rawSlots == null || rawSlots is! List || rawSlots.isEmpty) {
//         _showError('No forecast frames found in response');
//         return;
//       }

//       // ── Parse each slot, skip any that throw ───────────────────
//       final frames = <ForecastFrame>[];
//       for (final slot in rawSlots) {
//         if (slot == null) continue;
//         try {
//           final frame = ForecastFrame.fromJson(
//             slot is Map<String, dynamic>
//                 ? slot
//                 : Map<String, dynamic>.from(slot as Map),
//           );
//           // Only add frame if timeslot is a valid date string
//           frames.add(frame);
//         } catch (e) {
//           debugPrint('Skipping malformed frame: $slot — $e');
//         }
//       }

//       if (frames.isEmpty) {
//         _showError('All forecast frames were malformed');
//         return;
//       }

//       forecastFrames.value = frames;

//       // Pick the frame whose offset is 0 (current), or default to middle
//       final nowIndex = frames.indexWhere((f) => f.offset == 0);
//       currentFrameIndex.value =
//           nowIndex >= 0 ? nowIndex : (frames.length ~/ 2);

//       await _fetchWeatherDataForFrame(currentFrameIndex.value);
//     } catch (e) {
//       _showError('Failed to fetch forecast timeline: $e');
//     } finally {
//       isForecastLoading.value = false;
//     }
//   }

//   Future<void> _fetchWeatherDataForFrame(int frameIndex) async {
//     if (frameIndex < 0 || frameIndex >= forecastFrames.length) return;

//     if (_frameCache.containsKey(frameIndex)) {
//       final cached = _frameCache[frameIndex]!;
//       crrPolygons.value = cached.crrPolygons;
//       rdtPolygons.value = cached.rdtPolygons;
//       rdtPolylines.value = cached.rdtPolylines;
//       return;
//     }

//     final frame = forecastFrames[frameIndex];
//     await _fetchWeatherData(frame.timeParam);

//     _cacheFrame(frameIndex);
//     _prefetchNearbyFrames(frameIndex);
//   }

//   void _cacheFrame(int frameIndex) {
//     _frameCache[frameIndex] = CachedFrame(
//       crrPolygons: List.from(crrPolygons),
//       rdtPolygons: List.from(rdtPolygons),
//       rdtPolylines: List.from(rdtPolylines),
//       timestamp: DateTime.now(),
//     );

//     if (_frameCache.length > _maxCacheSize) {
//       _frameCache.remove(_frameCache.keys.first);
//     }
//   }

//   Future<void> _prefetchNearbyFrames(int centerIndex) async {
//     final toPrefetch = <int>[];

//     for (int i = 1; i <= _prefetchWindow; i++) {
//       final next = centerIndex + i;
//       if (next < forecastFrames.length && !_frameCache.containsKey(next)) {
//         toPrefetch.add(next);
//       }
//       final prev = centerIndex - i;
//       if (prev >= 0 && !_frameCache.containsKey(prev)) {
//         toPrefetch.add(prev);
//       }
//     }

//     for (final idx in toPrefetch) {
//       try {
//         await _fetchWeatherDataSilently(forecastFrames[idx].timeParam, idx);
//       } catch (e) {
//         debugPrint('Prefetch error for frame $idx: $e');
//       }
//     }
//   }

//   Future<void> _fetchWeatherDataSilently(
//       String timeslot, int frameIndex) async {
//     final tempCRR = <CRRFeature>[];
//     final tempRDT = <RDTFeature>[];

//     final coveragePoints = _getCoveragePoints();
//     final futures = <Future>[];

//     for (final c in coveragePoints) {
//       final crrUrl =
//           "${FastaConfig.baseUri}/api/v1/crr/$timeslot/?token=${FastaConfig.token}&point=${c['point']}&radius=${c['radius']}&tolerance=0.003";
//       futures.add(_fetchCRRDataSilently(crrUrl, tempCRR));

//       final rdtUrl =
//           "${FastaConfig.baseUri}/api/v1/rdt/$timeslot/?token=${FastaConfig.token}&point=${c['point']}&radius=${c['radius']}&forecast=15,30,45,60&level=1";
//       futures.add(_fetchRDTDataSilently(rdtUrl, tempRDT));
//     }

//     await Future.wait(futures).timeout(const Duration(seconds: 30));

//     final crrPolys = <Polygon>[];
//     final rdtPolys = <Polygon>[];
//     final rdtLines = <Polyline>[];

//     for (final f in tempCRR) {
//       final p = _createPolygonFromCRRFeature(f);
//       if (p != null) crrPolys.add(p);
//     }
//     for (final f in tempRDT) {
//       if (f.geometry.type == 'Polygon') {
//         final p = _createPolygonFromRDTFeature(f);
//         if (p != null) rdtPolys.add(p);
//       } else if (f.geometry.type == 'LineString') {
//         final l = _createPolylineFromRDTFeature(f);
//         if (l != null) rdtLines.add(l);
//       }
//     }

//     _frameCache[frameIndex] = CachedFrame(
//       crrPolygons: crrPolys,
//       rdtPolygons: rdtPolys,
//       rdtPolylines: rdtLines,
//       timestamp: DateTime.now(),
//     );
//   }

//   Future<void> _fetchWeatherData([String? timeslot]) async {
//     if (!showCRR.value && !showRDT.value) return;

//     isLoadingWeather.value = true;
//     loadedItemsCount.value = 0;
//     completedRequests.value = 0;

//     try {
//       final timeParam = timeslot ?? "now";
//       final coveragePoints = _getCoveragePoints();
//       totalCoveragePoints.value = coveragePoints.length;

//       final futures = <Future>[];
//       for (int i = 0; i < coveragePoints.length; i++) {
//         final c = coveragePoints[i];
//         final crrUrl =
//             "${FastaConfig.baseUri}/api/v1/crr/$timeParam/?token=${FastaConfig.token}&point=${c['point']}&radius=${c['radius']}&tolerance=0.003";
//         futures.add(_fetchCRRDataWithProgress(crrUrl, i));

//         final rdtUrl =
//             "${FastaConfig.baseUri}/api/v1/rdt/$timeParam/?token=${FastaConfig.token}&point=${c['point']}&radius=${c['radius']}&forecast=15,30,45,60&level=1";
//         futures.add(_fetchRDTDataWithProgress(rdtUrl, i));
//       }

//       if (futures.isNotEmpty) {
//         await Future.wait(futures).timeout(const Duration(seconds: 60));
//         _updateTimestamp();
//       }

//       await _createPolygonsFromData();
//     } catch (e) {
//       _showError('Failed to fetch weather data: $e');
//     } finally {
//       isLoadingWeather.value = false;
//     }
//   }

//   List<Map<String, dynamic>> _getCoveragePoints() {
//     return [
//       {"point": "-1.0,5.6", "radius": 1000},
//       {"point": "-1.6,6.7", "radius": 1000},
//       {"point": "-2.5,8.1", "radius": 1000},
//       {"point": "-0.2,7.9", "radius": 1000},
//       {"point": "-1.7,5.2", "radius": 1000},
//       {"point": "3.4,6.5", "radius": 1000},
//       {"point": "7.5,9.1", "radius": 1000},
//       {"point": "4.0,7.5", "radius": 1000},
//       {"point": "7.4,11.8", "radius": 1000},
//       {"point": "-4.0,5.3", "radius": 1000},
//       {"point": "-5.3,7.7", "radius": 1000},
//       {"point": "-17.4,14.7", "radius": 300},
//       {"point": "-15.3,13.5", "radius": 250},
//       {"point": "-16.6,13.4", "radius": 200},
//       {"point": "-1.5,12.4", "radius": 1000},
//       {"point": "-4.3,11.2", "radius": 1000},
//       {"point": "1.2,6.2", "radius": 1000},
//       {"point": "2.4,6.5", "radius": 1000},
//       {"point": "2.3,9.3", "radius": 1000},
//       {"point": "-13.2,8.5", "radius": 1000},
//       {"point": "-10.8,6.3", "radius": 1000},
//       {"point": "-8.0,12.6", "radius": 1000},
//       {"point": "2.1,13.5", "radius": 1000},
//       {"point": "12.1,9.7", "radius": 1000},
//       {"point": "9.7,4.0", "radius": 1000},
//       {"point": "11.5,9.3", "radius": 1000},
//       {"point": "-3.0,10.0", "radius": 1000},
//       {"point": "4.0,10.0", "radius": 1000},
//       {"point": "-10.0,12.0", "radius": 1000},
//       {"point": "10.0,12.0", "radius": 1000},
//       {"point": "-5.0,7.0", "radius": 1000},
//     ];
//   }

//   Future<void> _fetchCRRDataSilently(
//       String url, List<CRRFeature> list) async {
//     try {
//       final response = await http
//           .get(Uri.parse(url))
//           .timeout(const Duration(seconds: 20));
//       if (response.statusCode == 200) {
//         _parseCRRResponse(response.body, list);
//       }
//     } catch (_) {}
//   }

//   Future<void> _fetchRDTDataSilently(
//       String url, List<RDTFeature> list) async {
//     try {
//       final response = await http
//           .get(Uri.parse(url))
//           .timeout(const Duration(seconds: 20));
//       if (response.statusCode == 200) {
//         _parseRDTResponse(response.body, list);
//       }
//     } catch (_) {}
//   }

//   Future<void> _fetchCRRDataWithProgress(String url, int idx) async {
//     try {
//       final response = await http
//           .get(Uri.parse(url))
//           .timeout(const Duration(seconds: 30));
//       if (response.statusCode == 200) {
//         final added = _parseCRRResponse(response.body, _crrData);
//         loadedItemsCount.value += added;
//       }
//     } catch (e) {
//       debugPrint('CRR fetch error $idx: $e');
//     } finally {
//       completedRequests.value++;
//     }
//   }

//   Future<void> _fetchRDTDataWithProgress(String url, int idx) async {
//     try {
//       final response = await http
//           .get(Uri.parse(url))
//           .timeout(const Duration(seconds: 30));
//       if (response.statusCode == 200) {
//         final added = _parseRDTResponse(response.body, _rdtData);
//         loadedItemsCount.value += added;
//       }
//     } catch (e) {
//       debugPrint('RDT fetch error $idx: $e');
//     } finally {
//       completedRequests.value++;
//     }
//   }

//   // ── FIX 4: Centralised safe parsers ──────────────────────────────────────
//   int _parseCRRResponse(String body, List<CRRFeature> list) {
//     try {
//       final data = json.decode(body);
//       if (data is! Map<String, dynamic>) return 0;
//       final features = data['features'];
//       if (features is! List) return 0;

//       final existing =
//           list.map((f) => f.geometry.coordinates.toString()).toSet();
//       final newItems = features
//           .whereType<Map>()
//           .map((f) {
//             try {
//               return CRRFeature.fromJson(Map<String, dynamic>.from(f));
//             } catch (_) {
//               return null;
//             }
//           })
//           .where((f) =>
//               f != null &&
//               (f.properties.rainRate?.isNotEmpty ?? false) &&
//               !existing.contains(f.geometry.coordinates.toString()))
//           .cast<CRRFeature>()
//           .toList();

//       list.addAll(newItems);
//       return newItems.length;
//     } catch (_) {
//       return 0;
//     }
//   }

//   int _parseRDTResponse(String body, List<RDTFeature> list) {
//     try {
//       final data = json.decode(body);
//       if (data is! Map<String, dynamic>) return 0;
//       final features = data['features'];
//       if (features is! List) return 0;

//       final existing =
//           list.map((f) => f.geometry.coordinates.toString()).toSet();
//       final newItems = features
//           .whereType<Map>()
//           .map((f) {
//             try {
//               return RDTFeature.fromJson(Map<String, dynamic>.from(f));
//             } catch (_) {
//               return null;
//             }
//           })
//           .where((f) =>
//               f != null &&
//               f.properties.objectType.isNotEmpty &&
//               !existing.contains(f.geometry.coordinates.toString()))
//           .cast<RDTFeature>()
//           .toList();

//       list.addAll(newItems);
//       return newItems.length;
//     } catch (_) {
//       return 0;
//     }
//   }

//   Future<void> _createPolygonsFromData() async {
//     final crrPolys = <Polygon>[];
//     final rdtPolys = <Polygon>[];
//     final rdtLines = <Polyline>[];

//     for (int i = 0; i < _crrData.length && i < 500; i++) {
//       final p = _createPolygonFromCRRFeature(_crrData[i]);
//       if (p != null) crrPolys.add(p);
//     }
//     for (int i = 0; i < _rdtData.length && i < 500; i++) {
//       final f = _rdtData[i];
//       if (f.geometry.type == 'Polygon') {
//         final p = _createPolygonFromRDTFeature(f);
//         if (p != null) rdtPolys.add(p);
//       } else if (f.geometry.type == 'LineString') {
//         final l = _createPolylineFromRDTFeature(f);
//         if (l != null) rdtLines.add(l);
//       }
//     }

//     crrPolygons.value = crrPolys;
//     rdtPolygons.value = rdtPolys;
//     rdtPolylines.value = rdtLines;
//   }

//   Polygon? _createPolygonFromCRRFeature(CRRFeature feature) {
//     if (feature.geometry.type != 'Polygon' ||
//         feature.geometry.coordinates == null) return null;
//     try {
//       final coordinates = feature.geometry.coordinates as List;
//       if (coordinates.isEmpty) return null;
//       final ring = coordinates[0] as List;
//       if (ring.length < 3) return null;
//       final points = _parseCoordinates(ring);
//       if (points.length < 3) return null;
//       final color = _getCRRColor(feature.properties.rainRate ?? '');
//       final opacity = _getCRROpacity(feature.properties.rainRate ?? '');
//       return Polygon(
//         points: points,
//         color: color.withOpacity(opacity),
//         borderColor: color.withOpacity(min(opacity + 0.3, 1.0)),
//         borderStrokeWidth: 1.0,
//       );
//     } catch (e) {
//       debugPrint('CRR polygon error: $e');
//       return null;
//     }
//   }

//   Polygon? _createPolygonFromRDTFeature(RDTFeature feature) {
//     if (feature.geometry.type != 'Polygon' ||
//         feature.geometry.coordinates == null) return null;
//     try {
//       final coordinates = feature.geometry.coordinates as List;
//       if (coordinates.isEmpty) return null;
//       final ring = coordinates[0] as List;
//       if (ring.length < 3) return null;
//       final points = _parseCoordinates(ring);
//       if (points.length < 3) return null;
//       final color = _getRDTColor(feature.properties.phaseLife);
//       return Polygon(
//         points: points,
//         color: color.withOpacity(0.6),
//         borderColor: color.withOpacity(0.8),
//         borderStrokeWidth: 2.0,
//       );
//     } catch (e) {
//       debugPrint('RDT polygon error: $e');
//       return null;
//     }
//   }

//   Polyline? _createPolylineFromRDTFeature(RDTFeature feature) {
//     if (feature.geometry.type != 'LineString' ||
//         feature.geometry.coordinates == null) return null;
//     try {
//       final points =
//           _parseCoordinates(feature.geometry.coordinates as List);
//       if (points.length < 2) return null;
//       return Polyline(
//         points: points,
//         color: Colors.red.withOpacity(0.8),
//         strokeWidth: 3.0,
//       );
//     } catch (e) {
//       debugPrint('RDT polyline error: $e');
//       return null;
//     }
//   }

//   List<LatLng> _parseCoordinates(List coordinates) {
//     final points = <LatLng>[];
//     for (final coord in coordinates) {
//       if (coord is! List || coord.length < 2) continue;
//       try {
//         final lon = (coord[0] as num).toDouble();
//         final lat = (coord[1] as num).toDouble();
//         if (lat.abs() <= 90 && lon.abs() <= 180) {
//           points.add(LatLng(lat, lon));
//         }
//       } catch (_) {}
//     }
//     return points;
//   }

//   Color _getCRRColor(String rate) {
//     const map = {
//       'CRR_02_1': Color(0xFF87CEEB),
//       'CRR_1_2': Color(0xFF4169E1),
//       'CRR_2_3': Color(0xFF00CED1),
//       'CRR_3_5': Color(0xFF32CD32),
//       'CRR_5_7': Color(0xFF228B22),
//       'CRR_7_10': Color(0xFF9ACD32),
//       'CRR_10_15': Color(0xFFFFD700),
//       'CRR_15_20': Color(0xFFFFA500),
//       'CRR_20_30': Color(0xFFFF6347),
//       'CRR_30_50': Color(0xFFFF0000),
//       'CRR_50_plus': Color(0xFF8B0000),
//     };
//     return map[rate] ?? const Color(0xFF808080);
//   }

//   double _getCRROpacity(String rate) {
//     const map = {
//       'CRR_02_1': 0.4,
//       'CRR_1_2': 0.5,
//       'CRR_2_3': 0.6,
//       'CRR_3_5': 0.7,
//       'CRR_5_7': 0.75,
//       'CRR_7_10': 0.8,
//       'CRR_10_15': 0.85,
//       'CRR_15_20': 0.9,
//       'CRR_20_30': 0.95,
//       'CRR_30_50': 1.0,
//       'CRR_50_plus': 1.0,
//     };
//     return map[rate] ?? 0.4;
//   }

//   Color _getRDTColor(int? phaseLife) {
//     if (phaseLife == null) return Colors.grey.withOpacity(0.5);
//     if (phaseLife <= 1) return const Color(0xFF808080);
//     if (phaseLife == 2) return const Color(0xFF32CD32);
//     if (phaseLife == 3) return const Color(0xFFFFFF00);
//     return const Color(0xFFFF4500);
//   }

//   // ============================================================================
//   // City Weather
//   // ============================================================================

//   Future<void> _fetchCityWeatherData() async {
//     if (!showWeatherIcons.value) return;
//     isLoadingCityWeather.value = true;

//     try {
//       final futures = WestAfricaCities.cities
//           .map((c) => CityWeatherService.fetchCityWeatherData(
//                 c['name'] as String,
//                 c['region'] as String,
//                 (c['lat'] as num).toDouble(),
//                 (c['lon'] as num).toDouble(),
//               ))
//           .toList();

//       final results = await Future.wait(futures);
//       cityWeatherData.value =
//           results.whereType<CityWeatherData>().toList();
//       _updateTimestamp();
//     } catch (e) {
//       _showError('Failed to fetch city weather: $e');
//     } finally {
//       isLoadingCityWeather.value = false;
//     }
//   }

//   // ============================================================================
//   // Playback
//   // ============================================================================

//   void startPlayback() {
//     if (isPlaying.value) return;
//     isPlaying.value = true;

//     _playbackTimer =
//         Timer.periodic(const Duration(seconds: 1), (timer) async {
//       if (!isPlaying.value) {
//         timer.cancel();
//         return;
//       }
//       if (currentFrameIndex.value < forecastFrames.length - 1) {
//         final next = currentFrameIndex.value + 1;
//         currentFrameIndex.value = next;
//         await _fetchWeatherDataForFrame(next);
//       } else {
//         stopPlayback();
//       }
//     });
//   }

//   void stopPlayback() {
//     _playbackTimer?.cancel();
//     _playbackTimer = null;
//     isPlaying.value = false;
//   }

//   void resetPlayback() {
//     stopPlayback();
//     currentFrameIndex.value = 0;
//     _fetchWeatherDataForFrame(0);
//   }

//   Future<void> onFrameChanged(double value) async {
//     final idx = value.round();
//     if (idx != currentFrameIndex.value) {
//       currentFrameIndex.value = idx;
//       await _fetchWeatherDataForFrame(idx);
//     }
//   }

//   // ============================================================================
//   // Refresh
//   // ============================================================================

//   Future<void> refreshData() async {
//     isRefreshing.value = true;

//     crrPolygons.clear();
//     rdtPolygons.clear();
//     rdtPolylines.clear();
//     cityWeatherData.clear();
//     _crrData.clear();
//     _rdtData.clear();

//     final futures = <Future>[];

//     if (showCRR.value || showRDT.value) {
//       futures.add(
//         forecastFrames.isNotEmpty
//             ? _fetchWeatherDataForFrame(currentFrameIndex.value)
//             : _fetchWeatherData(),
//       );
//     }

//     if (showWeatherIcons.value) {
//       futures.add(_fetchCityWeatherData());
//     }

//     if (futures.isNotEmpty) await Future.wait(futures);

//     isRefreshing.value = false;

//     Get.snackbar(
//       'Data Refreshed',
//       'Map data updated successfully',
//       snackPosition: SnackPosition.BOTTOM,
//       duration: const Duration(seconds: 2),
//       backgroundColor: AppTheme.successColor,
//       colorText: Colors.white,
//       icon: Icon(PhosphorIcons.check(), color: Colors.white),
//     );
//   }

//   // ============================================================================
//   // Utilities
//   // ============================================================================

//   void _showError(String message) {
//     debugPrint('[MapView] $message');
//     Get.snackbar(
//       'Error',
//       message,
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 4),
//     );
//   }

//   String formatTime(String timeslot) {
//     try {
//       final dt = DateTime.parse(timeslot);
//       return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
//     } catch (_) {
//       return '--:--';
//     }
//   }

//   String getOffsetLabel(int offset) {
//     if (offset < 0) return "${offset ~/ 60}h";
//     if (offset == 0) return "Now";
//     return "+${offset ~/ 60}h";
//   }

//   @override
//   void onClose() {
//     mapController.dispose();
//     _playbackTimer?.cancel();
//     super.onClose();
//   }
// }

// // ============================================================================
// // VIEW  (standalone full-page — used by the /map route)
// // ============================================================================

// class MapView extends GetView<MapViewController> {
//   const MapView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     Get.put(MapViewController());

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: Column(
//         children: [
//           _buildHeader(context),
//           _buildControls(context),
//           Expanded(child: _buildMap(context)),
//           Obx(() =>
//               controller.forecastFrames.isNotEmpty &&
//                       (controller.showCRR.value || controller.showRDT.value)
//                   ? _buildForecastTimeline(context)
//                   : const SizedBox.shrink()),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         border: Border(
//             bottom: BorderSide(color: Theme.of(context).dividerColor)),
//       ),
//       child: Row(
//         children: [
//           Icon(PhosphorIcons.mapTrifold(PhosphorIconsStyle.bold),
//               size: 28, color: AppTheme.primaryColor),
//           const SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('West Africa Weather Map',
//                   style:
//                       TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//               Obx(() => Text(
//                     'Last updated: ${controller.lastUpdated.value}',
//                     style:
//                         TextStyle(fontSize: 12, color: Colors.grey[600]),
//                   )),
//             ],
//           ),
//           const Spacer(),
//           Obx(() => ElevatedButton.icon(
//                 onPressed: controller.isRefreshing.value
//                     ? null
//                     : controller.refreshData,
//                 icon: controller.isRefreshing.value
//                     ? const SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation(Colors.white)),
//                       )
//                     : Icon(PhosphorIcons.arrowsClockwise()),
//                 label: Text(controller.isRefreshing.value
//                     ? 'Refreshing...'
//                     : 'Refresh Data'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppTheme.primaryColor,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 20, vertical: 16),
//                 ),
//               )),
//         ],
//       ),
//     );
//   }

//   Widget _buildControls(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor.withOpacity(0.5),
//         border: Border(
//             bottom: BorderSide(color: Theme.of(context).dividerColor)),
//       ),
//       child: Row(
//         children: [
//           const Text('Overlays:',
//               style:
//                   TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
//           const SizedBox(width: 16),
//           Obx(() => _buildToggleButton(
//                 'Rain & Storm (CRR/RDT)',
//                 controller.showCRR.value || controller.showRDT.value,
//                 controller.toggleCRRRDT,
//                 Colors.purple,
//               )),
//           const SizedBox(width: 12),
//           Obx(() => _buildToggleButton(
//                 'Weather Icons',
//                 controller.showWeatherIcons.value,
//                 controller.toggleWeatherIcons,
//                 Colors.orange,
//               )),
//           const Spacer(),
//           Obx(() {
//             final crrN = controller.crrPolygons.length;
//             final rdtN = controller.rdtPolygons.length +
//                 controller.rdtPolylines.length;
//             final citN = controller.cityWeatherData.length;
//             return Container(
//               padding: const EdgeInsets.symmetric(
//                   horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(8)),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (controller.showCRR.value ||
//                       controller.showRDT.value) ...[
//                     Text('CRR: $crrN',
//                         style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600)),
//                     const SizedBox(width: 16),
//                     Container(
//                         width: 1,
//                         height: 16,
//                         color: Colors.grey[400]),
//                     const SizedBox(width: 16),
//                     Text('RDT: $rdtN',
//                         style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600)),
//                   ],
//                   if (controller.showWeatherIcons.value)
//                     Text('Cities: $citN',
//                         style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600)),
//                   if (!controller.showCRR.value &&
//                       !controller.showRDT.value &&
//                       !controller.showWeatherIcons.value)
//                     Text('No overlay active',
//                         style: TextStyle(
//                             fontSize: 12, color: Colors.grey[600])),
//                 ],
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildToggleButton(
//       String label, bool isActive, VoidCallback onTap, Color color) {
//     return Material(
//       color: isActive ? color : Colors.transparent,
//       borderRadius: BorderRadius.circular(8),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           decoration: BoxDecoration(
//             border: Border.all(
//                 color: isActive ? color : Get.theme.dividerColor,
//                 width: 2),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 isActive
//                     ? PhosphorIcons.checkCircle()
//                     : PhosphorIcons.circle(),
//                 size: 16,
//                 color: isActive
//                     ? Colors.white
//                     : Get.theme.textTheme.bodyLarge?.color,
//               ),
//               const SizedBox(width: 8),
//               Text(label,
//                   style: TextStyle(
//                     color: isActive
//                         ? Colors.white
//                         : Get.theme.textTheme.bodyLarge?.color,
//                     fontWeight: isActive
//                         ? FontWeight.w600
//                         : FontWeight.normal,
//                     fontSize: 13,
//                   )),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMap(BuildContext context) {
//     return Obx(() => FlutterMap(
//           mapController: controller.mapController,
//           options: MapOptions(
//             initialCenter: controller.initialPosition,
//             initialZoom: controller.initialZoom,
//             minZoom: 4.0,
//             maxZoom: 18.0,
//             interactionOptions:
//                 const InteractionOptions(flags: InteractiveFlag.all),
//           ),
//           children: [
//             TileLayer(
//               urlTemplate:
//                   'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//               userAgentPackageName: 'com.weather.admin.dashboard',
//               tileBuilder: (ctx, tile, _) => ColorFiltered(
//                 colorFilter: ColorFilter.mode(
//                     Colors.grey.withOpacity(0.3), BlendMode.saturation),
//                 child: tile,
//               ),
//             ),
//             if (controller.crrPolygons.isNotEmpty)
//               PolygonLayer(polygons: controller.crrPolygons),
//             if (controller.rdtPolygons.isNotEmpty)
//               PolygonLayer(polygons: controller.rdtPolygons),
//             if (controller.rdtPolylines.isNotEmpty)
//               PolylineLayer(polylines: controller.rdtPolylines),
//             if (controller.showWeatherIcons.value &&
//                 controller.cityWeatherData.isNotEmpty)
//               MarkerLayer(
//                 markers: controller.cityWeatherData
//                     .map((c) => Marker(
//                           point: LatLng(c.lat, c.lon),
//                           width: 80,
//                           height: 60,
//                           child: _WeatherMarker(city: c),
//                         ))
//                     .toList(),
//               ),
//           ],
//         ));
//   }

//   Widget _buildForecastTimeline(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         border: Border(
//             top: BorderSide(color: Theme.of(context).dividerColor)),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 8,
//               offset: const Offset(0, -2))
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Obx(() => IconButton(
//                     icon: Icon(
//                       controller.isPlaying.value
//                           ? Icons.pause
//                           : Icons.play_arrow,
//                       color: AppTheme.primaryColor,
//                       size: 28,
//                     ),
//                     onPressed: controller.isForecastLoading.value
//                         ? null
//                         : () => controller.isPlaying.value
//                             ? controller.stopPlayback()
//                             : controller.startPlayback(),
//                   )),
//               IconButton(
//                 icon: Icon(Icons.replay,
//                     color: AppTheme.primaryColor, size: 28),
//                 onPressed: controller.isForecastLoading.value
//                     ? null
//                     : controller.resetPlayback,
//               ),
//               Obx(() {
//                 final frames = controller.forecastFrames;
//                 final idx = controller.currentFrameIndex.value;
//                 return Text(
//                   frames.isNotEmpty
//                       ? controller.formatTime(frames[idx].timeslot)
//                       : '--:--',
//                   style: const TextStyle(
//                       fontSize: 16, fontWeight: FontWeight.bold),
//                 );
//               }),
//               const SizedBox(width: 12),
//               Obx(() {
//                 final frames = controller.forecastFrames;
//                 final idx = controller.currentFrameIndex.value;
//                 return Text(
//                   frames.isNotEmpty
//                       ? controller
//                           .getOffsetLabel(frames[idx].offset)
//                       : 'Now',
//                   style: const TextStyle(
//                       fontSize: 14, fontWeight: FontWeight.w600),
//                 );
//               }),
//               const Spacer(),
//               Obx(() => controller.isForecastLoading.value
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child:
//                           CircularProgressIndicator(strokeWidth: 2))
//                   : const SizedBox(width: 20)),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Obx(() => SliderTheme(
//                 data: SliderThemeData(
//                   activeTrackColor: AppTheme.primaryColor,
//                   inactiveTrackColor: Colors.grey.withOpacity(0.3),
//                   thumbColor: AppTheme.primaryColor,
//                   thumbShape:
//                       const RoundSliderThumbShape(enabledThumbRadius: 8),
//                   overlayShape:
//                       const RoundSliderOverlayShape(overlayRadius: 16),
//                 ),
//                 child: Slider(
//                   value: controller.currentFrameIndex.value.toDouble(),
//                   min: 0,
//                   max: (controller.forecastFrames.length - 1)
//                       .toDouble()
//                       .clamp(0, double.infinity),
//                   divisions: controller.forecastFrames.length > 1
//                       ? controller.forecastFrames.length - 1
//                       : 1,
//                   onChanged: controller.onFrameChanged,
//                 ),
//               )),
//         ],
//       ),
//     );
//   }
// }

// // ── Simple weather marker for the standalone MapView page ─────────────────────
// class _WeatherMarker extends StatelessWidget {
//   final CityWeatherData city;
//   const _WeatherMarker({required this.city});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => _showPopup(context),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(4),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.9),
//               shape: BoxShape.circle,
//               border:
//                   Border.all(color: Colors.blue.withOpacity(0.4), width: 1),
//               boxShadow: [
//                 BoxShadow(
//                     color: Colors.black.withOpacity(0.15), blurRadius: 4)
//               ],
//             ),
//             child: Text(WeatherIconUtils.getWeatherEmoji(city.icon),
//                 style: const TextStyle(fontSize: 16)),
//           ),
//           const SizedBox(height: 2),
//           Container(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.7),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Text('${city.temperature.round()}°',
//                 style: const TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showPopup(BuildContext context) {
//     Get.dialog(Dialog(
//       backgroundColor: Colors.transparent,
//       child: Container(
//         width: 200,
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//               colors: [Colors.blue[100]!, Colors.blue[50]!],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight),
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black.withOpacity(0.2), blurRadius: 8)
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Align(
//               alignment: Alignment.topRight,
//               child: GestureDetector(
//                 onTap: Get.back,
//                 child: Container(
//                   padding: const EdgeInsets.all(2),
//                   decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.4),
//                       shape: BoxShape.circle),
//                   child: const Icon(Icons.close,
//                       size: 14, color: Colors.black54),
//                 ),
//               ),
//             ),
//             Text(WeatherIconUtils.getWeatherEmoji(city.icon),
//                 style: const TextStyle(fontSize: 30)),
//             const SizedBox(height: 6),
//             Text(city.name,
//                 style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87),
//                 textAlign: TextAlign.center),
//             Text(city.region,
//                 style: const TextStyle(
//                     fontSize: 10, color: Colors.black54)),
//             const SizedBox(height: 8),
//             Text('${city.temperature.round()}°C',
//                 style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue[900])),
//             const SizedBox(height: 4),
//             Text(city.description,
//                 style: const TextStyle(
//                     fontSize: 12, color: Colors.black87),
//                 textAlign: TextAlign.center),
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.6),
//                   borderRadius: BorderRadius.circular(8)),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _Detail(
//                       icon: Icons.air,
//                       label: 'Wind',
//                       value:
//                           '${city.windSpeed.toStringAsFixed(1)} m/s'),
//                   _Detail(
//                       icon: Icons.water_drop,
//                       label: 'Humidity',
//                       value: '${city.humidity.round()}%'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     ));
//   }
// }

// class _Detail extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   const _Detail(
//       {required this.icon, required this.label, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Icon(icon, color: Colors.blue[700], size: 20),
//         const SizedBox(height: 2),
//         Text(label,
//             style:
//                 const TextStyle(fontSize: 9, color: Colors.black54)),
//         Text(value,
//             style: const TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87)),
//       ],
//     );
//   }
// }