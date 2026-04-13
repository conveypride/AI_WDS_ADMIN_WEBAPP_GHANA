import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class WeekendImageGenerator {
  
  static Future<Uint8List?> generateThreeMapsImage({
    required Map<String, dynamic> regions,
    required Map<String, dynamic> markers,
    required DateTime startDate,
    required BuildContext context,
    int tileWaitMs = 4000, // Increased wait time to ensure tiles load
  }) async {
    final repaintKey = GlobalKey();
    final completer = Completer<Uint8List?>();

    // Load Ghana border before rendering
    final ghanaBorder = await _loadGhanaBorder();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: -9999, // Render far off-screen
        top: -9999,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: repaintKey,
            child: Container(
              width: 2400,  // Wide enough for 3 maps side-by-side
              height: 1000, // Tall enough to prevent vertical clipping
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(child: _buildSingleMap( regions['day1'], markers['day1'], ghanaBorder)),
                  Container(width: 4, color: Colors.black), // Thicker divider
                  Expanded(child: _buildSingleMap( regions['day2'], markers['day2'], ghanaBorder)),
                  Container(width: 4, color: Colors.black), // Thicker divider
                  Expanded(child: _buildSingleMap( regions['day3'], markers['day3'], ghanaBorder)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Safely locate overlay
    final overlayState = Navigator.maybeOf(context)?.overlay ?? Overlay.maybeOf(context);
    
    if (overlayState != null) {
      overlayState.insert(entry);
    } else {
      debugPrint("CRITICAL: Could not find OverlayState");
      completer.complete(null);
      return completer.future;
    }

    // Wait for map tiles and polygons to fully render
    await Future.delayed(Duration(milliseconds: tileWaitMs));

    try {
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0); // 2.0 is usually sufficient and faster
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        completer.complete(byteData?.buffer.asUint8List());
      } else {
        completer.complete(null);
      }
    } catch (e) {
      debugPrint("Map Capture Error: $e");
      completer.complete(null);
    } finally {
      entry.remove();
    }

    return completer.future;
  }

 
  static Widget _buildSingleMap(
    List<dynamic>? dayRegions, 
    List<dynamic>? dayMarkers,
    List<LatLng> ghanaBorder,
  ) {
    // REMOVED the Column and "Day Title Header" Container. 
    // Now it ONLY returns the Map, ensuring perfect aspect ratios.
    return Container(
      color: Colors.white,
      child: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(7.95, -1.05),
      initialZoom: 7.5,
          interactionOptions: InteractionOptions(
            flags: InteractiveFlag.none, // Static
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.gmet.weather_dashboard',
            errorTileCallback: (tile, error, stack) {},
          ),
          
          PolylineLayer(
            polylines: _buildGridLines(),
          ),
          
          if (dayRegions != null && dayRegions.isNotEmpty)
            PolygonLayer(
              polygons: dayRegions.map((r) {
                final points = (r['points'] as List).map((p) => LatLng(p['lat'], p['lng'])).toList();
                final color = _getRiskColor(r['color']);
                return Polygon(
                  points: points,
                  color: color.withOpacity(0.5),
                  borderColor: color.withOpacity(0.8),
                  borderStrokeWidth: 2.5,
                );
              }).toList(),
            ),
            
          if (ghanaBorder.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: ghanaBorder,
                  color: Colors.black87,
                  strokeWidth: 3.5,
                ),
              ],
            ),
            
          MarkerLayer(markers: _buildCityMarkers()),
            
          if (dayMarkers != null && dayMarkers.isNotEmpty)
            MarkerLayer(
              markers: dayMarkers.map((m) {
                return Marker(
                  point: LatLng(m['lat'], m['lng']),
                  width: 80,
                  height: 80,
                  child: _buildMapIcon(m),
                );
              }).toList(),
            ),
            
          MarkerLayer(markers: _buildGridLabels()),
        ],
      ),
    );
  }

  static Color _getRiskColor(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'red': return const Color(0xFFD32F2F);
      case 'orange': return const Color(0xFFE64A19);
      case 'yellow': return const Color(0xFFF9A825);
      case 'green': return const Color(0xFF2E7D32);
      default: return const Color(0xFF2E7D32);
    }
  }

  static Widget _buildMapIcon(Map<String, dynamic> item) {
    if (item['type'] == 'icon') {
      return _WeatherIconWidget(name: item['value']);
    } else {
      return _RiskLabelWidget(label: item['value']);
    }
  }

  // =========================================================================
  // GRID LINES & LABELS
  // =========================================================================
  static List<Polyline> _buildGridLines() {
    final List<Polyline> gridLines = [];
    const gridColor = Color(0xFF9E9E9E);
    const strokeWidth = 0.8;

    // Latitude lines
    for (double lat = 4.0; lat <= 12.0; lat += 2.0) {
      gridLines.add(Polyline(points: [LatLng(lat, -3.5), LatLng(lat, 1.5)], color: gridColor, strokeWidth: strokeWidth));
    }
    // Longitude lines
    for (double lng = -3.0; lng <= 1.0; lng += 1.0) {
      gridLines.add(Polyline(points: [LatLng(4.0, lng), LatLng(12.0, lng)], color: gridColor, strokeWidth: strokeWidth));
    }
    return gridLines;
  }

  static List<Marker> _buildGridLabels() {
    final List<Marker> labels = [];
    // Latitude labels
    for (double lat = 4.0; lat <= 12.0; lat += 2.0) {
      labels.add(
        Marker(
          point: LatLng(lat, -3.3),
          width: 40, height: 20,
          child: Container(
            alignment: Alignment.centerRight,
            child: Text('${lat.toInt()}°N', style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold, backgroundColor: Colors.white70)),
          ),
        ),
      );
    }
    // Longitude labels
    for (double lng = -3.0; lng <= 1.0; lng += 1.0) {
      String label = lng < 0 ? '${lng.abs().toInt()}°W' : lng == 0 ? '0°' : '${lng.toInt()}°E';
      labels.add(
        Marker(
          point: LatLng(4.2, lng),
          width: 40, height: 20,
          child: Container(
            alignment: Alignment.topCenter,
            child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold, backgroundColor: Colors.white70)),
          ),
        ),
      );
    }
    return labels;
  }

  static List<Marker> _buildCityMarkers() {
    final cities = [
      {'name': 'Accra', 'lat': 5.6037, 'lng': -0.1870},
      {'name': 'Kumasi', 'lat': 6.6885, 'lng': -1.6244},
      {'name': 'Tamale', 'lat': 9.4075, 'lng': -0.8533},
      {'name': 'Takoradi', 'lat': 4.8974, 'lng': -1.7533},
      {'name': 'Wa', 'lat': 10.0606, 'lng': -2.5056},
      {'name': 'Bolgatanga', 'lat': 10.7856, 'lng': -0.8514},
      {'name': 'Sunyani', 'lat': 7.3390, 'lng': -2.3289},
      {'name': 'Ho', 'lat': 6.6108, 'lng': 0.4720},
    ];

    return cities.map((city) {
      return Marker(
        point: LatLng(city['lat'] as double, city['lng'] as double),
        width: 80, height: 40,
        child: _CityMarkerWidget(name: city['name'] as String),
      );
    }).toList();
  }

  static Future<List<LatLng>> _loadGhanaBorder() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/geoBoundaries-GHA-ADM0.geojson');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<LatLng> points = [];
      final features = data['features'] as List<dynamic>;
      if (features.isNotEmpty) {
        final geometry = features[0]['geometry'];
        final type = geometry['type'];
        final coords = geometry['coordinates'];
        if (type == 'Polygon') {
          for (var pt in coords[0]) points.add(LatLng(pt[1], pt[0]));
        } else if (type == 'MultiPolygon') {
          for (var pt in coords[0][0]) points.add(LatLng(pt[1], pt[0]));
        }
      }
      return points;
    } catch (e) {
      debugPrint("Error loading GeoJSON border: $e");
      return [];
    }
  }
}

// =============================================================================
// WEATHER ICON WIDGET (With ImageCodecException fix)
// =============================================================================
class _WeatherIconWidget extends StatelessWidget {
  final String name;
  const _WeatherIconWidget({required this.name});

  @override
  Widget build(BuildContext context) {
    final n = name.toLowerCase();
    String assetPath = 'assets/images/$n.png';

    return SizedBox(
      width: 80, height: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            assetPath,
            width: 50, height: 50,
            // THIS PREVENTS THE HTML 0x3c 0x21 CRASH
            errorBuilder: (context, error, stackTrace) {
              final (icon, color) = _resolve(n);
              return Icon(icon, size: 40, color: color); 
            },
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              _cap(name),
              style: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w900,
                color: Colors.black,
                shadows: [Shadow(color: Colors.white, blurRadius: 4, offset: Offset(0, 1))],
              ),
              overflow: TextOverflow.visible,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  static (IconData, Color) _resolve(String n) {
    if (n.contains('rain')) return (PhosphorIcons.cloudRain(PhosphorIconsStyle.fill), const Color(0xFF1565C0));
    if (n.contains('wind')) return (PhosphorIcons.wind(PhosphorIconsStyle.fill), const Color(0xFF546E7A));
    if (n.contains('dust') || n.contains('haze')) return (PhosphorIcons.dotsNine(PhosphorIconsStyle.fill), const Color(0xFFBF6F00));
    if (n.contains('hail')) return (PhosphorIcons.cloudSnow(PhosphorIconsStyle.fill), const Color(0xFF0277BD));
    if (n.contains('fog') || n.contains('mist')) return (PhosphorIcons.cloudFog(PhosphorIconsStyle.fill), const Color(0xFF546E7A));
    if (n.contains('cloud')) return (PhosphorIcons.cloud(PhosphorIconsStyle.fill), const Color(0xFF78909C));
    return (PhosphorIcons.sun(PhosphorIconsStyle.fill), const Color(0xFFF9A825));
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

// =============================================================================
// RISK LABEL WIDGET
// =============================================================================
class _RiskLabelWidget extends StatelessWidget {
  final String label;
  const _RiskLabelWidget({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          shadows: [
            Shadow(color: Colors.white, blurRadius: 6, offset: Offset(0, 0)),
            Shadow(color: Colors.white, blurRadius: 6, offset: Offset(0, 0)),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// =============================================================================
// CITY MARKER WIDGET
// =============================================================================
class _CityMarkerWidget extends StatelessWidget {
  final String name;
  const _CityMarkerWidget({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 2, spreadRadius: 1)],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 19, 1, 109),
            letterSpacing: 0.3, 
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}