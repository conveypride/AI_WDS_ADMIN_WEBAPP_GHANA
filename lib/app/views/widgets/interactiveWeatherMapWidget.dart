import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ============================================================================
// CONFIGURATION & CONSTANTS
// ============================================================================

class FastaConfig {
  static const String baseUri = "https://dev.fastaweather.com";
  static const String token = "YL0XfvchO2YXMMUAflZMUyFNhwGVSOEIYQGzMJYfx34";
}

// ============================================================================
// DATA MODELS
// ============================================================================

class CRRFeature {
  final Geometry geometry;
  final CRRProperties properties;

  CRRFeature({required this.geometry, required this.properties});

  factory CRRFeature.fromJson(Map<String, dynamic> json) {
    return CRRFeature(
      geometry: Geometry.fromJson(json['geometry'] ?? {}),
      properties: CRRProperties.fromJson(json['properties'] ?? {}),
    );
  }
}

class RDTFeature {
  final Geometry geometry;
  final RDTProperties properties;

  RDTFeature({required this.geometry, required this.properties});

  factory RDTFeature.fromJson(Map<String, dynamic> json) {
    return RDTFeature(
      geometry: Geometry.fromJson(json['geometry'] ?? {}),
      properties: RDTProperties.fromJson(json['properties'] ?? {}),
    );
  }
}

class Geometry {
  final String type;
  final dynamic coordinates;

  Geometry({required this.type, required this.coordinates});

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      type: json['type'] ?? 'Point',
      coordinates: json['coordinates'],
    );
  }
}

class CRRProperties {
  final String? rainRate;
  CRRProperties({this.rainRate});
  factory CRRProperties.fromJson(Map<String, dynamic> json) => 
      CRRProperties(rainRate: json['rain_rate']);
}

class RDTProperties {
  final String objectType;
  final int? phaseLife;
  RDTProperties({required this.objectType, this.phaseLife});
  factory RDTProperties.fromJson(Map<String, dynamic> json) => RDTProperties(
        objectType: json['object_type'] ?? '',
        phaseLife: json['phase_life'],
      );
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
}

// ============================================================================
// UTILS & SERVICES
// ============================================================================

class WeatherIconUtils {
  static String getWeatherEmoji(String symbolCode, [int? hour]) {
    final currentHour = hour ?? DateTime.now().hour;
    final isNight = currentHour < 6 || currentHour >= 18;

    if (symbolCode.contains('rain') && symbolCode.contains('thunder')) return '⛈️';
    if (symbolCode.contains('rain')) return '🌧️';
    if (symbolCode.contains('cloud') && symbolCode.contains('sun')) return '⛅';
    if (symbolCode.contains('cloud')) return '☁️';
    if (symbolCode.contains('fog') || symbolCode.contains('mist')) return '🌫️';
    if (symbolCode.contains('clear') || symbolCode.contains('sun')) {
      return isNight ? '🌙' : '☀️';
    }
    return isNight ? '🌙' : '🌤️';
  }
}

class WeatherService {
  static const String _baseUrl = 'https://api.met.no/weatherapi/locationforecast/2.0/compact';
  // IMPORTANT: Met.no requires a unique User-Agent. 
  // If this fails on Web due to CORS, use "flutter run -d chrome --web-browser-flag '--disable-web-security'" for dev
  static const Map<String, String> _headers = {
    'User-Agent': 'WeatherAdminDashboard/1.0 (admin@meteo.gov.gh)',
  };

  static const List<Map<String, dynamic>> _ghanaCities = [
    {"name": "Accra", "region": "Greater Accra", "lat": 5.6037, "lon": -0.187},
    {"name": "Kumasi", "region": "Ashanti", "lat": 6.6666, "lon": -1.6163},
    {"name": "Tamale", "region": "Northern", "lat": 9.4075, "lon": -0.853},
    {"name": "Takoradi", "region": "Western", "lat": 4.9349, "lon": -1.7542},
    {"name": "Sunyani", "region": "Bono", "lat": 7.333, "lon": -2.333},
    {"name": "Ho", "region": "Volta", "lat": 6.6008, "lon": 0.4713},
    {"name": "Wa", "region": "Upper West", "lat": 10.06, "lon": -2.5},
    {"name": "Bolgatanga", "region": "Upper East", "lat": 10.7856, "lon": -0.8514},
  ];

  Future<List<CityWeatherData>> fetchAllCitiesWeather() async {
    final futures = _ghanaCities.map((city) => _fetchCityWeather(
      city['name'], city['region'], city['lat'], city['lon']
    )).toList();
    
    final results = await Future.wait(futures);
    return results.whereType<CityWeatherData>().toList();
  }

  Future<CityWeatherData?> _fetchCityWeather(String name, String region, double lat, double lon) async {
    try {
      final url = '$_baseUrl?lat=$lat&lon=$lon';
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timeseries = data['properties']['timeseries'] as List;
        final current = timeseries[0]['data'];
        final instant = current['instant']['details'];
        final next1h = current['next_1_hours']?['summary']['symbol_code'] ?? 'clearsky_day';
        
        return CityWeatherData(
          name: name,
          region: region,
          lat: lat,
          lon: lon,
          temperature: (instant['air_temperature'] ?? 0.0).toDouble(),
          condition: next1h,
          icon: next1h,
          windSpeed: (instant['wind_speed'] ?? 0.0).toDouble(),
          humidity: (instant['relative_humidity'] ?? 0.0).toDouble(),
          description: next1h.replaceAll('_', ' '),
        );
      }
    } catch (e) {
      debugPrint("Error fetching weather for $name: $e");
    }
    return null;
  }
}

// ============================================================================
// MAIN WIDGET
// ============================================================================

class InteractiveWeatherMapWidget extends StatefulWidget {
  const InteractiveWeatherMapWidget({super.key});

  @override
  State<InteractiveWeatherMapWidget> createState() => _InteractiveWeatherMapWidgetState();
}

class _InteractiveWeatherMapWidgetState extends State<InteractiveWeatherMapWidget> {
  late MapController _mapController;
  bool _isLoading = false;
  bool _isDarkMode = true; // Default to dark mode for radar feel

  // Data Containers
  final List<CRRFeature> _crrData = [];
  final List<RDTFeature> _rdtData = [];
  List<Polygon> _crrPolygons = [];
  List<Polygon> _rdtPolygons = [];
  List<Polyline> _rdtPolylines = [];
  List<CityWeatherData> _cityWeatherData = [];

  // Toggles
  bool _showRainStorm = false;
  bool _showWeatherIcons = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchCityWeatherData(); // Load cities by default
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // --- DATA FETCHING ---

  Future<void> _fetchWeatherData() async {
    if (!_showRainStorm) return;

    setState(() => _isLoading = true);

    try {
      _crrData.clear();
      _rdtData.clear();

      final timeParam = "now";
      final coveragePoints = [
        {"point": "-1.0,5.6", "radius": 1000},
        {"point": "-1.6,6.7", "radius": 1000},
        {"point": "-2.5,8.1", "radius": 1000},
      ];

      final futures = <Future>[];
      for (final coverage in coveragePoints) {
        final crrUrl = "${FastaConfig.baseUri}/api/v1/crr/$timeParam/?token=${FastaConfig.token}&point=${coverage['point']}&radius=${coverage['radius']}&tolerance=0.003";
        final rdtUrl = "${FastaConfig.baseUri}/api/v1/rdt/$timeParam/?token=${FastaConfig.token}&point=${coverage['point']}&radius=${coverage['radius']}&forecast=15,30,45,60&level=1";
        
        futures.add(_fetchData(crrUrl, true));
        futures.add(_fetchData(rdtUrl, false));
      }

      await Future.wait(futures).timeout(const Duration(seconds: 30));
      await _createPolygonsFromData();
      
    } catch (e) {
      debugPrint('Error fetching satellite data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchData(String url, bool isCRR) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null) {
          final list = data['features'] as List;
          if (isCRR) {
            final features = list
                .map((f) => CRRFeature.fromJson(f))
                .where((f) => f.properties.rainRate != null)
                .toList();
            if (mounted) setState(() => _crrData.addAll(features));
          } else {
            final features = list.map((f) => RDTFeature.fromJson(f)).toList();
            if (mounted) setState(() => _rdtData.addAll(features));
          }
        }
      }
    } catch (e) {
      debugPrint('Fetch error (${isCRR ? "CRR" : "RDT"}): $e');
    }
  }

  Future<void> _fetchCityWeatherData() async {
    if (!_showWeatherIcons) return;
    
    setState(() => _isLoading = true);
    
    final service = WeatherService();
    final data = await service.fetchAllCitiesWeather();
    
    if (mounted) {
      setState(() {
        _cityWeatherData = data;
        _isLoading = false;
      });
    }
  }

  // --- GEOMETRY PROCESSING ---

  Future<void> _createPolygonsFromData() async {
    List<Polygon> crrPolys = [];
    List<Polygon> rdtPolys = [];
    List<Polyline> rdtLines = [];

    // Process Rain
    for (var f in _crrData) {
      final poly = _createPolygon(f.geometry, _getCRRColor(f.properties.rainRate), 0.5);
      if (poly != null) crrPolys.add(poly);
    }

    // Process Storms
    for (var f in _rdtData) {
      if (f.geometry.type == 'Polygon') {
        final poly = _createPolygon(f.geometry, _getRDTColor(f.properties.phaseLife), 0.6);
        if (poly != null) rdtPolys.add(poly);
      } else if (f.geometry.type == 'LineString') {
        final line = _createPolyline(f.geometry);
        if (line != null) rdtLines.add(line);
      }
    }

    if (mounted) {
      setState(() {
        _crrPolygons = crrPolys;
        _rdtPolygons = rdtPolys;
        _rdtPolylines = rdtLines;
      });
    }
  }

  Polygon? _createPolygon(Geometry geo, Color color, double opacity) {
    try {
      if (geo.coordinates == null || (geo.coordinates as List).isEmpty) return null;
      final ring = (geo.coordinates as List)[0] as List;
      final points = ring.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();

      return Polygon(
        points: points,
        color: color.withOpacity(opacity),
        borderColor: color.withOpacity(min(opacity + 0.3, 1.0)),
        borderStrokeWidth: 1,
        // isFilled: true,
      );
    } catch (e) { return null; }
  }

  Polyline? _createPolyline(Geometry geo) {
    try {
      if (geo.coordinates == null) return null;
      final coords = geo.coordinates as List;
      final points = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
      return Polyline(points: points, color: Colors.redAccent, strokeWidth: 2.0);
    } catch (e) { return null; }
  }

  // --- COLORS ---

  Color _getCRRColor(String? rate) {
    if (rate == null) return Colors.blue.withOpacity(0.3);
    if (rate.contains('02_1')) return Colors.lightBlue[200]!;
    if (rate.contains('1_2')) return Colors.blue;
    if (rate.contains('50_plus')) return Colors.red[900]!;
    return Colors.blue;
  }

  Color _getRDTColor(int? phase) {
    if (phase == null) return Colors.grey;
    if (phase <= 1) return Colors.yellow;
    if (phase == 2) return Colors.orange;
    if (phase >= 3) return Colors.red;
    return Colors.purple;
  }

  // --- TOGGLES ---

  void _toggleRainStorm() {
    setState(() {
      _showRainStorm = !_showRainStorm;
      if (_showRainStorm) {
        _showWeatherIcons = false;
        _fetchWeatherData();
      } else {
        _crrPolygons.clear();
        _rdtPolygons.clear();
        _rdtPolylines.clear();
      }
    });
  }

  void _toggleWeatherIcons() {
    setState(() {
      _showWeatherIcons = !_showWeatherIcons;
      if (_showWeatherIcons) {
        _showRainStorm = false;
        _fetchCityWeatherData();
      }
    });
  }

  void _toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
  }

  void _refreshAllData() {
    if (_showRainStorm) _fetchWeatherData();
    if (_showWeatherIcons) _fetchCityWeatherData();
  }

  // ==========================================================================
  // UI BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // A. MAP LAYER
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(7.94, -1.02), // Center of Ghana
            initialZoom: 6.5,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: _isDarkMode
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: _isDarkMode ? const ['a', 'b', 'c', 'd'] : const [],
              userAgentPackageName: 'com.weather.admin',
            ),
            
            if (_showRainStorm) ...[
              PolygonLayer(polygons: _crrPolygons),
              PolygonLayer(polygons: _rdtPolygons),
              PolylineLayer(polylines: _rdtPolylines),
            ],

            if (_showWeatherIcons)
              MarkerLayer(
                markers: _cityWeatherData.map((city) => Marker(
                  point: LatLng(city.lat, city.lon),
                  width: 80,
                  height: 60,
                  child: _buildCityMarker(city),
                )).toList(),
              ),
          ],
        ),

        // B. HEADER OVERLAY WITH CUSTOM LOGO
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                // ----------------------------------------------------
                // THIS IS WHERE YOUR ICON GOES
                // Ensure 'assets/images/gmet_logo.png' exists in your project
                // ----------------------------------------------------
                Image.asset(
                  'images/gmet_logo.png', // Replace with your actual asset path
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if image not found yet
                    return const Icon(Icons.public, color: Colors.blueAccent, size: 20);
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'LIVE SATELLITE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // C. CONTROLS OVERLAY
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildControlButton(
                icon: Icons.thunderstorm,
                label: "Radar",
                isActive: _showRainStorm,
                onTap: _toggleRainStorm,
                activeColor: Colors.purpleAccent,
              ),
              const SizedBox(height: 12),
              _buildControlButton(
                icon: Icons.wb_sunny,
                label: "Cities",
                isActive: _showWeatherIcons,
                onTap: _toggleWeatherIcons,
                activeColor: Colors.orangeAccent,
              ),
              const SizedBox(height: 12),
              _buildControlButton(
                icon: _isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                label: "Theme",
                isActive: false, 
                onTap: _toggleTheme,
                activeColor: Colors.grey,
              ),
              const SizedBox(height: 12),
              _buildControlButton(
                icon: Icons.refresh,
                label: "Sync",
                isActive: _isLoading,
                onTap: _refreshAllData,
                activeColor: Colors.blue,
                spin: _isLoading,
              ),
            ],
          ),
        ),

        // D. LEGEND (Bottom Right)
        if (_showRainStorm && (_crrPolygons.isNotEmpty || _rdtPolygons.isNotEmpty))
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("INTENSITY", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildLegendRow(Colors.lightBlue[200]!, "Light Rain"),
                  _buildLegendRow(Colors.blue, "Moderate"),
                  _buildLegendRow(Colors.red[900]!, "Extreme"),
                  const SizedBox(height: 8),
                  _buildLegendRow(Colors.purple, "Storm Cell"),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required Color activeColor,
    bool spin = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? activeColor : Colors.white12,
            width: 1.5,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: activeColor.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            spin 
              ? SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: activeColor)
                )
              : Icon(icon, color: isActive ? activeColor : Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCityMarker(CityWeatherData city) {
    return GestureDetector(
      onTap: () => _showCityDialog(city),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Text(
              WeatherIconUtils.getWeatherEmoji(city.icon, null),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "${city.temperature.round()}°",
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  void _showCityDialog(CityWeatherData city) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                WeatherIconUtils.getWeatherEmoji(city.icon, null),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 10),
              Text(city.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(city.region, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              Text("${city.temperature.round()}°C", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              Text(city.description, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _detailItem(Icons.water_drop, "${city.humidity.round()}%"),
                  _detailItem(Icons.air, "${city.windSpeed.toStringAsFixed(1)} m/s"),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}