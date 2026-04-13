import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:weather_admin_dashboard/app/services/coastline_table_pdf_service.dart';
import 'package:intl/intl.dart'; 
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'package:weather_admin_dashboard/app/services/coastline_image_generator.dart';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart'; 
import 'package:weather_admin_dashboard/app/services/coastline_ibf_pdf_service.dart'; // NEW IBF SERVICE


// ============================================================================
// CONTROLLER
// ============================================================================
class CoastlineForecastController extends GetxController with GetTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authCtrl = Get.find<AuthController>();

  late TabController tabController; 
  final GlobalKey mapKey = GlobalKey(); // NEW: Used to capture the map
  // --- ROLE-BASED ACCESS CONTROL (RBAC) ---
  bool get isMarineUser {
    final dept = _authCtrl.currentUser.value?.department.toLowerCase();
    return dept == 'marine' ;
  }

  bool get isAdmin {
    final role = _authCtrl.currentUser.value?.role.toLowerCase() ?? '';
    return role.contains('admin');
  }

  bool get canCreate => isMarineUser;
  bool get canApprove => isMarineUser && isAdmin;
  
  var currentForecast = Rxn<dynamic>(); 

  // KPI Analytics Variables
  final kpiTotal = 0.obs;
  final kpiDraft = 0.obs;
  final kpiPending = 0.obs;
  final kpiPublished = 0.obs;
  
  // --- TOP-LEVEL NAVIGATION ---
  final List<String> forecastTypes = ["Coastline Forecast", "Inland Forecast"];
  var selectedForecastType = "Coastline Forecast".obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    _autoSetIssueTime();
    
    if (_authCtrl.currentUser.value != null) {
      fetchForecastHistory();
      fetchAnalytics();
    } else {
      ever(_authCtrl.currentUser, (user) {
        if (user != null && coastlineHistory.isEmpty) {
          fetchForecastHistory();
          fetchAnalytics();
        }
      });
    }
  }
  
  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }


// ========================================================================
  // 5. IBF PDF DOWNLOAD LOGIC
  // ========================================================================
  Future<Uint8List?> captureMapImage() async {
    try {
      RenderRepaintBoundary boundary = mapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // High-res capture
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing map: $e");
      return null;
    }
  }

   // ========================================================================
  // 6. IBF PDF & IMAGE DOWNLOAD LOGIC (MID-WEEK APPROACH)
  // ========================================================================
  Future<void> downloadIbfForecastPdfImage(String docId, BuildContext context) async {
    try {
     
      // 1. Get the data
      final forecast = coastlineHistory.firstWhere((f) => f['id'] == docId);
      final mapRegions = forecast['mapRegions'] as List<dynamic>? ?? [];
      final mapItems = forecast['mapItems'] as List<dynamic>? ?? [];

      Get.snackbar("Preparing Download", "Rendering Coastline map off-screen. Please wait...",
          backgroundColor: Colors.blue.shade600, colorText: Colors.white, duration: const Duration(seconds: 15));

      // 2. Generate Map Image Off-Screen
      final mapBytes = await CoastlineImageGenerator.generateMapImage(
         mapRegions: mapRegions,
      mapItems: mapItems,
      // eezBoundaries: eezBoundaries, // Pass EEZ data
      context: context,
      tileWaitMs: 2500,
      );

      if (mapBytes == null) {
        Get.snackbar("Error", "Could not render map.", backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      // 3. Generate the PDF
      final pdfBytes = await CoastlineIbfPdfService.generateIbfPdf(forecast, mapBytes!);

      // 4. Download the PDF directly via Browser Anchor
      final pdfBlob = html.Blob([pdfBytes], 'application/pdf');
      final pdfUrl = html.Url.createObjectUrlFromBlob(pdfBlob);
      html.AnchorElement(href: pdfUrl)
        ..setAttribute("download", "Coastline_IBF_$docId.pdf")
        ..click();
      html.Url.revokeObjectUrl(pdfUrl);

      // 5. Convert the PDF to an Image (Rasterize) and Download
      await for (var page in Printing.raster(pdfBytes, pages: [0], dpi: 300)) {
        final imageBytes = await page.toPng();
        final imageBlob = html.Blob([imageBytes], 'image/png');
        final imageUrl = html.Url.createObjectUrlFromBlob(imageBlob);
        html.AnchorElement(href: imageUrl)
          ..setAttribute("download", "Coastline_IBF_$docId.png")
          ..click();
        html.Url.revokeObjectUrl(imageUrl);
      }

      Get.snackbar("Success", "PDF and Image downloaded successfully!", 
        backgroundColor: const Color(0xFF3DD68C), colorText: Colors.black);

    } catch (e) {
      debugPrint("IBF Download Error: $e");
      Get.snackbar("Error", "Failed to process files: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
// ========================================================================
  // PDF & IMAGE DOWNLOAD LOGIC (Like CAFO)
  // ========================================================================
  Future<void> downloadTableForecastPdfImage(String docId) async {
    print("Attempting to download PDF and Image for docId: $docId");
    try {
      Get.snackbar(
        'Generating Files', 
        'Please wait while the PDF and Image are compiled...', 
        showProgressIndicator: true,
        backgroundColor: AppTheme.accentBlue.withOpacity(0.9),
        colorText: Colors.white,
      );
      
      // 1. Find the forecast data
      final rawForecast = coastlineHistory.firstWhere((f) => f['id'] == docId);
      final Map<String, dynamic> forecast = Map<String, dynamic>.from(rawForecast);
      
      // 2. Format Date
      DateTime parsedDate = DateTime.now();
      if (forecast['validDate'] != null) {
        try {
          parsedDate = DateTime.parse(forecast['validDate']);
        } catch (_) {}
      }
      
      String formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);
      String validTime = forecast['validTime'] ?? '1200Z';
      
      // 3. Generate the PDF bytes ONCE
      final Uint8List pdfBytes = await CoastlineTablePdfService.generateForecastPdf(forecast);
      
      // 4. Rasterize to get Image bytes
      final rasterStream = Printing.raster(pdfBytes, dpi: 300);
      final firstPage = await rasterStream.first; 
      final Uint8List imageBytes = await firstPage.toPng();
      
      // 5. Create a clean base filename
      String safeDate = formattedDate.replaceAll('/', '-');
      String baseFileName = "Coastline_Maritime_Forecast_${safeDate}_${validTime}";
 
      // 6. Trigger Downloads
      _triggerWebDownload(pdfBytes, '$baseFileName.pdf', 'application/pdf');
      await Future.delayed(const Duration(milliseconds: 200));
      _triggerWebDownload(imageBytes, '$baseFileName.png', 'image/png');
      
      Get.snackbar(
        'Success', 
        'PDF and Image downloaded successfully!',
        backgroundColor: const Color(0xFF3DD68C).withOpacity(0.95),
        colorText: Colors.black,
        icon: Icon(PhosphorIcons.downloadSimple(PhosphorIconsStyle.fill), color: Colors.black87, size: 18),
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      debugPrint("Error generating files: $e");
      Get.snackbar(
        'Error', 
        'Could not generate files. ${e.toString()}',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }
 
  // Helper method to trigger web downloads
  void _triggerWebDownload(Uint8List bytes, String fileName, String mimeType) {
    final jsArray = [bytes.toJS].toJS;
    final blob = web.Blob(jsArray, web.BlobPropertyBag(type: mimeType)); 
    final url = web.URL.createObjectURL(blob);
    
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
      
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
 
  
  // ========================================================================
  // 1. HISTORY TAB & PAGINATION
  // ========================================================================
  var isLoadingHistory = false.obs;
  var isFetchingMore = false.obs;
  var hasMore = true.obs;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 15;

  var coastlineHistory = <Map<String, dynamic>>[].obs;

  Future<void> fetchAnalytics() async {
    final user = _authCtrl.currentUser.value;
    if (user == null) return;

    Query baseQuery = _firestore.collection('coastline_forecasts');
    
    if (!isAdmin) {
      baseQuery = baseQuery.where('author.uid', isEqualTo: user.uid);
    }

    try {
      final total = await baseQuery.count().get();
      final draft = await baseQuery.where('status', isEqualTo: 'draft').count().get();
      final pending = await baseQuery.where('status', isEqualTo: 'pending_approval').count().get();
      final published = await baseQuery.where('status', isEqualTo: 'published').count().get();

      kpiTotal.value = total.count ?? 0;
      kpiDraft.value = draft.count ?? 0;
      kpiPending.value = pending.count ?? 0;
      kpiPublished.value = published.count ?? 0;
    } catch (e) {
      debugPrint("Analytics Error: $e");
    }
  }

  Future<void> fetchForecastHistory() async {
    if (!isMarineUser) return; 

    try {
      isLoadingHistory.value = true;
      hasMore.value = true;
      _lastDocument = null;

      final user = _authCtrl.currentUser.value;
      if (user == null) return;

      Query query = _firestore.collection('coastline_forecasts')
          .orderBy('updatedAt', descending: true)
          .limit(_pageSize);

      if (!isAdmin) {
        query = query.where('author.uid', isEqualTo: user.uid);
      }

      QuerySnapshot snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last; 
        if (snapshot.docs.length < _pageSize) hasMore.value = false; 
      } else {
        hasMore.value = false;
      }

      coastlineHistory.value = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        return data;
      }).toList();

    } catch (e) {
      debugPrint("History Fetch Error: $e");
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> fetchMoreForecasts() async {
    if (isFetchingMore.value || !hasMore.value || _lastDocument == null) return;
    if (!isMarineUser) return;

    final user = _authCtrl.currentUser.value;
    if (user == null) return;

    try {
      isFetchingMore.value = true;
      Query query = _firestore.collection('coastline_forecasts')
          .orderBy('updatedAt', descending: true)
          .startAfterDocument(_lastDocument!) 
          .limit(_pageSize);

      if (!isAdmin) {
        query = query.where('author.uid', isEqualTo: user.uid);
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last; 
        if (snapshot.docs.length < _pageSize) hasMore.value = false;

        var newDocs = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        coastlineHistory.addAll(newDocs); 
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      debugPrint("Pagination Error: $e");
    } finally {
      isFetchingMore.value = false;
    }
  }

  // ========================================================================
  // 2. DATA ENTRY STATE (TIME, DAILY TABLE, IBF TABLE)
  // ========================================================================
  var currentForecastId = RxnString(null);

  final List<String> zTimeOptions = ["0500Z", "1100Z", "1700Z", "2300Z"];
  final List<String> seaStateOptions = ["Calm", "Rough", "Dangerous"]; 

  // --- DAILY TAB OBSERVABLES ---
  var dailyIssueDate = DateTime.now().obs;
  var dailyValidDate = DateTime.now().obs;
  var dailyIssueTime = "0500Z".obs;
  var dailyValidTime = "0600Z".obs;
  var dailyWeatherSummary = "".obs;
  var dailyStateOfSea = "Calm".obs;
  var dailyWarningText = "".obs;

  // --- IBF TAB OBSERVABLES ---
  var issueDate = DateTime.now().obs;
  var validDate = DateTime.now().obs;
  var issueTime = "0500Z".obs;
  var validTime = "0600Z".obs;
  var weatherSummary = "".obs;
  var stateOfSea = "Calm".obs;
  var warningText = "".obs;

  // SHARED PARAMETERS LIST
  final List<String> parameters = [
    "SURFACE WIND", "VISIBILITY", "SEA SURFACE TEMPERATURE", 
    "SIG WAVE HEIGHT", "TIDAL WAVE", "WAVE CURRENT"
  ];

  void _autoSetIssueTime() {
    final hour = DateTime.now().toUtc().hour;
    String newTime = '0500Z';
    String vTime = '0600Z';

    if (hour < 6) { newTime = '0500Z'; vTime = '0600Z'; } 
    else if (hour < 12) { newTime = '1100Z'; vTime = '1200Z'; } 
    else if (hour < 18) { newTime = '1700Z'; vTime = '1800Z'; } 
    else if (hour < 23) { newTime = '2300Z'; vTime = '0000Z'; } 
    else { newTime = '0500Z'; vTime = '0600Z'; }
    
    dailyIssueTime.value = newTime;
    dailyValidTime.value = vTime;
    issueTime.value = newTime;
    validTime.value = vTime;
  }

  void updateDailyIssueTime(String time) {
    dailyIssueTime.value = time;
    if (time == '0500Z') dailyValidTime.value = '0600Z';
    else if (time == '1100Z') dailyValidTime.value = '1200Z';
    else if (time == '1700Z') dailyValidTime.value = '1800Z';
    else if (time == '2300Z') dailyValidTime.value = '0000Z';
  }

  void updateIssueTime(String time) {
    issueTime.value = time;
    if (time == '0500Z') validTime.value = '0600Z';
    else if (time == '1100Z') validTime.value = '1200Z';
    else if (time == '1700Z') validTime.value = '1800Z';
    else if (time == '2300Z') validTime.value = '0000Z';
  }

 // --- DAILY TABLE DATA ---
  var dailyTableData = <String, Map<String, dynamic>>{
    "SURFACE WIND": {"12h": "-", "24h": "-"},
    "VISIBILITY": {"12h": "-", "24h": "-"},
    "SEA SURFACE TEMPERATURE": {"12h": "-", "24h": "-"},
    "SIG WAVE HEIGHT": {"12h": "-", "24h": "-"},
    "TIDAL WAVE": {"12h": "-", "24h": "-"},
    "WAVE CURRENT": {"12h": "-", "24h": "-"},
  }.obs;

 // NULL-SAFE UPDATE
  void updateDailyTableData(String param, String period, String value) {
    if (!dailyTableData.containsKey(param)) {
      dailyTableData[param] = {"12h": "-", "24h": "-"};
    }
    dailyTableData[param]![period] = value;
    dailyTableData.refresh();
  }

  // --- NEW EXPLICIT VALIDATION METHOD ---
  void validateAndGoToIbfTab() {
    List<String> missing = [];

    // Check Summary
    if (dailyWeatherSummary.value.trim().isEmpty) {
      missing.add("Daily Weather Summary");
    }
    
    // Check Warning Notes
    if (dailyWarningText.value.trim().isEmpty) {
      missing.add("Important Notes (Type 'NIL' if none)");
    }

    // Check every single cell in the table
    bool tableIncomplete = false;
    for (var param in parameters) {
      for (var period in ['12h', '24h']) {
        final val = dailyTableData[param]?[period]?.trim() ?? '';
        print('val = $val for $period');
        if (val.isEmpty || val == '-') tableIncomplete = true;
      }
    }
    
    if (tableIncomplete) {
      missing.add("Some Table Cells are still empty or have '-'");
    }

    // If anything is missing, show an exact error message!
    if (missing.isNotEmpty) {
      Get.snackbar(
        "Action Required",
        "Please complete the following:\n• ${missing.join('\n• ')}",
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
        duration: const Duration(seconds: 4),
      );
    } else {
      // Everything is perfect, move to the next tab!
      tabController.animateTo(2);
    }
  }

  bool get isDailyTabComplete {
    if (dailyWeatherSummary.value.trim().isEmpty) return false;
    // if (dailyWarningText.value.trim().isEmpty) return false;
    for (var param in parameters) {
      // Safely handle missing keys for old legacy data
      final rowData = dailyTableData[param];
      if (rowData == null) return false;

      for (var period in ['12h', '24h']) {
        final val = rowData[period]?.trim() ?? '';
        if (val.isEmpty || val == '-') return false;
      }
    }
    return true;
  }

  // --- IBF TABLE DATA ---
  var tableData = <String, Map<String, dynamic>>{
    "SURFACE WIND": {"12h": "-", "24h": "-"},
    "VISIBILITY": {"12h": "-", "24h": "-"},
    "SEA SURFACE TEMPERATURE": {"12h": "-", "24h": "-"},
    "SIG WAVE HEIGHT": {"12h": "-", "24h": "-"},
    "TIDAL WAVE": {"12h": "-", "24h": "-"},
    "WAVE CURRENT": {"12h": "-", "24h": "-"},
  }.obs;

  // NULL-SAFE UPDATE
  void updateTableData(String param, String period, String value) {
    if (!tableData.containsKey(param)) {
      tableData[param] = {"12h": "-", "24h": "-"};
    }
    tableData[param]![period] = value;
    tableData.refresh();
  }

  void createNewForecast() {
    if (!canCreate) return;
    currentForecastId.value = null;
    
    // Reset Times
    issueDate.value = DateTime.now(); validDate.value = DateTime.now();
    dailyIssueDate.value = DateTime.now(); dailyValidDate.value = DateTime.now();
    _autoSetIssueTime();
    
    weatherSummary.value = ''; stateOfSea.value = 'Calm'; warningText.value = '';
    dailyWeatherSummary.value = ''; dailyStateOfSea.value = 'Calm'; dailyWarningText.value = '';
    
    // SAFE RESET
    for (var param in parameters) { 
      tableData[param] = {"12h": "-", "24h": "-"}; 
      dailyTableData[param] = {"12h": "-", "24h": "-"}; 
    }
    
    finishedRegions.clear(); editablePoints.clear(); mapItems.clear();
    _clearActiveDrawingState();

    tabController.animateTo(1); 
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

  void selectPolygonForEditing(LatLng tapPoint) {
    for (int i = finishedRegions.length - 1; i >= 0; i--) {
      if (_isPointInPolygon(tapPoint, finishedRegions[i].points)) {
        final regionToEdit = finishedRegions.removeAt(i);
        _originalRegionToEdit = MarineMapRegion(points: List.from(regionToEdit.points), color: regionToEdit.color);
        setColor(regionToEdit.color);
        editablePoints.assignAll(regionToEdit.points.asMap().entries.map((e) => MarineEditablePoint(e.value, e.key)));
        _undoStack.clear(); 
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
  
  void addMapItem(MarineItemType type, String value, LatLng spawnPoint) => mapItems.add(MarineMapItem(id: DateTime.now().millisecondsSinceEpoch.toString(), type: type, value: value, position: spawnPoint));
  void updateMapItemPos(String id, LatLng newPos) {
    final index = mapItems.indexWhere((item) => item.id == id);
    if (index != -1) { mapItems[index].position = newPos; mapItems.refresh(); }
  }
  void deleteMapItem(String id) => mapItems.removeWhere((item) => item.id == id);

  // ========================================================================
  // 4. DATABASE SAVE / PUBLISH / APPROVE / REVOKE
  // ========================================================================
  var isPublishing = false.obs;

   Future<void> saveForecast(String status) async {
    if (!canCreate) {
      Get.snackbar('Access Denied', 'You do not have permission to create marine forecasts.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    String finalStatus = status;
    if (status == 'published' && !isAdmin) {
      finalStatus = 'pending_approval';
    }

    try {
      isPublishing.value = true;
      final user = _authCtrl.currentUser.value!;

      final data = {
        'dailyIssueDate': dailyIssueDate.value.toIso8601String(),
        'dailyValidDate': dailyValidDate.value.toIso8601String(),
        'dailyIssueTime': dailyIssueTime.value,
        'dailyValidTime': dailyValidTime.value,
        'dailyWeatherSummary': dailyWeatherSummary.value,
        'dailyStateOfSea': dailyStateOfSea.value,
        'dailyWarningText': dailyWarningText.value,
        'dailyTableData': dailyTableData,
        'issueDate': issueDate.value.toIso8601String(),
        'validDate': validDate.value.toIso8601String(),
        'issueTime': issueTime.value,
        'validTime': validTime.value,
        'weatherSummary': weatherSummary.value,
        'stateOfSea': stateOfSea.value,
        'warningText': warningText.value,
        'tableData': tableData,
        'mapRegions': finishedRegions.map((r) => {
          'color': r.color,
          'points': r.points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList()
        }).toList(),
        'mapItems': mapItems.map((item) => {
          'id': item.id,
          'type': item.type == MarineItemType.icon ? 'icon' : 'text',
          'value': item.value,
          'lat': item.position.latitude,
          'lng': item.position.longitude,
        }).toList(),
        'status': finalStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'author': {
          'uid': user.uid,
          'name': user.name,
          'role': user.role,
        }
      };

      if (currentForecastId.value == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _firestore.collection('coastline_forecasts').add(data);
        currentForecastId.value = docRef.id;
      } else {
        await _firestore.collection('coastline_forecasts').doc(currentForecastId.value).update(data);
      }

      await fetchForecastHistory();
      await fetchAnalytics();

      String message = finalStatus == 'published' ? "Forecast Published Successfully." 
                     : finalStatus == 'pending_approval' ? "Submitted for Admin Approval." 
                     : "Draft Saved.";

      Get.snackbar(
        "Success", message,
        backgroundColor: Colors.green.shade600, colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20),
        icon: Icon(PhosphorIcons.checkCircle(), color: Colors.white),
      );
      
      tabController.animateTo(0);
    } catch (e) {
      Get.snackbar("Error", "Failed to save: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isPublishing.value = false;
    }
  }

  void loadForecastForEditing(Map<String, dynamic> forecast, {bool isViewOnly = false}) {
    currentForecastId.value = forecast['id'];
    currentForecast.value = forecast;

    dailyIssueDate.value = DateTime.tryParse(forecast['dailyIssueDate'] ?? '') ?? DateTime.now();
    dailyValidDate.value = DateTime.tryParse(forecast['dailyValidDate'] ?? '') ?? DateTime.now();
    dailyIssueTime.value = forecast['dailyIssueTime'] ?? '0500Z';
    dailyValidTime.value = forecast['dailyValidTime'] ?? '0600Z';
    dailyWeatherSummary.value = forecast['dailyWeatherSummary'] ?? '';
    dailyStateOfSea.value = forecast['dailyStateOfSea'] ?? 'Calm';
    dailyWarningText.value = forecast['dailyWarningText'] ?? '';

    // SAFE LOAD: Guarantees keys exist even for old legacy data
    for (var param in parameters) { 
      dailyTableData[param] = {"12h": "-", "24h": "-"}; 
      tableData[param] = {"12h": "-", "24h": "-"}; 
    }

    if (forecast['dailyTableData'] != null) {
      Map<String, dynamic> savedDailyTable = forecast['dailyTableData'];
      for (var param in parameters) {
        if (savedDailyTable.containsKey(param)) {
           dailyTableData[param] = Map<String, dynamic>.from(savedDailyTable[param]);
        }
      }
      dailyTableData.refresh();
    }

    issueDate.value = DateTime.tryParse(forecast['issueDate'] ?? '') ?? DateTime.now();
    validDate.value = DateTime.tryParse(forecast['validDate'] ?? '') ?? DateTime.now();
    issueTime.value = forecast['issueTime'] ?? '0500Z';
    validTime.value = forecast['validTime'] ?? '0600Z';
    weatherSummary.value = forecast['weatherSummary'] ?? '';
    stateOfSea.value = forecast['stateOfSea'] ?? 'Calm';
    warningText.value = forecast['warningText'] ?? '';

    if (forecast['tableData'] != null) {
      Map<String, dynamic> savedTable = forecast['tableData'];
      for (var param in parameters) {
        if (savedTable.containsKey(param)) {
          tableData[param] = Map<String, dynamic>.from(savedTable[param]);
        }
      }
      tableData.refresh();
    }

    finishedRegions.clear();
    editablePoints.clear();
    _clearActiveDrawingState();
    
    if (forecast['mapRegions'] != null) {
      for (var r in forecast['mapRegions']) {
        List<LatLng> pts = (r['points'] as List).map((p) => LatLng(p['lat'], p['lng'])).toList();
        finishedRegions.add(MarineMapRegion(points: pts, color: r['color'] ?? 'green'));
      }
    }

    mapItems.clear();
    if (forecast['mapItems'] != null) {
      for (var i in forecast['mapItems']) {
        mapItems.add(MarineMapItem(
          id: i['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: i['type'] == 'icon' ? MarineItemType.icon : MarineItemType.text,
          value: i['value'],
          position: LatLng(i['lat'], i['lng'])
        ));
      }
    }

    tabController.animateTo(1);
  }

  Future<void> updateForecastStatus(String id, String newStatus) async {
    if (!canApprove) {
      Get.snackbar('Access Denied', 'Only Marine Admins can change statuses.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    try {
      await _firestore.collection('coastline_forecasts').doc(id).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await fetchForecastHistory();
      Get.snackbar('Status Updated', 'Forecast is now $newStatus.', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status.', backgroundColor: Colors.red, colorText: Colors.white);
    }
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
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';

// // ============================================================================
// // CONTROLLER
// // ============================================================================
// class CoastlineForecastController extends GetxController with GetTickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AuthController _authCtrl = Get.find<AuthController>();

//   late TabController tabController;

//   // --- ROLE-BASED ACCESS CONTROL (RBAC) ---
//   bool get isMarineUser {
//     final dept = _authCtrl.currentUser.value?.department.toLowerCase();
//     return dept == 'marine' ;
//   }

//   bool get isAdmin {
//     final role = _authCtrl.currentUser.value?.role.toLowerCase() ?? '';
//     return role.contains('admin');
//   }

//   bool get canCreate => isMarineUser;
//   bool get canApprove => isMarineUser && isAdmin;
// // --- MISSING VARIABLES FIXED ---
//   var currentForecast = Rxn<dynamic>(); // Fixes the InfoSidePanel error

//   // KPI Analytics Variables
//   final kpiTotal = 0.obs;
//   final kpiDraft = 0.obs;
//   final kpiPending = 0.obs;
//   final kpiPublished = 0.obs;
//   // --- TOP-LEVEL NAVIGATION ---
//   final List<String> forecastTypes = ["Coastline Forecast", "Inland Forecast"];
//   var selectedForecastType = "Coastline Forecast".obs;

//   @override
//   @override
//   void onInit() {
//     super.onInit();
//     tabController = TabController(length: 2, vsync: this);
//     _autoSetIssueTime();
    
//     // Check if the user is already loaded
//     if (_authCtrl.currentUser.value != null) {
//       fetchForecastHistory();
//       fetchAnalytics();
//     } else {
//       // If user is null (like during a Hot Restart), wait for AuthController to restore the session
//       ever(_authCtrl.currentUser, (user) {
//         if (user != null && coastlineHistory.isEmpty) {
//           fetchForecastHistory();
//           fetchAnalytics();
//         }
//       });
//     }
//   }

//   @override
//   void onClose() {
//     tabController.dispose();
//     super.onClose();
//   }

//   // ========================================================================
//   // 1. HISTORY TAB & PAGINATION
//   // ========================================================================
//   var isLoadingHistory = false.obs;
//   var isFetchingMore = false.obs;
//   var hasMore = true.obs;
//   DocumentSnapshot? _lastDocument;
//   final int _pageSize = 15;

//   var coastlineHistory = <Map<String, dynamic>>[].obs;



// // ========================================================================
//   // ANALYTICS (OPTIMIZED COUNT QUERIES WITH ROLE CHECK)
//   // ========================================================================
//   Future<void> fetchAnalytics() async {
//     final user = _authCtrl.currentUser.value;
//     if (user == null) return;

//     Query baseQuery = _firestore.collection('coastline_forecasts');
    
//     // Filter to only this user's posts if they are not an admin
//     if (!isAdmin) {
//       baseQuery = baseQuery.where('author.uid', isEqualTo: user.uid);
//     }

//     try {
//       final total = await baseQuery.count().get();
//       final draft = await baseQuery.where('status', isEqualTo: 'draft').count().get();
//       final pending = await baseQuery.where('status', isEqualTo: 'pending_approval').count().get();
//       final published = await baseQuery.where('status', isEqualTo: 'published').count().get();

//       kpiTotal.value = total.count ?? 0;
//       kpiDraft.value = draft.count ?? 0;
//       kpiPending.value = pending.count ?? 0;
//       kpiPublished.value = published.count ?? 0;
//     } catch (e) {
//       debugPrint("Analytics Error: $e");
//     }
//   }

//   Future<void> fetchForecastHistory() async {
//     if (!isMarineUser) return; // Security Guard

//     try {
//       isLoadingHistory.value = true;
//       hasMore.value = true;
//       _lastDocument = null;

//       final user = _authCtrl.currentUser.value;
//       if (user == null) return;

//       Query query = _firestore.collection('coastline_forecasts')
//           .orderBy('updatedAt', descending: true)
//           .limit(_pageSize);

//       // If they are not an admin, they only see their own forecasts
//       if (!isAdmin) {
//         query = query.where('author.uid', isEqualTo: user.uid);
//       }

//       QuerySnapshot snapshot = await query.get();
      
//       if (snapshot.docs.isNotEmpty) {
//         _lastDocument = snapshot.docs.last; 
//         if (snapshot.docs.length < _pageSize) hasMore.value = false; 
//       } else {
//         hasMore.value = false;
//       }

//       coastlineHistory.value = snapshot.docs.map((doc) {
//         var data = doc.data() as Map<String, dynamic>;
//         data['id'] = doc.id; 
//         return data;
//       }).toList();

//     } catch (e) {
//       debugPrint("History Fetch Error: $e");
//     } finally {
//       isLoadingHistory.value = false;
//     }
//   }

//   Future<void> fetchMoreForecasts() async {
//     if (isFetchingMore.value || !hasMore.value || _lastDocument == null) return;
//     if (!isMarineUser) return;

//     final user = _authCtrl.currentUser.value;
//     if (user == null) return;

//     try {
//       isFetchingMore.value = true;
//       Query query = _firestore.collection('coastline_forecasts')
//           .orderBy('updatedAt', descending: true)
//           .startAfterDocument(_lastDocument!) 
//           .limit(_pageSize);

//       if (!isAdmin) {
//         query = query.where('author.uid', isEqualTo: user.uid);
//       }

//       QuerySnapshot snapshot = await query.get();

//       if (snapshot.docs.isNotEmpty) {
//         _lastDocument = snapshot.docs.last; 
//         if (snapshot.docs.length < _pageSize) hasMore.value = false;

//         var newDocs = snapshot.docs.map((doc) {
//           var data = doc.data() as Map<String, dynamic>;
//           data['id'] = doc.id;
//           return data;
//         }).toList();
//         coastlineHistory.addAll(newDocs); 
//       } else {
//         hasMore.value = false;
//       }
//     } catch (e) {
//       debugPrint("Pagination Error: $e");
//     } finally {
//       isFetchingMore.value = false;
//     }
//   }

//   // ========================================================================
//   // 2. DATA ENTRY STATE (TIME & TABLE)
//   // ========================================================================
//   var currentForecastId = RxnString(null);

//   var issueDate = DateTime.now().obs;
//   var validDate = DateTime.now().obs;
//   var issueTime = "0500Z".obs;
//   var validTime = "0600Z".obs;

//   final List<String> zTimeOptions = ["0500Z", "1100Z", "1700Z", "2300Z"];

//   void _autoSetIssueTime() {
//     final hour = DateTime.now().toUtc().hour;
//     String newTime = '0500Z';
//     String vTime = '0600Z';

//     if (hour < 6) {
//       newTime = '0500Z'; vTime = '0600Z';
//     } else if (hour < 12) {
//       newTime = '1100Z'; vTime = '1200Z';
//     } else if (hour < 18) {
//       newTime = '1700Z'; vTime = '1800Z';
//     } else if (hour < 23) {
//       newTime = '2300Z'; vTime = '0000Z';
//     } else {
//       newTime = '0500Z'; vTime = '0600Z';
//     }
    
//     issueTime.value = newTime;
//     validTime.value = vTime;
//   }

//   // Triggered if the admin manually changes the issue time from the dropdown
//   void updateIssueTime(String time) {
//     issueTime.value = time;
//     if (time == '0500Z') validTime.value = '0600Z';
//     else if (time == '1100Z') validTime.value = '1200Z';
//     else if (time == '1700Z') validTime.value = '1800Z';
//     else if (time == '2300Z') validTime.value = '0000Z';
//   }

//   // Weather Summary & Sea State
//   var weatherSummary = "".obs;
//   var stateOfSea = "Calm".obs;
//   var warningText = "".obs;

//   final List<String> seaStateOptions = ["Calm", "Moderate", "Rough"];

//   final List<String> parameters = [
//     "SURFACE WIND", "VISIBILITY", "SEA SURFACE TEMPERATURE", 
//     "SIG WAVE HEIGHT", "TIDAL WAVE", "WAVE CURRENT"
//   ];

//   var tableData = <String, Map<String, dynamic>>{
//     "SURFACE WIND": {"12h": "-", "24h": "-"},
//     "VISIBILITY": {"12h": "-", "24h": "-"},
//     "SEA SURFACE TEMPERATURE": {"12h": "-", "24h": "-"},
//     "SIG WAVE HEIGHT": {"12h": "-", "24h": "-"},
//     "TIDAL WAVE": {"12h": "-", "24h": "-"},
//     "WAVE CURRENT": {"12h": "-", "24h": "-"},
//   }.obs;

//   // In CoastlineForecastController
// void updateTableData(String param, String period, String value) {
//   tableData[param]![period] = value;
//   tableData.refresh(); // If using GetX
// }


//   void createNewForecast() {
//     if (!canCreate) return;
//     currentForecastId.value = null;
//     issueDate.value = DateTime.now();
//     validDate.value = DateTime.now();
//     _autoSetIssueTime();
    
//     weatherSummary.value = '';
//     stateOfSea.value = 'Calm';
//     warningText.value = '';
    
//     // Reset Table
//     for (var param in parameters) {
//       tableData[param] = {"12h": "-", "24h": "-"};
//     }
    
//     // Reset Map
//     finishedRegions.clear();
//     editablePoints.clear();
//     mapItems.clear();
//     _clearActiveDrawingState();

//     tabController.animateTo(1);
//   }

//   // ========================================================================
//   // 3. IBF MAP DRAWING ENGINE
//   // ========================================================================
//   final mapController = MapController();
  
//   var isDrawing = false.obs;
//   var selectedColor = 'green'.obs;
//   var draggedPointIndex = RxnInt();
//   MarineMapRegion? _originalRegionToEdit; 

//   final finishedRegions = <MarineMapRegion>[].obs;
//   final editablePoints = <MarineEditablePoint>[].obs;
//   final mapItems = <MarineMapItem>[].obs;
//   final _undoStack = <List<MarineEditablePoint>>[];

//   // --- Drawing Actions ---
//   void startDrawing() { isDrawing.value = true; _originalRegionToEdit = null; }
//   void setColor(String c) => selectedColor.value = c;
  
//   Color get activeColor {
//     switch (selectedColor.value) {
//       case 'red': return Colors.red;
//       case 'orange': return Colors.orange;
//       case 'yellow': return Colors.yellow;
//       case 'green': return Colors.green;
//       default: return Colors.blue;
//     }
//   }

//   void addEditablePoint(LatLng point) => editablePoints.add(MarineEditablePoint(point, editablePoints.length));
//   void updateEditablePoint(int index, LatLng newPos) {
//     if (index >= 0 && index < editablePoints.length) { editablePoints[index].position = newPos; editablePoints.refresh(); }
//   }
//   void removeEditablePoint(int index) {
//     if (index >= 0 && index < editablePoints.length) { saveUndoState(); editablePoints.removeAt(index); }
//   }

//   void finishDrawing() {
//     if (editablePoints.length < 3) { Get.snackbar("Error", "Need at least 3 points.", backgroundColor: Colors.red, colorText: Colors.white); return; }
//     finishedRegions.add(MarineMapRegion(points: editablePoints.map((e) => e.position).toList(), color: selectedColor.value));
//     _clearActiveDrawingState();
//   }

//   void cancelDrawing() {
//     if (_originalRegionToEdit != null) finishedRegions.add(_originalRegionToEdit!); 
//     _clearActiveDrawingState();
//   }
//   void deleteActiveDrawing() => _clearActiveDrawingState(); 

//   void _clearActiveDrawingState() {
//     editablePoints.clear(); _undoStack.clear(); isDrawing.value = false; _originalRegionToEdit = null;
//   }

//   void saveUndoState() => _undoStack.add(editablePoints.map((e) => MarineEditablePoint(e.position, e.id)).toList());
//   void undo() {
//     if (_undoStack.isNotEmpty) editablePoints.assignAll(_undoStack.removeLast());
//     else if (editablePoints.isNotEmpty) editablePoints.removeLast();
//   }
// // --- Ray-Casting & Editing ---
//   void selectPolygonForEditing(LatLng tapPoint) {
//     for (int i = finishedRegions.length - 1; i >= 0; i--) {
//       if (_isPointInPolygon(tapPoint, finishedRegions[i].points)) {
//         final regionToEdit = finishedRegions.removeAt(i);
//         _originalRegionToEdit = MarineMapRegion(points: List.from(regionToEdit.points), color: regionToEdit.color);
//         setColor(regionToEdit.color);
//         editablePoints.assignAll(regionToEdit.points.asMap().entries.map((e) => MarineEditablePoint(e.value, e.key)));
//         _undoStack.clear(); 
//         isDrawing.value = true; 
//         break; 
//       }
//     }
//   }

//   bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
//     if (polygon.length < 3) return false;
//     int intersectCount = 0;
//     for (int j = 0; j < polygon.length - 1; j++) {
//       if (_rayCastIntersect(point, polygon[j], polygon[j + 1])) intersectCount++;
//     }
//     if (_rayCastIntersect(point, polygon.last, polygon.first)) intersectCount++;
//     return (intersectCount % 2) == 1; 
//   }

//   bool _rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
//     double aY = vertA.latitude, bY = vertB.latitude; 
//     double aX = vertA.longitude, bX = vertB.longitude;
//     double pY = point.latitude, pX = point.longitude;
//     if ((aY > pY) != (bY > pY)) {
//       double intersectX = ((bX - aX) * (pY - aY) / (bY - aY)) + aX;
//       if (pX < intersectX) return true;
//     }
//     return false;
//   }
//   // --- Icons & Letters ---
//   void addMapItem(MarineItemType type, String value, LatLng spawnPoint) => mapItems.add(MarineMapItem(id: DateTime.now().millisecondsSinceEpoch.toString(), type: type, value: value, position: spawnPoint));
//   void updateMapItemPos(String id, LatLng newPos) {
//     final index = mapItems.indexWhere((item) => item.id == id);
//     if (index != -1) { mapItems[index].position = newPos; mapItems.refresh(); }
//   }
//   void deleteMapItem(String id) => mapItems.removeWhere((item) => item.id == id);

//   // ========================================================================
//   // 4. DATABASE SAVE / PUBLISH / APPROVE / REVOKE
//   // ========================================================================
//   var isPublishing = false.obs;

//    Future<void> saveForecast(String status) async {
//     if (!canCreate) {
//       Get.snackbar('Access Denied', 'You do not have permission to create marine forecasts.', backgroundColor: Colors.red, colorText: Colors.white);
//       return;
//     }

//     String finalStatus = status;
//     if (status == 'published' && !isAdmin) {
//       finalStatus = 'pending_approval';
//     }

//     try {
//       isPublishing.value = true;
//       final user = _authCtrl.currentUser.value!;

//       // Package Data (NOW INCLUDES MAP REGIONS AND ITEMS)
//       final data = {
//         'issueDate': issueDate.value.toIso8601String(),
//         'validDate': validDate.value.toIso8601String(),
//         'issueTime': issueTime.value,
//         'validTime': validTime.value,
//         'weatherSummary': weatherSummary.value,
//         'stateOfSea': stateOfSea.value,
//         'warningText': warningText.value,
//         'tableData': tableData,
//         'mapRegions': finishedRegions.map((r) => {
//           'color': r.color,
//           'points': r.points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList()
//         }).toList(),
//         'mapItems': mapItems.map((item) => {
//           'id': item.id,
//           'type': item.type == MarineItemType.icon ? 'icon' : 'text',
//           'value': item.value,
//           'lat': item.position.latitude,
//           'lng': item.position.longitude,
//         }).toList(),
//         'status': finalStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//         'author': {
//           'uid': user.uid,
//           'name': user.name,
//           'role': user.role,
//         }
//       };

//       if (currentForecastId.value == null) {
//         data['createdAt'] = FieldValue.serverTimestamp();
//         final docRef = await _firestore.collection('coastline_forecasts').add(data);
//         currentForecastId.value = docRef.id;
//       } else {
//         await _firestore.collection('coastline_forecasts').doc(currentForecastId.value).update(data);
//       }

//       await fetchForecastHistory();
//       await fetchAnalytics();

//       String message = finalStatus == 'published' ? "Forecast Published Successfully." 
//                      : finalStatus == 'pending_approval' ? "Submitted for Admin Approval." 
//                      : "Draft Saved.";

//       Get.snackbar(
//         "Success", message,
//         backgroundColor: Colors.green.shade600, colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20),
//         icon: Icon(PhosphorIcons.checkCircle(), color: Colors.white),
//       );
      
//       tabController.animateTo(0);
//     } catch (e) {
//       Get.snackbar("Error", "Failed to save: $e", backgroundColor: Colors.red, colorText: Colors.white);
//     } finally {
//       isPublishing.value = false;
//     }
//   }


// // ========================================================================
//   // EDIT & LOAD FORECAST LOGIC
//   // ========================================================================
//   void loadForecastForEditing(Map<String, dynamic> forecast, {bool isViewOnly = false}) {
//     currentForecastId.value = forecast['id'];
//     currentForecast.value = forecast;

//     issueDate.value = DateTime.tryParse(forecast['issueDate'] ?? '') ?? DateTime.now();
//     validDate.value = DateTime.tryParse(forecast['validDate'] ?? '') ?? DateTime.now();
//     issueTime.value = forecast['issueTime'] ?? '0500Z';
//     validTime.value = forecast['validTime'] ?? '0600Z';

//     weatherSummary.value = forecast['weatherSummary'] ?? '';
//     stateOfSea.value = forecast['stateOfSea'] ?? 'Calm';
//     warningText.value = forecast['warningText'] ?? '';

//     // 1. Load Table Data
//     if (forecast['tableData'] != null) {
//       Map<String, dynamic> savedTable = forecast['tableData'];
//       for (var param in parameters) {
//         if (savedTable.containsKey(param)) {
//           tableData[param] = Map<String, dynamic>.from(savedTable[param]);
//         }
//       }
//       tableData.refresh();
//     }

//     // 2. Load Map Regions (Polygons)
//     finishedRegions.clear();
//     editablePoints.clear();
//     _clearActiveDrawingState();
    
//     if (forecast['mapRegions'] != null) {
//       for (var r in forecast['mapRegions']) {
//         List<LatLng> pts = (r['points'] as List).map((p) => LatLng(p['lat'], p['lng'])).toList();
//         finishedRegions.add(MarineMapRegion(points: pts, color: r['color'] ?? 'green'));
//       }
//     }

//     // 3. Load Map Items (Icons & Letters)
//     mapItems.clear();
//     if (forecast['mapItems'] != null) {
//       for (var i in forecast['mapItems']) {
//         mapItems.add(MarineMapItem(
//           id: i['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
//           type: i['type'] == 'icon' ? MarineItemType.icon : MarineItemType.text,
//           value: i['value'],
//           position: LatLng(i['lat'], i['lng'])
//         ));
//       }
//     }

//     // Jump to the input tab
//     tabController.animateTo(1);
//   }

//   Future<void> updateForecastStatus(String id, String newStatus) async {
//     if (!canApprove) {
//       Get.snackbar('Access Denied', 'Only Marine Admins can change statuses.', backgroundColor: Colors.red, colorText: Colors.white);
//       return;
//     }
//     try {
//       await _firestore.collection('coastline_forecasts').doc(id).update({
//         'status': newStatus,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//       await fetchForecastHistory();
//       Get.snackbar('Status Updated', 'Forecast is now $newStatus.', backgroundColor: Colors.green, colorText: Colors.white);
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to update status.', backgroundColor: Colors.red, colorText: Colors.white);
//     }
//   }
// }

// // ============================================================================
// // MAP MODELS
// // ============================================================================
// enum MarineItemType { icon, text }

// class MarineMapItem {
//   final String id;
//   final MarineItemType type;
//   final String value;
//   LatLng position;
//   MarineMapItem({required this.id, required this.type, required this.value, required this.position});
// }

// class MarineMapRegion {
//   final List<LatLng> points;
//   final String color;
//   MarineMapRegion({required this.points, required this.color});
// }

// class MarineEditablePoint {
//   LatLng position;
//   final int id;
//   MarineEditablePoint(this.position, this.id);
// }