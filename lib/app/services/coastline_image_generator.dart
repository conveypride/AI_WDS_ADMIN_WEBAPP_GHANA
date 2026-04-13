import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CoastlineImageGenerator {
  /// Generates a single map image matching the Coastline IBF format
  static Future<Uint8List?> generateMapImage({
    required List<dynamic> mapRegions,
    required List<dynamic> mapItems,
    required BuildContext context,
    int tileWaitMs = 3000, 
  }) async {
    final repaintKey = GlobalKey();
    final completer = Completer<Uint8List?>();

    // ==========================================
    // PARSE EEZ GEOJSON
    // ==========================================
    List<Polygon> eezPolygons = [];
    try {
      // Ensure this path matches where you put the JSON file in your assets
      final String geoJsonStr = await rootBundle.loadString('assets/data/marineRegionsEEZ.geojson');
      final data = json.decode(geoJsonStr);
      final features = data['features'] as List;
      
      // Parse the MultiPolygon coordinates
      final coordinates = features[0]['geometry']['coordinates'] as List;
      for (var poly in coordinates) {
        var outerRing = poly[0] as List; // Extract the outer boundary ring
        List<LatLng> points = [];
        for (var pt in outerRing) {
          // GeoJSON is [longitude, latitude], LatLng requires (latitude, longitude)
          points.add(LatLng(pt[1], pt[0]));
        }
        eezPolygons.add(Polygon(
          points: points,
          color: const Color(0xFFDDF8FF), // Light cyan/blue matching the image
          borderColor: Colors.lightBlue,
          borderStrokeWidth: 1.5,
        ));
      }
    } catch (e) {
      debugPrint("Error loading EEZ GeoJSON: $e");
    }

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
              width: 1000,  
              height: 750, 
              color: Colors.white,
              child: _buildSingleMap(mapRegions, mapItems, eezPolygons),
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
        final image = await boundary.toImage(pixelRatio: 2.0); 
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

  static Widget _buildSingleMap(List<dynamic> regions, List<dynamic> items, List<Polygon> eezPolygons) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // ==========================================
          // THE BASE MAP & LAYERS
          // ==========================================
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(3.8, -1.0),
              initialZoom: 6.8,
              interactionOptions: InteractionOptions(flags: InteractiveFlag.none), // Static
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gmet.weather_dashboard',
                errorTileCallback: (tile, error, stack) {},
              ),
              
              // 1. EEZ GEOJSON POLYGONS
              if (eezPolygons.isNotEmpty)
                PolygonLayer(polygons: eezPolygons),

              // 2. EEZ INTERNAL GRID LINES
              PolylineLayer(
                polylines: [
                  Polyline(points: const [LatLng(4.90, -1.75), LatLng(1.30, -1.75)], color: Colors.lightBlue, strokeWidth: 1.0), // West/Central separator
                  Polyline(points: const [LatLng(5.50, -0.05), LatLng(1.70, -0.05)], color: Colors.lightBlue, strokeWidth: 1.0), // Central/East separator
                  Polyline(points: const [LatLng(3.80, -3.11), LatLng(3.50, -1.75), LatLng(4.10, -0.05), LatLng(4.80, 1.20)], color: Colors.lightBlue, strokeWidth: 1.0), // Horizontal coast offset line
                ],
              ),

              // 3. STATIC LABELS
              MarkerLayer(
                markers: [
                  Marker(point: const LatLng(4.4, -2.45), width: 140, height: 40, child: Transform.rotate(angle: -0.15, child: Center(child: Text("West Coast", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87.withOpacity(0.7), letterSpacing: 1.0))))),
                  Marker(point: const LatLng(4.2, -0.9), width: 160, height: 40, child: Transform.rotate(angle: -0.05, child: Center(child: Text("Central Coast", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87.withOpacity(0.7), letterSpacing: 1.0))))),
                  Marker(point: const LatLng(4.8, 0.6), width: 140, height: 40, child: Transform.rotate(angle: -0.25, child: Center(child: Text("East Coast", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87.withOpacity(0.7), letterSpacing: 1.0))))),
                ],
              ),

              // 4. DRAWN FORECASTER REGIONS
              if (regions.isNotEmpty)
                PolygonLayer(
                  polygons: regions.map((r) {
                    final points = (r['points'] as List).map((p) => LatLng(p['lat'], p['lng'])).toList();
                    final color = _getRiskColor(r['color']);
                    return Polygon(
                      points: points,
                      color: color.withOpacity(0.4),
                      borderColor: color,
                      borderStrokeWidth: 2.0,
                    );
                  }).toList(),
                ),
                
              // 5. DRAWN ITEMS/ICONS
              if (items.isNotEmpty)
                MarkerLayer(
                  markers: items.map((m) {
                    return Marker(
                      point: LatLng(m['lat'], m['lng']),
                      width: 80,
                      height: 80,
                      child: _buildMapIcon(m),
                    );
                  }).toList(),
                ),
            ],
          ),

          // ==========================================
          // COMPASS ICON (TOP RIGHT)
          // ==========================================
          Positioned(
            top: 20,
            right: 20,
            child: Image.asset(
              'assets/images/compass.png',
              width: 180,
              height: 180,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.explore, size: 80, color: Colors.black87);
              },
            ),
          ),

          // ==========================================
          // SCALE ICON (BOTTOM RIGHT)
          // ==========================================
          Positioned(
            bottom: 30,
            right: 20,
            child: Image.asset(
              'assets/images/scale.png',
              width: 200,
              height: 130,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 30,
                  width: 200,
                  alignment: Alignment.bottomCenter,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 3),
                      left: BorderSide(width: 2),
                      right: BorderSide(width: 2),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      "0       25       50       100 km", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Color _getRiskColor(String? colorStr) {
    switch (colorStr?.toLowerCase()) {
      case 'red': return const Color(0xFFD32F2F);
      case 'orange': return const Color(0xFFE64A19);
      case 'yellow': return const Color(0xFFF9A825);
      case 'green': return const Color(0xFF2E7D32);
      default: return const Color(0xFF1565C0);
    }
  }

  static Widget _buildMapIcon(Map<String, dynamic> item) {
    if (item['type'] == 'icon') {
      return _WeatherIconWidget(name: item['value']);
    } else {
      return _RiskLabelWidget(label: item['value']);
    }
  }
}

// =============================================================================
// SAFE WEATHER ICON WIDGET (Prevents HTML Image Crashes)
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
            width: 40, height: 40,
            errorBuilder: (context, error, stackTrace) {
              final (icon, color) = _resolve(n);
              return Icon(icon, size: 36, color: color); 
            },
          ),
        ],
      ),
    );
  }

  static (IconData, Color) _resolve(String n) {
    if (n.contains('rain')) return (PhosphorIcons.cloudRain(PhosphorIconsStyle.fill), const Color(0xFF1565C0));
    if (n.contains('wind')) return (PhosphorIcons.wind(PhosphorIconsStyle.fill), const Color(0xFF546E7A));
    if (n.contains('hail')) return (PhosphorIcons.cloudSnow(PhosphorIconsStyle.fill), const Color(0xFF0277BD));
    if (n.contains('mist')) return (PhosphorIcons.cloudFog(PhosphorIconsStyle.fill), const Color(0xFF546E7A));
    return (PhosphorIcons.warning(PhosphorIconsStyle.fill), const Color(0xFFD32F2F));
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
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
          fontSize: 36,
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