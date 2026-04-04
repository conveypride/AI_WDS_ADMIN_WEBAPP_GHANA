// lib/app/controllers/marine_forecast_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/model/forecastData.dart';


// ============================================================================
// CONTROLLER
// ============================================================================
class CoastlineForecastController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

var currentForecast = Rxn<ForecastData>( 
  );
  // --- TOP-LEVEL NAVIGATION ---
  final List<String> forecastTypes = ["Coastline Forecast", "Inland Forecast"];
  var selectedForecastType = "Coastline Forecast".obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  // ========================================================================
  // 1. HISTORY TAB STATE (COASTLINE)
  // ========================================================================
  var currentPage = 1.obs;
  final int totalPages = 1;

  var coastlineHistory = <Map<String, dynamic>>[
    {"id": "CST-022", "validity": "22 Feb 2026 - 1200Z", "status": "Published", "author": "Admin"},
    {"id": "CST-021", "validity": "21 Feb 2026 - 1200Z", "status": "Published", "author": "J. Mensah"},
  ].obs;

  void nextPage() { if (currentPage.value < totalPages) currentPage.value++; }
  void previousPage() { if (currentPage.value > 1) currentPage.value--; }

   // ========================================================================
  // 2. DATA ENTRY STATE (STANDARD TABLE & META)
  // ========================================================================
  
  // Dates and Times
  var issueDate = DateTime.now().obs;
  var validDate = DateTime.now().obs;
  var issueTime = "1000Z".obs;
  var validTime = "1200Z".obs;

  final List<String> zTimeOptions = [
    "0000Z", "0600Z", "1000Z", "1200Z", "1600Z", "1800Z", "2000Z"
  ];

  // Weather Summary & Sea State
  var weatherSummary = "".obs;
  var stateOfSea = "Calm (0-1)".obs;
  var warningText = "WARNING: MAX WAVE CURRENT RANGE (0.69-0.77)m/s".obs;

  final List<String> seaStateOptions = ["Calm (0-1)", "Smooth (2)", "Slight (3)", "Moderate (4)", "Rough (5)", "Very Rough (6)"];

  final List<String> parameters = [
    "SURFACE WIND", "VISIBILITY", "SEA SURFACE TEMPERATURE", 
    "SIG WAVE HEIGHT", "TIDAL WAVE", "WAVE CURRENT"
  ];

  // tableData[Parameter] = { "12h": value, "24h": value }
  var tableData = <String, Map<String, dynamic>>{
    "SURFACE WIND": {"12h": "S/SW 07KT MAX 19KT", "24h": "S/SW 05KT MAX 18KT"},
    "VISIBILITY": {"12h": "(5-10) km", "24h": "(4-10) km"},
    "SEA SURFACE TEMPERATURE": {"12h": "(27-30)°C", "24h": "(27-30)°C"},
    "SIG WAVE HEIGHT": {"12h": "(0.9-1.4) m / (3.0-4.6) ft", "24h": "(0.9-1.5) m / (3.0-4.9) ft"},
    "TIDAL WAVE": {"12h": "(0.35-1.75) m / (1.15-5.74) ft", "24h": "(0.41-1.37) m / (1.35-4.49) ft"},
    "WAVE CURRENT": {"12h": "Average: E/NE\n0.61 m/s\nMax (0.69 – 0.77)", "24h": "Average: E/NE\n0.70 m/s\nMax (0.79 – 0.87)"},
  }.obs;

  void updateTableData(String parameter, String period, String value) {
    tableData[parameter]![period] = value;
  }

  

  // ========================================================================
  // 3. IBF MAP DRAWING ENGINE
  // ========================================================================
  final mapController = MapController();
  
  var isDrawing = false.obs;
  var selectedColor = 'green'.obs;
  var draggedPointIndex = RxnInt();
  MarineMapRegion? _originalRegionToEdit; 

  final finishedRegions = <MarineMapRegion>[].obs;
  final editablePoints = <MarineEditablePoint>[].obs;
  final mapItems = <MarineMapItem>[].obs;
  final _undoStack = <List<MarineEditablePoint>>[];

  // --- Drawing Actions ---
  void startDrawing() { isDrawing.value = true; _originalRegionToEdit = null; }
  void setColor(String c) => selectedColor.value = c;
  
  Color get activeColor {
    switch (selectedColor.value) {
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      case 'yellow': return Colors.yellow;
      case 'green': return Colors.green;
      default: return Colors.blue;
    }
  }

  void addEditablePoint(LatLng point) => editablePoints.add(MarineEditablePoint(point, editablePoints.length));
  void updateEditablePoint(int index, LatLng newPos) {
    if (index >= 0 && index < editablePoints.length) { editablePoints[index].position = newPos; editablePoints.refresh(); }
  }
  void removeEditablePoint(int index) {
    if (index >= 0 && index < editablePoints.length) { saveUndoState(); editablePoints.removeAt(index); }
  }

  void finishDrawing() {
    if (editablePoints.length < 3) { Get.snackbar("Error", "Need at least 3 points.", backgroundColor: Colors.red, colorText: Colors.white); return; }
    finishedRegions.add(MarineMapRegion(points: editablePoints.map((e) => e.position).toList(), color: selectedColor.value));
    _clearActiveDrawingState();
  }

  void cancelDrawing() {
    if (_originalRegionToEdit != null) finishedRegions.add(_originalRegionToEdit!); 
    _clearActiveDrawingState();
  }
  void deleteActiveDrawing() => _clearActiveDrawingState(); 

  void _clearActiveDrawingState() {
    editablePoints.clear(); _undoStack.clear(); isDrawing.value = false; _originalRegionToEdit = null;
  }

  void saveUndoState() => _undoStack.add(editablePoints.map((e) => MarineEditablePoint(e.position, e.id)).toList());
  void undo() {
    if (_undoStack.isNotEmpty) editablePoints.assignAll(_undoStack.removeLast());
    else if (editablePoints.isNotEmpty) editablePoints.removeLast();
  }

  // --- Ray-Casting & Editing ---
  void selectPolygonForEditing(LatLng tapPoint) {
    for (int i = finishedRegions.length - 1; i >= 0; i--) {
      if (_isPointInPolygon(tapPoint, finishedRegions[i].points)) {
        final regionToEdit = finishedRegions.removeAt(i);
        _originalRegionToEdit = MarineMapRegion(points: List.from(regionToEdit.points), color: regionToEdit.color);
        setColor(regionToEdit.color);
        editablePoints.assignAll(regionToEdit.points.asMap().entries.map((e) => MarineEditablePoint(e.value, e.key)));
        _undoStack.clear(); isDrawing.value = true; break; 
      }
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    int intersectCount = 0;
    for (int j = 0; j < polygon.length - 1; j++) {
      if (_rayCastIntersect(point, polygon[j], polygon[j + 1])) intersectCount++;
    }
    if (_rayCastIntersect(point, polygon.last, polygon.first)) intersectCount++;
    return (intersectCount % 2) == 1; 
  }

  bool _rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    double aY = vertA.latitude, bY = vertB.latitude; double aX = vertA.longitude, bX = vertB.longitude;
    double pY = point.latitude, pX = point.longitude;
    if ((aY > pY) != (bY > pY)) {
      double intersectX = ((bX - aX) * (pY - aY) / (bY - aY)) + aX;
      if (pX < intersectX) return true;
    }
    return false;
  }

  // --- Icons & Letters ---
  void addMapItem(MarineItemType type, String value, LatLng spawnPoint) => mapItems.add(MarineMapItem(id: DateTime.now().millisecondsSinceEpoch.toString(), type: type, value: value, position: spawnPoint));
  void updateMapItemPos(String id, LatLng newPos) {
    final index = mapItems.indexWhere((item) => item.id == id);
    if (index != -1) { mapItems[index].position = newPos; mapItems.refresh(); }
  }
  void deleteMapItem(String id) => mapItems.removeWhere((item) => item.id == id);

  // ========================================================================
  // 4. PUBLISHING LOGIC
  // ========================================================================
  var isPublishing = false.obs;

  void publishForecast() async {
    isPublishing.value = true;
    await Future.delayed(const Duration(seconds: 2)); 
    isPublishing.value = false;
    
    Get.snackbar(
      "Published!", "Coastline Forecast successfully pushed to database.",
      backgroundColor: Colors.green.shade600, colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20),
      icon:  Icon(PhosphorIcons.cloudCheck(), color: Colors.white),
    );
    tabController.animateTo(0);
  }
}

// ============================================================================
// MAP MODELS
// ============================================================================
enum MarineItemType { icon, text }

class MarineMapItem {
  final String id;
  final MarineItemType type;
  final String value;
  LatLng position;
  MarineMapItem({required this.id, required this.type, required this.value, required this.position});
}

class MarineMapRegion {
  final List<LatLng> points;
  final String color;
  MarineMapRegion({required this.points, required this.color});
}

class MarineEditablePoint {
  LatLng position;
  final int id;
  MarineEditablePoint(this.position, this.id);
}
