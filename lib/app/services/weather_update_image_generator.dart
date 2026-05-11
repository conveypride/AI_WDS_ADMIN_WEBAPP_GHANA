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

class WeatherUpdateImageGenerator {
  
  static Future<Uint8List?> generateMapImage({
    required List<dynamic> regions,
    required List<dynamic> mapItems,
    required BuildContext context,
    int tileWaitMs = 4000,
  }) async {
    final repaintKey = GlobalKey();
    final completer = Completer<Uint8List?>();

    final ghanaBorder = await _loadGhanaBorder();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: -9999, 
        top: -9999,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: repaintKey,
            child: Container(
              width: 800,
              height: 1000,
              color: Colors.white,
              child: _buildSingleMap(regions, mapItems, ghanaBorder),
            ),
          ),
        ),
      ),
    );

    final overlayState = Navigator.maybeOf(context)?.overlay ?? Overlay.maybeOf(context);
    if (overlayState != null) {
      overlayState.insert(entry);
    } else {
      completer.complete(null);
      return completer.future;
    }

    await Future.delayed(Duration(milliseconds: tileWaitMs));

    try {
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        completer.complete(byteData?.buffer.asUint8List());
      } else {
        completer.complete(null);
      }
    } catch (e) {
      completer.complete(null);
    } finally {
      entry.remove();
    }

    return completer.future;
  }

  static Widget _buildSingleMap(
    List<dynamic> regions, 
    List<dynamic> mapItems,
    List<LatLng> ghanaBorder,
  ) {
    return Container(
      color: Colors.white,
      child: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(7.95, -1.05),
          initialZoom: 7.5,
          interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.gmet.weather_dashboard',
          ),
          PolylineLayer(polylines: _buildGridLines()),
          if (regions.isNotEmpty)
            PolygonLayer(
              polygons: regions.map((r) {
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
              polylines: [Polyline(points: ghanaBorder, color: Colors.black87, strokeWidth: 3.5)],
            ),
          MarkerLayer(markers: _buildCityMarkers()),
          if (mapItems.isNotEmpty)
            MarkerLayer(
              markers: mapItems.map((m) {
                return Marker(
                  point: LatLng(m['lat'], m['lng']),
                  width: 80, height: 80,
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
    if (item['type'] == 'icon' || item['type'] == 'WeeklyItemType.icon') {
      return _WeatherIconWidget(name: item['value']);
    } else {
      return _RiskLabelWidget(label: item['value']);
    }
  }

  static List<Polyline> _buildGridLines() {
    final List<Polyline> gridLines = [];
    const gridColor = Color(0xFF9E9E9E);
    for (double lat = 4.0; lat <= 12.0; lat += 2.0) {
      gridLines.add(Polyline(points: [LatLng(lat, -3.5), LatLng(lat, 1.5)], color: gridColor, strokeWidth: 0.8));
    }
    for (double lng = -3.0; lng <= 1.0; lng += 1.0) {
      gridLines.add(Polyline(points: [LatLng(4.0, lng), LatLng(12.0, lng)], color: gridColor, strokeWidth: 0.8));
    }
    return gridLines;
  }

  static List<Marker> _buildGridLabels() {
    final List<Marker> labels = [];
    for (double lat = 4.0; lat <= 12.0; lat += 2.0) {
      labels.add(Marker(point: LatLng(lat, -3.3), width: 40, height: 20, child: Container(alignment: Alignment.centerRight, child: Text('${lat.toInt()}°N', style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold, backgroundColor: Colors.white70)))));
    }
    for (double lng = -3.0; lng <= 1.0; lng += 1.0) {
      String label = lng < 0 ? '${lng.abs().toInt()}°W' : lng == 0 ? '0°' : '${lng.toInt()}°E';
      labels.add(Marker(point: LatLng(4.2, lng), width: 40, height: 20, child: Container(alignment: Alignment.topCenter, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold, backgroundColor: Colors.white70)))));
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
      {'name': 'Kintampo', 'lat': 8.05, 'lng': -1.73},
      {'name': 'Kete Krachi', 'lat': 7.82, 'lng': -0.05},
      {'name': 'Aflao', 'lat': 6.12, 'lng': 1.19},
      {'name': 'Axim', 'lat': 4.87, 'lng': -2.24},
      {'name': 'Saltpond', 'lat': 5.21, 'lng': -1.06},
      {'name': 'Navrongo', 'lat': 10.89, 'lng': -1.09},
      {'name': 'Bawku', 'lat': 11.05, 'lng': -0.24},
      {'name': 'Yendi', 'lat': 9.44, 'lng': -0.01},
      {'name': 'Tumu', 'lat': 10.85, 'lng': -1.98},
    ];
    return cities.map((city) => Marker(point: LatLng(city['lat'] as double, city['lng'] as double), width: 80, height: 40, child: _CityMarkerWidget(name: city['name'] as String))).toList();
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
      return [];
    }
  }
}

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
          Image.asset(assetPath, width: 40, height: 40, errorBuilder: (context, error, stackTrace) {
            final (icon, color) = _resolve(n);
            return Icon(icon, size: 30, color: color); 
          }),
          const SizedBox(height: 2),
          Text(_cap(name), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black, shadows: [Shadow(color: Colors.white, blurRadius: 4)])),
        ],
      ),
    );
  }
  static (IconData, Color) _resolve(String n) {
    if (n.contains('rain')) return (PhosphorIcons.cloudRain(PhosphorIconsStyle.fill), Colors.blue);
    if (n.contains('wind')) return (PhosphorIcons.wind(PhosphorIconsStyle.fill), Colors.grey);
    if (n.contains('dust')) return (PhosphorIcons.dotsNine(PhosphorIconsStyle.fill), Colors.brown);
    return (PhosphorIcons.warning(PhosphorIconsStyle.fill), Colors.orange);
  }
  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class _RiskLabelWidget extends StatelessWidget {
  final String label;
  const _RiskLabelWidget({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black, shadows: [Shadow(color: Colors.white, blurRadius: 6)])));
  }
}

class _CityMarkerWidget extends StatelessWidget {
  final String name;
  const _CityMarkerWidget({required this.name});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
        Text(name, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.center),
      ],
    );
  }
}
