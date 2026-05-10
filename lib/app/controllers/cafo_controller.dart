import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:printing/printing.dart';
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';
import 'package:weather_admin_dashboard/app/data/models/settings_model.dart';
import 'package:weather_admin_dashboard/app/model/forecastData.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:weather_admin_dashboard/app/routes/app_routes.dart';
import 'package:weather_admin_dashboard/app/services/cafo_dailyforecast_ibf_service.dart';
import 'package:weather_admin_dashboard/app/services/cafo_image_generator.dart';
import 'package:weather_admin_dashboard/app/services/cafo_table_pdf_service.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web; 
import 'dart:convert'; 
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class CAFOController extends GetxController with GetSingleTickerProviderStateMixin {
// ── EDIT MODE STATE ──
  var editingDocId = ''.obs;
  var isViewOnlyMode = false.obs;
  String seastate = 'CALM(1)'; // Add this field
  late TabController tabController;
final List<String> issueTimeOptions = ['0500', '1100', '1700', '2300'];
// Add this near your other state variables (like isTableComplete)
  var tableRefreshTrigger = UniqueKey().obs;
var isImporting = false.obs;
 var isSubmitting = false.obs;
  var submitAction = ''.obs; // Tracks if we are doing 'approval' or 'draft'
  final RxString publishStatus = ''.obs; 

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authCtrl = Get.find<AuthController>();
  var isLoadingSettings = true.obs; // NEW: Tracks Firestore fetch status
 var isTableComplete = false.obs;
  var selectedIssueTime = '0500'.obs;

  // Completion progress (0.0 – 1.0) computed reactively
  final RxDouble tableProgress = 0.0.obs;

  final summaryController = TextEditingController();
  final nbController = TextEditingController();
final cityData = <Map<String, dynamic>>[].obs;
  final weatherOptions = <String>[].obs;
 final List<String> probOptions =
      List.generate(101, (i) => '${i + 0}');

 int get totalCellCount => cityData.length * 9;

  double get filledPercent =>
      totalCellCount == 0 ? 0 : filledCellCount / totalCellCount;

// ========================================================================
// MAP EXPORT / CAPTURE STATE
// ========================================================================
final GlobalKey morningMapKey = GlobalKey();
final GlobalKey afternoonMapKey = GlobalKey();
final GlobalKey eveningMapKey = GlobalKey();
final GlobalKey nightMapKey = GlobalKey();


// ========================================================================
  // MAP LAYOUT STATE
  // ========================================================================
  var isVerticalMapLayout = false.obs;

  void toggleMapLayout() {
    isVerticalMapLayout.value = !isVerticalMapLayout.value;
  }


 // ========================================================================
  // ANALYTICS & LIST STATE
  // ========================================================================
  var forecastsList = <Map<String, dynamic>>[].obs;
  var isLoadingList = true.obs;
  
  // -- Pagination State --
  var isFetchingMore = false.obs;
  var hasMore = true.obs;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 10; // Load 10 items at a time

  // Real-time KPI Counters
  var kpiTotal = 0.obs;
  var kpiDraft = 0.obs;
  var kpiPending = 0.obs;
  var kpiPublished = 0.obs;

  // ========================================================================
  // LIFECYCLE
  // ========================================================================
  @override
  void onInit() {
    super.onInit();
       
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_handleTabChange);
   
    _autoSetIssueTime();

  }

 @override
void onReady() {
  super.onReady();
  print("CAFO: onReady triggered.");
  
  // 1. Check if user is already here
  if (_authCtrl.currentUser.value != null) {
    print("CAFO: User already exists. Fetching settings immediately.");
    fetchSettings();
    fetchForecastsAndAnalytics(); // NEW: Fetch data when user is ready
  } 
  
  // 2. Safely catch the user if there's a microsecond delay
  ever(_authCtrl.currentUser, (user) {
    if (user != null) {
      print("CAFO: Auth state changed! User arrived. Fetching settings.");
      fetchSettings();
      fetchForecastsAndAnalytics();
    }
  });
}


 // ========================================================================
  // INITIAL FETCH (Resets Pagination & KPIs)
  // ========================================================================
  Future<void> fetchForecastsAndAnalytics() async {
    try {
      isLoadingList.value = true;
      hasMore.value = true; 
      _lastDocument = null; 

      // CRITICAL: Reset KPIs to 0 immediately so old data doesn't linger
      kpiTotal.value = 0;
      kpiDraft.value = 0;
      kpiPending.value = 0;
      kpiPublished.value = 0;

      final user = _authCtrl.currentUser.value;
      if (user == null) return;

      final isSuperAdmin = user.role.contains('super_admin') || user.role.contains('admin');

      // 1. Fetch the correct KPI Stats
      if (isSuperAdmin) {
        DocumentSnapshot globalStats = await _firestore.collection('analytics').doc('cafo_daily_global').get();
        if (globalStats.exists && globalStats.data() != null) {
          final data = globalStats.data() as Map<String, dynamic>;
          kpiTotal.value = data['total'] ?? 0;
          kpiDraft.value = data['draft'] ?? 0;
          kpiPending.value = data['pending_approval'] ?? 0;
          kpiPublished.value = data['published'] ?? 0;
        }
      } else {
        DocumentSnapshot userStats = await _firestore.collection('users').doc(user.uid).get();
        if (userStats.exists && userStats.data() != null) {
          final data = userStats.data() as Map<String, dynamic>;
          
          // Safely read the nested map we are now creating
          if (data['cafo_daily_stats'] != null && data['cafo_daily_stats'] is Map) {
            final cafoStats = data['cafo_daily_stats'] as Map<String, dynamic>;
            kpiTotal.value = cafoStats['total'] ?? 0;
            kpiDraft.value = cafoStats['draft'] ?? 0;
            kpiPending.value = cafoStats['pending_approval'] ?? 0;
            kpiPublished.value = cafoStats['published'] ?? 0;
          }
        }
      }

      // 2. Fetch the FIRST page of forecasts
      Query query = _firestore.collection('cafo_daily_forecast')
          .orderBy('updatedAt', descending: true)
          .limit(_pageSize);
      
      if (!isSuperAdmin) {
        query = query.where('author.uid', isEqualTo: user.uid);
      }

      QuerySnapshot snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last; 
        if (snapshot.docs.length < _pageSize) {
          hasMore.value = false; 
        }
      } else {
        hasMore.value = false; 
      }
      
      forecastsList.value = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        return data;
      }).toList();

    } catch (e) {
      debugPrint("Error fetching forecasts: $e");
    } finally {
      isLoadingList.value = false;
    }
  }

  // ========================================================================
  // PAGINATION FETCH (Load More)
  // ========================================================================
  Future<void> fetchMoreForecasts() async {
    // Prevent overlapping requests or fetching if there's no more data
    if (isFetchingMore.value || !hasMore.value || _lastDocument == null) return;

    try {
      isFetchingMore.value = true;
      final user = _authCtrl.currentUser.value;
      if (user == null) return;

      final isSuperAdmin = user.role.contains('super_admin') || user.role.contains('admin');

      Query query = _firestore.collection('cafo_daily_forecast')
          .orderBy('updatedAt', descending: true)
          .startAfterDocument(_lastDocument!) // <-- The Magic Cursor
          .limit(_pageSize);

      if (!isSuperAdmin) {
        query = query.where('author.uid', isEqualTo: user.uid);
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last; // Update the cursor
        
        if (snapshot.docs.length < _pageSize) {
          hasMore.value = false; // Reached the end
        }

        var newForecasts = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        forecastsList.addAll(newForecasts); // Append the new data to the existing list
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      debugPrint("Error fetching more forecasts: $e");
    } finally {
      isFetchingMore.value = false;
    }
  }

 
 // ========================================================================
  // SMART COUNTER UPDATER (Prevents mass database reads)
  // ========================================================================
  Future<void> _updateCountersWithBatch(String docId, String newStatus, Map<String, dynamic> payload, bool isSuperAdmin, String authorUid) async {
    final docRef = _firestore.collection('cafo_daily_forecast').doc(docId);
    final userRef = _firestore.collection('users').doc(authorUid);
    final globalRef = _firestore.collection('analytics').doc('cafo_daily_global');

    // 1. Check if document already exists to know if we are updating or creating
    final existingDoc = await docRef.get();
    String? oldStatus;
    if (existingDoc.exists) {
      oldStatus = (existingDoc.data() as Map<String, dynamic>)['status'];
    }

    // 2. Start a WriteBatch
    WriteBatch batch = _firestore.batch();
    
    // Save the actual forecast data
    batch.set(docRef, payload, SetOptions(merge: true));

    // 3. Update User & Global Counters if the status changed or it's new
    if (oldStatus != newStatus) {
      
      // Build the increment map directly (NO DOT NOTATION)
      Map<String, dynamic> statIncrements = {};
      if (oldStatus == null) {
        statIncrements['total'] = FieldValue.increment(1);
        statIncrements[newStatus] = FieldValue.increment(1);
      } else {
        statIncrements[oldStatus] = FieldValue.increment(-1);
        statIncrements[newStatus] = FieldValue.increment(1);
      }

      // Deep merge the nested map into the user document
      batch.set(userRef, { 'cafo_daily_stats': statIncrements }, SetOptions(merge: true));
      
      // Global document doesn't use a parent key, the stats sit at the root
      batch.set(globalRef, statIncrements, SetOptions(merge: true));
    }

    // Commit the batch atomically
    await batch.commit();
  }

Future<void> toggleForecastStatus(String docId, String newStatus, String authorUid) async {
    try {
      final user = _authCtrl.currentUser.value!;
      final isSuperAdmin = user.role.contains('super_admin') || user.role.contains('admin');
      
      // Safety check: Only admins can trigger this directly
      if (!isSuperAdmin) return;

      Get.snackbar('Processing', 'Updating forecast status...', showProgressIndicator: true);

      // Create a targeted payload that ONLY updates the status and audit trails
      Map<String, dynamic> payload = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'published') {
        payload['approvedAt'] = FieldValue.serverTimestamp();
        payload['approvedBy'] = user.uid; // Record who approved it
      }

      // Re-use our smart counter batch to update the database AND the analytics accurately
      await _updateCountersWithBatch(docId, newStatus, payload, isSuperAdmin, authorUid);

      // Refresh the UI list
      await fetchForecastsAndAnalytics();

      if (newStatus == 'published') {
        await _autoPostCafoToCommunityGroups(docId);
      }

      Get.snackbar(
        'Success', 
        newStatus == 'published' ? 'Forecast Approved & Published!' : 'Approval Revoked. Set to Pending.',
        backgroundColor: Colors.green.withOpacity(0.9), 
        colorText: Colors.white,
      );

    } catch (e) {
      debugPrint("Error updating status: $e");
      Get.snackbar('Error', 'Failed to update status.');
    }
  }
// ========================================================================
  // 5. SUBMIT / SAVE ACTION & FIREBASE UPLOAD
  // ========================================================================
 
  // Helper to serialize drawn map regions (Polygons)
  List<Map<String, dynamic>> _serializeRegions(List<MapRegion> regions) {
    return regions.map((r) => {
      'color': r.color,
      'points': r.points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    }).toList();
  }

  // Helper to serialize map icons and text
  List<Map<String, dynamic>> _serializeItems(List<DraggableMapItem> items) {
    return items.map((i) => {
      'id': i.id,
      'type': i.type.name, // 'icon' or 'text'
      'value': i.value,
      'position': {'lat': i.position.latitude, 'lng': i.position.longitude},
    }).toList();
  }

// ========================================================================
  // EDIT & DESERIALIZE LOGIC
  // ========================================================================

  // Helper to deserialize drawn map regions
  List<MapRegion> _deserializeRegions(List<dynamic>? regionsData) {
    if (regionsData == null) return [];
    return regionsData.map((r) {
      List<LatLng> points = (r['points'] as List).map((p) => LatLng(p['lat'], p['lng'])).toList();
      return MapRegion(points: points, color: r['color']);
    }).toList();
  }

  // Helper to deserialize map icons and text
  List<DraggableMapItem> _deserializeItems(List<dynamic>? itemsData) {
    if (itemsData == null) return [];
    return itemsData.map((i) {
      return DraggableMapItem(
        id: i['id'],
        type: i['type'] == 'icon' ? MapItemType.icon : MapItemType.text,
        value: i['value'],
        position: LatLng(i['position']['lat'], i['position']['lng']),
      );
    }).toList();
  }

  // Master method to load an existing forecast into the workspace
  void loadForecastForEditing(Map<String, dynamic> forecast, {bool isViewOnly = false}) {
    try {
      isViewOnlyMode.value = isViewOnly;
      editingDocId.value = forecast['id']; // Track the document we are editing!

      final metadata = forecast['metadata'] ?? {};
      final tData = forecast['tableData'] ?? [];
      final mData = forecast['mapData'] ?? {};

      // 1. Text Fields & Times
      summaryController.text = metadata['tableSummary'] ?? '';
      nbController.text = metadata['tableNb'] ?? '';
      selectedIssueTime.value = metadata['issueTimeSlot'] ?? '0500';

      // 2. Table Data
      if (tData.isNotEmpty) {
        cityData.assignAll(List<Map<String, dynamic>>.from(tData));
        isTableComplete.value = true; 
      }

      // 3. Metadata / Sector Temperatures
      Map<String, dynamic> rawTemps = metadata['sectorTemperatures'] ?? {};
      Map<String, ({int min, int max})> parsedTemps = {};
      rawTemps.forEach((key, value) {
        parsedTemps[key] = (min: (value['min'] ?? 0) as int, max: (value['max'] ?? 0) as int);
      });

      currentForecast.value = ForecastData(
        date: metadata['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
        timeIssued: metadata['timeIssued'] ?? '',
        validFrom: metadata['validFrom'] ?? '',
        warningType: metadata['warningType'] ?? 'None',
        seastate: metadata['seastate'] ?? '',
        weatherSummary: metadata['mapSummary'] ?? '',
        caution: metadata['mapNb'] ?? '',
        notaBene: '', 
        sectorTemperatures: parsedTemps.isNotEmpty ? parsedTemps : {
          'Coast': (min: 0, max: 0),
          'Forest': (min: 0, max: 0),
          'Transition': (min: 0, max: 0), 
          'Northern': (min: 0, max: 0),
        },
      );

      // 4. Map Data (Inject shapes and icons back into the UI)
      final morning = mData['morning'] ?? {};
      morningRegions.assignAll(_deserializeRegions(morning['regions']));
      morningItems.assignAll(_deserializeItems(morning['items']));

      final afternoon = mData['afternoon'] ?? {};
      afternoonRegions.assignAll(_deserializeRegions(afternoon['regions']));
      afternoonItems.assignAll(_deserializeItems(afternoon['items']));

      final evening = mData['evening'] ?? {};
      eveningRegions.assignAll(_deserializeRegions(evening['regions']));
      eveningItems.assignAll(_deserializeItems(evening['items']));

      final night = mData['night'] ?? {};
      nightRegions.assignAll(_deserializeRegions(night['regions']));
      nightItems.assignAll(_deserializeItems(night['items']));

      // 5. Navigate to the Table Tab
      tabController.animateTo(1);
      
      Get.snackbar(
        isViewOnly ? 'View Mode' : 'Edit Mode',
        isViewOnly ? 'Forecast loaded for inspection.' : 'Forecast loaded into workspace.',
        backgroundColor: AppTheme.accentBlue.withOpacity(0.95),
        colorText: Colors.white,
        icon: Icon(isViewOnly ? PhosphorIcons.eye() : PhosphorIcons.pencilSimple(), color: Colors.white),
      );
    } catch (e) {
      debugPrint("Error loading forecast: $e");
      Get.snackbar("Error", "Could not load forecast data properly.");
    }
  }
  
// Helper method to capture the map UI into bytes
// Future<Uint8List?> captureWidget(GlobalKey key) async {
//   try {
//     if (key.currentContext == null) {
//       debugPrint("Widget not found on screen. Ensure you are viewing the map.");
//       return null;
//     }
//     RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
//     ui.Image image = await boundary.toImage(pixelRatio: 3.0); 
//     ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//     return byteData?.buffer.asUint8List();
//   } catch (e) {
//     debugPrint("Error capturing map: $e");
//     return null;
//   }
// }
Future<Uint8List?> captureWidget(GlobalKey key) async {
  if (key.currentContext == null) return null;
  RenderRepaintBoundary boundary = 
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}
 // ========================================================================
// UPDATED DOWNLOAD IBF FUNCTION
// ========================================================================
// Add this right above downloadForecastIbf
List<String> _getHeadersFromDatabaseTime(String issueTime) {
  switch (issueTime) {
    case '0500': return ['MORNING', 'AFTERNOON', 'EVENING'];
    case '1100': return ['AFTERNOON', 'EVENING', 'NIGHT'];
    case '1700': return ['EVENING', 'NIGHT', 'MORNING'];
    case '2300': return ['NIGHT', 'MORNING', 'AFTERNOON'];
    default: return ['MORNING', 'AFTERNOON', 'EVENING'];
  }
}
  

  


Future<void> downloadForecastIbf(String docId) async {
  debugPrint("IBF download requested for: $docId");
  try {
    Get.snackbar(
      'Generating IBF',
      'Loading maps in background — this takes ~10 seconds...',
      showProgressIndicator: true,
      backgroundColor: AppTheme.accentBlue.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 15),
    );

    // ── 1. Find the forecast ───────────────────────────────────────────────
    final forecast =
        forecastsList.firstWhere((f) => f['id'] == docId, orElse: () => {});
    if (forecast.isEmpty) throw Exception("Forecast not found.");

    final metadata = forecast['metadata'] ?? {};
    final mData    = forecast['mapData']  ?? {};

    // ── 2. Dates ───────────────────────────────────────────────────────────
    DateTime parsedDate =
        DateTime.tryParse(metadata['date'] ?? '') ?? DateTime.now();
    DateTime tomorrow = parsedDate.add(const Duration(days: 1));

    String dateStr         = DateFormat('dd-MMM-yy').format(parsedDate).toUpperCase();
    String todayFormatted  = DateFormat('dd/MM/yyyy').format(parsedDate);
    String tomFormatted    = DateFormat('dd/MM/yyyy').format(tomorrow);

    // ── 3. Temperatures ────────────────────────────────────────────────────
    Map<String, dynamic> rawTemps = metadata['sectorTemperatures'] ?? {};
    List<Map<String, String>> formattedTemps = [
      'Coast', 'Forest', 'Transition', 'Northern'
    ].map((s) => {
      'sector': s,
      'min': rawTemps[s]?['min']?.toString() ?? '-',
      'max': rawTemps[s]?['max']?.toString() ?? '-',
    }).toList();

    // ── 4. Headers + dates ─────────────────────────────────────────────────
    String dbIssueTime       = metadata['issueTimeSlot'] ?? '0500';
    List<String> activeHdrs  = _getHeadersFromDatabaseTime(dbIssueTime);

    List<String> activeDates;
    switch (dbIssueTime) {
      case '0500': activeDates = [todayFormatted, todayFormatted, todayFormatted]; break;
      case '1100': activeDates = [todayFormatted, todayFormatted, tomFormatted];   break;
      case '1700': activeDates = [todayFormatted, tomFormatted,   tomFormatted];   break;
      case '2300': activeDates = [tomFormatted,   tomFormatted,   tomFormatted];   break;
      default:     activeDates = [todayFormatted, todayFormatted, todayFormatted];
    }

    // ── 5. Get a BuildContext from the navigator ───────────────────────────
    //
    // Get.context gives us a valid context even when the user is not on the
    // Map tab, so the Overlay insertion always works.
    final ctx = Get.context!;

    // ── 6. Render maps offscreen (real OSM tiles + polygons + icons) ───────
    //
    // Each call:
    //   • Inserts a hidden FlutterMap into the app Overlay
    //   • Waits 3 s for OSM tiles to load
    //   • Screenshots it at 3× pixel ratio
    //   • Removes the overlay
    //
    // We run them SEQUENTIALLY so the device isn't loading 3 tile sets at once.

    final String p1 = activeHdrs[0].toLowerCase();
    final String p2 = activeHdrs[1].toLowerCase();
    final String p3 = activeHdrs[2].toLowerCase();

    Uint8List? bytes1 = await CAFOImageGenerator.generateMapImageFromData(
      mData[p1]?['regions'],
      itemsData: mData[p1]?['items'],
      context: ctx,
      tileWaitMs: 3500,
    );

    Uint8List? bytes2 = await CAFOImageGenerator.generateMapImageFromData(
      mData[p2]?['regions'],
      itemsData: mData[p2]?['items'],
      context: ctx,
      tileWaitMs: 3500,
    );

    Uint8List? bytes3 = await CAFOImageGenerator.generateMapImageFromData(
      mData[p3]?['regions'],
      itemsData: mData[p3]?['items'],
      context: ctx,
      tileWaitMs: 3500,
    );

    // ── 7. Build PDF payload ───────────────────────────────────────────────
    final Map<String, dynamic> ibfPayload = {
      'date':          dateStr,
      'formattedDate': todayFormatted,
      'timeIssued':    metadata['timeIssued'] ?? '$dbIssueTime UTC',
      'validFrom':     metadata['validFrom']  ?? '',
      'temperatures':  formattedTemps,
      'summary': metadata['mapSummary'] ??
                 metadata['tableSummary'] ??
                 'No summary provided.',
      'headers':     activeHdrs,
      'headerDates': activeDates,
      'map1': bytes1,
      'map2': bytes2,
      'map3': bytes3,
    };

    // ── 8. Generate PDF + rasterise to PNG ────────────────────────────────
     Get.snackbar(
      'Generating Files', 
      'Please wait while the PDF and Image are compiled...', 
      showProgressIndicator: true,
      backgroundColor: AppTheme.accentBlue.withOpacity(0.9),
      colorText: Colors.white,
    );
    final Uint8List pdfBytes =
        await CafoDailyForecastIbfPdfService.generateIbfPdf(ibfPayload);

    final rasterStream = Printing.raster(pdfBytes, dpi: 300);
    final firstPage    = await rasterStream.first;
    final Uint8List imageBytes = await firstPage.toPng();

    // ── 9. Download ────────────────────────────────────────────────────────
    String safeDate  = (metadata['date'] ?? 'Forecast').toString().replaceAll('/', '-');
    String baseName  = 'GMet_IBF_${safeDate}_${dbIssueTime}UTC';

    _triggerWebDownload(pdfBytes,   '$baseName.pdf', 'application/pdf');
    await Future.delayed(const Duration(milliseconds: 300));
    _triggerWebDownload(imageBytes, '$baseName.png', 'image/png');

    Get.snackbar(
      'Done!',
      'IBF PDF and Image downloaded successfully.',
      backgroundColor: const Color(0xFF3DD68C).withOpacity(0.95),
      colorText: Colors.black,
    );

  } catch (e) {
    print("IBF generation error: $e");
    Get.snackbar(
      'Error',
      'Could not generate IBF: ${e.toString()}',
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      duration: const Duration(seconds: 6),
    );
  }
}


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
    // We create a deep copy so we can safely inject the formatted dates without mutating the original list
    final rawForecast = forecastsList.firstWhere((f) => f['id'] == docId);
    final Map<String, dynamic> forecast = Map<String, dynamic>.from(rawForecast);
    forecast['metadata'] = Map<String, dynamic>.from(rawForecast['metadata'] ?? {});

    // 2. Format Dates (TODAY and TOMORROW)
    final metadata = forecast['metadata'];
    DateTime parsedDate = DateTime.tryParse(metadata['date'] ?? '') ?? DateTime.now();
    DateTime tomorrowDate = parsedDate.add(const Duration(days: 1));

    String todayFormatted = DateFormat('dd/MM/yyyy').format(parsedDate); 
    String tomorrowFormatted = DateFormat('dd/MM/yyyy').format(tomorrowDate);

    // 3. Determine the 3 active dates based on issue time
    String issueTime = metadata['issueTimeSlot'] ?? '0500';
    List<String> activeDates;
    switch (issueTime) {
      case '0500':
        activeDates = [todayFormatted, todayFormatted, todayFormatted]; 
        break;
      case '1100':
        activeDates = [todayFormatted, todayFormatted, tomorrowFormatted]; // Afternoon, Evening, Night(Next Day)
        break;
      case '1700':
        activeDates = [todayFormatted, tomorrowFormatted, tomorrowFormatted]; // Evening, Night(Next Day), Morning(Next Day)
        break;
      case '2300':
        activeDates = [tomorrowFormatted, tomorrowFormatted, tomorrowFormatted]; // All next day
        break;
      default:
        activeDates = [todayFormatted, todayFormatted, todayFormatted];
    }

    // 4. Inject formatted dates into metadata so the PDF service can use them
    forecast['metadata']['formattedDate'] = todayFormatted;
    forecast['metadata']['headerDates'] = activeDates;
    
    // 5. Generate the PDF bytes ONCE
    final Uint8List pdfBytes = await CAFOTablePdfService.generateForecastPdf(forecast);
    
    // 6. Rasterize to get Image bytes
    final rasterStream = Printing.raster(pdfBytes, dpi: 300);
    final firstPage = await rasterStream.first; 
    final Uint8List imageBytes = await firstPage.toPng();
    
    // 7. Create a clean base filename
    String safeDate = (metadata['date'] ?? 'Forecast').toString().replaceAll('/', '-');
    String baseFileName = "GMet_Forecast_${safeDate}_${issueTime}UTC";

    // 8. Trigger Downloads
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
//  Future<void> downloadTableForecastPdfImage(String docId) async {
//   print("Attempting to download PDF and Image for docId: $docId");
//   try {
//     Get.snackbar(
//       'Generating Files', 
//       'Please wait while the PDF and Image are compiled...', 
//       showProgressIndicator: true,
//       backgroundColor: AppTheme.accentBlue.withOpacity(0.9),
//       colorText: Colors.white,
//     );
    
//     // 1. Find the forecast data
//     final forecast = forecastsList.firstWhere((f) => f['id'] == docId);
    
//     // 2. Generate the PDF bytes ONCE (highly efficient)
//     final Uint8List pdfBytes = await GMetPdfService.generateForecastPdf(forecast);
    
//     // 3. Rasterize to get Image bytes
//     final rasterStream = Printing.raster(pdfBytes, dpi: 300);
//     final firstPage = await rasterStream.first; 
//     final Uint8List imageBytes = await firstPage.toPng();
    
//     // 4. Create a clean base filename
//     String safeDate = (forecast['metadata']['date'] ?? 'Forecast').toString().replaceAll('/', '-');
//     String issueTime = forecast['metadata']['issueTimeSlot'] ?? '0500';
//     String baseFileName = "GMet_Forecast_${safeDate}_${issueTime}UTC";

//     // 5. Trigger PDF Download
//     _triggerWebDownload(pdfBytes, '$baseFileName.pdf', 'application/pdf');
    
//     // A tiny delay is required on the web so the browser doesn't block 
//     // the second download as a popup/spam action.
//     await Future.delayed(const Duration(milliseconds: 200));

//     // 6. Trigger Image Download
//     _triggerWebDownload(imageBytes, '$baseFileName.png', 'image/png');
    
//     Get.snackbar(
//       'Success', 
//       'PDF and Image downloaded successfully!',
//       backgroundColor: const Color(0xFF3DD68C).withOpacity(0.95),
//       colorText: Colors.black,
//       icon: Icon(PhosphorIcons.downloadSimple(PhosphorIconsStyle.fill), color: Colors.black87, size: 18),
//       duration: const Duration(seconds: 3),
//     );
    
//   } catch (e) {
//     debugPrint("Error generating files: $e");
//     Get.snackbar(
//       'Error', 
//       'Could not generate files. ${e.toString()}',
//       backgroundColor: Colors.redAccent,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 5),
//     );
//   }
// }

// --- HELPER FUNCTION ---
// Keeps the main function clean since the web download logic is repetitive
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
  
 

  // Master method to compile all data into a Firestore-ready Map
  Map<String, dynamic> _buildForecastPayload(String status) {
    final forecast = currentForecast.value;
    final user = _authCtrl.currentUser.value;

    // Serialize sector temperatures
    Map<String, dynamic> serializedTemps = {};
    forecast?.sectorTemperatures.forEach((key, value) {
      serializedTemps[key] = {'min': value.min, 'max': value.max};
    });

    return {
      'status': status, 
      'updatedAt': FieldValue.serverTimestamp(),
      'author': {
        'uid': user?.uid,
        'name': user?.name,
        'email': user?.email,
      },
      'metadata': {
        'issueTimeSlot': selectedIssueTime.value,
        'date': forecast?.date,
        'timeIssued': forecast?.timeIssued,
        'validFrom': forecast?.validFrom,
        'warningType': forecast?.warningType,
        'sectorTemperatures': serializedTemps,
        'seastate': forecast?.seastate ?? '',
        // ── TABLE TAB TEXT FIELDS ──
        'tableSummary': summaryController.text.trim(),
        'tableNb': nbController.text.trim(),
        
        // ── MAP TAB TEXT FIELDS ──
        'mapSummary': forecast?.weatherSummary ?? '',
        'mapNb': forecast?.caution ?? '', // Maps to the 'Caution / NB' field in the Map tab
      },
      'tableData': cityData.toList(), 
      'mapData': {
        'morning': {
          'regions': _serializeRegions(morningRegions),
          'items': _serializeItems(morningItems),
        },
        'afternoon': {
          'regions': _serializeRegions(afternoonRegions),
          'items': _serializeItems(afternoonItems),
        },
        'evening': {
          'regions': _serializeRegions(eveningRegions),
          'items': _serializeItems(eveningItems),
        },
        'night': {
          'regions': _serializeRegions(nightRegions),
          'items': _serializeItems(nightItems),
        },
      }
    };
  }

 
 Future<void> sendForApproval() async {
    // ── 1. VALIDATE TABLE DATA ──
    if (filledCellCount < totalCellCount) {
      Get.snackbar(
        'Incomplete Table',
        'Please ensure all weather, probability, and temperature cells are filled before publishing.',
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (summaryController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Table Summary',
        'Please provide a table summary before publishing.',
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }
// --> NEW: Sea State Validation
    if (currentForecast.value?.seastate.trim().isEmpty ?? true) {
      Get.snackbar(
        'Missing Sea State',
        'Please select or enter the sea state before publishing.',
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }
    // ── 2. VALIDATE IBF MAP DATA (Weather Summary & Temperatures) ──
    if (currentForecast.value?.weatherSummary.trim().isEmpty ?? true) {
      Get.snackbar(
        'Missing IBF Summary',
        'Please fill out the Weather Summary card in the Impact-Based Forecast tab.',
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    // Check if any sector temperature is still at the default (0, 0)
    bool hasMissingTemps = false;
    currentForecast.value?.sectorTemperatures.forEach((sector, temps) {
      if (temps.min == 0 && temps.max == 0) {
        hasMissingTemps = true;
      }
    });

    if (hasMissingTemps) {
      Get.snackbar(
        'Missing Temperatures',
        'Please enter the minimum and maximum temperatures for all sectors in the Temperature Card.',
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    // ── 3. PROCEED WITH SUBMISSION ──
    isSubmitting.value = true;
    submitAction.value = 'approval';
    publishStatus.value = 'idle';
    
    try {
      final user = _authCtrl.currentUser.value;
      if (user == null) throw Exception("User session expired. Please log in again.");

      final isSuperAdmin = user.role.contains('super_admin') || user.role.contains('admin');
      final finalStatus = isSuperAdmin ? 'published' : 'pending_approval';
      
      final payload = _buildForecastPayload(finalStatus);
      payload['submittedAt'] = FieldValue.serverTimestamp(); 
      
      if (isSuperAdmin) {
        payload['approvedAt'] = FieldValue.serverTimestamp();
        payload['approvedBy'] = user.uid; 
      }
      
      String docId;
      if (editingDocId.value.isNotEmpty) {
        docId = editingDocId.value; 
      } else {
        docId = 'CAFO_${currentForecast.value?.date}_${selectedIssueTime.value}_${user.uid}'.replaceAll('-', '');
      }
      
      await _updateCountersWithBatch(docId, finalStatus, payload, isSuperAdmin, user.uid);
      await fetchForecastsAndAnalytics();

      if (isSuperAdmin) {
        await _autoPostCafoToCommunityGroups(docId);
      }

      publishStatus.value = 'success';

      if (isSuperAdmin) {
        Get.snackbar(
          'Published Instantly',
          'Admin privileges applied. Forecast is live.',
          backgroundColor: const Color(0xFF3DD68C).withOpacity(0.95),
          colorText: Colors.black,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(20),
          borderRadius: 8,
          duration: const Duration(seconds: 4),
          icon: Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: Colors.black87, size: 18),
        );
      } else {
        Get.snackbar(
          'Sent for Approval',
          'Forecast has been routed to the supervisor for review.',
          backgroundColor: const Color(0xFF3DD68C).withOpacity(0.95),
          colorText: Colors.black,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(20),
          borderRadius: 8,
          duration: const Duration(seconds: 4),
          icon: Icon(PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill), color: Colors.black87, size: 18),
        );
      }
      
      _resetForm();
      
      await Future.delayed(const Duration(milliseconds: 500)); 
      Get.toNamed(AppRoutes.cafoUnified); 

    } catch (e) {
      debugPrint("Error submitting approval: $e");
      publishStatus.value = 'error';
      Get.snackbar('Submission Failed', 'Could not save to database. Please check your connection.', 
        backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }
   Future<void> saveAsDraft() async {
   isSubmitting.value = true;
    submitAction.value = 'draft';
    publishStatus.value = 'idle';
    
    try {
      // 1. Get the current user
      final user = _authCtrl.currentUser.value;

      // ── ADD THIS GUARD CLAUSE ──
      if (user == null) throw Exception("User session expired. Please log in again.");

      // Since we checked for null above, 'user' is now 100% safe!
      final isSuperAdmin = user.role.contains('super_admin') || user.role.contains('admin');

      final payload = _buildForecastPayload('draft');
      
      final docId = 'CAFO_${currentForecast.value?.date}_${selectedIssueTime.value}_${user.uid}'.replaceAll('-', '');
      // Completely safe now!
      await _updateCountersWithBatch(docId, 'draft', payload, isSuperAdmin, user.uid);
      // 4. Refresh the list to show the new/updated forecast in the Analytics tab
      fetchForecastsAndAnalytics(); 

      publishStatus.value = 'success';
      Get.snackbar(
        'Draft Saved',
        'Forecast securely saved to your workspace.',
        backgroundColor: Colors.blueAccent.withOpacity(0.95),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
        duration: const Duration(seconds: 4),
        icon: Icon(PhosphorIcons.floppyDisk(PhosphorIconsStyle.fill), color: Colors.white, size: 18),
      );
      
      // ── ADDED RESET FORM HERE ──
      _resetForm();
      
      // FIX 3: Redirect to CAFO Unified View (or Dashboard)
      await Future.delayed(const Duration(milliseconds: 500)); 
    Get.toNamed(AppRoutes.cafoUnified); // Redirect to the CAFO Unified View after submission


    } catch (e) {
      debugPrint("Error saving draft: $e");
      publishStatus.value = 'error';
      Get.snackbar('Save Failed', 'Could not save draft. Please check your connection.', 
        backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }
// ========================================================================
  // EXCEL IMPORT & EXPORT LOGIC
  // ========================================================================
// Helper to safely format imported CSV numbers
  String _formatCSVNumber(dynamic rawValue) {
    if (rawValue == null) return '';
    String val = rawValue.toString().trim();
    
    // If the CSV parser made it a double (e.g., "100.0"), strip the ".0"
    if (val.endsWith('.0')) {
      return val.substring(0, val.length - 2);
    }
    return val;
  }


  Future<void> importCSVData() async {
    // 1. Pick the CSV file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true, 
    );

    if (result != null && result.files.single.bytes != null) {
      // START LOADING STATE
      isImporting.value = true;
      
      // Allow the UI to paint the loading spinner before parsing
      await Future.delayed(const Duration(milliseconds: 300)); 

      try {
        var bytes = result.files.single.bytes!;
        final csvString = utf8.decode(bytes); 
        final List<List<dynamic>> rows = csv.decode(csvString);

        for (int i = 1; i < rows.length; i++) {
          var row = rows[i];
          if (row.isEmpty || row[0] == null || row[0].toString().trim().isEmpty) continue;

          String cityName = row[0].toString().trim().toUpperCase();
          int cityIndex = cityData.indexWhere((c) => c['name'].toString().toUpperCase() == cityName);
          
         if (cityIndex != -1) {
            cityData[cityIndex]['slot1_weather'] = row.length > 1 ? row[1].toString().trim() : '';
            cityData[cityIndex]['slot1_prob']    = row.length > 2 ? _formatCSVNumber(row[2]) : '';
            cityData[cityIndex]['slot1_temp']    = row.length > 3 ? _formatCSVNumber(row[3]) : '';

            cityData[cityIndex]['slot2_weather'] = row.length > 4 ? row[4].toString().trim() : '';
            cityData[cityIndex]['slot2_prob']    = row.length > 5 ? _formatCSVNumber(row[5]) : '';
            cityData[cityIndex]['slot2_temp']    = row.length > 6 ? _formatCSVNumber(row[6]) : '';

            cityData[cityIndex]['slot3_weather'] = row.length > 7 ? row[7].toString().trim() : '';
            cityData[cityIndex]['slot3_prob']    = row.length > 8 ? _formatCSVNumber(row[8]) : '';
            cityData[cityIndex]['slot3_temp']    = row.length > 9 ? _formatCSVNumber(row[9]) : '';
          }
        }
        
        cityData.refresh();
        onCellChanged(); 
        tableRefreshTrigger.value = UniqueKey(); 
        
        Get.snackbar(
          "Import Successful", 
          "Data successfully mapped to table fields.",
          backgroundColor: const Color(0xFF3DD68C).withOpacity(0.95),
          colorText: Colors.black,
        );
      } catch (e) {
        debugPrint("Error parsing CSV: $e");
        Get.snackbar("Error", "Failed to parse CSV file. Ensure it is formatted correctly.", backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        // STOP LOADING STATE (Executes even if an error occurs!)
        isImporting.value = false;
      }
    }
  }

// ========================================================================
  // FORM RESET LOGIC
  // ========================================================================
  void _resetForm() {
    // ── Clear Edit State ──
    editingDocId.value = '';
    isViewOnlyMode.value = false;

    // 1. Clear text fields
    summaryController.clear();
    nbController.clear();

    // 2. Reset the Table Data while keeping the City Names
    for (var city in cityData) {
      city['slot1_weather'] = '';
      city['slot1_prob'] = '';
      city['slot1_temp'] = '';
      city['slot2_weather'] = '';
      city['slot2_prob'] = '';
      city['slot2_temp'] = '';
      city['slot3_weather'] = '';
      city['slot3_prob'] = '';
      city['slot3_temp'] = '';
    }
    cityData.refresh();
    tableRefreshTrigger.value = UniqueKey(); // Forces the UI table to redraw blanks
    isTableComplete.value = false;

    // 3. Clear all drawn map polygons
    morningRegions.clear();
    afternoonRegions.clear();
    eveningRegions.clear();
    nightRegions.clear();

    // 4. Clear all dragged map icons/text
    morningItems.clear();
    afternoonItems.clear();
    eveningItems.clear();
    nightItems.clear();

    // 5. Clear undo stacks and drawing states
    clearEditablePoints('morning');
    clearEditablePoints('afternoon');
    clearEditablePoints('evening');
    clearEditablePoints('night');
    isDrawing.value = false;
    activeMapPeriod.value = '';

    // 6. Reset Forecast Metadata to defaults
    currentForecast.value = ForecastData(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      timeIssued: currentForecast.value?.timeIssued ?? '', 
      validFrom: currentForecast.value?.validFrom ?? '',
      warningType: 'None',
      weatherSummary: '',
      caution: '',
      notaBene: '',
      seastate: '',
      sectorTemperatures: {
        'Coast': (min: 0, max: 0),
        'Forest': (min: 0, max: 0),
        'Transition': (min: 0, max: 0), 
        'Northern': (min: 0, max: 0),
      },
    );

    // 7. Push user back to the first tab
    tabController.animateTo(0);
  }

void createNewForecast(){
   // ── Clear Edit State ──
    editingDocId.value = '';
    isViewOnlyMode.value = false;

    // 1. Clear text fields
    summaryController.clear();
    nbController.clear();

    // 2. Reset the Table Data while keeping the City Names
    for (var city in cityData) {
      city['slot1_weather'] = '';
      city['slot1_prob'] = '';
      city['slot1_temp'] = '';
      city['slot2_weather'] = '';
      city['slot2_prob'] = '';
      city['slot2_temp'] = '';
      city['slot3_weather'] = '';
      city['slot3_prob'] = '';
      city['slot3_temp'] = '';
    }
    cityData.refresh();
    tableRefreshTrigger.value = UniqueKey(); // Forces the UI table to redraw blanks
    isTableComplete.value = false;

    // 3. Clear all drawn map polygons
    morningRegions.clear();
    afternoonRegions.clear();
    eveningRegions.clear();
    nightRegions.clear();

    // 4. Clear all dragged map icons/text
    morningItems.clear();
    afternoonItems.clear();
    eveningItems.clear();
    nightItems.clear();

    // 5. Clear undo stacks and drawing states
    clearEditablePoints('morning');
    clearEditablePoints('afternoon');
    clearEditablePoints('evening');
    clearEditablePoints('night');
    isDrawing.value = false;
    activeMapPeriod.value = '';

    // 6. Reset Forecast Metadata to defaults
    currentForecast.value = ForecastData(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      timeIssued: currentForecast.value?.timeIssued ?? '', 
      validFrom: currentForecast.value?.validFrom ?? '',
      warningType: 'None',
      weatherSummary: '',
      seastate: '',
      caution: '',
      notaBene: '',
      sectorTemperatures: {
        'Coast': (min: 0, max: 0),
        'Forest': (min: 0, max: 0),
        'Transition': (min: 0, max: 0), 
        'Northern': (min: 0, max: 0),
      },
    );

    // 7. Push user back to the first tab
    tabController.animateTo(1); // Directly navigate to the Table tab for new forecasts
}

 Future<void> downloadCSVTemplate() async {
    // 1. Create headers
    List<List<dynamic>> csvData = [
      [
        'CITY', 'SLOT1_WEATHER', 'SLOT1_PROB', 'SLOT1_TEMP',
        'SLOT2_WEATHER', 'SLOT2_PROB', 'SLOT2_TEMP',
        'SLOT3_WEATHER', 'SLOT3_PROB', 'SLOT3_TEMP'
      ]
    ];

    // 2. Add city rows
    for (var city in cityData) {
      csvData.add([city['name'], '', '', '', '', '', '', '', '', '']);
    }

    // 3. Convert to CSV string using the NEW csv 8.0.0 syntax
    String csvString = csv.encode(csvData);
    
    // 4. Download file using package:web (Flutter Web compatible)
    final bytes = utf8.encode(csvString);
    final jsArray = [Uint8List.fromList(bytes).toJS].toJS;
    final blob = web.Blob(jsArray, web.BlobPropertyBag(type: 'text/csv'));
    final url = web.URL.createObjectURL(blob);
    
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = "CAFO_Daily_Template.csv";
      
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  void _handleTabChange() {
    // Changed index check from 1 to 2, and fallback from 0 to 1
    if (tabController.index == 2 && !isTableComplete.value && !tabController.indexIsChanging) {
      tabController.animateTo(1); // Force back to Table (Index 1)
      Get.snackbar(
        'Complete Table First',
        'Finish the Daily Forecast Table before proceeding.',
        backgroundColor: const Color(0xFFFFB547).withOpacity(0.95),
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
    }
    update(); // Always rebuild step bar
  }

  @override
  void onClose() {
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    summaryController.dispose();
    nbController.dispose();
    super.onClose();
  }

  // ========================================================================
  // 1. TABLE & HEADER STATE
  // ========================================================================
 

 void goToNextTab() {
    // 1. Validate the Table Data
    // We compare your existing filledCellCount against the total required cells.
    if (filledCellCount < totalCellCount) {
      Get.snackbar(
        'Incomplete Table',
        'Please ensure all weather, probability, and temperature cells are filled for every city.',
        backgroundColor: AppTheme.dangerRed.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return; // Stop execution, don't move to the next tab
    }

    // 2. Validate the Summary Field
    if (summaryController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Summary',
        'Please provide a weather summary before proceeding.',
        backgroundColor: AppTheme.dangerRed.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return; // Stop execution
    }

    // 3. If all validations pass, allow navigation
    isTableComplete.value = true;
    tabController.animateTo(2);
    update();
  }

  void updateIssueTime(String val) {
    selectedIssueTime.value = val;
    // Sync the metadata whenever the user manually changes the dropdown
    _syncForecastTimes(val);
  }


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
    
    // Sync the metadata immediately when the app opens
    _syncForecastTimes(newTime); 
  }


  List<String> get dynamicHeaders {
    switch (selectedIssueTime.value) {
      case '0500': return ['MORNING', 'AFTERNOON', 'EVENING'];
      case '1100': return ['AFTERNOON', 'EVENING', 'NIGHT'];
      case '1700': return ['EVENING', 'NIGHT', 'MORNING'];
      case '2300': return ['NIGHT', 'MORNING', 'AFTERNOON'];
      default: return ['MORNING', 'AFTERNOON', 'EVENING'];
    }
  }

  List<String> get dynamicDates {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final fmt = DateFormat('dd MMM');
    final today = fmt.format(now);
    final tom = fmt.format(tomorrow);
    switch (selectedIssueTime.value) {
      case '0500': return [today, today, today];
      case '1100': return [today, today, tom];
      case '1700': return [today, tom, tom];
      case '2300': return [tom, tom, tom];
      default: return [today, today, today];
    }
  }

  // ── City data ─────────────────────────────────────────────────────────────
  

  static Map<String, dynamic> _emptyCity(String name) => {
        'name': name,
        'slot1_weather': '',
        'slot1_prob': '',
        'slot1_temp': '',
        'slot2_weather': '',
        'slot2_prob': '',
        'slot2_temp': '',
        'slot3_weather': '',
        'slot3_prob': '',
        'slot3_temp': '',
      };

  int get filledCellCount {
    int count = 0;
    for (final city in cityData) {
      for (final slot in ['slot1', 'slot2', 'slot3']) {
        if ((city['${slot}_weather'] as String).isNotEmpty) count++;
        if ((city['${slot}_prob'] as String).isNotEmpty) count++;
        if ((city['${slot}_temp'] as String).isNotEmpty) count++;
      }
    }
    return count;
  }

 

  void onCellChanged() {
    tableProgress.value = filledPercent;
    cityData.refresh();
  }


 
  // ========================================================================
  // 2. MAP & DRAWING LOGIC
  // ========================================================================
 var isDrawing = false.obs;
  var activeMapPeriod = ''.obs;
  var selectedColor = 'green'.obs;
  var isLoadingPDF = false.obs;

  // ADDED: Night regions
  final morningRegions = <MapRegion>[].obs;
  final afternoonRegions = <MapRegion>[].obs;
  final eveningRegions = <MapRegion>[].obs;
  final nightRegions = <MapRegion>[].obs; 

  // ADDED: Night editable points
  final morningEditable = <EditablePoint>[].obs;
  final afternoonEditable = <EditablePoint>[].obs;
  final eveningEditable = <EditablePoint>[].obs;
  final nightEditable = <EditablePoint>[].obs;

 // ADDED: Night undo stack
  final _undoStack = <String, List<List<EditablePoint>>>{
    'morning': [],
    'afternoon': [],
    'evening': [],
    'night': [],
  };

  // ADDED: Night Map Controller
  final morningMapCtrl = MapController();
  final afternoonMapCtrl = MapController();
  final eveningMapCtrl = MapController();
  final nightMapCtrl = MapController(); 

  // UPDATED GETTERS TO INCLUDE NIGHT
  MapController getMapControllerForPeriod(String p) {
    final pLower = p.toLowerCase();
    if (pLower == 'morning') return morningMapCtrl;
    if (pLower == 'afternoon') return afternoonMapCtrl;
    if (pLower == 'night') return nightMapCtrl;
    return eveningMapCtrl; 
  }

  RxList<MapRegion> getRegionsForPeriod(String p) {
    final pLower = p.toLowerCase();
    if (pLower == 'morning') return morningRegions;
    if (pLower == 'afternoon') return afternoonRegions;
    if (pLower == 'night') return nightRegions;
    return eveningRegions;
  }

  RxList<EditablePoint> getEditablePointsForPeriod(String p) {
    final pLower = p.toLowerCase();
    if (pLower == 'morning') return morningEditable;
    if (pLower == 'afternoon') return afternoonEditable;
    if (pLower == 'night') return nightEditable;
    return eveningEditable;
  }

  var draggedPointIndex = RxnInt();

  void updateEditablePoint(String p, int index, LatLng newPos) {
    final list = getEditablePointsForPeriod(p);
    if (index >= 0 && index < list.length) {
      list[index].position = newPos;
      list.refresh();
    }
  }

  void removeEditablePoint(String p, int index) {
    final list = getEditablePointsForPeriod(p);
    if (index >= 0 && index < list.length) {
      saveUndoState(p);
      list.removeAt(index);
    }
  }

  void selectPolygonForEditing(String p, LatLng tapPoint) {
    final regions = getRegionsForPeriod(p);
    for (int i = regions.length - 1; i >= 0; i--) {
      if (_isPointInPolygon(tapPoint, regions[i].points)) {
        final regionToEdit = regions.removeAt(i);
        _originalRegionToEdit = MapRegion(
          points: List.from(regionToEdit.points),
          color: regionToEdit.color,
        );
        setActiveMapPeriod(p);
        setColor(regionToEdit.color);
        final activeList = getEditablePointsForPeriod(p);
        activeList.assignAll(
          regionToEdit.points.asMap().entries
              .map((e) => EditablePoint(e.value, e.key)),
        );
        _undoStack[p]?.clear();
        isDrawing.value = true;
        break;
      }
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    int count = 0;
    for (int j = 0; j < polygon.length - 1; j++) {
      if (_rayCastIntersect(point, polygon[j], polygon[j + 1])) count++;
    }
    if (_rayCastIntersect(point, polygon.last, polygon.first)) count++;
    return count % 2 == 1;
  }

  bool _rayCastIntersect(LatLng point, LatLng a, LatLng b) {
    if ((a.latitude > point.latitude) != (b.latitude > point.latitude)) {
      final x = ((b.longitude - a.longitude) *
              (point.latitude - a.latitude) /
              (b.latitude - a.latitude)) +
          a.longitude;
      if (point.longitude < x) return true;
    }
    return false;
  }

  MapRegion? _originalRegionToEdit;

  void cancelDrawing(String p) {
    if (_originalRegionToEdit != null) {
      getRegionsForPeriod(p).add(_originalRegionToEdit!);
    }
    _resetDrawingState(p);
  }

  void deleteActiveDrawing(String p) => _resetDrawingState(p);

  void _resetDrawingState(String p) {
    clearEditablePoints(p);
    isDrawing.value = false;
    activeMapPeriod.value = '';
    _originalRegionToEdit = null;
  }

  Color get activeColor {
    switch (selectedColor.value) {
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      case 'yellow': return Colors.yellow;
      case 'green': return Colors.green;
      default: return Colors.blue;
    }
  }

 List<String> getOrderedPeriods() {
    switch (selectedIssueTime.value) {
        case '0500': return ['MORNING', 'AFTERNOON', 'EVENING'];
      case '1100': return ['AFTERNOON', 'EVENING', 'NIGHT'];
      case '1700': return ['EVENING', 'NIGHT', 'MORNING'];
      case '2300': return ['NIGHT', 'MORNING', 'AFTERNOON'];
      default: return ['MORNING', 'AFTERNOON', 'EVENING'];
    }
  }
  void setActiveMapPeriod(String p) => activeMapPeriod.value = p;

  void startDrawing() {
    isDrawing.value = true;
    _originalRegionToEdit = null;
  }

 void setColor(String c) => selectedColor.value = c;

  void addEditablePoint(String p, LatLng point) {
    final list = getEditablePointsForPeriod(p);
    list.add(EditablePoint(point, list.length));
  }
  
  void finishDrawingFromEditablePoints(String p) {
    final list = getEditablePointsForPeriod(p);
    if (list.length < 3) {
      Get.snackbar('Invalid Shape', 'At least 3 points required.',
          backgroundColor: Colors.red.shade700, colorText: Colors.white);
      return;
    }
    getRegionsForPeriod(p).add(
      MapRegion(
        points: list.map((e) => e.position).toList(),
        color: selectedColor.value,
      ),
    );
    _resetDrawingState(p);
  }

  void clearEditablePoints(String p) {
    getEditablePointsForPeriod(p).clear();
    _undoStack[p]?.clear();
  }

  void saveUndoState(String p) {
    final snap = getEditablePointsForPeriod(p)
        .map((e) => EditablePoint(e.position, e.id))
        .toList();
    _undoStack[p]?.add(snap);
  }
 void undo(String p) {
    final stack = _undoStack[p];
    if (stack != null && stack.isNotEmpty) {
      getEditablePointsForPeriod(p).assignAll(stack.removeLast());
    } else {
      final list = getEditablePointsForPeriod(p);
      if (list.isNotEmpty) list.removeLast();
    }
  }
  // ========================================================================
  // 3. MOVABLE ICONS & LETTERS
  // ========================================================================
 final morningItems = <DraggableMapItem>[].obs;
  final afternoonItems = <DraggableMapItem>[].obs;
  final eveningItems = <DraggableMapItem>[].obs;
  final nightItems = <DraggableMapItem>[].obs; // ADDED: Night items

 // UPDATED GETTER TO INCLUDE NIGHT
  RxList<DraggableMapItem> getMapItemsForPeriod(String p) {
    final pLower = p.toLowerCase();
    if (pLower == 'morning') return morningItems;
    if (pLower == 'afternoon') return afternoonItems;
    if (pLower == 'night') return nightItems;
    return eveningItems;
  }

  void addMapItem(String p, MapItemType type, String value, LatLng spawnPoint) {
    getMapItemsForPeriod(p).add(DraggableMapItem(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      value: value,
      position: spawnPoint,
    ));
  }

  void updateMapItemPos(String p, String id, LatLng newPos) {
    final list = getMapItemsForPeriod(p);
    final i = list.indexWhere((item) => item.id == id);
    if (i != -1) {
      list[i].position = newPos;
      list.refresh();
    }
  }

  void deleteMapItem(String p, String id) =>
      getMapItemsForPeriod(p).removeWhere((item) => item.id == id);

  // ========================================================================
  // 4. FORECAST METADATA
  // ========================================================================
  var currentForecast = Rxn<ForecastData>(ForecastData(
    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    timeIssued: '', // We will auto-fill this now
    validFrom: '',  // We will auto-fill this now
    warningType: 'None',
    weatherSummary: '',
    seastate: '', 
    caution: '',
    notaBene: '',
    sectorTemperatures: {
      'Coast': (min: 0, max: 0),
      'Forest': (min: 0, max: 0),
      'Transition': (min: 0, max: 0), 
      'Northern': (min: 0, max: 0),
    },
  ));

  // ADD THIS NEW METHOD:
  void _syncForecastTimes(String rawTime) {
    if (rawTime.length != 4) return;

    // Extract hours and minutes from "0500", "1100", etc.
    String hh = rawTime.substring(0, 2);
    String mm = rawTime.substring(2, 4);

    // Format Time Issued -> "05:00 UTC"
    String newTimeIssued = "$hh:$mm UTC";

    // Calculate Valid From (+1 hour)
    int hourInt = int.tryParse(hh) ?? 0;
    int validHourInt = (hourInt + 1) % 24; // % 24 handles wrap-around at midnight
    String validHh = validHourInt.toString().padLeft(2, '0');
    String newValidFrom = "$validHh:$mm";

    // Update the forecast state
    currentForecast.value = currentForecast.value?.copyWith(
      timeIssued: newTimeIssued,
      validFrom: newValidFrom,
    );
  }

  void updateDate(String v) =>
      currentForecast.value = currentForecast.value?.copyWith(date: v);
  void updateTimeIssued(String v) =>
      currentForecast.value = currentForecast.value?.copyWith(timeIssued: v);
  void updateWarningType(String v) =>
      currentForecast.value = currentForecast.value?.copyWith(warningType: v);
  void updateSeastate(String v) =>
      currentForecast.value = currentForecast.value?.copyWith(seastate: v);
  void updateValidFrom(String v) =>
      currentForecast.value = currentForecast.value?.copyWith(validFrom: v);
  void updateSummary(String v) =>
      currentForecast.value = currentForecast.value?.copyWith(weatherSummary: v);
  void updateCaution(String v) =>
      currentForecast.value = currentForecast.value?.copyWith(caution: v);

  void updateTemperatureRange(String key, int min, int max) {
    final old = currentForecast.value?.sectorTemperatures ?? {};
    final newMap = Map<String, ({int min, int max})>.from(old);
    newMap[key] = (min: min, max: max);
    currentForecast.value = currentForecast.value?.copyWith(sectorTemperatures: newMap);
  }

 
 
 Future<void> fetchSettings() async {
    try {
      final user = _authCtrl.currentUser.value;
      if (user == null) {
        print("CAFO Error: fetchSettings aborted because user is null.");
        return; 
      }

      isLoadingSettings.value = true;
      
      String dept = user.department.toLowerCase().replaceAll(' ', '_');
      if (dept.isEmpty || dept == 'all') dept = 'cafo'; 
      String docId = '${dept}_settings';

      print("CAFO: Attempting to fetch settings from Firestore doc: $docId");

      DocumentSnapshot doc = await _firestore.collection('settings').doc(docId).get();

      if (doc.exists) {
        print("CAFO: SUCCESS! Settings downloaded.");
        SettingsModel settings = SettingsModel.fromFirestore(doc);
        weatherOptions.assignAll(settings.weatherConditions);
        cityData.assignAll(
          settings.cities.map((cityName) => _emptyCity(cityName)).toList()
        );
      } else {
        print("CAFO Warning: Document $docId does NOT exist in Firestore!");
        Get.snackbar('Settings Missing', 'No config found for $dept. Using defaults.');
        weatherOptions.assignAll(['CLEAR', 'SUNNY', 'CLOUDY', 'RAIN']);
        cityData.assignAll([_emptyCity('ACCRA'), _emptyCity('KUMASI')]);
      }
    } catch (e) {
      print("CAFO CRITICAL ERROR: $e");
      Get.snackbar('Database Error', 'Could not load settings from Firebase.');
    } finally {
      isLoadingSettings.value = false;
      print("CAFO: isLoadingSettings turned off.");
}
  }

  List<String> get _cafoGroupIds => [
    'O9HcbFUOYgAFnxN2OrLN',
    'FXQGcjeQfEJKtreb9cyN',
  ];

  Future<void> _autoPostCafoToCommunityGroups(String docId) async {
    const String functionName = 'CAFO Auto-Post';
    Get.snackbar(functionName, 'Starting to generate and post forecast files...',
        showProgressIndicator: true, duration: const Duration(seconds: 10));

    try {
      // Fetch forecast directly from Firestore instead of relying on forecastsList
      final docSnapshot = await _firestore.collection('cafo_daily_forecast').doc(docId).get();
      if (!docSnapshot.exists) {
        Get.snackbar('Warning', 'Forecast not found for auto-post.', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      final forecast = Map<String, dynamic>.from(docSnapshot.data()!);
      forecast['id'] = docId;
      final metadata = forecast['metadata'] ?? {};
      final mData = forecast['mapData'] ?? {};
      
      final validDate = forecast['validDate'] ?? forecast['date'] ?? '';
      final formattedDate = validDate.isNotEmpty 
          ? DateFormat('dd/MM/yyyy').format(DateTime.tryParse(validDate) ?? DateTime.now()) 
          : DateFormat('dd/MM/yyyy').format(DateTime.now());

      List<String> postedFiles = [];

      // ============ 1. Generate Table PDF ONCE ============
      String? tablePdfUrl;
      try {
        Get.snackbar(functionName, 'Generating Table PDF...', duration: const Duration(seconds: 5));
        final tablePdfBytes = await CAFOTablePdfService.generateForecastPdf(forecast);
        if (tablePdfBytes.isNotEmpty) {
          tablePdfUrl = await _uploadToStorage(
            fileBytes: tablePdfBytes,
            fileName: 'CAFO_Table_${DateTime.now().millisecondsSinceEpoch}.pdf',
            type: 'file',
          );
          postedFiles.add('Table PDF');
        }
      } catch (e) {
        debugPrint('Error generating CAFO Table PDF: $e');
      }

      // ============ 2. Generate Table Image ONCE ============
      String? tableImageUrl;
      try {
        Get.snackbar(functionName, 'Generating Table Image...', duration: const Duration(seconds: 5));
        final tablePdfBytes = await CAFOTablePdfService.generateForecastPdf(forecast);
        final tableImageBytes = await _rasterizePdfToImage(tablePdfBytes);
        if (tableImageBytes.isNotEmpty) {
          tableImageUrl = await _uploadToStorage(
            fileBytes: tableImageBytes,
            fileName: 'CAFO_Table_${DateTime.now().millisecondsSinceEpoch}.png',
            type: 'image',
          );
          postedFiles.add('Table Image');
        }
      } catch (e) {
        debugPrint('Error generating CAFO Table Image: $e');
      }

      // ============ 3. Generate IBF with 3 maps ONCE ============
      String? ibfPdfUrl;
      String? ibfImageUrl;
      try {
        Get.snackbar(functionName, 'Generating IBF Maps...', duration: const Duration(seconds: 15));
        
        final dbIssueTime = metadata['issueTimeSlot'] ?? '0500';
        final activeHdrs = _getHeadersFromDatabaseTime(dbIssueTime);
        
        final String p1 = activeHdrs[0].toLowerCase();
        final String p2 = activeHdrs[1].toLowerCase();
        final String p3 = activeHdrs[2].toLowerCase();
        
        final ctx = Get.context!;

        final bytes1 = await CAFOImageGenerator.generateMapImageFromData(
          mData[p1]?['regions'],
          itemsData: mData[p1]?['items'],
          context: ctx,
          tileWaitMs: 3500,
        );

        final bytes2 = await CAFOImageGenerator.generateMapImageFromData(
          mData[p2]?['regions'],
          itemsData: mData[p2]?['items'],
          context: ctx,
          tileWaitMs: 3500,
        );

        final bytes3 = await CAFOImageGenerator.generateMapImageFromData(
          mData[p3]?['regions'],
          itemsData: mData[p3]?['items'],
          context: ctx,
          tileWaitMs: 3500,
        );

        if (bytes1 != null && bytes1.isNotEmpty && 
            bytes2 != null && bytes2.isNotEmpty && 
            bytes3 != null && bytes3.isNotEmpty) {
          
          final ibfPayload = _buildCafoIbfPayload(forecast, bytes1, bytes2, bytes3);
          final ibfPdfBytes = await CafoDailyForecastIbfPdfService.generateIbfPdf(ibfPayload);
          
          if (ibfPdfBytes.isNotEmpty) {
            ibfPdfUrl = await _uploadToStorage(
              fileBytes: ibfPdfBytes,
              fileName: 'CAFO_IBF_${DateTime.now().millisecondsSinceEpoch}.pdf',
              type: 'file',
            );
            postedFiles.add('IBF PDF');

            // Generate IBF Image from the same PDF
            final ibfImageBytes = await _rasterizePdfToImage(ibfPdfBytes);
            if (ibfImageBytes.isNotEmpty) {
              ibfImageUrl = await _uploadToStorage(
                fileBytes: ibfImageBytes,
                fileName: 'CAFO_IBF_${DateTime.now().millisecondsSinceEpoch}.png',
                type: 'image',
              );
              postedFiles.add('IBF Image');
            }
          }
        }
      } catch (e) {
        debugPrint('Error generating CAFO IBF: $e');
      }

      // ============ 4. Post URLs to BOTH groups ============
      for (final groupId in _cafoGroupIds) {
        // Post Table PDF
        if (tablePdfUrl != null) {
          await _postUrlToGroup(
            groupId: groupId,
            mediaUrl: tablePdfUrl,
            content: 'CAFO Daily Forecast Table for $formattedDate',
            type: 'file',
          );
        }

        // Post Table Image
        if (tableImageUrl != null) {
          await _postUrlToGroup(
            groupId: groupId,
            mediaUrl: tableImageUrl,
            content: 'CAFO Daily Forecast Table Image for $formattedDate',
            type: 'image',
          );
        }

        // Post IBF PDF
        if (ibfPdfUrl != null) {
          await _postUrlToGroup(
            groupId: groupId,
            mediaUrl: ibfPdfUrl,
            content: 'CAFO IBF Forecast for $formattedDate',
            type: 'file',
          );
        }

        // Post IBF Image
        if (ibfImageUrl != null) {
          await _postUrlToGroup(
            groupId: groupId,
            mediaUrl: ibfImageUrl,
            content: 'CAFO IBF Forecast Image for $formattedDate',
            type: 'image',
          );
        }
      }

      if (postedFiles.isNotEmpty) {
        await _markCafoForecastAsPosted(docId);
        Get.snackbar(
          'Auto-Post Complete',
          'Posted: ${postedFiles.join(", ")} to ${_cafoGroupIds.length} groups',
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
      debugPrint('Critical error in CAFO auto-post: $e');
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

  Future<void> _markCafoForecastAsPosted(String docId) async {
    try {
      await _firestore.collection('cafo_daily_forecast').doc(docId).update({
        'communityPosted': true,
        'communityPostedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to mark CAFO forecast as posted: $e');
    }
  }

  Map<String, dynamic> _buildCafoIbfPayload(Map<String, dynamic> forecast, Uint8List map1Bytes, Uint8List map2Bytes, Uint8List map3Bytes) {
    final metadata = forecast['metadata'] ?? {};
    
    final dbIssueTime = metadata['issueTimeSlot'] ?? '0500';
    final dateStr = metadata['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
    final tomorrow = parsedDate.add(const Duration(days: 1));
    final todayFormatted = DateFormat('dd/MM/yyyy').format(parsedDate);
    final tomFormatted = DateFormat('dd/MM/yyyy').format(tomorrow);
    
    final activeHdrs = _getHeadersFromDatabaseTime(dbIssueTime);
    List<String> activeDates;
    switch (dbIssueTime) {
      case '0500': activeDates = [todayFormatted, todayFormatted, todayFormatted]; break;
      case '1100': activeDates = [todayFormatted, todayFormatted, tomFormatted];   break;
      case '1700': activeDates = [todayFormatted, tomFormatted,   tomFormatted];   break;
      case '2300': activeDates = [tomFormatted,   tomFormatted,   tomFormatted];   break;
      default:     activeDates = [todayFormatted, todayFormatted, todayFormatted];
    }
    
    final rawTemps = metadata['sectorTemperatures'] ?? {};
    final List<Map<String, String>> formattedTemps = [
      'Coast', 'Forest', 'Transition', 'Northern'
    ].map((s) => {
      'sector': s,
      'min': rawTemps[s]?['min']?.toString() ?? '-',
      'max': rawTemps[s]?['max']?.toString() ?? '-',
    }).toList();

    return {
      'date': DateFormat('dd-MMM-yy').format(parsedDate).toUpperCase(),
      'formattedDate': todayFormatted,
      'timeIssued': metadata['timeIssued'] ?? '$dbIssueTime UTC',
      'validFrom': metadata['validFrom'] ?? '',
      'temperatures': formattedTemps,
      'summary': metadata['mapSummary'] ?? metadata['tableSummary'] ?? 'No summary provided.',
      'headers': activeHdrs,
      'headerDates': activeDates,
      'map1': map1Bytes,
      'map2': map2Bytes,
      'map3': map3Bytes,
      'forecasterName': forecast['author']?['name'] ?? 'DUTY FORECASTER',
    };
  }

  Future<Uint8List> _rasterizePdfToImage(Uint8List pdfBytes) async {
    try {
      final pages = await Printing.raster(pdfBytes, dpi: 300).toList();
      if (pages.isEmpty) return Uint8List(0);
      return await pages.first.toPng();
    } catch (e) {
      debugPrint('Error rasterizing PDF: $e');
      return Uint8List(0);
    }
  }
 
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
class MapRegion {
  final List<LatLng> points;
  final String color;
  MapRegion({required this.points, required this.color});
}

class EditablePoint {
  LatLng position;
  final int id;
  EditablePoint(this.position, this.id);
}

enum MapItemType { icon, text }

class DraggableMapItem {
  final String id;
  final MapItemType type;
  final String value;
  LatLng position;

  DraggableMapItem({
    required this.id,
    required this.type,
    required this.value,
    required this.position,
  });
}
