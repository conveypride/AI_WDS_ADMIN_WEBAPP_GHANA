// lib/app/controllers/inland_forecast_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/model/forecastData.dart';

// ============================================================================
// INLAND MAP MODELS
// ============================================================================
enum InlandItemType { icon, text }

class InlandMapItem {
  final String id;
  final InlandItemType type;
  final String value;
  LatLng position;
  InlandMapItem({required this.id, required this.type, required this.value, required this.position});
}

class InlandMapRegion {
  final List<LatLng> points;
  final String color;
  InlandMapRegion({required this.points, required this.color});
}

class InlandEditablePoint {
  LatLng position;
  final int id;
  InlandEditablePoint(this.position, this.id);
}

// ============================================================================
// CONTROLLER
// ============================================================================
class InlandForecastController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    
    // Auto-detect cycle based on current time
    _autoSelectForecastCycle();

    // STRICT VALIDATION LISTENER
    tabController.addListener(() {
      if (tabController.index == 2) {
        if (!_validateTableTab()) {
          tabController.index = 1; // Force back to Table
          Get.snackbar(
            "Incomplete Data", 
            "Please fill the Weather Summary, General Table, and all District fields before drawing maps.",
            backgroundColor: Colors.red.shade600, colorText: Colors.white,
            icon: const Icon(Icons.warning, color: Colors.white),
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20),
          );
        }
      }
    });
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }


var currentForecast = Rxn<ForecastData>( 
  );

  // ========================================================================
  // 1. HISTORY TAB STATE
  // ========================================================================
  var history = <Map<String, dynamic>>[
    {"id": "INL-105", "validity": "20 Feb 2026 - 1200Z", "status": "Published", "author": "Admin"},
    {"id": "INL-104", "validity": "19 Feb 2026 - 1200Z", "status": "Published", "author": "J. Mensah"},
  ].obs;

  // ========================================================================
  // 2. FORECAST CYCLE LOGIC (Dynamic Sequences)
  // ========================================================================
  var issueDate = DateTime.now().obs;
  var validDate = DateTime.now().obs;
  
  var issueTime = "".obs;
  var validTime = "".obs;
  var currentPeriods = <String>[].obs;
  var activeCycleIndex = 1.obs;

  final List<Map<String, dynamic>> forecastCycles = [
    { "issue": "0400Z", "valid": "0600Z", "periods": ["MORNING", "AFTERNOON", "EVENING"], "label": "Early Morning Cycle" },
    { "issue": "1000Z", "valid": "1200Z", "periods": ["AFTERNOON", "EVENING", "MORNING"], "label": "Mid-Morning Cycle" },
    { "issue": "1600Z", "valid": "1800Z", "periods": ["EVENING", "MORNING", "AFTERNOON"], "label": "Late Afternoon Cycle" },
  ];

  void _autoSelectForecastCycle() {
    final hour = DateTime.now().hour;
    if (hour < 8) {
      setCycle(0); // Before 8 AM -> 4 AM Issue
    } else if (hour < 14) {
      setCycle(1); // Between 8 AM and 2 PM -> 10 AM Issue
    } else {
      setCycle(2); // After 2 PM -> 4 PM Issue
    }
  }

  void setCycle(int index) {
    activeCycleIndex.value = index;
    issueTime.value = forecastCycles[index]['issue'];
    validTime.value = forecastCycles[index]['valid'];
    currentPeriods.assignAll(forecastCycles[index]['periods']);
    
    // Automatically increment validDate by 1 day if issue is 1600Z and last period is afternoon
    if (index == 2) {
      validDate.value = issueDate.value; // Stays same day, but the "Morning/Afternoon" columns imply next day visually
    }
  }

  // ========================================================================
  // 3. DATA ENTRY STATE (TABLE TAB)
  // ========================================================================
  var weatherSummary = "".obs;

  final List<String> weatherOptions = [
    "Sunny", "Sunny Intervals", "Partly Cloudy", "Cloudy", "Mostly Cloudy", "Overcast", 
    "Fairly Dry & Hazy", "Dry & Hazy", "Slightly Hazy", "Hazy Sunshine", "Early Morning Mist", 
    "Early Morning Mist/Fog Patches", "Localised Thunderstorms/Rain", "Thunderstorms", "Light Rain", "Rain"
  ];

  final List<String> generalParams = ["SURFACE WIND", "VISIBILITY", "TEMPERATURE"];
  var generalTable = <String, Map<String, dynamic>>{
    "SURFACE WIND": {"12h": "E/NE 05 Max 20 kt", "24h": "S/SW 05 Max 18 kt"},
    "VISIBILITY": {"12h": "(4-10) km", "24h": "(4-10) km"},
    "TEMPERATURE": {"12h": "(19-38)°C", "24h": "(20-34)°C"},
  }.obs;

  final List<String> districts = [
    "BOLE-BAMBOI", "WEST GONJA", "CENTRAL GONJA", "EAST GONJA", "KINTAMPO NORTH", 
    "PRU EAST", "PRU WEST", "KPANDAI", "NKWANTA-NORTH", "NKWANTA-SOUTH", 
    "KRACHI NTSUMURU", "KRACHI-EAST", "KRACHI-WEST", "SENE WEST", "SENE EAST", 
    "BIAKOYE", "KWAHU AFRAM PLAIN NORTH", "KWAHU AFRAM PLAIN SOUTH", "AFADZATO SOUTH", 
    "KPANDO", "NORTH-DAYI", "SOUTH-DAYI", "KWAHU EAST", "KWAHU SOUTH", 
    "FANTEAKWA", "ASOGYAMANG", "UPPER MANYA KROBO", "LOWER MANYA KROBO", 
    "NORTH-TONGU", "CENTRAL-TONGU", "SOUTH-TONGU", "ADA EAST"
  ];

  // Dynamic keys: p1, p2, p3 map to the current sequence
  var districtData = <String, Map<String, dynamic>>{}.obs;

  InlandForecastController() {
    for (var d in districts) {
      districtData[d] = {"p1": "", "p2": "", "p3": "", "wind": ""};
    }
  }

  void updateGeneralTable(String param, String period, String val) => generalTable[param]![period] = val;
  void updateDistrictData(String district, String key, String val) => districtData[district]![key] = val;

  bool _validateTableTab() {
    if (weatherSummary.value.trim().isEmpty) return false;
    for (var param in generalTable.values) {
      if (param['12h']!.trim().isEmpty || param['24h']!.trim().isEmpty) return false;
    }
    for (var dist in districtData.values) {
      if (dist['p1']!.trim().isEmpty || dist['p2']!.trim().isEmpty || dist['p3']!.trim().isEmpty || dist['wind']!.trim().isEmpty) return false;
    }
    return true;
  }

  void proceedToMaps() {
    if (_validateTableTab()) tabController.animateTo(2); 
    else tabController.index = 2; // Trigger snackbar
  }

  // ========================================================================
  // 4. IBF MAP DRAWING ENGINE (DYNAMIC PERIODS p1, p2, p3)
  // ========================================================================
  final mapControllers = { 'p1': MapController(), 'p2': MapController(), 'p3': MapController() };
  var isDrawing = false.obs;
  var activeMapPeriod = ''.obs; 
  var selectedColor = 'green'.obs;
  var draggedPointIndex = RxnInt();
  InlandMapRegion? _originalRegionToEdit; 

  final finishedRegions = { 'p1': <InlandMapRegion>[].obs, 'p2': <InlandMapRegion>[].obs, 'p3': <InlandMapRegion>[].obs };
  final editablePoints = { 'p1': <InlandEditablePoint>[].obs, 'p2': <InlandEditablePoint>[].obs, 'p3': <InlandEditablePoint>[].obs };
  final mapItems = { 'p1': <InlandMapItem>[].obs, 'p2': <InlandMapItem>[].obs, 'p3': <InlandMapItem>[].obs };
  final _undoStack = { 'p1': <List<InlandEditablePoint>>[], 'p2': <List<InlandEditablePoint>>[], 'p3': <List<InlandEditablePoint>>[] };

  void setActiveMapPeriod(String p) => activeMapPeriod.value = p; 
  void startDrawing(String p) { activeMapPeriod.value = p; isDrawing.value = true; _originalRegionToEdit = null; }
  void setColor(String c) => selectedColor.value = c;
  
  Color get activeColor {
    switch (selectedColor.value) { case 'red': return Colors.red; case 'orange': return Colors.orange; case 'yellow': return Colors.yellow; case 'green': return Colors.green; default: return Colors.blue; }
  }

  void addEditablePoint(String p, LatLng point) => editablePoints[p]!.add(InlandEditablePoint(point, editablePoints[p]!.length));
  void updateEditablePoint(String p, int index, LatLng newPos) {
    if (index >= 0 && index < editablePoints[p]!.length) { editablePoints[p]![index].position = newPos; editablePoints[p]!.refresh(); }
  }
  void removeEditablePoint(String p, int index) {
    if (index >= 0 && index < editablePoints[p]!.length) { saveUndoState(p); editablePoints[p]!.removeAt(index); }
  }
  void finishDrawing(String p) {
    if (editablePoints[p]!.length < 3) { Get.snackbar("Error", "Need at least 3 points.", backgroundColor: Colors.red, colorText: Colors.white); return; }
    finishedRegions[p]!.add(InlandMapRegion(points: editablePoints[p]!.map((e) => e.position).toList(), color: selectedColor.value));
    _clearActiveDrawingState(p);
  }
  void cancelDrawing(String p) {
    if (_originalRegionToEdit != null) finishedRegions[p]!.add(_originalRegionToEdit!); 
    _clearActiveDrawingState(p);
  }
  void deleteActiveDrawing(String p) => _clearActiveDrawingState(p); 
  void _clearActiveDrawingState(String p) {
    editablePoints[p]!.clear(); _undoStack[p]!.clear(); isDrawing.value = false; activeMapPeriod.value = ''; _originalRegionToEdit = null;
  }
  void saveUndoState(String p) => _undoStack[p]!.add(editablePoints[p]!.map((e) => InlandEditablePoint(e.position, e.id)).toList());
  void undo(String p) {
    if (_undoStack[p]!.isNotEmpty) editablePoints[p]!.assignAll(_undoStack[p]!.removeLast());
    else if (editablePoints[p]!.isNotEmpty) editablePoints[p]!.removeLast();
  }
  void selectPolygonForEditing(String p, LatLng tapPoint) {
    for (int i = finishedRegions[p]!.length - 1; i >= 0; i--) {
      if (_isPointInPolygon(tapPoint, finishedRegions[p]![i].points)) {
        final regionToEdit = finishedRegions[p]!.removeAt(i);
        _originalRegionToEdit = InlandMapRegion(points: List.from(regionToEdit.points), color: regionToEdit.color);
        setActiveMapPeriod(p); setColor(regionToEdit.color);
        editablePoints[p]!.assignAll(regionToEdit.points.asMap().entries.map((e) => InlandEditablePoint(e.value, e.key)));
        _undoStack[p]!.clear(); isDrawing.value = true; break; 
      }
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false; int intersectCount = 0;
    for (int j = 0; j < polygon.length - 1; j++) { if (_rayCastIntersect(point, polygon[j], polygon[j + 1])) intersectCount++; }
    if (_rayCastIntersect(point, polygon.last, polygon.first)) intersectCount++; return (intersectCount % 2) == 1; 
  }
  bool _rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    double aY = vertA.latitude, bY = vertB.latitude; double aX = vertA.longitude, bX = vertB.longitude; double pY = point.latitude, pX = point.longitude;
    if ((aY > pY) != (bY > pY)) { double intersectX = ((bX - aX) * (pY - aY) / (bY - aY)) + aX; if (pX < intersectX) return true; } return false;
  }

  void addMapItem(String p, InlandItemType type, String value, LatLng spawnPoint) => mapItems[p]!.add(InlandMapItem(id: DateTime.now().millisecondsSinceEpoch.toString(), type: type, value: value, position: spawnPoint));
  void updateMapItemPos(String p, String id, LatLng newPos) {
    final index = mapItems[p]!.indexWhere((item) => item.id == id);
    if (index != -1) { mapItems[p]![index].position = newPos; mapItems[p]!.refresh(); }
  }
  void deleteMapItem(String p, String id) => mapItems[p]!.removeWhere((item) => item.id == id);

  // ========================================================================
  // 5. PUBLISH
  // ========================================================================
  var isPublishing = false.obs;

  void publishForecast() async {
    isPublishing.value = true; await Future.delayed(const Duration(seconds: 2)); isPublishing.value = false;
    Get.snackbar("Published!", "Inland Water Forecast pushed successfully.", backgroundColor: Colors.green.shade600, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20), icon:  Icon(PhosphorIcons.cloudCheck(), color: Colors.white));
    tabController.animateTo(0);
  }
}