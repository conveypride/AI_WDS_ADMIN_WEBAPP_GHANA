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

class CAFOImageGenerator {
  // =========================================================================
  // PUBLIC API
  // =========================================================================

  /// Renders a real FlutterMap offscreen and returns it as PNG bytes.
  ///
  /// Parameters:
  ///   [regionsData] – Firestore list: [{color, points:[{lat,lng}]}]
  ///   [itemsData]   – Firestore list: [{type,value,position:{lat,lng}}]
  ///   [context]     – any live BuildContext (used to insert Overlay)
  ///   [tileWaitMs]  – ms to wait for OSM tiles (default 3000 = 3 s)
 static Future<Uint8List?> generateMapImageFromData(
    List<dynamic>? regionsData, {
    List<dynamic>? itemsData,
    required BuildContext context,
    int tileWaitMs = 3000,
  }) async {
    final repaintKey = GlobalKey();
    final completer  = Completer<Uint8List?>();

    final polygons = _buildPolygons(regionsData ?? []);
    final markers  = _buildMarkers(itemsData   ?? []);
    
    // NEW: Load the precise border dynamically
    final preciseBorder = await _loadGhanaBorder();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left:   -4000, 
        top:    -4000,
        width:   600,  
        height:  940, 
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: repaintKey,
            child: _OffscreenMap(
              polygons: polygons,
              markers:  markers,
              ghanaBorder: preciseBorder, // NEW: Pass it down!
              onReady: () async {
                // Give OSM tiles time to paint
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
 // Safely locates the overlay through the Navigator, falling back to Overlay.maybeOf
    final overlayState = Navigator.maybeOf(context)?.overlay ?? Overlay.maybeOf(context);
    
    if (overlayState != null) {
      overlayState.insert(entry);
    } else {
      debugPrint("CRITICAL: Could not find OverlayState to insert the map renderer.");
      completer.complete(null);
    }
    
    return completer.future;
  }

  // =========================================================================
  // BUILD FLUTTER_MAP LAYERS
  // =========================================================================

  static List<Polygon> _buildPolygons(List<dynamic> regionsData) {
    final out = <Polygon>[];
    for (final r in regionsData) {
      final color  = _colorFromName((r['color'] ?? 'green').toString());
      final rawPts = (r['points'] as List<dynamic>?) ?? [];
      final points = rawPts.map<LatLng>((p) =>
          LatLng(_d(p, ['lat','latitude']), _d(p, ['lng','longitude']))).toList();
      if (points.length < 3) continue;
      out.add(Polygon(
        points:            points,
        color:             color.withOpacity(0.45),
       borderColor:       color.withOpacity(0.6), // Lighter border color
        borderStrokeWidth: 0,
      ));
    }
    return out;
  }
// =========================================================================
  // LOAD HIGH-ACCURACY GEOJSON BORDER
  // =========================================================================
  static Future<List<LatLng>> _loadGhanaBorder() async {
    try {
      // 1. Load the file from assets
      final String jsonString = await rootBundle.loadString('assets/data/geoBoundaries-GHA-ADM0.geojson');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<LatLng> points = [];

      // 2. Extract the features
      final features = data['features'] as List<dynamic>;
      if (features.isNotEmpty) {
        final geometry = features[0]['geometry'];
        final type = geometry['type'];
        final coords = geometry['coordinates'];

        // 3. GeoJSON stores coordinates as [Longitude, Latitude]
        // FlutterMap requires LatLng(Latitude, Longitude), so we flip them!
        if (type == 'Polygon') {
          for (var pt in coords[0]) {
            points.add(LatLng(pt[1], pt[0])); 
          }
        } else if (type == 'MultiPolygon') {
          // Grab the primary landmass polygon
          for (var pt in coords[0][0]) {
            points.add(LatLng(pt[1], pt[0]));
          }
        }
      }
      return points;
    } catch (e) {
      debugPrint("Error loading GeoJSON border: $e");
      return []; // Fallback to empty if it fails
    }
  }
  static List<Marker> _buildMarkers(List<dynamic> itemsData) {
    final out = <Marker>[];
    for (final item in itemsData) {
      final type  = (item['type']  ?? 'text').toString();
      final value = (item['value'] ?? '').toString();
      final pos   = item['position'];
      if (pos == null) continue;
      out.add(Marker(
        point:  LatLng(_d(pos,['lat','latitude']), _d(pos,['lng','longitude'])),
        width:  160,
        height: 160,
        child: type == 'icon'
            ? _WeatherIconWidget(name: value)
            : _RiskLabelWidget(label: value),
      ));
    }
    return out;
  }

  // =========================================================================
  // CAPTURE
  // =========================================================================

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
      debugPrint('CAFOImageGenerator._capture: $e');
      return null;
    }
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  static double _d(dynamic map, List<String> keys) {
    for (final k in keys) {
      if (map[k] != null) return (map[k] as num).toDouble();
    }
    return 0.0;
  }

  static Color _colorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'red':    return const Color(0xFFD32F2F);
      case 'orange': return const Color(0xFFE64A19);
      case 'yellow': return const Color(0xFFF9A825);
      case 'green':  return const Color(0xFF2E7D32);
      case 'blue':   return const Color(0xFF1565C0);
      case 'purple': return const Color(0xFF6A1B9A);
      default:       return const Color(0xFF2E7D32);
    }
  }

  // =========================================================================
  // LEGACY stub (keeps existing call-sites compiling)
  // =========================================================================
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
    Canvas(rec, Rect.fromLTWH(0, 0, w, h))
        .drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
    return (rec.endRecording()).toImage(w.toInt(), h.toInt());
  }
}

// =============================================================================
// _OffscreenMap  – a self-contained FlutterMap widget
// =============================================================================
class _OffscreenMap extends StatefulWidget {
  final List<Polygon> polygons;
  final List<Marker>  markers;
  final List<LatLng>  ghanaBorder; // ADD THIS
  final VoidCallback  onReady;

  const _OffscreenMap({
    required this.polygons,
    required this.markers,
    required this.ghanaBorder, // ADD THIS
    required this.onReady,
  });

  @override
  State<_OffscreenMap> createState() => _OffscreenMapState();
}

class _OffscreenMapState extends State<_OffscreenMap> {
// ADD THIS BLOCK: Ghana boundary coordinates
 

  @override
  void initState() {
    super.initState();
    // Fire after the first frame so the map widget exists in the render tree
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady());
  }
@override
Widget build(BuildContext context) {
  return FlutterMap(
    options: const MapOptions(
      initialCenter: LatLng(7.95, -1.05),
      initialZoom: 7.5,
      interactionOptions: InteractionOptions(
        flags: InteractiveFlag.none, // Static — no user interaction
      ),
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.gmet.weather_dashboard',
        errorTileCallback: (tile, error, stack) {},
      ),
      
      // ADD THIS: Grid lines (Graticules) for Latitude and Longitude
      PolylineLayer(
        polylines: _buildGridLines(),
      ),
      
      if (widget.polygons.isNotEmpty)
        PolygonLayer(polygons: widget.polygons),
        
      // Ghana Border
      if (widget.ghanaBorder.isNotEmpty)
        PolylineLayer(
          polylines: [
            Polyline(
              points: widget.ghanaBorder,
              color: Colors.black87,
              strokeWidth: 3.5,
            ),
          ],
        ),
          // ADD THIS: City markers BEFORE weather markers so they appear below
      MarkerLayer(markers: _buildCityMarkers()),
        
      if (widget.markers.isNotEmpty)
        MarkerLayer(markers: widget.markers),
        
      // ADD THIS: Text labels for Latitude and Longitude
      MarkerLayer(markers: _buildGridLabels()),
    ],
  );
}

// ADD THESE HELPER METHODS:
// ADD THIS METHOD: Build prominent city markers
List<Marker> _buildCityMarkers() {
  // Major cities in Ghana with their coordinates
  final cities = [
    {'name': 'Accra', 'lat': 5.6037, 'lng': -0.1870},
    {'name': 'Kumasi', 'lat': 6.6885, 'lng': -1.6244},
    {'name': 'Tamale', 'lat': 9.4034, 'lng': -0.8424},
    {'name': 'Takoradi', 'lat': 4.8845, 'lng': -1.7554},
    {'name': 'Cape Coast', 'lat': 5.1053, 'lng': -1.2466},
    {'name': 'Sunyani', 'lat': 7.3397, 'lng': -2.3269},
    {'name': 'Koforidua', 'lat': 6.0942, 'lng': -0.2597},
    {'name': 'Wa', 'lat': 10.0601, 'lng': -2.5097},
    {'name': 'Bolgatanga', 'lat': 10.7856, 'lng': -0.8514},
    {'name': 'Ho', 'lat': 6.6108, 'lng': 0.4710},
    {'name': 'Techiman', 'lat': 7.5892, 'lng': -1.9381},
  ];

  return cities.map((city) {
    return Marker(
      point: LatLng(city['lat'] as double, city['lng'] as double),
      width: 80,
      height: 49,
      child: _CityMarkerWidget(name: city['name'] as String),
    );
  }).toList();
}



/// Build grid lines for latitude and longitude
List<Polyline> _buildGridLines() {
  final List<Polyline> gridLines = [];
  const gridColor = Color(0xFF9E9E9E); // Grey color for grid lines
  const strokeWidth = 0.8;

  // Latitude lines (horizontal) - from 4°N to 12°N
  for (double lat = 4.0; lat <= 12.0; lat += 2.0) {
    gridLines.add(
      Polyline(
        points: [
          LatLng(lat, -3.5),
          LatLng(lat, 1.5),
        ],
        color: gridColor,
        strokeWidth: strokeWidth,
      ),
    );
  }

  // Longitude lines (vertical) - from -4°W to 2°E
  for (double lng = -3.0; lng <= 1.0; lng += 1.0) {
    gridLines.add(
      Polyline(
        points: [
          LatLng(4.0, lng),
          LatLng(12.0, lng),
        ],
        color: gridColor,
        strokeWidth: strokeWidth,
      ),
    );
  }

  return gridLines;
}

/// Build text labels for latitude and longitude grid
List<Marker> _buildGridLabels() {
  final List<Marker> labels = [];
  
  // Latitude labels (on the left side)
  for (double lat = 4.0; lat <= 12.0; lat += 2.0) {
    labels.add(
      Marker(
        point: LatLng(lat, -3.3), // Position on the left
        width: 40,
        height: 20,
        child: Container(
          alignment: Alignment.centerRight,
          child: Text(
            '${lat.toInt()}°N',
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              backgroundColor: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  // Longitude labels (on the bottom)
  for (double lng = -3.0; lng <= 1.0; lng += 1.0) {
    String label = lng < 0 
        ? '${lng.abs().toInt()}°W' 
        : lng == 0 
            ? '0°' 
            : '${lng.toInt()}°E';
    
    labels.add(
      Marker(
        point: LatLng(4.2, lng), // Position at the bottom
        width: 40,
        height: 20,
        child: Container(
          alignment: Alignment.topCenter,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              backgroundColor: Colors.white70,
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
// _WeatherIconWidget  – Uses custom image assets for weather icons
// =============================================================================

class _WeatherIconWidget extends StatelessWidget {
  final String name;
  const _WeatherIconWidget({required this.name});

  @override
  Widget build(BuildContext context) {
    final n = name.toLowerCase();
    
    // Assumes your individual icon images are named exactly like the dropdown values
    // e.g., 'assets/images/rain.png', 'assets/images/wind.png', etc.
    String assetPath = 'assets/images/$n.png';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Attempt to load the custom image asset
        Image.asset(
          assetPath,
          width: 100,
          height: 100,
          // If the image isn't found in assets, fallback to a PhosphorIcon gracefully
          errorBuilder: (context, error, stackTrace) {
            final (icon, color) = _resolve(n);
            return Icon(icon, size: 40, color: color);
          },
        ),
        const SizedBox(height: 2),
        // Text label right beneath the icon (e.g., "Dust", "Mist")
        Text(
          _cap(name),
          style: const TextStyle(
            fontSize: 30, 
            fontWeight: FontWeight.w900, 
            color: Colors.black,
            // Slight white shadow to ensure it is readable over dark polygons
            shadows: [Shadow(color: Colors.white, blurRadius: 3)],
          ),
        ),
      ],
    );
  }

  // Fallback resolver if the PNG image is missing from your assets folder
  static (IconData, Color) _resolve(String n) {
    if (n.contains('rain')) return (PhosphorIcons.cloudRain(PhosphorIconsStyle.fill), const Color(0xFF1565C0));
    if (n.contains('wind')) return (PhosphorIcons.wind(PhosphorIconsStyle.fill), const Color(0xFF546E7A));
    if (n.contains('dust') || n.contains('haze')) return (PhosphorIcons.dotsNine(PhosphorIconsStyle.fill), const Color(0xFFBF6F00));
    if (n.contains('hail')) return (PhosphorIcons.cloudSnow(PhosphorIconsStyle.fill), const Color(0xFF0277BD));
    if (n.contains('fog') || n.contains('mist')) return (PhosphorIcons.cloudFog(PhosphorIconsStyle.fill), const Color(0xFF546E7A));
    if (n.contains('cloud')) return (PhosphorIcons.cloud(PhosphorIconsStyle.fill), const Color(0xFF78909C));
    return (PhosphorIcons.sun(PhosphorIconsStyle.fill), const Color(0xFFF9A825));
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

// =============================================================================
// _RiskLabelWidget  – Large, bold, free-floating text (No circle background)
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
          fontSize: 45, // INCREASED from 28 for bigger, bolder letters
          fontWeight: FontWeight.w900,
          color: Colors.black,
          shadows: [
            // Strong white shadow for contrast
            Shadow(color: Colors.white, blurRadius: 8, offset: Offset(0,0)),
            Shadow(color: Colors.white, blurRadius: 8, offset: Offset(0,0)),
            Shadow(color: Colors.white, blurRadius: 8, offset: Offset(0,0)),
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
        // Larger, more visible dot
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 3,
                spreadRadius: 1.5,
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Clearer label with better contrast
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: ui.Color.fromARGB(255, 19, 1, 109),
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}