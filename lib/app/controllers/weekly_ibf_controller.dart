import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';
import 'package:weather_admin_dashboard/app/model/forecastData.dart';
import 'package:weather_admin_dashboard/app/model/weeklyEditablePoint.dart';
import 'package:weather_admin_dashboard/app/model/weeklyItemType.dart';
import 'package:weather_admin_dashboard/app/model/weeklyMapItem.dart';
import 'package:weather_admin_dashboard/app/model/weeklyMapRegion.dart';
import 'dart:html' as html;
import 'package:printing/printing.dart';
import 'package:weather_admin_dashboard/app/services/weekly_image_generator.dart';
import 'package:weather_admin_dashboard/app/services/weekly_ibf_pdf_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class WeeklyIBFController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  final AuthController _authCtrl = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    _autoSetIssueTime();
  }

  @override
  void onReady() {
    super.onReady();
    if (_authCtrl.currentUser.value != null) {
      _initDynamicData();
    }
    ever(_authCtrl.currentUser, (user) {
      if (user != null) _initDynamicData();
    });
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  // ========================================================================
  // 1. HISTORY TAB & ANALYTICS STATE
  // ========================================================================
  var kpiTotal = 0.obs;
  var kpiDraft = 0.obs;
  var kpiPending = 0.obs;
  var kpiPublished = 0.obs;

  var isLoadingList = true.obs;
  var isFetchingMore = false.obs;
  var hasMore = true.obs;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 10;

  var forecastsList = <Map<String, dynamic>>[].obs;

  var isAdmin = false.obs; 
  var isSuperAdmin = false.obs; 
  var currentForecast = Rxn<ForecastData>(); 

  Future<void> _initDynamicData() async {
    final user = _authCtrl.currentUser.value;
    if (user != null) {
      isAdmin.value = user.role.contains('admin') || user.role.contains('super_admin');
      isSuperAdmin.value = user.role.contains('admin') || user.role.contains('super_admin');
    }
    await fetchAnalytics();
    await fetchForecastHistory();
  }

   // ========================================================================
  // 2. ANALYTICS (OPTIMIZED COUNT QUERIES WITH ROLE CHECK)
  // ========================================================================
  Future<void> fetchAnalytics() async {
    final user = _authCtrl.currentUser.value;
    if (user == null) return;

    Query baseQuery = _firestore.collection('weekly_forecasts');
    
    // Filter to only this user's posts if they are not an admin
    if (!isAdmin.value) {
      baseQuery = baseQuery.where('author.uid', isEqualTo: user.uid);
    }

    try {
      // .count() is highly optimized by Firebase. Costs 1 read per execution.
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

  // ========================================================================
  // 3. FETCH HISTORY & PAGINATION (WITH ROLE CHECK)
  // ========================================================================
  Future<void> fetchForecastHistory() async {
    try {
      isLoadingList.value = true;
      hasMore.value = true;
      _lastDocument = null;

      final user = _authCtrl.currentUser.value;
      if (user == null) return;

      Query query = _firestore.collection('weekly_forecasts')
          .orderBy('updatedAt', descending: true)
          .limit(_pageSize);

      // Apply role filter
      if (!isAdmin.value) {
        query = query.where('author.uid', isEqualTo: user.uid);
      }

      QuerySnapshot snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last; 
        if (snapshot.docs.length < _pageSize) hasMore.value = false; 
      } else {
        hasMore.value = false;
      }

      forecastsList.value = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        return data;
      }).toList();

    } catch (e) {
      debugPrint("History Fetch Error: $e");
    } finally {
      isLoadingList.value = false;
    }
  }

  Future<void> fetchMoreForecasts() async {
    if (isFetchingMore.value || !hasMore.value || _lastDocument == null) return;

    final user = _authCtrl.currentUser.value;
    if (user == null) return;

    try {
      isFetchingMore.value = true;
      Query query = _firestore.collection('weekly_forecasts')
          .orderBy('updatedAt', descending: true)
          .startAfterDocument(_lastDocument!) 
          .limit(_pageSize);

      // Apply role filter to pagination as well
      if (!isAdmin.value) {
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
        forecastsList.addAll(newDocs); 
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      debugPrint("Pagination Error: $e");
    } finally {
      isFetchingMore.value = false;
    }
  }

  void createNewForecast() {
    validFrom.value = DateTime.now();
    _autoSetIssueTime();
    _initializeTable();
    shortDescription.value = '';
    for (var p in ['day1', 'day2', 'day3']) {
      finishedRegions[p]!.clear();
      editablePoints[p]!.clear();
      mapItems[p]!.clear();
    }
    tabController.animateTo(1);
  }
  // ========================================================================
  // 2. TIME & DATE CONTROLS
  // ========================================================================
  var validFrom = DateTime.now().obs;
  
  var selectedIssueTime = '0500'.obs;
  final issueTimeOptions = ['0500', '1100', '1700', '2300'];

  List<DateTime> get dynamicDates => [validFrom.value, validFrom.value.add(const Duration(days: 1)), validFrom.value.add(const Duration(days: 2))];
  
  void updateStartDate(DateTime date) => validFrom.value = date;

// <--- ADD THIS ENTIRE FUNCTION HERE
  void _autoSetIssueTime() {
    final hour = DateTime.now().toUtc().hour;
    String newTime = '0500';

    if (hour < 6) {
      newTime = '0500';
    } else if (hour < 12) {
      newTime = '1100';
    } else if (hour < 18) {
      newTime = '1700';
    } else if (hour < 23) {
      newTime = '2300';
    } else {
      newTime = '0500';
    }
    
    selectedIssueTime.value = newTime;
  }

  String _calculateValidityString(DateTime start, String issueTime) {
    String valTime = '0600';
    if (issueTime == '1100') {
      valTime = '1200';
    } else if (issueTime == '1700'){ valTime = '1800';}
    else if (issueTime == '2300'){ valTime = '0000';}

    String startStr = DateFormat('dd MMM yyyy').format(start);
    String endStr = DateFormat('dd MMM yyyy').format(start.add(const Duration(days: 2)));

    if (issueTime == '2300') {
      startStr = DateFormat('dd MMM yyyy').format(start.add(const Duration(days: 1)));
      endStr = DateFormat('dd MMM yyyy').format(start.add(const Duration(days: 7)));
    }

    return '$valTime UTC $startStr  TO  $valTime UTC $endStr';
  }

  // ========================================================================
  // 3. MAP DRAWING ENGINE
  // ========================================================================
  final mapControllers = { 'day1': MapController(), 'day2': MapController(), 'day3': MapController() };
  var isDrawing = false.obs;
  var activeMapPeriod = ''.obs; 
  var selectedColor = 'green'.obs;
  var draggedPointIndex = RxnInt();
  WeeklyMapRegion? _originalRegionToEdit; 

  final finishedRegions = { 'day1': <WeeklyMapRegion>[].obs, 'day2': <WeeklyMapRegion>[].obs, 'day3': <WeeklyMapRegion>[].obs };
  final editablePoints = { 'day1': <WeeklyEditablePoint>[].obs, 'day2': <WeeklyEditablePoint>[].obs, 'day3': <WeeklyEditablePoint>[].obs };
  final mapItems = { 'day1': <WeeklyMapItem>[].obs, 'day2': <WeeklyMapItem>[].obs, 'day3': <WeeklyMapItem>[].obs };
  final _undoStack = { 'day1': <List<WeeklyEditablePoint>>[], 'day2': <List<WeeklyEditablePoint>>[], 'day3': <List<WeeklyEditablePoint>>[] };

  void setActiveMapPeriod(String p) => activeMapPeriod.value = p; 
  void startDrawing(String p) { activeMapPeriod.value = p; isDrawing.value = true; _originalRegionToEdit = null; }
  void setColor(String c) => selectedColor.value = c;
  
  Color get activeColor {
    switch (selectedColor.value) {
      case 'red': return Colors.red; case 'orange': return Colors.orange; case 'yellow': return Colors.yellow; case 'green': return Colors.green; default: return Colors.blue;
    }
  }

  void addEditablePoint(String p, LatLng point) => editablePoints[p]!.add(WeeklyEditablePoint(point, editablePoints[p]!.length));
  void updateEditablePoint(String p, int index, LatLng newPos) {
    if (index >= 0 && index < editablePoints[p]!.length) { editablePoints[p]![index].position = newPos; editablePoints[p]!.refresh(); }
  }
  void removeEditablePoint(String p, int index) {
    if (index >= 0 && index < editablePoints[p]!.length) { saveUndoState(p); editablePoints[p]!.removeAt(index); }
  }

  void finishDrawing(String p) {
    if (editablePoints[p]!.length < 3) { Get.snackbar("Invalid Polygon", "You need at least 3 points.", backgroundColor: Colors.red, colorText: Colors.white); return; }
    finishedRegions[p]!.add(WeeklyMapRegion(points: editablePoints[p]!.map((e) => e.position).toList(), color: selectedColor.value));
    _clearActiveDrawingState(p);
  }

  void cancelDrawing(String p) {
    if (_originalRegionToEdit != null) finishedRegions[p]!.add(_originalRegionToEdit!); 
    _clearActiveDrawingState(p);
  }

  void deleteActiveDrawing(String p) => _clearActiveDrawingState(p); 
  void _clearActiveDrawingState(String p) { editablePoints[p]!.clear(); _undoStack[p]!.clear(); isDrawing.value = false; activeMapPeriod.value = ''; _originalRegionToEdit = null; }
  void saveUndoState(String p) => _undoStack[p]!.add(editablePoints[p]!.map((e) => WeeklyEditablePoint(e.position, e.id)).toList());

  void undo(String p) {
    if (_undoStack[p]!.isNotEmpty) {
      editablePoints[p]!.assignAll(_undoStack[p]!.removeLast());
    } else if (editablePoints[p]!.isNotEmpty) {editablePoints[p]!.removeLast();}
  }

  void selectPolygonForEditing(String p, LatLng tapPoint) {
    for (int i = finishedRegions[p]!.length - 1; i >= 0; i--) {
      final regionToEdit = finishedRegions[p]!.removeAt(i);
      _originalRegionToEdit = WeeklyMapRegion(points: List.from(regionToEdit.points), color: regionToEdit.color);
      setActiveMapPeriod(p); setColor(regionToEdit.color);
      editablePoints[p]!.assignAll(regionToEdit.points.asMap().entries.map((e) => WeeklyEditablePoint(e.value, e.key)));
      _undoStack[p]!.clear(); isDrawing.value = true; break; 
    }
  }

  // ========================================================================
  // 4. ICONS & LETTERS LOGIC
  // ========================================================================
  void addMapItem(String p, WeeklyItemType type, String value, LatLng spawnPoint) {
    mapItems[p]!.add(WeeklyMapItem(id: DateTime.now().millisecondsSinceEpoch.toString(),
           type: type, value: value, position: spawnPoint));
  }

  void updateMapItemPos(String p, String id, LatLng newPos) {
    final index = mapItems[p]!.indexWhere((item) => item.id == id);
    if (index != -1) { mapItems[p]![index].position = newPos; mapItems[p]!.refresh(); }
  }
  void deleteMapItem(String p, String id) => mapItems[p]!.removeWhere((item) => item.id == id);

  // ========================================================================
  // 5. STRUCTURED IBF TABLE DATA
  // ========================================================================
  final List<String> sectors = ["COASTLINE", "SLIGHTLY NORTH OF THE COASTLINE", "MIDDLE", "TRANSITION", "NORTH"];
  final List<String> riskLevels = ["White (No Risk)", "Green (Low Risk)", "Yellow (Moderate Risk)", "Orange (Medium Risk)", "Red (High Risk)"];
  var ibfDetails = <String, List<Map<String, dynamic>>>{}.obs;
  var shortDescription = ''.obs;

  WeeklyIBFController() { _initializeTable(); }

  void _initializeTable() {
    for (var sector in sectors) {
      ibfDetails[sector] = List.generate(3, (index) => { "risk": "White (No Risk)", "cond1": "", "cond2": "", "cond3": "" });
    }
  }
 
   // ========================================================================
  // 6. CAFO-STYLE BATCH ANALYTICS & PUBLISHING
  // ========================================================================
  var isPublishing = false.obs;

  // Exact match to the CAFO method for atomic batch writing
  Future<void> _updateCountersWithBatch(String docId, String newStatus, Map<String, dynamic> payload, String authorUid) async {
    final docRef = _firestore.collection('weekly_forecasts').doc(docId);
    final userRef = _firestore.collection('users').doc(authorUid);
    final globalRef = _firestore.collection('analytics').doc('weekly_global');

    final existingDoc = await docRef.get();
    String? oldStatus;
    if (existingDoc.exists) {
      oldStatus = (existingDoc.data() as Map<String, dynamic>)['status'];
    }

    WriteBatch batch = _firestore.batch();
    batch.set(docRef, payload, SetOptions(merge: true));

    if (oldStatus != newStatus) {
      Map<String, dynamic> statIncrements = {};
      if (oldStatus == null) {
        statIncrements['total'] = FieldValue.increment(1);
        statIncrements[newStatus] = FieldValue.increment(1);
      } else {
        statIncrements[oldStatus] = FieldValue.increment(-1);
        statIncrements[newStatus] = FieldValue.increment(1);
      }

      batch.set(userRef, { 'weekly_stats': statIncrements }, SetOptions(merge: true));
      batch.set(globalRef, statIncrements, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // UPDATED: Now accepts an isDraft parameter
  Future<void> publishForecast({bool isDraft = false}) async {
    isPublishing.value = true;
    
    try {
      final user = _authCtrl.currentUser.value;
      if (user == null) throw Exception("User session expired.");

      // Calculate the final status based on the button clicked
      final finalStatus = isDraft 
          ? 'draft' 
          : (isSuperAdmin.value ? 'published' : 'pending_approval');
      
      String generatedValidity = _calculateValidityString(validFrom.value, selectedIssueTime.value);

      Map<String, dynamic> serializedRegions = {};
      finishedRegions.forEach((period, regions) {
        serializedRegions[period] = regions.map((r) => {
          'color': r.color,
          'points': r.points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList()
        }).toList();
      });

      Map<String, dynamic> serializedItems = {};
      mapItems.forEach((period, items) {
        serializedItems[period] = items.map((i) => {
          'id': i.id, 'type': i.type.name, 'value': i.value,
          'lat': i.position.latitude, 'lng': i.position.longitude
        }).toList();
      });

      Map<String, dynamic> payload = {
        'status': finalStatus,
        'validFrom': validFrom.value.toIso8601String(),
        'issueTime': selectedIssueTime.value,
        'validity': generatedValidity, 
        'areas': "${finishedRegions['day1']!.length + finishedRegions['day2']!.length + finishedRegions['day3']!.length} Polygons",
        'regions': serializedRegions,
        'markers': serializedItems,
        'ibfDetails': ibfDetails,
        'shortDescription': shortDescription.value,
        'updatedAt': FieldValue.serverTimestamp(),
        'author': { 'uid': user.uid, 'name': user.name, 'email': user.email }
      };

      String docId = 'WF_${DateFormat('yyyyMMdd').format(validFrom.value)}_${user.uid.substring(0, 5)}';

await _updateCountersWithBatch(docId, finalStatus, payload, user.uid);

      if (finalStatus == 'published') {
        await _autoPostWeeklyToCommunityGroups(docId);
      }
     

      // Show dynamic success messages based on what they clicked
      String title = isDraft ? "Draft Saved" : (isSuperAdmin.value ? "Published!" : "Sent for Approval");
      String message = isDraft ? "Forecast safely stored in your drafts." : (isSuperAdmin.value ? "Weekly Forecast is now live." : "Forecast routed to supervisor.");

      Get.snackbar(
        title, 
        message,
        backgroundColor: isDraft ? Colors.grey.shade800 : const Color(0xFF3DD68C).withOpacity(0.95), 
        colorText: isDraft ? Colors.white : Colors.black,
      );
      
      await fetchAnalytics();
      await fetchForecastHistory();
      tabController.animateTo(0);

    } catch (e) {
      debugPrint("Publish Error: $e");
      Get.snackbar('Error', 'Failed to save forecast.', backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isPublishing.value = false;
    }
  }

  Future<void> changeForecastStatus(String id, String status, String authorUid) async {
    try {
      final user = _authCtrl.currentUser.value;
      
      Map<String, dynamic> payload = {
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': user?.name ?? 'Admin',
      };

      // UPDATED: Now uses the atomic batch function
      await _updateCountersWithBatch(id, status, payload, authorUid);

      if (status == 'published') {
        await _autoPostWeeklyToCommunityGroups(id);
      }

      Get.snackbar("Success", "Forecast marked as ${status.toUpperCase()}", backgroundColor: Colors.blueAccent, colorText: Colors.white);
      
      await fetchAnalytics();
      await fetchForecastHistory();
    } catch (e) {
      Get.snackbar("Error", "Could not update status.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
  
  // ========================================================================
  // 7. VIEW, EDIT & DOWNLOAD LOGIC
  // ========================================================================
  
  void loadForecastForEditing(Map<String, dynamic> forecast, {bool isViewOnly = false}) {
    try {
      // 1. Load Dates and Texts
      if (forecast['validFrom'] != null) validFrom.value = DateTime.parse(forecast['validFrom']);
      if (forecast['issueTime'] != null) selectedIssueTime.value = forecast['issueTime'];
      if (forecast['shortDescription'] != null) shortDescription.value = forecast['shortDescription'];

      // 2. Load the IBF Matrix Table
      if (forecast['ibfDetails'] != null) {
        Map<String, dynamic> savedDetails = forecast['ibfDetails'];
        for (var sector in sectors) {
          if (savedDetails.containsKey(sector)) {
            var sectorData = savedDetails[sector] as List;
            for (int i = 0; i < 3; i++) {
              if (i < sectorData.length) {
                var dayData = sectorData[i];
                ibfDetails[sector]![i] = {
                  "risk": dayData['risk']?.toString() ?? "Green (No Risk)",
                  "cond1": dayData['cond1']?.toString() ?? "",
                  "cond2": dayData['cond2']?.toString() ?? "",
                  "cond3": dayData['cond3']?.toString() ?? "",
                };
              }
            }
          }
        }
        ibfDetails.refresh();
      }

      // 3. Load Map Regions (Polygons)
      if (forecast['regions'] != null) {
        Map<String, dynamic> savedRegions = forecast['regions'];
        for (var period in ['day1', 'day2', 'day3']) {
          finishedRegions[period]!.clear();
          if (savedRegions.containsKey(period)) {
            var periodRegions = savedRegions[period] as List;
            for (var regionData in periodRegions) {
              List<LatLng> points = (regionData['points'] as List).map((p) {
                return LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble());
              }).toList();
              finishedRegions[period]!.add(WeeklyMapRegion(
                points: points,
                color: regionData['color']?.toString() ?? 'green'
              ));
            }
          }
        }
      }

      // 4. Load Map Items (Weather Icons & Matrix Letters)
      if (forecast['markers'] != null) {
        Map<String, dynamic> savedMarkers = forecast['markers'];
        for (var period in ['day1', 'day2', 'day3']) {
          mapItems[period]!.clear();
          if (savedMarkers.containsKey(period)) {
            var periodMarkers = savedMarkers[period] as List;
            for (var markerData in periodMarkers) {
              mapItems[period]!.add(WeeklyMapItem(
                id: markerData['id'].toString(),
                type: markerData['type'] == 'icon' ? WeeklyItemType.icon : WeeklyItemType.text,
                value: markerData['value'].toString(),
                position: LatLng((markerData['lat'] as num).toDouble(), (markerData['lng'] as num).toDouble())
              ));
            }
          }
        }
      }

      // 5. Navigate to the Input Tab
      tabController.animateTo(1);
      
      Get.snackbar(
        isViewOnly ? "View Mode" : "Edit Mode", 
        isViewOnly ? "Viewing forecast details." : "Loaded forecast data for editing.", 
        backgroundColor: Colors.blueAccent, 
        colorText: Colors.white
      );
    } catch (e) {
      debugPrint("Error loading forecast: $e");
      Get.snackbar("Error", "Could not load the forecast data.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }


 Future<void> downloadForecastPdfAndImage(BuildContext context, Map<String, dynamic> forecast) async {
    try {
      Get.snackbar("Processing", "Generating Weekly PDF and Image this takes time (10 mins Approx.), go get some water ...", backgroundColor: Colors.amber.shade700, colorText: Colors.black, duration: const Duration(seconds: 15),);
      
      // 1. Generate the 3-Map Image invisibly
      final Uint8List? mapBytes = await WeeklyImageGenerator.generateThreeMapsImage(
        context: context,
        regions: forecast['regions'] ?? {},
        markers: forecast['markers'] ?? {},
        startDate: DateTime.parse(forecast['validFrom']),
      );

      if (mapBytes == null) throw Exception("Failed to generate map imagery.");

      // 2. Generate the full PDF
      final Uint8List pdfBytes = await WeeklyIbfPdfService.generateIbfPdf(forecast, mapBytes);
      String docId = forecast['id'] ?? "Forecast";

      // 3. Download the PDF
      final pdfBlob = html.Blob([pdfBytes], 'application/pdf');
      final pdfUrl = html.Url.createObjectUrlFromBlob(pdfBlob);
      html.AnchorElement(href: pdfUrl)
        ..setAttribute("download", "Weekly_IBF_$docId.pdf")
        ..click();
      html.Url.revokeObjectUrl(pdfUrl);

      // 4. Convert the entire PDF document to an Image (Rasterize)
      // This ensures the image looks EXACTLY like the PDF template!
      await for (var page in Printing.raster(pdfBytes, pages: [0], dpi: 300)) {
        final imageBytes = await page.toPng();
        final imageBlob = html.Blob([imageBytes], 'image/png');
        final imageUrl = html.Url.createObjectUrlFromBlob(imageBlob);
        html.AnchorElement(href: imageUrl)
          ..setAttribute("download", "Weekly_IBF_$docId.png")
          ..click();
        html.Url.revokeObjectUrl(imageUrl);
      }

      Get.snackbar("Success", "Files downloaded successfully!", backgroundColor: const Color(0xFF3DD68C), colorText: Colors.black);
    } catch (e) {
      debugPrint("Download Error: $e");
      Get.snackbar("Error", "Failed to generate files.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void viewForecast(Map<String, dynamic> item) {}
  void editForecast(Map<String, dynamic> item) { tabController.animateTo(1); }

  // ========================================================================
  // 8. AUTO-POST TO COMMUNITY GROUPS
  // ========================================================================
  static const List<String> _weeklyGroupIds = [
    'O9HcbFUOYgAFnxN2OrLN',
    'FXQGcjeQfEJKtreb9cyN',
  ];

  Future<void> _autoPostWeeklyToCommunityGroups(String docId) async {
    const String functionName = 'Weekly Auto-Post';
    Get.snackbar(functionName, 'Starting to generate and post forecast files...',
        showProgressIndicator: true, duration: const Duration(seconds: 10));

    try {
      // Fetch forecast directly from Firestore instead of relying on forecastsList
      final docSnapshot = await _firestore.collection('weekly_forecasts').doc(docId).get();
      if (!docSnapshot.exists) {
        Get.snackbar('Warning', 'Forecast not found for auto-post.', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      final forecast = Map<String, dynamic>.from(docSnapshot.data()!);
      forecast['id'] = docId;
      final validDate = forecast['validFrom'] ?? '';
      final formattedDate = validDate.isNotEmpty 
          ? DateFormat('dd/MM/yyyy').format(DateTime.tryParse(validDate) ?? DateTime.now()) 
          : DateFormat('dd/MM/yyyy').format(DateTime.now());

      List<String> postedFiles = [];

      // ============ 1. Generate IBF PDF ONCE ============
      String? ibfPdfUrl;
      try {
        Get.snackbar(functionName, 'Generating IBF PDF...', duration: const Duration(seconds: 10));
        final mapRegions = forecast['regions'] as Map<String, dynamic>? ?? {};
        final mapItems = forecast['markers'] as Map<String, dynamic>? ?? {};

        final mapBytes = await WeeklyImageGenerator.generateThreeMapsImage(
          context: Get.context!,
          regions: mapRegions,
          markers: mapItems,
          startDate: validDate.isNotEmpty ? DateTime.parse(validDate) : DateTime.now(),
        );

        if (mapBytes != null && mapBytes.isNotEmpty) {
          final ibfPdfBytes = await WeeklyIbfPdfService.generateIbfPdf(forecast, mapBytes);
          if (ibfPdfBytes.isNotEmpty) {
            ibfPdfUrl = await _uploadToStorage(
              fileBytes: ibfPdfBytes,
              fileName: 'Weekly_IBF_${DateTime.now().millisecondsSinceEpoch}.pdf',
              type: 'file',
            );
            postedFiles.add('IBF PDF');
          }
        }
      } catch (e) {
        debugPrint('Error generating Weekly IBF PDF: $e');
      }

      // ============ 2. Generate IBF Image ONCE ============
      String? ibfImageUrl;
      try {
        Get.snackbar(functionName, 'Generating IBF Image...', duration: const Duration(seconds: 10));
        final mapRegions = forecast['regions'] as Map<String, dynamic>? ?? {};
        final mapItems = forecast['markers'] as Map<String, dynamic>? ?? {};

        final mapBytes = await WeeklyImageGenerator.generateThreeMapsImage(
          context: Get.context!,
          regions: mapRegions,
          markers: mapItems,
          startDate: validDate.isNotEmpty ? DateTime.parse(validDate) : DateTime.now(),
        );

        if (mapBytes != null && mapBytes.isNotEmpty) {
          final ibfPdfBytes = await WeeklyIbfPdfService.generateIbfPdf(forecast, mapBytes);
          final ibfImageBytes = await _rasterizePdfToImage(ibfPdfBytes);
          if (ibfImageBytes.isNotEmpty) {
            ibfImageUrl = await _uploadToStorage(
              fileBytes: ibfImageBytes,
              fileName: 'Weekly_IBF_${DateTime.now().millisecondsSinceEpoch}.png',
              type: 'image',
            );
            postedFiles.add('IBF Image');
          }
        }
      } catch (e) {
        debugPrint('Error generating Weekly IBF Image: $e');
      }

      // ============ 3. Post URLs to BOTH groups ============
      for (final groupId in _weeklyGroupIds) {
        if (ibfPdfUrl != null) {
          await _postUrlToGroup(
            groupId: groupId,
            mediaUrl: ibfPdfUrl,
            content: 'Weekly IBF Forecast for $formattedDate',
            type: 'file',
          );
        }

        if (ibfImageUrl != null) {
          await _postUrlToGroup(
            groupId: groupId,
            mediaUrl: ibfImageUrl,
            content: 'Weekly IBF Forecast Image for $formattedDate',
            type: 'image',
          );
        }
      }

      if (postedFiles.isNotEmpty) {
        await _markWeeklyForecastAsPosted(docId);
        Get.snackbar(
          'Auto-Post Complete',
          'Posted: ${postedFiles.join(", ")} to ${_weeklyGroupIds.length} groups',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Auto-Post Failed',
          'Could not generate any files.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }

    } catch (e) {
      debugPrint('Critical error in Weekly auto-post: $e');
      Get.snackbar(
        'Auto-Post Error',
        'Published but failed to auto-post: ${e.toString()}',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 10),
      );
    }
  }

  Future<String> _uploadToStorage({
    required Uint8List fileBytes,
    required String fileName,
    required String type,
  }) async {
    final folder = type == 'image' ? 'chat_images' : 'chat_documents';
    final storageRef = FirebaseStorage.instance.ref().child('$folder/$fileName');

    final uploadTask = storageRef.putData(
      fileBytes,
      SettableMetadata(contentType: type == 'image' ? 'image/png' : 'application/pdf'),
    );

    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _postUrlToGroup({
    required String groupId,
    required String mediaUrl,
    required String content,
    required String type,
  }) async {
    await _firestore.collection('groups').doc(groupId).collection('messages').add({
      'author_name': _authCtrl.currentUser.value?.name ?? 'GMet Admin',
      'author_id': _authCtrl.currentUser.value?.uid ?? 'system',
      'author_role': 'admin',
      'content': content,
      'type': type,
      'media_url': mediaUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'is_admin': true,
      'department': 'cafo',
    });
  }

  Future<void> _markWeeklyForecastAsPosted(String docId) async {
    try {
      await _firestore.collection('weekly_forecasts').doc(docId).update({
        'postedToCommunity': true,
        'postedToCommunityAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to mark Weekly forecast as posted: $e');
    }
  }

  Future<Uint8List> _rasterizePdfToImage(Uint8List pdfBytes) async {
    final List<int> imageBytesList = [];
    await for (var page in Printing.raster(pdfBytes, pages: [0], dpi: 300)) {
      final bytes = await page.toPng();
      imageBytesList.addAll(bytes);
    }
    return Uint8List.fromList(imageBytesList);
  }
}