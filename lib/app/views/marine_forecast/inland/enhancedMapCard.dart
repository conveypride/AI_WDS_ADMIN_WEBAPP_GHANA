import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/controllers/inland_forecast_controller.dart';


class EnhancedMapCard extends StatelessWidget {
  final InlandForecastController ctrl;
  final String period;
  final String dateLabel;
  final bool isDark;

  const EnhancedMapCard({
    super.key,
    required this.ctrl,
    required this.period,
    required this.dateLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final mapController = ctrl.getMapControllerForPeriod(period);

    return SizedBox(
      height: 480, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Map Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
            ),
            child: Text(
              "${period.toUpperCase()} ($dateLabel)",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black87),
            ),
          ),

          // UPDATED: Icon & Risk Letter Toolbar
         // CLEANED UP: Icon & Risk Letter Dropdown Toolbar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                border: Border(
                  left: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
                  right: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
                ),
              ),
              child:  SingleChildScrollView(
            scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Centers the two dropdowns
                  children: [
                    // 1. Weather Icon Dropdown
                    PopupMenuButton<String>(
                      tooltip: "Select Weather Condition",
                      onSelected: (iconName) => _spawnItem(MapItemType.icon, iconName, mapController),
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      itemBuilder: (context) => [
                        _buildIconMenuItem('Rain', PhosphorIcons.cloudRain(PhosphorIconsStyle.fill), isDark),
                        _buildIconMenuItem('Wind', PhosphorIcons.wind(PhosphorIconsStyle.fill), isDark),
                        _buildIconMenuItem('Dust', PhosphorIcons.dotsNine(PhosphorIconsStyle.fill), isDark),
                        _buildIconMenuItem('Hail', PhosphorIcons.cloudSnow(PhosphorIconsStyle.fill), isDark),
                        _buildIconMenuItem('Mist', PhosphorIcons.cloudFog(PhosphorIconsStyle.fill), isDark),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.cloudSun(PhosphorIconsStyle.fill), size: 16, color: isDark ? Colors.white70 : Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text("Drop Weather Icon", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 16),
                          ],
                        ),
                      ),
                    ),
                            
                    Container(width: 1, height: 20, color: Colors.grey, margin: const EdgeInsets.symmetric(horizontal: 16)),
                    
                    // 2. Risk Matrix Letter Dropdown
                    PopupMenuButton<String>(
                      tooltip: "Select Risk Letter",
                      onSelected: (letter) => _spawnItem(MapItemType.text, letter, mapController),
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      itemBuilder: (context) => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'].map((letter) => PopupMenuItem(
                        value: letter,
                        child: Text("Risk Level $letter", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      )).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill), size: 16, color: isDark ? Colors.white70 : Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text("Drop Matrix Letter", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // The Map Area
          Expanded(
            child: Obx(() {
              final isCurrentlyDrawingThisPeriod = ctrl.isDrawing.value && ctrl.activeMapPeriod.value == period;
              
              return MouseRegion(
                cursor: isCurrentlyDrawingThisPeriod ? SystemMouseCursors.precise : SystemMouseCursors.basic,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
                      right: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
                      bottom: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
                    ),
                  ),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(7.9465, -1.0232), 
                          initialZoom: 5.5,
                          onTap: (tapPosition, latLng) {
                            if (isCurrentlyDrawingThisPeriod) {
                              ctrl.saveUndoState(period);
                              ctrl.addEditablePoint(period, latLng);
                            } else {
                              ctrl.selectPolygonForEditing(period, latLng);
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.gmet.weather_dashboard',
                          ),
                          
                          PolygonLayer(
                            polygons: ctrl.getRegionsForPeriod(period).map((region) {
                              return Polygon(
                                points: region.points,
                                color: _getColorFromString(region.color).withOpacity(0.3),
                                borderColor: _getColorFromString(region.color),
                                borderStrokeWidth: 0.3, 
                              );
                            }).toList(),
                          ),

                          if (ctrl.getEditablePointsForPeriod(period).isNotEmpty)
                            PolygonLayer(
                              polygons: [
                                Polygon(
                                  points: ctrl.getEditablePointsForPeriod(period).map((e) => e.position).toList(),
                                  color: ctrl.activeColor.withOpacity(0.3),
                                  borderColor: ctrl.activeColor,
                                  borderStrokeWidth: 0.3, 
                                )
                              ],
                            ),

                          if (isCurrentlyDrawingThisPeriod)
                            MarkerLayer(
                              markers: ctrl.getEditablePointsForPeriod(period).asMap().entries.map((entry) {
                                final index = entry.key;
                                final point = entry.value;

                                return Marker(
                                  point: point.position,
                                  width: 24, height: 24,
                                  child: GestureDetector(
                                    onSecondaryTapDown: (_) => ctrl.removeEditablePoint(period, index),
                                    onDoubleTap: () => ctrl.removeEditablePoint(period, index),
                                    onPanStart: (_) => ctrl.draggedPointIndex.value = index,
                                    onPanUpdate: (details) {
                                      final renderBox = context.findRenderObject() as RenderBox;
                                      final localPosition = renderBox.globalToLocal(details.globalPosition);
                                      final newLatLng = mapController.camera.offsetToCrs(localPosition);
                                      ctrl.updateEditablePoint(period, index, newLatLng);
                                    },
                                    onPanEnd: (_) => ctrl.draggedPointIndex.value = null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: ctrl.activeColor, width: 2),
                                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 6, height: 6,
                                          decoration: BoxDecoration(color: ctrl.activeColor, shape: BoxShape.circle),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                          // Movable Icons and Letters
                          MarkerLayer(
                            markers: ctrl.getMapItemsForPeriod(period).map((item) {
                              return Marker(
                                point: item.position,
                               width: 24, height: 24,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.grab,
                                  child: GestureDetector(
                                    onSecondaryTapDown: (_) => ctrl.deleteMapItem(period, item.id),
                                    onDoubleTap: () => ctrl.deleteMapItem(period, item.id),
                                    onPanUpdate: (details) {
                                      final renderBox = context.findRenderObject() as RenderBox;
                                      final localPosition = renderBox.globalToLocal(details.globalPosition);
                                      final newLatLng = mapController.camera.offsetToCrs(localPosition);
                                      ctrl.updateMapItemPos(period, item.id, newLatLng);
                                    },
                                    child: Container(
                                      color: Colors.transparent, 
                                      child: Center(child: _buildItemVisual(item)),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          // Map Controls & Color Picker (Bottom Bar)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : Colors.white,
              border: Border(
                left: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
                right: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
                bottom: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.blue.shade200),
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Obx(() {
              final isDrawingThis = ctrl.isDrawing.value && ctrl.activeMapPeriod.value == period;
              
              if (!isDrawingThis) {
                return Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ctrl.setActiveMapPeriod(period);
                      ctrl.startDrawing();
                    },
                    icon: Icon(PhosphorIcons.pencilSimple(), size: 16),
                    label: const Text("Draw Risk Area", style: TextStyle(fontSize: 11)),
                  ),
                );
              }

              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: ['green', 'yellow', 'orange', 'red'].map((colorName) {
                        final isSelected = ctrl.selectedColor.value == colorName;
                        return GestureDetector(
                          onTap: () => ctrl.setColor(colorName),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: _getColorFromString(colorName),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSelected ? [BoxShadow(color: _getColorFromString(colorName).withOpacity(0.5), blurRadius: 4)] : [],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        IconButton(tooltip: "Undo Last Point", icon: const Icon(Icons.undo, size: 18), onPressed: () => ctrl.undo(period), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        const SizedBox(width: 12),
                        IconButton(tooltip: "Delete Polygon", icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => ctrl.deleteActiveDrawing(period), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        const SizedBox(width: 12),
                        IconButton(tooltip: "Cancel Edit", icon: const Icon(Icons.close, size: 18, color: Colors.orange), onPressed: () => ctrl.cancelDrawing(period), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: () => ctrl.finishDrawingFromEditablePoints(period),
                          icon: const Icon(Icons.check, size: 16, color: Colors.green),
                          label: const Text("Finish", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _spawnItem(MapItemType type, String value, MapController mapCtrl) {
    final center = mapCtrl.camera.center;
    ctrl.addMapItem(period, type, value, center);
  }

  // UPDATED: Dynamic styling based on Risk Matrix
  Widget _buildItemVisual(DraggableMapItem item) {
    if (item.type == MapItemType.text) {
      Color letterColor = Colors.black; // Default to black for all text items
      return Text(
        item.value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: letterColor,
          // Strong shadow ensures text is legible over map backgrounds
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 4),
            Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      );
    }
    
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

  // Helper for formatting the icon dropdown list
  PopupMenuItem<String> _buildIconMenuItem(String label, IconData iconData, bool isDark) {
    return PopupMenuItem(
      value: label,
      child: Row(
        children: [
          Icon(iconData, size: 20, color: isDark ? Colors.white70 : Colors.black87),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

}

 