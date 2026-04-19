import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class InlandImageGenerator {
  // =========================================================================
  // PUBLIC API
  // =========================================================================

  static Future<Uint8List?> generateMapImageFromData(
    List<dynamic>? regionsData, {
    List<dynamic>? itemsData,
    required BuildContext context,
    int tileWaitMs = 500,
  }) async {
    final repaintKey = GlobalKey();
    final completer = Completer<Uint8List?>();

    final polygons = _buildPolygons(regionsData ?? []);
    final markers = _buildMarkers(itemsData ?? []);

    // 1. Load exact geometry using a robust Polygon parser
    // final ghanaPolygons = await _parseGeoJsonPolygons(
    //   'assets/data/geoBoundaries-GHA-ADM0.geojson',
    //   fillColor: Colors.transparent,
    //   borderColor: Colors.black,
    //   strokeWidth: 2.5,
    // );

    // final lakePolygons = await _parseGeoJsonPolygons(
    //   'assets/data/lake_volta.geojson',
    //   fillColor: const ui.Color.fromARGB(255, 255, 255, 255), // Exact Navy Blue
    //   borderColor: const Color(0xFF000080),
    //   strokeWidth: 1.0,
    // );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -4000,
        top: -4000,
        width: 600,
        height: 850,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: repaintKey,
            child: _OffscreenMap(
              polygons: polygons,
              markers: markers,
              // ghanaPolygons: ghanaPolygons,
              // lakePolygons: lakePolygons,
              onReady: () async {
                await Future.delayed(Duration(milliseconds: tileWaitMs));
                final bytes = await _capture(repaintKey);
                entry.remove();
                completer.complete(bytes);
              },
            ),
          ),
        ),
      ),
    );

    final overlayState =
        Navigator.maybeOf(context)?.overlay ?? Overlay.maybeOf(context);

    if (overlayState != null) {
      overlayState.insert(entry);
    } else {
      debugPrint(
        "CRITICAL: Could not find OverlayState to insert the map renderer.",
      );
      completer.complete(null);
    }

    return completer.future;
  }

  // =========================================================================
  // ROBUST GEOJSON PARSER
  // =========================================================================

  // static Future<List<Polygon>> _parseGeoJsonPolygons(
  //   String path, {
  //   required Color fillColor,
  //   required Color borderColor,
  //   required double strokeWidth,
  // }) async {
  //   final List<Polygon> polys = [];
  //   try {
  //     final String jsonString = await rootBundle.loadString(path);
  //     final Map<String, dynamic> data = jsonDecode(jsonString);
  //     final features = data['features'] as List<dynamic>? ?? [];

  //     for (var feature in features) {
  //       final geometry = feature['geometry'];
  //       if (geometry == null) continue;
  //       final type = geometry['type'];
  //       final coords = geometry['coordinates'];

  //       if (type == 'Polygon') {
  //         final List<LatLng> pts = [];
  //         for (var pt in coords[0]) { pts.add(LatLng(pt[1], pt[0])); }
  //         polys.add(Polygon(points: pts, color: fillColor, borderColor: borderColor, borderStrokeWidth: strokeWidth));
  //       } else if (type == 'MultiPolygon') {
  //         for (var poly in coords) {
  //           final List<LatLng> pts = [];
  //           for (var pt in poly[0]) { pts.add(LatLng(pt[1], pt[0])); }
  //           polys.add(Polygon(points: pts, color: fillColor, borderColor: borderColor, borderStrokeWidth: strokeWidth));
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint("Error loading GeoJSON $path: $e");
  //   }
  //   return polys;
  // }

  // =========================================================================
  // BUILD FLUTTER_MAP LAYERS
  // =========================================================================

  static List<Polygon> _buildPolygons(List<dynamic> regionsData) {
    final out = <Polygon>[];
    for (final r in regionsData) {
      final color = _colorFromName((r['color'] ?? 'green').toString());
      final rawPts = (r['points'] as List<dynamic>?) ?? [];
      final points = rawPts
          .map<LatLng>(
            (p) =>
                LatLng(_d(p, ['lat', 'latitude']), _d(p, ['lng', 'longitude'])),
          )
          .toList();
      if (points.length < 3) continue;
      out.add(
        Polygon(
          points: points,
          color: color.withOpacity(
            0.55,
          ), // CHANGED: Reduced from 0.65 to 0.55 for lighter transparency matching target
          borderColor: Colors.transparent,
          borderStrokeWidth: 0,
        ),
      );
    }
    return out;
  }

  static List<Marker> _buildMarkers(List<dynamic> itemsData) {
    final out = <Marker>[];
    for (final item in itemsData) {
      final type = (item['type'] ?? 'text').toString();
      final value = (item['value'] ?? '').toString();
      final pos = item['position'];
      if (pos == null) continue;
      out.add(
        Marker(
          point: LatLng(
            _d(pos, ['lat', 'latitude']),
            _d(pos, ['lng', 'longitude']),
          ),
          width: 160,
          height: 160,
          child: type == 'icon'
              ? _WeatherIconWidget(name: value)
              : _RiskLabelWidget(label: value),
        ),
      );
    }
    return out;
  }

  static Future<Uint8List?> _capture(GlobalKey key) async {
    try {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image img = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? bd = await img.toByteData(format: ui.ImageByteFormat.png);
      return bd?.buffer.asUint8List();
    } catch (e) {
      debugPrint('InlandImageGenerator._capture: $e');
      return null;
    }
  }

  static double _d(dynamic map, List<String> keys) {
    for (final k in keys) {
      if (map[k] != null) return (map[k] as num).toDouble();
    }
    return 0.0;
  }

  static Color _colorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'red':
        return const Color(0xFFD32F2F);
      case 'orange':
        return const Color(0xFFE64A19);
      case 'yellow':
        return const Color(0xFFF9A825);
      case 'green':
        return const Color(0xFF2E7D32);
      case 'blue':
        return const Color(0xFF1565C0);
      case 'purple':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  static Future<ui.Image> generateForecastImage({
    required String date,
    required String timeIssued,
    required String validFrom,
    required Map<String, dynamic> temperatures,
    required String summary,
    required String nb,
    required String caution,
    required List<dynamic> afternoonRegions,
    required List<dynamic> eveningRegions,
    required List<dynamic> morningRegions,
  }) async {
    const double w = 1200, h = 1600;
    final rec = ui.PictureRecorder();
    Canvas(
      rec,
      Rect.fromLTWH(0, 0, w, h),
    ).drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
    return (rec.endRecording()).toImage(w.toInt(), h.toInt());
  }
}

// =============================================================================
// _OffscreenMap
// =============================================================================
class _OffscreenMap extends StatefulWidget {
  final List<Polygon> polygons;
  final List<Marker> markers;
  // final List<Polygon> ghanaPolygons;
  // final List<Polygon> lakePolygons;
  final VoidCallback onReady;

  const _OffscreenMap({
    required this.polygons,
    required this.markers,
    // required this.ghanaPolygons,
    // required this.lakePolygons,
    required this.onReady,
  });

  @override
  State<_OffscreenMap> createState() => _OffscreenMapState();
}

class _OffscreenMapState extends State<_OffscreenMap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const ui.Color.fromARGB(86, 255, 255, 255), // Pure white background
      child: FlutterMap(
        options: const MapOptions(
          // CHANGED: Updated center and zoom to focus tightly on Lake Volta, matching target image
          initialCenter: LatLng(
            7.5,
            -0.3,
          ), // Shifted slightly north for better lake framing
          initialZoom:
              8.5, // Slightly tighter zoom to focus on lake area (was 7.0)
          interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          TileLayer(
        urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.gmet.weather_dashboard',
        errorTileCallback: (tile, error, stack) {},
      ),
      
          // Grid lines for Latitude and Longitude reference
          PolylineLayer(polylines: _buildGridLines()),

          if (widget.polygons.isNotEmpty)
            PolygonLayer(polygons: widget.polygons),

          // Ghana Lake Border

          // ADD THIS: City markers BEFORE weather markers so they appear below
          MarkerLayer(markers: _buildCityMarkers()),

          if (widget.markers.isNotEmpty) MarkerLayer(markers: widget.markers),

          // ADD THIS: Text labels for Latitude and Longitude
          MarkerLayer(markers: _buildGridLabels()),
        ],
      ),
    );
  }

  // --- HELPERS ---

  List<Marker> _buildCityMarkers() {
    final cities = [
      {'name': 'Koforidua', 'lat': 6.0942, 'lng': -0.2597}, // South of lake
      {'name': 'Ho', 'lat': 6.6108, 'lng': 0.4710}, // East of lake
      {'name': 'Sokpoe', 'lat': 6.60, 'lng': -0.50}, // Southeast shore
      {'name': 'Jasikan', 'lat': 7.42, 'lng': 0.30}, // East shore
      {'name': 'Yeji', 'lat': 7.8333, 'lng': -0.0667}, // Center on lake
      {'name': 'Kete Krachi', 'lat': 7.8000, 'lng': -0.0333}, // On lake
      {'name': 'Buipe', 'lat': 8.75, 'lng': -1.72}, // Northwest on lake
    ];

    return cities.map((city) {
      return Marker(
        point: LatLng(city['lat'] as double, city['lng'] as double),
        width: 80,
        height: 40,
        child: _CityMarkerWidget(name: city['name'] as String),
      );
    }).toList();
  }

  List<Polyline> _buildGridLines() {
    final List<Polyline> gridLines = [];
    const gridColor = Color(0xFFE0E0E0);
    const strokeWidth = 1.0;

    for (double lat = 6.0; lat <= 9.0; lat += 1.0) {
      gridLines.add(
        Polyline(
          points: [LatLng(lat, -3.5), LatLng(lat, 1.5)],
          color: gridColor,
          strokeWidth: strokeWidth,
        ),
      );
    }
    for (double lng = -1.5; lng <= 1.5; lng += 0.5) {
      gridLines.add(
        Polyline(
          points: [LatLng(4.5, lng), LatLng(11.5, lng)],
          color: gridColor,
          strokeWidth: strokeWidth,
        ),
      );
    }
    return gridLines;
  }

  List<Marker> _buildGridLabels() {
    // CHANGED: Updated to only show labels visible in the zoomed Lake Volta view
    // Added white shadows for better visibility
    final List<Marker> labels = [];

    // Only show latitude labels that will be visible in the zoomed view (6-9°N)
    for (double lat = 6.0; lat <= 9.0; lat += 1.0) {
      labels.add(
        Marker(
          point: LatLng(lat, -1.2), // Positioned closer to the visible area
          width: 35,
          height: 18,
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '${lat.toInt()}°N',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.white70, blurRadius: 2)],
              ),
            ),
          ),
        ),
      );
    }

    // Only show longitude labels that will be visible in the zoomed view (-1 to 1°)
    for (double lng = -1.0; lng <= 1.0; lng += 1.0) {
      String label = lng < 0
          ? '${lng.abs().toInt()}°W'
          : lng == 0
          ? '0°'
          : '${lng.toInt()}°E';
      labels.add(
        Marker(
          point: LatLng(6.3, lng), // Positioned in the visible lower area
          width: 35,
          height: 18,
          child: Container(
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.white70, blurRadius: 2)],
              ),
            ),
          ),
        ),
      );
    }
    return labels;
  }
}

// =============================================================================
// WIDGETS
// =============================================================================

class _WeatherIconWidget extends StatelessWidget {
  final String name;
  const _WeatherIconWidget({required this.name});

  @override
  Widget build(BuildContext context) {
    final n = name.toLowerCase();
    String assetPath = 'assets/images/$n.png';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          assetPath,
          width: 80,
          height: 80,
          errorBuilder: (context, error, stackTrace) {
            final (icon, color) = _resolve(n);
            return Icon(icon, size: 40, color: color);
          },
        ),
        Text(
          _cap(name),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            shadows: [Shadow(color: Colors.white, blurRadius: 3)],
          ),
        ),
      ],
    );
  }

  static (IconData, Color) _resolve(String n) {
    if (n.contains('rain')) {
      return (
        PhosphorIcons.cloudRain(PhosphorIconsStyle.fill),
        const Color(0xFF1565C0),
      );
    }
    if (n.contains('wind')) {
      return (
        PhosphorIcons.wind(PhosphorIconsStyle.fill),
        const Color(0xFF546E7A),
      );
    }
    if (n.contains('dust') || n.contains('haze')) {
      return (
        PhosphorIcons.dotsNine(PhosphorIconsStyle.fill),
        const Color(0xFFBF6F00),
      );
    }
    if (n.contains('hail')) {
      return (
        PhosphorIcons.cloudSnow(PhosphorIconsStyle.fill),
        const Color(0xFF0277BD),
      );
    }
    if (n.contains('fog') || n.contains('mist')) {
      return (
        PhosphorIcons.cloudFog(PhosphorIconsStyle.fill),
        const Color(0xFF546E7A),
      );
    }
    if (n.contains('cloud')) {
      return (
        PhosphorIcons.cloud(PhosphorIconsStyle.fill),
        const Color(0xFF78909C),
      );
    }
    return (
      PhosphorIcons.sun(PhosphorIconsStyle.fill),
      const Color(0xFFF9A825),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class _RiskLabelWidget extends StatelessWidget {
  final String label;
  const _RiskLabelWidget({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 35,
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
          ),
        ),
        const SizedBox(height: 3),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            shadows: const [
              Shadow(color: Colors.white, blurRadius: 4, offset: Offset(0, 0)),
              Shadow(color: Colors.white, blurRadius: 4, offset: Offset(0, 0)),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

