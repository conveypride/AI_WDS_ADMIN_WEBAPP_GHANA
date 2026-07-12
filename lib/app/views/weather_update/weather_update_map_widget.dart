import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:weather_admin_dashboard/app/controllers/weather_update_controller.dart';
import 'package:weather_admin_dashboard/app/model/weeklyItemType.dart';
import 'package:weather_admin_dashboard/app/model/weather_update_map_item.dart'; 

class WeatherUpdateMapWidget extends StatelessWidget {
  final WeatherUpdateController ctrl;
  final bool isDark;

  const WeatherUpdateMapWidget({
    super.key, 
    required this.ctrl, 
    required this.isDark
  });

  @override
  Widget build(BuildContext context) {
    final mapController = ctrl.mapController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TOOLBAR
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PopupMenuButton<String>(
                tooltip: "Select Weather Condition",
                onSelected: (iconName) => _spawnItem(WeeklyItemType.icon, iconName, mapController),
                color: isDark ? Colors.grey.shade800 : Colors.white,
                itemBuilder: (context) => [
                  _buildIconMenuItem('Rain', PhosphorIcons.cloudRain(PhosphorIconsStyle.fill)),
                  _buildIconMenuItem('Wind', PhosphorIcons.wind(PhosphorIconsStyle.fill)),
                  _buildIconMenuItem('Dust', PhosphorIcons.dotsNine(PhosphorIconsStyle.fill)),
                  _buildIconMenuItem('Hail', PhosphorIcons.cloudSnow(PhosphorIconsStyle.fill)),
                  _buildIconMenuItem('Mist', PhosphorIcons.cloudFog(PhosphorIconsStyle.fill)),
                ],
                child: _toolbarButtonUI("Icon", PhosphorIcons.cloudSun(PhosphorIconsStyle.fill), Colors.blue.shade700),
              ),
              Container(width: 1, height: 20, color: Colors.grey, margin: const EdgeInsets.symmetric(horizontal: 8)),
              PopupMenuButton<String>(
                tooltip: "Select Risk Letter",
                onSelected: (letter) => _spawnItem(WeeklyItemType.text, letter, mapController),
                color: isDark ? Colors.grey.shade800 : Colors.white,
                itemBuilder: (context) => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'].map((letter) => PopupMenuItem(
                  value: letter, child: Text("Risk Level $letter", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                )).toList(),
                child: _toolbarButtonUI("Matrix", PhosphorIcons.warning(PhosphorIconsStyle.fill), Colors.red.shade700),
              ),
            ],
          ),
        ),

        // THE MAP
        Expanded(
          child: Obx(() {
            final isDrawing = ctrl.isDrawing.value;
            final activePoints = ctrl.editablePoints;
            final regions = ctrl.finishedRegions;
            final items = ctrl.mapItems;

            return MouseRegion(
              cursor: isDrawing ? SystemMouseCursors.precise : SystemMouseCursors.basic,
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: const LatLng(7.9465, -1.0232),
                  initialZoom: 6.5,
                  onTap: (tapPosition, latLng) {
                    if (isDrawing) {
                      ctrl.saveUndoState();
                      ctrl.addEditablePoint(latLng);
                    } else {
                      ctrl.selectPolygonForEditing(latLng);
                    }
                  },
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.gmet.weather'),
                  
                  PolygonLayer(
                    polygons: regions.map((region) => Polygon(points: region.points, color: _getColorFromString(region.color).withOpacity(0.3), borderColor: _getColorFromString(region.color), borderStrokeWidth: 0.3)).toList(),
                  ),

                  if (activePoints.isNotEmpty)
                    PolygonLayer(
                      polygons: [Polygon(points: activePoints.map((e) => e.position).toList(), color: ctrl.activeColor.withOpacity(0.3), borderColor: ctrl.activeColor, borderStrokeWidth: 0.3)]
                    ),

                  if (isDrawing)
                    MarkerLayer(
                      markers: activePoints.asMap().entries.map((entry) {
                        final index = entry.key;
                        final point = entry.value;
                        return Marker(
                          point: point.position, width: 24, height: 24,
                          child: GestureDetector(
                            onSecondaryTapDown: (_) => ctrl.removeEditablePoint(index),
                            onDoubleTap: () => ctrl.removeEditablePoint(index),
                            onPanStart: (_) => ctrl.draggedPointIndex.value = index,
                            onPanUpdate: (details) {
                              final renderBox = context.findRenderObject() as RenderBox;
                              final localPos = renderBox.globalToLocal(details.globalPosition);
                              ctrl.updateEditablePoint(index, mapController.camera.offsetToCrs(localPos));
                            },
                            onPanEnd: (_) => ctrl.draggedPointIndex.value = null,
                            child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: ctrl.activeColor, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]), child: Center(child: Container(width: 6, height: 6, decoration: BoxDecoration(color: ctrl.activeColor, shape: BoxShape.circle)))),
                          ),
                        );
                      }).toList(),
                    ),

                  MarkerLayer(
                    markers: items.map((item) => Marker(
                      point: item.position, width: 24, height: 24,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: GestureDetector(
                          onSecondaryTapDown: (_) => ctrl.deleteMapItem(item.id),
                          onDoubleTap: () => ctrl.deleteMapItem(item.id),
                          onPanUpdate: (details) {
                            final renderBox = context.findRenderObject() as RenderBox;
                            final localPos = renderBox.globalToLocal(details.globalPosition);
                            ctrl.updateMapItemPos(item.id, mapController.camera.offsetToCrs(localPos));
                          },
                          child: Container(color: Colors.transparent, child: Center(child: _buildItemVisual(item))),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            );
          }),
        ),

        // BOTTOM CONTROLS
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : Colors.white,
            border: Border(
              top: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
            ),
          ),
          child: Obx(() {
            final isDrawing = ctrl.isDrawing.value;

            if (!isDrawing) {
              return Center(child: TextButton.icon(onPressed: () => ctrl.startDrawing(), icon: Icon(PhosphorIcons.pencilSimple(), size: 16), label: const Text("Draw Risk Area", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))));
            }

            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: ['green', 'yellow', 'orange', 'red'].map((cName) {
                      final isSelected = ctrl.selectedColor.value == cName;
                      return GestureDetector(
                        onTap: () => ctrl.setColor(cName),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6), width: 20, height: 20,
                          decoration: BoxDecoration(color: _getColorFromString(cName), shape: BoxShape.circle, border: Border.all(color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent, width: 2)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      IconButton(tooltip: "Undo", icon: const Icon(Icons.undo, size: 16), onPressed: () => ctrl.undo(), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      const SizedBox(width: 8),
                      IconButton(tooltip: "Delete", icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red), onPressed: () => ctrl.deleteActiveDrawing(), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      const SizedBox(width: 8),
                      IconButton(tooltip: "Cancel", icon: const Icon(Icons.close, size: 16, color: Colors.orange), onPressed: () => ctrl.cancelDrawing(), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      const SizedBox(width: 8),
                      TextButton.icon(onPressed: () => ctrl.finishDrawing(), icon: const Icon(Icons.check, size: 14, color: Colors.green), label: const Text("Finish", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)), style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero)),
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

  void _spawnItem(WeeklyItemType type, String value, MapController mapCtrl) => ctrl.addMapItem(type, value, mapCtrl.camera.center);

  Widget _toolbarButtonUI(String label, IconData icon, Color iconCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade400)),
      child: Row(children: [Icon(icon, size: 14, color: isDark ? Colors.white70 : iconCol), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), const SizedBox(width: 2), const Icon(Icons.arrow_drop_down, size: 14)]),
    );
  }

  PopupMenuItem<String> _buildIconMenuItem(String label, IconData iconData) {
    return PopupMenuItem(value: label, child: Row(children: [Icon(iconData, size: 20, color: isDark ? Colors.white70 : Colors.black87), const SizedBox(width: 12), Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))]));
  }

  Widget _buildItemVisual(WeatherUpdateMapItem item) {
    if (item.type == WeeklyItemType.text) return Text(item.value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black, shadows: const [Shadow(color: Colors.white, blurRadius: 4), Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2)]));
    IconData iconData;
    switch (item.value) {
      case 'Rain': iconData = PhosphorIcons.cloudRain(PhosphorIconsStyle.fill); break;
      case 'Wind': iconData = PhosphorIcons.wind(PhosphorIconsStyle.fill); break;
      case 'Dust': iconData = PhosphorIcons.dotsNine(PhosphorIconsStyle.fill); break;
      case 'Hail': iconData = PhosphorIcons.cloudSnow(PhosphorIconsStyle.fill); break;
      case 'Mist': iconData = PhosphorIcons.cloudFog(PhosphorIconsStyle.fill); break;
      default: iconData = PhosphorIcons.warning(PhosphorIconsStyle.fill);
    }
    return Icon(iconData, size: 20, color: Colors.black, shadows: const [Shadow(color: Colors.white, blurRadius: 4)]);
  }

  Color _getColorFromString(String c) {
    switch (c) {
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      case 'yellow': return Colors.yellow;
      case 'green': return Colors.green;
      default: return Colors.blue;
    }
  }
}
