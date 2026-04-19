
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/helpers/mapconfig.dart';
import 'package:weather_admin_dashboard/app/model/forecast_frame.dart';
import 'package:weather_admin_dashboard/app/services/weather_service.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

class MapViewController extends GetxController {
  final MapController mapController = MapController();

  final showCRR = false.obs;
  final showRDT = false.obs;
  final showWeatherIcons = false.obs;

  final isMapReady = false.obs;
  final isRefreshing = false.obs;
  final isForecastLoading = false.obs;
  final isLoadingCityWeather = false.obs;
  final isLoadingWeather = false.obs;

  final initialPosition =
      LatLng(WestAfricaConstants.centerLat, WestAfricaConstants.centerLon);
  final initialZoom = 6.5;

  final crrPolygons = <Polygon>[].obs;
  final rdtPolygons = <Polygon>[].obs;
  final rdtPolylines = <Polyline>[].obs;
  final cityWeatherData = <CityWeatherData>[].obs;

  final List<CRRFeature> _crrData = [];
  final List<RDTFeature> _rdtData = [];

  final forecastFrames = <ForecastFrame>[].obs;
  final currentFrameIndex = 0.obs;
  final Map<int, CachedFrame> _frameCache = {};
  static const int _maxCacheSize = 8;
  static const int _prefetchWindow = 2;

  final isPlaying = false.obs;
  Timer? _playbackTimer;

  final lastUpdated = ''.obs;
  final loadedItemsCount = 0.obs;
  final totalCoveragePoints = 0.obs;
  final completedRequests = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _updateTimestamp();
    Future.delayed(const Duration(milliseconds: 500), () {
      isMapReady.value = true;
    });
  }

  void _updateTimestamp() {
    lastUpdated.value = DateFormat('HH:mm').format(DateTime.now());
  }

  // ============================================================================
  // Toggle & Fetch
  // ============================================================================

  Future<void> toggleCRRRDT() async {
    final newState = !(showCRR.value || showRDT.value);

    showCRR.value = newState;
    showRDT.value = newState;
    showWeatherIcons.value = false;

    crrPolygons.clear();
    rdtPolygons.clear();
    rdtPolylines.clear();
    cityWeatherData.clear();
    _crrData.clear();
    _rdtData.clear();
    _frameCache.clear();

    if (newState) {
      await _fetchForecastTimeline();
    } else {
      forecastFrames.clear();
      currentFrameIndex.value = 0;
      stopPlayback();
    }
  }

  Future<void> toggleWeatherIcons() async {
    final newState = !showWeatherIcons.value;

    showWeatherIcons.value = newState;
    showCRR.value = false;
    showRDT.value = false;

    crrPolygons.clear();
    rdtPolygons.clear();
    rdtPolylines.clear();
    _crrData.clear();
    _rdtData.clear();
    forecastFrames.clear();
    currentFrameIndex.value = 0;
    _frameCache.clear();
    stopPlayback();

    if (newState) {
      await _fetchCityWeatherData();
    } else {
      cityWeatherData.clear();
    }
  }

  // ── FIX 3: Robust timeline fetch ──────────────────────────────────────────
  Future<void> _fetchForecastTimeline() async {
    isForecastLoading.value = true;

    final point =
        "${WestAfricaConstants.centerLon},${WestAfricaConstants.centerLat}";
    final url =
        "${FastaConfig.baseUri}/api/v1/quicklook/?point=$point&token=${FastaConfig.token}";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        _showError('Server returned ${response.statusCode}');
        return;
      }

      // ── Safely decode JSON ─────────────────────────────────────
      dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (e) {
        _showError('Invalid JSON response from server');
        return;
      }

      if (decoded == null || decoded is! Map<String, dynamic>) {
        _showError('Unexpected response format');
        return;
      }

      // ── Try both 'slots' and 'results' keys ────────────────────
      final rawSlots =
          decoded['slots'] ?? decoded['results'] ?? decoded['data'];

      if (rawSlots == null || rawSlots is! List || rawSlots.isEmpty) {
        _showError('No forecast frames found in response');
        return;
      }

      // ── Parse each slot, skip any that throw ───────────────────
      final frames = <ForecastFrame>[];
      for (final slot in rawSlots) {
        if (slot == null) continue;
        try {
          final frame = ForecastFrame.fromJson(
            slot is Map<String, dynamic>
                ? slot
                : Map<String, dynamic>.from(slot as Map),
          );
          // Only add frame if timeslot is a valid date string
          frames.add(frame);
        } catch (e) {
          debugPrint('Skipping malformed frame: $slot — $e');
        }
      }

      if (frames.isEmpty) {
        _showError('All forecast frames were malformed');
        return;
      }

      forecastFrames.value = frames;

      // Pick the frame whose offset is 0 (current), or default to middle
      final nowIndex = frames.indexWhere((f) => f.offset == 0);
      currentFrameIndex.value =
          nowIndex >= 0 ? nowIndex : (frames.length ~/ 2);

      await _fetchWeatherDataForFrame(currentFrameIndex.value);
    } catch (e) {
      _showError('Failed to fetch forecast timeline: $e');
    } finally {
      isForecastLoading.value = false;
    }
  }

  Future<void> _fetchWeatherDataForFrame(int frameIndex) async {
    if (frameIndex < 0 || frameIndex >= forecastFrames.length) return;

    if (_frameCache.containsKey(frameIndex)) {
      final cached = _frameCache[frameIndex]!;
      crrPolygons.value = cached.crrPolygons;
      rdtPolygons.value = cached.rdtPolygons;
      rdtPolylines.value = cached.rdtPolylines;
      return;
    }

    final frame = forecastFrames[frameIndex];
    await _fetchWeatherData(frame.timeParam);

    _cacheFrame(frameIndex);
    _prefetchNearbyFrames(frameIndex);
  }

  void _cacheFrame(int frameIndex) {
    _frameCache[frameIndex] = CachedFrame(
      crrPolygons: List.from(crrPolygons),
      rdtPolygons: List.from(rdtPolygons),
      rdtPolylines: List.from(rdtPolylines),
      timestamp: DateTime.now(),
    );

    if (_frameCache.length > _maxCacheSize) {
      _frameCache.remove(_frameCache.keys.first);
    }
  }

  Future<void> _prefetchNearbyFrames(int centerIndex) async {
    final toPrefetch = <int>[];

    for (int i = 1; i <= _prefetchWindow; i++) {
      final next = centerIndex + i;
      if (next < forecastFrames.length && !_frameCache.containsKey(next)) {
        toPrefetch.add(next);
      }
      final prev = centerIndex - i;
      if (prev >= 0 && !_frameCache.containsKey(prev)) {
        toPrefetch.add(prev);
      }
    }

    for (final idx in toPrefetch) {
      // ── SAFETY GUARD: Abort if the user cleared the map while we were waiting ──
      if (forecastFrames.isEmpty || idx < 0 || idx >= forecastFrames.length) {
        break; // Safely stop the background prefetch loop
      }

      try {
        await _fetchWeatherDataSilently(forecastFrames[idx].timeParam, idx);
      } catch (e) {
        debugPrint('Prefetch error for frame $idx: $e');
      }
    }
  }

  Future<void> _fetchWeatherDataSilently(
      String timeslot, int frameIndex) async {
    final tempCRR = <CRRFeature>[];
    final tempRDT = <RDTFeature>[];

    final coveragePoints = _getCoveragePoints();
    final futures = <Future>[];

    for (final c in coveragePoints) {
      final crrUrl =
          "${FastaConfig.baseUri}/api/v1/crr/$timeslot/?token=${FastaConfig.token}&point=${c['point']}&radius=${c['radius']}&tolerance=0.003";
      futures.add(_fetchCRRDataSilently(crrUrl, tempCRR));

      final rdtUrl =
          "${FastaConfig.baseUri}/api/v1/rdt/$timeslot/?token=${FastaConfig.token}&point=${c['point']}&radius=${c['radius']}&forecast=15,30,45,60&level=1";
      futures.add(_fetchRDTDataSilently(rdtUrl, tempRDT));
    }

    await Future.wait(futures).timeout(const Duration(seconds: 30));

    final crrPolys = <Polygon>[];
    final rdtPolys = <Polygon>[];
    final rdtLines = <Polyline>[];

    for (final f in tempCRR) {
      final p = _createPolygonFromCRRFeature(f);
      if (p != null) crrPolys.add(p);
    }
    for (final f in tempRDT) {
      if (f.geometry.type == 'Polygon') {
        final p = _createPolygonFromRDTFeature(f);
        if (p != null) rdtPolys.add(p);
      } else if (f.geometry.type == 'LineString') {
        final l = _createPolylineFromRDTFeature(f);
        if (l != null) rdtLines.add(l);
      }
    }

    _frameCache[frameIndex] = CachedFrame(
      crrPolygons: crrPolys,
      rdtPolygons: rdtPolys,
      rdtPolylines: rdtLines,
      timestamp: DateTime.now(),
    );
  }

  Future<void> _fetchWeatherData([String? timeslot]) async {
    if (!showCRR.value && !showRDT.value) return;

    isLoadingWeather.value = true;
    loadedItemsCount.value = 0;
    completedRequests.value = 0;

    try {
      final timeParam = timeslot ?? "now";
      final coveragePoints = _getCoveragePoints();
      totalCoveragePoints.value = coveragePoints.length;

      final futures = <Future>[];
      for (int i = 0; i < coveragePoints.length; i++) {
        final c = coveragePoints[i];
        final crrUrl =
            "${FastaConfig.baseUri}/api/v1/crr/$timeParam/?token=${FastaConfig.token}&point=${c['point']}&radius=${c['radius']}&tolerance=0.003";
        futures.add(_fetchCRRDataWithProgress(crrUrl, i));

        final rdtUrl =
            "${FastaConfig.baseUri}/api/v1/rdt/$timeParam/?token=${FastaConfig.token}&point=${c['point']}&radius=${c['radius']}&forecast=15,30,45,60&level=1";
        futures.add(_fetchRDTDataWithProgress(rdtUrl, i));
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures).timeout(const Duration(seconds: 60));
        _updateTimestamp();
      }

      await _createPolygonsFromData();
    } catch (e) {
      _showError('Failed to fetch weather data: $e');
    } finally {
      isLoadingWeather.value = false;
    }
  }

  List<Map<String, dynamic>> _getCoveragePoints() {
    return [
      {"point": "-1.0,5.6", "radius": 1000},
      {"point": "-1.6,6.7", "radius": 1000},
      {"point": "-2.5,8.1", "radius": 1000},
      {"point": "-0.2,7.9", "radius": 1000},
      {"point": "-1.7,5.2", "radius": 1000},
      {"point": "3.4,6.5", "radius": 1000},
      {"point": "7.5,9.1", "radius": 1000},
      {"point": "4.0,7.5", "radius": 1000},
      {"point": "7.4,11.8", "radius": 1000},
      {"point": "-4.0,5.3", "radius": 1000},
      {"point": "-5.3,7.7", "radius": 1000},
      {"point": "-17.4,14.7", "radius": 300},
      {"point": "-15.3,13.5", "radius": 250},
      {"point": "-16.6,13.4", "radius": 200},
      {"point": "-1.5,12.4", "radius": 1000},
      {"point": "-4.3,11.2", "radius": 1000},
      {"point": "1.2,6.2", "radius": 1000},
      {"point": "2.4,6.5", "radius": 1000},
      {"point": "2.3,9.3", "radius": 1000},
      {"point": "-13.2,8.5", "radius": 1000},
      {"point": "-10.8,6.3", "radius": 1000},
      {"point": "-8.0,12.6", "radius": 1000},
      {"point": "2.1,13.5", "radius": 1000},
      {"point": "12.1,9.7", "radius": 1000},
      {"point": "9.7,4.0", "radius": 1000},
      {"point": "11.5,9.3", "radius": 1000},
      {"point": "-3.0,10.0", "radius": 1000},
      {"point": "4.0,10.0", "radius": 1000},
      {"point": "-10.0,12.0", "radius": 1000},
      {"point": "10.0,12.0", "radius": 1000},
      {"point": "-5.0,7.0", "radius": 1000},
    ];
  }

  Future<void> _fetchCRRDataSilently(
      String url, List<CRRFeature> list) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        _parseCRRResponse(response.body, list);
      }
    } catch (_) {}
  }

  Future<void> _fetchRDTDataSilently(
      String url, List<RDTFeature> list) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        _parseRDTResponse(response.body, list);
      }
    } catch (_) {}
  }

  Future<void> _fetchCRRDataWithProgress(String url, int idx) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final added = _parseCRRResponse(response.body, _crrData);
        loadedItemsCount.value += added;
      }
    } catch (e) {
      debugPrint('CRR fetch error $idx: $e');
    } finally {
      completedRequests.value++;
    }
  }

  Future<void> _fetchRDTDataWithProgress(String url, int idx) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final added = _parseRDTResponse(response.body, _rdtData);
        loadedItemsCount.value += added;
      }
    } catch (e) {
      debugPrint('RDT fetch error $idx: $e');
    } finally {
      completedRequests.value++;
    }
  }

  // ── FIX 4: Centralised safe parsers ──────────────────────────────────────
  int _parseCRRResponse(String body, List<CRRFeature> list) {
    try {
      final data = json.decode(body);
      if (data is! Map<String, dynamic>) return 0;
      final features = data['features'];
      if (features is! List) return 0;

      final existing =
          list.map((f) => f.geometry.coordinates.toString()).toSet();
      final newItems = features
          .whereType<Map>()
          .map((f) {
            try {
              return CRRFeature.fromJson(Map<String, dynamic>.from(f));
            } catch (_) {
              return null;
            }
          })
          .where((f) =>
              f != null &&
              (f.properties.rainRate?.isNotEmpty ?? false) &&
              !existing.contains(f.geometry.coordinates.toString()))
          .cast<CRRFeature>()
          .toList();

      list.addAll(newItems);
      return newItems.length;
    } catch (_) {
      return 0;
    }
  }

  int _parseRDTResponse(String body, List<RDTFeature> list) {
    try {
      final data = json.decode(body);
      if (data is! Map<String, dynamic>) return 0;
      final features = data['features'];
      if (features is! List) return 0;

      final existing =
          list.map((f) => f.geometry.coordinates.toString()).toSet();
      final newItems = features
          .whereType<Map>()
          .map((f) {
            try {
              return RDTFeature.fromJson(Map<String, dynamic>.from(f));
            } catch (_) {
              return null;
            }
          })
          .where((f) =>
              f != null &&
              f.properties.objectType.isNotEmpty &&
              !existing.contains(f.geometry.coordinates.toString()))
          .cast<RDTFeature>()
          .toList();

      list.addAll(newItems);
      return newItems.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _createPolygonsFromData() async {
    final crrPolys = <Polygon>[];
    final rdtPolys = <Polygon>[];
    final rdtLines = <Polyline>[];

    for (int i = 0; i < _crrData.length && i < 500; i++) {
      final p = _createPolygonFromCRRFeature(_crrData[i]);
      if (p != null) crrPolys.add(p);
    }
    for (int i = 0; i < _rdtData.length && i < 500; i++) {
      final f = _rdtData[i];
      if (f.geometry.type == 'Polygon') {
        final p = _createPolygonFromRDTFeature(f);
        if (p != null) rdtPolys.add(p);
      } else if (f.geometry.type == 'LineString') {
        final l = _createPolylineFromRDTFeature(f);
        if (l != null) rdtLines.add(l);
      }
    }

    crrPolygons.value = crrPolys;
    rdtPolygons.value = rdtPolys;
    rdtPolylines.value = rdtLines;
  }

  Polygon? _createPolygonFromCRRFeature(CRRFeature feature) {
    if (feature.geometry.type != 'Polygon' ||
        feature.geometry.coordinates == null) return null;
    try {
      final coordinates = feature.geometry.coordinates as List;
      if (coordinates.isEmpty) return null;
      final ring = coordinates[0] as List;
      if (ring.length < 3) return null;
      final points = _parseCoordinates(ring);
      if (points.length < 3) return null;
      final color = _getCRRColor(feature.properties.rainRate ?? '');
      final opacity = _getCRROpacity(feature.properties.rainRate ?? '');
      return Polygon(
        points: points,
        color: color.withOpacity(opacity),
        borderColor: color.withOpacity(min(opacity + 0.3, 1.0)),
        borderStrokeWidth: 1.0,
      );
    } catch (e) {
      debugPrint('CRR polygon error: $e');
      return null;
    }
  }

  Polygon? _createPolygonFromRDTFeature(RDTFeature feature) {
    if (feature.geometry.type != 'Polygon' ||
        feature.geometry.coordinates == null) return null;
    try {
      final coordinates = feature.geometry.coordinates as List;
      if (coordinates.isEmpty) return null;
      final ring = coordinates[0] as List;
      if (ring.length < 3) return null;
      final points = _parseCoordinates(ring);
      if (points.length < 3) return null;
      final color = _getRDTColor(feature.properties.phaseLife);
      return Polygon(
        points: points,
        color: color.withOpacity(0.6),
        borderColor: color.withOpacity(0.8),
        borderStrokeWidth: 2.0,
      );
    } catch (e) {
      debugPrint('RDT polygon error: $e');
      return null;
    }
  }

  Polyline? _createPolylineFromRDTFeature(RDTFeature feature) {
    if (feature.geometry.type != 'LineString' ||
        feature.geometry.coordinates == null) return null;
    try {
      final points =
          _parseCoordinates(feature.geometry.coordinates as List);
      if (points.length < 2) return null;
      return Polyline(
        points: points,
        color: Colors.red.withOpacity(0.8),
        strokeWidth: 3.0,
      );
    } catch (e) {
      debugPrint('RDT polyline error: $e');
      return null;
    }
  }

  List<LatLng> _parseCoordinates(List coordinates) {
    final points = <LatLng>[];
    for (final coord in coordinates) {
      if (coord is! List || coord.length < 2) continue;
      try {
        final lon = (coord[0] as num).toDouble();
        final lat = (coord[1] as num).toDouble();
        if (lat.abs() <= 90 && lon.abs() <= 180) {
          points.add(LatLng(lat, lon));
        }
      } catch (_) {}
    }
    return points;
  }

  Color _getCRRColor(String rate) {
    const map = {
      'CRR_02_1': Color(0xFF87CEEB),
      'CRR_1_2': Color(0xFF4169E1),
      'CRR_2_3': Color(0xFF00CED1),
      'CRR_3_5': Color(0xFF32CD32),
      'CRR_5_7': Color(0xFF228B22),
      'CRR_7_10': Color(0xFF9ACD32),
      'CRR_10_15': Color(0xFFFFD700),
      'CRR_15_20': Color(0xFFFFA500),
      'CRR_20_30': Color(0xFFFF6347),
      'CRR_30_50': Color(0xFFFF0000),
      'CRR_50_plus': Color(0xFF8B0000),
    };
    return map[rate] ?? const Color(0xFF808080);
  }

  double _getCRROpacity(String rate) {
    const map = {
      'CRR_02_1': 0.4,
      'CRR_1_2': 0.5,
      'CRR_2_3': 0.6,
      'CRR_3_5': 0.7,
      'CRR_5_7': 0.75,
      'CRR_7_10': 0.8,
      'CRR_10_15': 0.85,
      'CRR_15_20': 0.9,
      'CRR_20_30': 0.95,
      'CRR_30_50': 1.0,
      'CRR_50_plus': 1.0,
    };
    return map[rate] ?? 0.4;
  }

  Color _getRDTColor(int? phaseLife) {
    if (phaseLife == null) return Colors.grey.withOpacity(0.5);
    if (phaseLife <= 1) return const Color(0xFF808080);
    if (phaseLife == 2) return const Color(0xFF32CD32);
    if (phaseLife == 3) return const Color(0xFFFFFF00);
    return const Color(0xFFFF4500);
  }

  // ============================================================================
  // City Weather
  // ============================================================================

  Future<void> _fetchCityWeatherData() async {
    if (!showWeatherIcons.value) return;
    isLoadingCityWeather.value = true;

    try {
      final futures = WestAfricaCities.cities
          .map((c) => CityWeatherService.fetchCityWeatherData(
                c['name'] as String,
                c['region'] as String,
                (c['lat'] as num).toDouble(),
                (c['lon'] as num).toDouble(),
              ))
          .toList();

      final results = await Future.wait(futures);
      cityWeatherData.value =
          results.whereType<CityWeatherData>().toList();
      _updateTimestamp();
    } catch (e) {
      _showError('Failed to fetch city weather: $e');
    } finally {
      isLoadingCityWeather.value = false;
    }
  }

  // ============================================================================
  // Playback
  // ============================================================================

  void startPlayback() {
    if (isPlaying.value) return;
    isPlaying.value = true;

    _playbackTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!isPlaying.value) {
        timer.cancel();
        return;
      }
      if (currentFrameIndex.value < forecastFrames.length - 1) {
        final next = currentFrameIndex.value + 1;
        currentFrameIndex.value = next;
        await _fetchWeatherDataForFrame(next);
      } else {
        stopPlayback();
      }
    });
  }

  void stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    isPlaying.value = false;
  }

  void resetPlayback() {
    stopPlayback();
    currentFrameIndex.value = 0;
    _fetchWeatherDataForFrame(0);
  }

  Future<void> onFrameChanged(double value) async {
    final idx = value.round();
    if (idx != currentFrameIndex.value) {
      currentFrameIndex.value = idx;
      await _fetchWeatherDataForFrame(idx);
    }
  }

  // ============================================================================
  // Refresh
  // ============================================================================

  Future<void> refreshData() async {
    isRefreshing.value = true;

    crrPolygons.clear();
    rdtPolygons.clear();
    rdtPolylines.clear();
    cityWeatherData.clear();
    _crrData.clear();
    _rdtData.clear();

    final futures = <Future>[];

    if (showCRR.value || showRDT.value) {
      futures.add(
        forecastFrames.isNotEmpty
            ? _fetchWeatherDataForFrame(currentFrameIndex.value)
            : _fetchWeatherData(),
      );
    }

    if (showWeatherIcons.value) {
      futures.add(_fetchCityWeatherData());
    }

    if (futures.isNotEmpty) await Future.wait(futures);

    isRefreshing.value = false;

    Get.snackbar(
      'Data Refreshed',
      'Map data updated successfully',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: AppTheme.successGreen,
      colorText: Colors.white,
      icon: Icon(PhosphorIcons.check(), color: Colors.white),
    );
  }

  // ============================================================================
  // Utilities
  // ============================================================================

  void _showError(String message) {
    debugPrint('[MapView] $message');
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  String formatTime(String timeslot) {
    try {
      final dt = DateTime.parse(timeslot);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '--:--';
    }
  }

  String getOffsetLabel(int offset) {
    if (offset < 0) return "${offset ~/ 60}h";
    if (offset == 0) return "Now";
    return "+${offset ~/ 60}h";
  }

  @override
  void onClose() {
    mapController.dispose();
    _playbackTimer?.cancel();
    super.onClose();
  }
}