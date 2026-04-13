import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/controllers/coastline_forecast_controller.dart'; 

class CoastlineMapWidget extends StatelessWidget {
  final CoastlineForecastController ctrl;
  final bool isDark;

  const CoastlineMapWidget({super.key, required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TOOLBAR
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PopupMenuButton<String>(
                  tooltip: "Select Weather Condition",
                  onSelected: (iconName) => _spawnItem(MarineItemType.icon, iconName),
                  color: isDark ? Colors.grey.shade800 : Colors.white,
                  itemBuilder: (context) => [
                    _buildIconMenuItem('Rain', PhosphorIcons.cloudRain(PhosphorIconsStyle.fill)),
                    _buildIconMenuItem('Wind', PhosphorIcons.wind(PhosphorIconsStyle.fill)),
                    _buildIconMenuItem('Hail', PhosphorIcons.cloudSnow(PhosphorIconsStyle.fill)),
                    _buildIconMenuItem('Mist', PhosphorIcons.cloudFog(PhosphorIconsStyle.fill)),
                  ],
                  child: _toolbarButtonUI("Drop Weather Icon", PhosphorIcons.cloudSun(PhosphorIconsStyle.fill), Colors.blue.shade700),
                ),
                Container(width: 1, height: 20, color: Colors.grey, margin: const EdgeInsets.symmetric(horizontal: 16)),
                PopupMenuButton<String>(
                  tooltip: "Select Risk Letter",
                  onSelected: (letter) => _spawnItem(MarineItemType.text, letter),
                  color: isDark ? Colors.grey.shade800 : Colors.white,
                  itemBuilder: (context) => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'].map((letter) => PopupMenuItem(
                    value: letter, child: Text("Risk Level $letter", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  )).toList(),
                  child: _toolbarButtonUI("Drop Matrix Letter", PhosphorIcons.warning(PhosphorIconsStyle.fill), Colors.red.shade700),
                ),
              ],
            ),
          ),
        ),

        // THE MAP
        Expanded(
          child: Obx(() {
            final isDrawing = ctrl.isDrawing.value;
            return MouseRegion(
              cursor: isDrawing ? SystemMouseCursors.precise : SystemMouseCursors.basic,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
                    right: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
                  ),
                ),
                 child: FlutterMap(
                  mapController: ctrl.mapController,
                  options: MapOptions(
                    // Center adjusted to perfectly frame the Ghanaian Coastline
                    initialCenter: const LatLng(3.8, -1.0),
                    initialZoom: 6.2,
                    onTap: (tapPosition, latLng) {
                      if (isDrawing) { ctrl.saveUndoState(); ctrl.addEditablePoint(latLng); } 
                      else { ctrl.selectPolygonForEditing(latLng); }
                    },
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.gmet.weather'),
                    
                    // ==========================================================
                    // 1. EEZ GEOJSON POLYGONS
                    // ==========================================================
                    FutureBuilder<String>(
                      future: rootBundle.loadString('assets/data/marineRegionsEEZ.geojson'),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        
                        try {
                          final data = json.decode(snapshot.data!);
                          final features = data['features'] as List;
                          List<Polygon> eezPolygons = [];
                          final coordinates = features[0]['geometry']['coordinates'] as List;
                          
                          for (var poly in coordinates) {
                            var outerRing = poly[0] as List;
                            List<LatLng> points = [];
                            for (var pt in outerRing) {
                              points.add(LatLng(pt[1], pt[0]));
                            }
                            eezPolygons.add(Polygon(
                              points: points,
                              // Adapts the light blue color based on dark mode setting
                              color: isDark ? Colors.blue.withOpacity(0.1) : const Color(0xFFDDF8FF).withOpacity(0.6),
                              borderColor: Colors.lightBlue,
                              borderStrokeWidth: 1.5,
                            ));
                          }
                          return PolygonLayer(polygons: eezPolygons);
                        } catch (e) {
                          debugPrint("Error loading EEZ GeoJSON: $e");
                          return const SizedBox.shrink();
                        }
                      }
                    ),

                    // ==========================================================
                    // 2. STATIC MAP LABELS (Rotated Text)
                    // ==========================================================
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: const LatLng(4.4, -2.45), 
                          width: 140, height: 40,
                          child: Transform.rotate(
                            angle: -0.15, 
                            child: Center(child: Text("West Coast", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black87.withOpacity(0.7), letterSpacing: 1.0))),
                          ),
                        ),
                        Marker(
                          point: const LatLng(4.2, -0.9), 
                          width: 160, height: 40,
                          child: Transform.rotate(
                            angle: -0.05,
                            child: Center(child: Text("Central Coast", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black87.withOpacity(0.7), letterSpacing: 1.0))),
                          ),
                        ),
                        Marker(
                          point: const LatLng(4.8, 0.6), 
                          width: 140, height: 40,
                          child: Transform.rotate(
                            angle: -0.25, 
                            child: Center(child: Text("East Coast", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black87.withOpacity(0.7), letterSpacing: 1.0))),
                          ),
                        ),
                      ],
                    ),

                    // ==========================================================
                    // 3. EEZ INTERNAL GRID LINES (Dividers only)
                    // ==========================================================
                    PolylineLayer(
                      polylines: [
                        // Vertical Divider 1 (West / Central)
                        Polyline(
                          points: const [LatLng(4.90, -1.75), LatLng(1.30, -1.75)],
                          color: Colors.lightBlue, strokeWidth: 1.2,
                        ),
                        // Vertical Divider 2 (Central / East)
                        Polyline(
                          points: const [LatLng(5.50, -0.05), LatLng(1.70, -0.05)],
                          color: Colors.lightBlue, strokeWidth: 1.2,
                        ),
                        // Inner Horizontal Divider (Near-shore vs Deep Sea)
                        Polyline(
                          points: const [LatLng(3.80, -3.11), LatLng(3.50, -1.75), LatLng(4.10, -0.05), LatLng(4.80, 1.20)],
                          color: Colors.lightBlue, strokeWidth: 1.2,
                        ),
                      ],
                    ),

                    // ==========================================================
                    // 4. FORECASTER DRAWINGS (Polygons, Points, Icons)
                    // ==========================================================
                    PolygonLayer(polygons: ctrl.finishedRegions.map((region) => Polygon(points: region.points, color: _getColorFromString(region.color).withOpacity(0.3), borderColor: _getColorFromString(region.color), borderStrokeWidth: 1.5,)).toList()),
                    
                    if (ctrl.editablePoints.isNotEmpty)
                      PolygonLayer(polygons: [Polygon(points: ctrl.editablePoints.map((e) => e.position).toList(), color: ctrl.activeColor.withOpacity(0.3), borderColor: ctrl.activeColor, borderStrokeWidth: 1.5,)]),
                    
                    if (isDrawing)
                      MarkerLayer(
                        markers: ctrl.editablePoints.asMap().entries.map((entry) {
                          final index = entry.key; final point = entry.value;
                          return Marker(
                            point: point.position, width: 24, height: 24,
                            child: GestureDetector(
                              onSecondaryTapDown: (_) => ctrl.removeEditablePoint(index), onDoubleTap: () => ctrl.removeEditablePoint(index),
                              onPanStart: (_) => ctrl.draggedPointIndex.value = index,
                              onPanUpdate: (details) {
                                final renderBox = context.findRenderObject() as RenderBox;
                                final localPos = renderBox.globalToLocal(details.globalPosition);
                                ctrl.updateEditablePoint(index, ctrl.mapController.camera.offsetToCrs(localPos));
                              },
                              onPanEnd: (_) => ctrl.draggedPointIndex.value = null,
                              child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: ctrl.activeColor, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]), child: Center(child: Container(width: 6, height: 6, decoration: BoxDecoration(color: ctrl.activeColor, shape: BoxShape.circle)))),
                            ),
                          );
                        }).toList(),
                      ),
                      
                    MarkerLayer(
                      markers: ctrl.mapItems.map((item) => Marker(
                        point: item.position,width: 24, height: 24,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: GestureDetector(
                            onSecondaryTapDown: (_) => ctrl.deleteMapItem(item.id), onDoubleTap: () => ctrl.deleteMapItem(item.id),
                            onPanUpdate: (details) {
                              final renderBox = context.findRenderObject() as RenderBox;
                              final localPos = renderBox.globalToLocal(details.globalPosition);
                              ctrl.updateMapItemPos(item.id, ctrl.mapController.camera.offsetToCrs(localPos));
                            },
                            child: Container(color: Colors.transparent, child: Center(child: _buildItemVisual(item))),
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        // BOTTOM CONTROLS
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : Colors.white,
            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          child: Obx(() {
            if (!ctrl.isDrawing.value) {
              return Center(child: TextButton.icon(onPressed: ctrl.startDrawing, icon: Icon(PhosphorIcons.pencilSimple(), size: 16), label: const Text("Draw Risk Area", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))));
            }
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: ['green', 'yellow', 'orange', 'red'].map((cName) {
                    final isSelected = ctrl.selectedColor.value == cName;
                    return GestureDetector(
                      onTap: () => ctrl.setColor(cName),
                      child: Container(margin: const EdgeInsets.only(right: 8), width: 22, height: 22, decoration: BoxDecoration(color: _getColorFromString(cName), shape: BoxShape.circle, border: Border.all(color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent, width: 2.5))),
                    );
                  }).toList()),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      IconButton(tooltip: "Undo", icon: const Icon(Icons.undo, size: 18), onPressed: ctrl.undo, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      const SizedBox(width: 12),
                      IconButton(tooltip: "Delete", icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: ctrl.deleteActiveDrawing, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      const SizedBox(width: 12),
                      IconButton(tooltip: "Cancel", icon: const Icon(Icons.close, size: 18, color: Colors.orange), onPressed: ctrl.cancelDrawing, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      const SizedBox(width: 12),
                      TextButton.icon(onPressed: ctrl.finishDrawing, icon: const Icon(Icons.check, size: 16, color: Colors.green), label: const Text("Finish", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)), style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // Helpers
  void _spawnItem(MarineItemType type, String value) => ctrl.addMapItem(type, value, ctrl.mapController.camera.center);

  Widget _toolbarButtonUI(String label, IconData icon, Color iconCol) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade400)),
    child: Row(children: [Icon(icon, size: 16, color: isDark ? Colors.white70 : iconCol), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), const SizedBox(width: 4), const Icon(Icons.arrow_drop_down, size: 16)]),
  );

  PopupMenuItem<String> _buildIconMenuItem(String label, IconData iconData) => PopupMenuItem(value: label, child: Row(children: [Icon(iconData, size: 20, color: isDark ? Colors.white70 : Colors.black87), const SizedBox(width: 12), Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))]));

  Widget _buildItemVisual(MarineMapItem item) {
    if (item.type == MarineItemType.text) return Text(item.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black, shadows: [Shadow(color: Colors.white, blurRadius: 4), Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2)]));
    IconData iconData;
    switch (item.value) {
      case 'Rain': iconData = PhosphorIcons.cloudRain(PhosphorIconsStyle.fill); break;
      case 'Wind': iconData = PhosphorIcons.wind(PhosphorIconsStyle.fill); break;
      case 'Hail': iconData = PhosphorIcons.cloudSnow(PhosphorIconsStyle.fill); break;
      case 'Mist': iconData = PhosphorIcons.cloudFog(PhosphorIconsStyle.fill); break;
      default: iconData = PhosphorIcons.warning(PhosphorIconsStyle.fill);
    }
    return Icon(iconData, size: 20, color: Colors.black, shadows: const [Shadow(color: Colors.white, blurRadius: 4)]);
  }

   
  Color _getColorFromString(String c) {
    switch (c) { case 'red': return Colors.red; case 'orange': return Colors.orange; case 'yellow': return Colors.yellow; case 'green': return Colors.green; default: return Colors.blue; }
  }
}