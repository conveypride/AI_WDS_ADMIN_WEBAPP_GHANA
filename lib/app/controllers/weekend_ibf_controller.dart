import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/model/forecastData.dart';
import 'package:weather_admin_dashboard/app/model/midWeekEditablePoint.dart';
import 'package:weather_admin_dashboard/app/model/midWeekItemType.dart';
import 'package:weather_admin_dashboard/app/model/midWeekMapItem.dart';
import 'package:weather_admin_dashboard/app/model/midWeekMapRegion.dart';

 class WeekendIBFController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

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


var currentForecast = Rxn<ForecastData>( 
  );
  // ========================================================================
  // 1. HISTORY TAB STATE
  // ========================================================================
  var currentPage = 1.obs;
  final int totalPages = 2;
 

  var ibfHistory = <Map<String, dynamic>>[
    {"id": "WE-502", "validity": "Fri 27 - Sun 29 Feb", "areas": "3 Polygons", "status": "Published", "forecaster": "Admin User"},
    {"id": "WE-501", "validity": "Fri 20 - Sun 22 Feb", "areas": "1 Polygon", "status": "Published", "forecaster": "J. Mensah"},
  ].obs;

  void nextPage() { if (currentPage.value < totalPages) currentPage.value++; }
  void previousPage() { if (currentPage.value > 1) currentPage.value--; }

  // ========================================================================
  // 2. 3-MAP DRAWING ENGINE (FRI, SAT, SUN)
  // ========================================================================
  var fridayDate = DateTime.now().obs;
  
  // Returns [Friday, Saturday, Sunday]
  List<DateTime> get weekendDates {
    return [fridayDate.value, fridayDate.value.add(const Duration(days: 1)), fridayDate.value.add(const Duration(days: 2))];
  }

  void updateStartDate(DateTime date) => fridayDate.value = date;

  // Keys updated to include 'fri'
  final mapControllers = {
    'fri': MapController(),
    'sat': MapController(),
    'sun': MapController(),
  };

  var isDrawing = false.obs;
  var activeMapPeriod = ''.obs; 
  var selectedColor = 'green'.obs;
  var draggedPointIndex = RxnInt();
  MidWeekMapRegion? _originalRegionToEdit; 

  // Data Storage for 3 Days
  final finishedRegions = {
    'fri': <MidWeekMapRegion>[].obs,
    'sat': <MidWeekMapRegion>[].obs,
    'sun': <MidWeekMapRegion>[].obs,
  };
  final editablePoints = {
    'fri': <MidWeekEditablePoint>[].obs,
    'sat': <MidWeekEditablePoint>[].obs,
    'sun': <MidWeekEditablePoint>[].obs,
  };
  final mapItems = {
    'fri': <MidWeekMapItem>[].obs,
    'sat': <MidWeekMapItem>[].obs,
    'sun': <MidWeekMapItem>[].obs,
  };
  final _undoStack = {
    'fri': <List<MidWeekEditablePoint>>[],
    'sat': <List<MidWeekEditablePoint>>[],
    'sun': <List<MidWeekEditablePoint>>[],
  };

  // --- Drawing Actions ---
  void setActiveMapPeriod(String p) => activeMapPeriod.value = p; 

  void startDrawing(String p) {
    activeMapPeriod.value = p;
    isDrawing.value = true;
    _originalRegionToEdit = null;
  }

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

  void addEditablePoint(String p, LatLng point) {
    editablePoints[p]!.add(MidWeekEditablePoint(point, editablePoints[p]!.length));
  }

  void updateEditablePoint(String p, int index, LatLng newPos) {
    final list = editablePoints[p]!;
    if (index >= 0 && index < list.length) {
      list[index].position = newPos;
      list.refresh();
    }
  }

  void removeEditablePoint(String p, int index) {
    final list = editablePoints[p]!;
    if (index >= 0 && index < list.length) {
      saveUndoState(p);
      list.removeAt(index);
    }
  }

  void finishDrawing(String p) {
    final list = editablePoints[p]!;
    if (list.length < 3) {
      Get.snackbar("Invalid Polygon", "You need at least 3 points.", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    final points = list.map((e) => e.position).toList();
    finishedRegions[p]!.add(MidWeekMapRegion(points: points, color: selectedColor.value));
    _clearActiveDrawingState(p);
  }

  void cancelDrawing(String p) {
    if (_originalRegionToEdit != null) {
      finishedRegions[p]!.add(_originalRegionToEdit!); 
    }
    _clearActiveDrawingState(p);
  }

  void deleteActiveDrawing(String p) {
    _clearActiveDrawingState(p); 
  }

  void _clearActiveDrawingState(String p) {
    editablePoints[p]!.clear();
    _undoStack[p]!.clear();
    isDrawing.value = false;
    activeMapPeriod.value = '';
    _originalRegionToEdit = null;
  }

  void saveUndoState(String p) {
    final snapshot = editablePoints[p]!.map((e) => MidWeekEditablePoint(e.position, e.id)).toList();
    _undoStack[p]!.add(snapshot);
  }

  void undo(String p) {
    if (_undoStack[p]!.isNotEmpty) {
      final lastState = _undoStack[p]!.removeLast();
      editablePoints[p]!.assignAll(lastState);
    } else if (editablePoints[p]!.isNotEmpty) {
      editablePoints[p]!.removeLast();
    }
  }

  // --- Ray-Casting Algorithm ---
  void selectPolygonForEditing(String p, LatLng tapPoint) {
    final regions = finishedRegions[p]!;
    for (int i = regions.length - 1; i >= 0; i--) {
      if (_isPointInPolygon(tapPoint, regions[i].points)) {
        final regionToEdit = regions.removeAt(i);
        _originalRegionToEdit = MidWeekMapRegion(points: List.from(regionToEdit.points), color: regionToEdit.color);
        
        setActiveMapPeriod(p);
        setColor(regionToEdit.color);
        editablePoints[p]!.assignAll(regionToEdit.points.asMap().entries.map((e) => MidWeekEditablePoint(e.value, e.key)));
        
        _undoStack[p]!.clear();
        isDrawing.value = true;
        break; 
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
    double aY = vertA.latitude, bY = vertB.latitude;
    double aX = vertA.longitude, bX = vertB.longitude;
    double pY = point.latitude, pX = point.longitude;
    if ((aY > pY) != (bY > pY)) {
      double intersectX = ((bX - aX) * (pY - aY) / (bY - aY)) + aX;
      if (pX < intersectX) return true;
    }
    return false;
  }

  // ========================================================================
  // 3. ICONS & LETTERS LOGIC
  // ========================================================================
  void addMapItem(String p, MidWeekItemType type, String value, LatLng spawnPoint) {
    mapItems[p]!.add(MidWeekMapItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type, value: value, position: spawnPoint,
    ));
  }

  void updateMapItemPos(String p, String id, LatLng newPos) {
    final index = mapItems[p]!.indexWhere((item) => item.id == id);
    if (index != -1) {
      mapItems[p]![index].position = newPos;
      mapItems[p]!.refresh();
    }
  }

  void deleteMapItem(String p, String id) {
    mapItems[p]!.removeWhere((item) => item.id == id);
  }

  // ========================================================================
  // 4. IBF TABLE DATA (SECTOR vs 3 DAYS)
  // ========================================================================
  
  final List<String> sectors = ["Northern Sector", "Middle Sector", "Coastal Sector"];

  // Stores bullet points: ibfDetails[Sector][DayIndex (0, 1, or 2)]
  var ibfDetails = <String, List<String>>{
    "Northern Sector": ["", "", ""],
    "Middle Sector": ["", "", ""],
    "Coastal Sector": ["", "", ""],
  }.obs;

  var shortDescription = ''.obs; 

  // ========================================================================
  // 5. PUBLISHING LOGIC
  // ========================================================================
  var isPublishing = false.obs;

  void publishForecast() async {
    isPublishing.value = true;
    await Future.delayed(const Duration(seconds: 2)); 
    isPublishing.value = false;
    
    Get.snackbar(
      "Published!", "Weekend forecast pushed to database.",
      backgroundColor: Colors.green.shade600, colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20),
      icon:  Icon(PhosphorIcons.cloudCheck(), color: Colors.white),
    );
    tabController.animateTo(0);
  }
}