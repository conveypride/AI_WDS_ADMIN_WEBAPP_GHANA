import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';
import 'package:weather_admin_dashboard/app/data/models/settings_model.dart';

class SevenDayForecastController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  final AuthController _authCtrl = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
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
  // STATE VARIABLES
  // ========================================================================
  var isLoadingSettings = true.obs;
  var isPublishing = false.obs;
  var isImporting = false.obs;
  var isAdmin = false.obs; // Tracks role for UI rendering

  var startDate = DateTime.now().obs;
  
  final locations = <String>[].obs;
  final weatherOptions = <String>[].obs;
  final List<String> probOptions = List.generate(101, (i) => i.toString()); // Fixed to include 0

  var forecastGrid = <String, List<Map<String, dynamic>>>{}.obs;
  var tableKey = UniqueKey().obs; // Forces UI refresh on import

  // Pagination & History State
  var forecastHistory = <Map<String, dynamic>>[].obs;
  var isLoadingHistory = true.obs;
  var isFetchingMore = false.obs;
  var hasMore = true.obs;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 10;

  // Analytics State
  var totalCount = 0.obs;
  var approvedCount = 0.obs;
  var pendingCount = 0.obs;
  var revokedCount = 0.obs;

  // ========================================================================
  // 1. DYNAMIC INITIALIZATION
  // ========================================================================
  Future<void> _initDynamicData() async {
    final user = _authCtrl.currentUser.value;
    if (user != null) {
      isAdmin.value = user.role.contains('super_admin') || user.role.contains('admin');
    }
    await fetchSettings();
    await fetchAnalytics();
    await fetchForecastHistory();
  }


// ========================================================================
  // VIEW FORECAST (READ-ONLY DIALOG)
  // ========================================================================
  void viewForecast(Map<String, dynamic> item) {
    Map<String, dynamic> grid = item['forecastGrid'] ?? {};
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          width: 800,
          constraints: BoxConstraints(maxHeight: Get.height * 0.85),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Forecast Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text("ID: ${item['id']}  |  Range: ${item['dateRange']}", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Get.back(),
                    splashRadius: 24,
                  ),
                ],
              ),
              const Divider(height: 32),
              
              // Scrollable Data Summary
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: grid.entries.map((entry) {
                      String city = entry.key;
                      List days = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(city, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: List.generate(days.length, (index) {
                                var dayData = days[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!)
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Day ${index + 1}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                                      const SizedBox(height: 4),
                                      Text(dayData['cond'] == '' ? 'No data' : dayData['cond'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text("Temp: ${dayData['min']}° - ${dayData['max']}°", style: const TextStyle(fontSize: 12)),
                                      Text("Prob: ${dayData['prob']}%", style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                );
                              }),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            ],
          ),
        ),
      )
    );
  }

  // ========================================================================
  // EDIT FORECAST
  // ========================================================================
  // ========================================================================
  // EDIT FORECAST (BULLETPROOF)
  // ========================================================================
  void editForecast(Map<String, dynamic> item) {
    try {
      // 1. Set the date back to the forecast's original start date
      if (item['startDate'] != null) {
        startDate.value = DateTime.parse(item['startDate']);
      }

      // 2. Load the old grid data into active memory with strict String casting
      Map<String, dynamic> savedGrid = item['forecastGrid'] ?? {};
      
      for (var loc in locations) {
        if (savedGrid.containsKey(loc)) {
          // Firebase arrays come back as Lists
          var locData = savedGrid[loc] as List; 
          for (int i = 0; i < 7; i++) {
            if (i < locData.length) {
              var cellData = locData[i] ?? {};
              // Enforce String conversion so TextFormField never crashes
              forecastGrid[loc]![i] = {
                'cond': cellData['cond']?.toString() ?? '',
                'min': cellData['min']?.toString() ?? '',
                'max': cellData['max']?.toString() ?? '',
                'prob': cellData['prob']?.toString() ?? '',
              };
            }
          }
        }
      }
      
      // 3. Force the UI to refresh with the newly loaded data
      forecastGrid.refresh();
      tableKey.value = UniqueKey();
      
      // 4. Switch to the entry tab
      tabController.animateTo(1);
      
      Get.snackbar("Edit Mode", "Loaded forecast data. You can now make changes and resubmit.", backgroundColor: Colors.blueAccent, colorText: Colors.white);
    } catch (e) {
      debugPrint("Edit Error: $e");
      Get.snackbar("Error", "Could not load forecast data.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> fetchSettings() async {
    try {
      isLoadingSettings.value = true;
      final user = _authCtrl.currentUser.value;
      if (user == null) return;

      String dept = user.department.toLowerCase().replaceAll(' ', '_');
      if (dept.isEmpty || dept == 'all') dept = 'cafo';
      String docId = '${dept}_settings';

      DocumentSnapshot doc = await _firestore.collection('settings').doc(docId).get();

      if (doc.exists) {
        SettingsModel settings = SettingsModel.fromFirestore(doc);
        weatherOptions.assignAll(settings.weatherConditions);
        locations.assignAll(settings.cities);
      } else {
        weatherOptions.assignAll(["CLEAR", "SUNNY", "CLOUDY", "RAIN"]);
        locations.assignAll(["ACCRA", "KUMASI"]);
      }
      _initializeEmptyGrid();
    } catch (e) {
      debugPrint("Error fetching settings: $e");
    } finally {
      isLoadingSettings.value = false;
    }
  }

  void _initializeEmptyGrid() {
    for (var loc in locations) {
      forecastGrid[loc] = List.generate(7, (index) => {
        "cond": "", "prob": "", "min": "", "max": ""
      });
    }
    forecastGrid.refresh();
  }

  List<DateTime> get dynamicDates {
    return List.generate(7, (index) => startDate.value.add(Duration(days: index)));
  }

  void updateStartDate(DateTime date) {
    startDate.value = date;
  }

  // ========================================================================
  // 2. ANALYTICS (OPTIMIZED COUNT QUERIES)
  // ========================================================================
  Future<void> fetchAnalytics() async {
    final user = _authCtrl.currentUser.value;
    if (user == null) return;

    Query baseQuery = _firestore.collection('seven_day_forecast');
    if (!isAdmin.value) {
      baseQuery = baseQuery.where('author.uid', isEqualTo: user.uid);
    }

    try {
      // .count() is highly optimized by Firebase. Costs 1 read per execution.
      final total = await baseQuery.count().get();
      final approved = await baseQuery.where('status', isEqualTo: 'published').count().get();
      final pending = await baseQuery.where('status', isEqualTo: 'pending_approval').count().get();
      final revoked = await baseQuery.where('status', isEqualTo: 'revoked').count().get();

      totalCount.value = total.count ?? 0;
      approvedCount.value = approved.count ?? 0;
      pendingCount.value = pending.count ?? 0;
      revokedCount.value = revoked.count ?? 0;
    } catch (e) {
      debugPrint("Analytics Error: $e");
    }
  }

  // ========================================================================
  // 3. FETCH HISTORY & PAGINATION
  // ========================================================================
  Future<void> fetchForecastHistory() async {
    try {
      isLoadingHistory.value = true;
      hasMore.value = true;
      _lastDocument = null;

      final user = _authCtrl.currentUser.value;
      if (user == null) return;

      Query query = _firestore.collection('seven_day_forecast')
          .orderBy('updatedAt', descending: true)
          .limit(_pageSize);

      if (!isAdmin.value) query = query.where('author.uid', isEqualTo: user.uid);

      QuerySnapshot snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last; 
        if (snapshot.docs.length < _pageSize) hasMore.value = false; 
      } else {
        hasMore.value = false;
      }

      forecastHistory.value = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        return data;
      }).toList();

    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> loadMoreHistory() async {
    if (isFetchingMore.value || !hasMore.value || _lastDocument == null) return;

    try {
      isFetchingMore.value = true;
      final user = _authCtrl.currentUser.value;
      if (user == null) return;

      Query query = _firestore.collection('seven_day_forecast')
          .orderBy('updatedAt', descending: true)
          .startAfterDocument(_lastDocument!) 
          .limit(_pageSize);

      if (!isAdmin.value) query = query.where('author.uid', isEqualTo: user.uid);

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last; 
        if (snapshot.docs.length < _pageSize) hasMore.value = false;

        var newDocs = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        forecastHistory.addAll(newDocs); 
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      debugPrint("Error loading more history: $e");
    } finally {
      isFetchingMore.value = false;
    }
  }

  // ========================================================================
  // 4. ADMIN ACTIONS (Approve / Revoke)
  // ========================================================================
  Future<void> changeForecastStatus(String docId, String newStatus) async {
    if (!isAdmin.value) {
      Get.snackbar("Denied", "You don't have permission to do this.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    try {
      final user = _authCtrl.currentUser.value;
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': user?.name ?? 'Admin',
      };

      if (newStatus == 'published') {
        updateData['approvedAt'] = FieldValue.serverTimestamp();
        updateData['approvedBy'] = user?.uid;
      }

      await _firestore.collection('seven_day_forecast').doc(docId).update(updateData);
      
      Get.snackbar(
        "Success", 
        "Forecast marked as ${newStatus.toUpperCase()}",
        backgroundColor: const Color(0xFF3DD68C).withOpacity(0.9), colorText: Colors.black,
      );

      // Refresh Data
      await fetchAnalytics();
      await fetchForecastHistory();

    } catch (e) {
      debugPrint("Status Update Error: $e");
      Get.snackbar("Error", "Could not update status.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // ========================================================================
  // 5. PRE-POPULATE DATA
  // ========================================================================
  Future<void> createNewForecast() async {
    startDate.value = DateTime.now();
    _initializeEmptyGrid();

    try {
      QuerySnapshot lastApproved = await _firestore.collection('seven_day_forecast')
          .where('status', isEqualTo: 'published')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (lastApproved.docs.isNotEmpty) {
        var oldData = lastApproved.docs.first.data() as Map<String, dynamic>;
        
        DateTime oldStartDate = DateTime.tryParse(oldData['startDate'] ?? '') ?? DateTime.now();
        List<DateTime> oldDates = List.generate(7, (index) => oldStartDate.add(Duration(days: index)));
        List<DateTime> newDates = dynamicDates;

        Map<String, dynamic> oldGrid = oldData['forecastGrid'] ?? {};

        for (var loc in locations) {
          if (oldGrid.containsKey(loc)) {
            for (int newIdx = 0; newIdx < 7; newIdx++) {
              DateTime targetDate = newDates[newIdx];
              int oldIdx = oldDates.indexWhere((d) => 
                d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day
              );

              if (oldIdx != -1) {
                forecastGrid[loc]![newIdx] = Map<String, dynamic>.from(oldGrid[loc][oldIdx]);
              }
            }
          }
        }
        forecastGrid.refresh();
        tableKey.value = UniqueKey();
        Get.snackbar("Pre-populated", "Loaded overlapping data from the last approved forecast.", backgroundColor: Colors.blueAccent, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("Error prepopulating: $e");
    }

    tabController.animateTo(1);
  }

  // ========================================================================
  // 6. PUBLISH / SUBMIT
  // ========================================================================
  Future<void> submitForecast() async {
    // 1. VALIDATION CHECK: Ensure no fields are empty
    bool hasEmptyFields = false;
    forecastGrid.forEach((city, days) {
      for (var day in days) {
        if ((day['cond']?.toString().trim().isEmpty ?? true) ||
            (day['min']?.toString().trim().isEmpty ?? true) ||
            (day['max']?.toString().trim().isEmpty ?? true) ||
            (day['prob']?.toString().trim().isEmpty ?? true)) {
          hasEmptyFields = true;
        }
      }
    });

    if (hasEmptyFields) {
      Get.snackbar(
        "Incomplete Data", 
        "Please fill in all fields (Condition, Min, Max, Prob) for all locations before submitting.",
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return; // Stop the submission process
    }

    // 2. PROCEED WITH SUBMISSION
    isPublishing.value = true;
    
    try {
      final user = _authCtrl.currentUser.value;
      if (user == null) throw Exception("User session expired.");

      final finalStatus = isAdmin.value ? 'published' : 'pending_approval';
      String formattedStart = DateFormat('dd MMM yyyy').format(startDate.value);
      String formattedEnd = DateFormat('dd MMM yyyy').format(startDate.value.add(const Duration(days: 6)));

      Map<String, dynamic> payload = {
        'status': finalStatus,
        'startDate': startDate.value.toIso8601String(),
        'dateRange': '$formattedStart - $formattedEnd',
        'forecastGrid': forecastGrid,
        'updatedAt': FieldValue.serverTimestamp(),
        'author': {
          'uid': user.uid,
          'name': user.name,
          'email': user.email,
        }
      };

      if (isAdmin.value) {
        payload['approvedAt'] = FieldValue.serverTimestamp();
        payload['approvedBy'] = user.uid;
      }

      String docId = '7D_${DateFormat('yyyyMMdd').format(startDate.value)}_${user.uid.substring(0, 5)}';

      await _firestore.collection('seven_day_forecast').doc(docId).set(payload, SetOptions(merge: true));

      Get.snackbar(
        isAdmin.value ? "Published!" : "Sent for Approval", 
        isAdmin.value ? "7-Day Forecast successfully saved and is live." : "Forecast routed to supervisor.",
        backgroundColor: const Color(0xFF3DD68C).withOpacity(0.95), colorText: Colors.black,
      );
      
      await fetchAnalytics();
      await fetchForecastHistory();
      tabController.animateTo(0);

    } catch (e) {
      Get.snackbar('Error', 'Failed to save forecast.', backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isPublishing.value = false;
    }
  }

  // ========================================================================
  // 7. CSV EXPORT & IMPORT
  // ========================================================================
  Future<void> downloadCSVTemplate() async {
    try {
      await Future.delayed(const Duration(milliseconds: 50));
      StringBuffer csvBuffer = StringBuffer();
      List<String> headers = ['CITY'];
      for (int i = 1; i <= 7; i++) {
        headers.addAll(['D${i}_COND', 'D${i}_MIN', 'D${i}_MAX', 'D${i}_PROB']);
      }
      csvBuffer.writeln(headers.join(','));

      for (var loc in locations) {
        List<String> row = [loc];
        for (int i = 0; i < 7; i++) {
          var cell = forecastGrid[loc]?[i];
          row.addAll([
            _escapeCsv(cell?['cond'] ?? ''),
            _escapeCsv(cell?['min'] ?? ''),
            _escapeCsv(cell?['max'] ?? ''),
            _escapeCsv(cell?['prob'] ?? '')
          ]);
        }
        csvBuffer.writeln(row.join(','));
      }

      final bytes = utf8.encode(csvBuffer.toString());
      final jsArray = [Uint8List.fromList(bytes).toJS].toJS;
      final blob = web.Blob(jsArray, web.BlobPropertyBag(type: 'text/csv'));
      final url = web.URL.createObjectURL(blob);
      final anchor = web.HTMLAnchorElement()..href = url..download = "7Day_Forecast_Template.csv";
      anchor.click();
      web.URL.revokeObjectURL(url);

    } catch (e) {
      Get.snackbar("Error", "Could not generate CSV.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) return '"${value.replaceAll('"', '""')}"';
    return value;
  }

  Future<void> importCSVData() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['csv'], withData: true, 
    );

    if (result != null && result.files.single.bytes != null) {
      isImporting.value = true;
      await Future.delayed(const Duration(milliseconds: 100)); 

      try {
        var bytes = result.files.single.bytes!;
        final csvString = utf8.decode(bytes); 
        List<String> rows = csvString.split(RegExp(r'\r\n|\r|\n'));

        for (int i = 1; i < rows.length; i++) {
          if (rows[i].trim().isEmpty) continue;
          List<String> row = rows[i].split(',');
          if (row.isEmpty || row[0].isEmpty) continue;

          String cityName = row[0].replaceAll('"', '').trim().toUpperCase();
          
          if (forecastGrid.containsKey(cityName)) {
            for (int day = 0; day < 7; day++) {
              int colOffset = 1 + (day * 4);
              if (row.length > colOffset + 3) {
                forecastGrid[cityName]![day]['cond'] = row[colOffset].replaceAll('"', '').trim();
                forecastGrid[cityName]![day]['min'] = _formatCSVNumber(row[colOffset + 1]);
                forecastGrid[cityName]![day]['max'] = _formatCSVNumber(row[colOffset + 2]);
                forecastGrid[cityName]![day]['prob'] = _formatCSVNumber(row[colOffset + 3]);
              }
            }
          }
        }
        
        forecastGrid.refresh();
        tableKey.value = UniqueKey();
        Get.snackbar("Success", "CSV Data Imported.", backgroundColor: const Color(0xFF3DD68C).withOpacity(0.9), colorText: Colors.black);
      } catch (e) {
        Get.snackbar("Error", "Failed to parse CSV file.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      } finally {
        isImporting.value = false;
      }
    }
  }

  String _formatCSVNumber(dynamic rawValue) {
    if (rawValue == null) return '';
    String val = rawValue.toString().replaceAll('"', '').trim();
    if (val.endsWith('.0')) return val.substring(0, val.length - 2);
    return val;
  }
}
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'dart:js_interop';
// import 'package:web/web.dart' as web;
// import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';
// import 'package:weather_admin_dashboard/app/data/models/settings_model.dart';

// class SevenDayForecastController extends GetxController with GetSingleTickerProviderStateMixin {
//   late TabController tabController;
//   final AuthController _authCtrl = Get.find<AuthController>();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
//   var tableKey = UniqueKey().obs; // <--- ADD THIS LINE

//   @override
//   void onInit() {
//     super.onInit();
//     tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void onReady() {
//     super.onReady();
//     if (_authCtrl.currentUser.value != null) {
//       _initDynamicData();
//     }
//     ever(_authCtrl.currentUser, (user) {
//       if (user != null) _initDynamicData();
//     });
//   }

//   @override
//   void onClose() {
//     tabController.dispose();
//     super.onClose();
//   }

//   // ========================================================================
//   // STATE VARIABLES
//   // ========================================================================
//   var isLoadingSettings = true.obs;
//   var isPublishing = false.obs;
//   var isImporting = false.obs;

//   var startDate = DateTime.now().obs;
  
//   final locations = <String>[].obs;
//   final weatherOptions = <String>[].obs;
//   final List<String> probOptions = List.generate(101, (i) => i.toString());

//   // forecastGrid[locationName][dayIndex] = { cond, prob, min, max }
//   var forecastGrid = <String, List<Map<String, dynamic>>>{}.obs;

//   // Pagination State
//   var forecastHistory = <Map<String, dynamic>>[].obs;
//   var isLoadingHistory = true.obs;
//   var isFetchingMore = false.obs;
//   var hasMore = true.obs;
//   DocumentSnapshot? _lastDocument;
//   final int _pageSize = 10;

//   // ========================================================================
//   // 1. DYNAMIC INITIALIZATION
//   // ========================================================================
//   Future<void> _initDynamicData() async {
//     await fetchSettings();
//     await fetchForecastHistory();
//   }

//   Future<void> fetchSettings() async {
//     try {
//       isLoadingSettings.value = true;
//       final user = _authCtrl.currentUser.value;
//       if (user == null) return;

//       String dept = user.department.toLowerCase().replaceAll(' ', '_');
//       if (dept.isEmpty || dept == 'all') dept = 'cafo'; // Fallback
//       String docId = '${dept}_settings';

//       DocumentSnapshot doc = await _firestore.collection('settings').doc(docId).get();

//       if (doc.exists) {
//         SettingsModel settings = SettingsModel.fromFirestore(doc);
//         weatherOptions.assignAll(settings.weatherConditions);
//         locations.assignAll(settings.cities);
//       } else {
//         weatherOptions.assignAll(["CLEAR", "SUNNY", "CLOUDY", "RAIN"]);
//         locations.assignAll(["ACCRA", "KUMASI"]);
//       }

//       _initializeEmptyGrid();

//     } catch (e) {
//       debugPrint("Error fetching settings: $e");
//     } finally {
//       isLoadingSettings.value = false;
//     }
//   }

//   void _initializeEmptyGrid() {
//     for (var loc in locations) {
//       forecastGrid[loc] = List.generate(7, (index) => {
//         "cond": "", "prob": "", "min": "", "max": ""
//       });
//     }
//     forecastGrid.refresh();
//   }

//   List<DateTime> get dynamicDates {
//     return List.generate(7, (index) => startDate.value.add(Duration(days: index)));
//   }

//   void updateStartDate(DateTime date) {
//     startDate.value = date;
//   }

//   // ========================================================================
//   // 2. FETCH HISTORY & PAGINATION
//   // ========================================================================
//   Future<void> fetchForecastHistory() async {
//     try {
//       isLoadingHistory.value = true;
//       hasMore.value = true;
//       _lastDocument = null;

//       final user = _authCtrl.currentUser.value;
//       if (user == null) return;

//       final isSuperAdmin = user.role.contains('super_admin') || user.role.contains('admin');

//       Query query = _firestore.collection('seven_day_forecast')
//           .orderBy('updatedAt', descending: true)
//           .limit(_pageSize);

//       if (!isSuperAdmin) {
//         query = query.where('author.uid', isEqualTo: user.uid);
//       }

//       QuerySnapshot snapshot = await query.get();
      
//       if (snapshot.docs.isNotEmpty) {
//         _lastDocument = snapshot.docs.last; 
//         if (snapshot.docs.length < _pageSize) {
//           hasMore.value = false; 
//         }
//       } else {
//         hasMore.value = false;
//       }

//       forecastHistory.value = snapshot.docs.map((doc) {
//         var data = doc.data() as Map<String, dynamic>;
//         data['id'] = doc.id; 
//         return data;
//       }).toList();

//     } catch (e) {
//       debugPrint("Error fetching history: $e");
//     } finally {
//       isLoadingHistory.value = false;
//     }
//   }

//   Future<void> loadMoreHistory() async {
//     if (isFetchingMore.value || !hasMore.value || _lastDocument == null) return;

//     try {
//       isFetchingMore.value = true;
//       final user = _authCtrl.currentUser.value;
//       if (user == null) return;

//       final isSuperAdmin = user.role.contains('super_admin') || user.role.contains('admin');

//       Query query = _firestore.collection('seven_day_forecast')
//           .orderBy('updatedAt', descending: true)
//           .startAfterDocument(_lastDocument!) 
//           .limit(_pageSize);

//       if (!isSuperAdmin) {
//         query = query.where('author.uid', isEqualTo: user.uid);
//       }

//       QuerySnapshot snapshot = await query.get();

//       if (snapshot.docs.isNotEmpty) {
//         _lastDocument = snapshot.docs.last; 
//         if (snapshot.docs.length < _pageSize) {
//           hasMore.value = false;
//         }

//         var newDocs = snapshot.docs.map((doc) {
//           var data = doc.data() as Map<String, dynamic>;
//           data['id'] = doc.id;
//           return data;
//         }).toList();

//         forecastHistory.addAll(newDocs); 
//       } else {
//         hasMore.value = false;
//       }
//     } catch (e) {
//       debugPrint("Error loading more history: $e");
//     } finally {
//       isFetchingMore.value = false;
//     }
//   }

//   // ========================================================================
//   // 3. PRE-POPULATE DATA
//   // ========================================================================
//   Future<void> createNewForecast() async {
//     startDate.value = DateTime.now();
//     _initializeEmptyGrid();

//     try {
//       QuerySnapshot lastApproved = await _firestore.collection('seven_day_forecast')
//           .where('status', isEqualTo: 'published')
//           .orderBy('updatedAt', descending: true)
//           .limit(1)
//           .get();

//       if (lastApproved.docs.isNotEmpty) {
//         var oldData = lastApproved.docs.first.data() as Map<String, dynamic>;
        
//         DateTime oldStartDate = DateTime.tryParse(oldData['startDate'] ?? '') ?? DateTime.now();
//         List<DateTime> oldDates = List.generate(7, (index) => oldStartDate.add(Duration(days: index)));
//         List<DateTime> newDates = dynamicDates;

//         Map<String, dynamic> oldGrid = oldData['forecastGrid'] ?? {};

//         for (var loc in locations) {
//           if (oldGrid.containsKey(loc)) {
//             for (int newIdx = 0; newIdx < 7; newIdx++) {
//               DateTime targetDate = newDates[newIdx];
//               int oldIdx = oldDates.indexWhere((d) => 
//                 d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day
//               );

//               if (oldIdx != -1) {
//                 forecastGrid[loc]![newIdx] = Map<String, dynamic>.from(oldGrid[loc][oldIdx]);
//               }
//             }
//           }
//         }
//         forecastGrid.refresh();
//         tableKey.value = UniqueKey();
//         Get.snackbar("Pre-populated", "Loaded overlapping data from the last approved forecast.", backgroundColor: Colors.blueAccent, colorText: Colors.white);
//       }
//     } catch (e) {
//       debugPrint("Error prepopulating: $e");
//     }

//     tabController.animateTo(1);
//   }

//   // ========================================================================
//   // 4. PUBLISH / SUBMIT
//   // ========================================================================
//   Future<void> submitForecast() async {
//     isPublishing.value = true;
    
//     try {
//       final user = _authCtrl.currentUser.value;
//       if (user == null) throw Exception("User session expired.");

//       final isSuperAdmin = user.role.contains('super_admin') || user.role.contains('admin');
//       final finalStatus = isSuperAdmin ? 'published' : 'pending_approval';

//       String formattedStart = DateFormat('dd MMM yyyy').format(startDate.value);
//       String formattedEnd = DateFormat('dd MMM yyyy').format(startDate.value.add(const Duration(days: 6)));

//       Map<String, dynamic> payload = {
//         'status': finalStatus,
//         'startDate': startDate.value.toIso8601String(),
//         'dateRange': '$formattedStart - $formattedEnd',
//         'forecastGrid': forecastGrid,
//         'updatedAt': FieldValue.serverTimestamp(),
//         'author': {
//           'uid': user.uid,
//           'name': user.name,
//           'email': user.email,
//         }
//       };

//       if (isSuperAdmin) {
//         payload['approvedAt'] = FieldValue.serverTimestamp();
//         payload['approvedBy'] = user.uid;
//       }

//       String docId = '7D_${DateFormat('yyyyMMdd').format(startDate.value)}_${user.uid.substring(0, 5)}';

//       await _firestore.collection('seven_day_forecast').doc(docId).set(payload, SetOptions(merge: true));

//       Get.snackbar(
//         isSuperAdmin ? "Published!" : "Sent for Approval", 
//         isSuperAdmin ? "7-Day Forecast successfully saved and is live." : "Forecast routed to supervisor.",
//         backgroundColor: const Color(0xFF3DD68C).withOpacity(0.95), 
//         colorText: Colors.black,
//         snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20),
//       );
      
//       await fetchForecastHistory();
//       tabController.animateTo(0);

//     } catch (e) {
//       debugPrint("Submit Error: $e");
//       Get.snackbar('Error', 'Failed to save forecast.', backgroundColor: Colors.redAccent, colorText: Colors.white);
//     } finally {
//       isPublishing.value = false;
//     }
//   }

//   // ========================================================================
//   // 5. NATIVE CSV EXPORT & IMPORT (No external packages required)
//   // ========================================================================
//   Future<void> downloadCSVTemplate() async {
//     try {
//       await Future.delayed(const Duration(milliseconds: 50));

//       StringBuffer csvBuffer = StringBuffer();
      
//       List<String> headers = ['CITY'];
//       for (int i = 1; i <= 7; i++) {
//         headers.addAll(['D${i}_COND', 'D${i}_MIN', 'D${i}_MAX', 'D${i}_PROB']);
//       }
//       csvBuffer.writeln(headers.join(','));

//       for (var loc in locations) {
//         List<String> row = [loc];
//         for (int i = 0; i < 7; i++) {
//           var cell = forecastGrid[loc]?[i];
//           row.addAll([
//             _escapeCsv(cell?['cond'] ?? ''),
//             _escapeCsv(cell?['min'] ?? ''),
//             _escapeCsv(cell?['max'] ?? ''),
//             _escapeCsv(cell?['prob'] ?? '')
//           ]);
//         }
//         csvBuffer.writeln(row.join(','));
//       }

//       final bytes = utf8.encode(csvBuffer.toString());
//       final jsArray = [Uint8List.fromList(bytes).toJS].toJS;
//       final blob = web.Blob(jsArray, web.BlobPropertyBag(type: 'text/csv'));
//       final url = web.URL.createObjectURL(blob);
      
//       final anchor = web.HTMLAnchorElement()
//         ..href = url
//         ..download = "7Day_Forecast_Template.csv";
        
//       anchor.click();
//       web.URL.revokeObjectURL(url);

//     } catch (e) {
//       debugPrint("Export Error: $e");
//       Get.snackbar("Error", "Could not generate CSV.", backgroundColor: Colors.redAccent, colorText: Colors.white);
//     }
//   }

//   String _escapeCsv(String value) {
//     if (value.contains(',') || value.contains('"') || value.contains('\n')) {
//       return '"${value.replaceAll('"', '""')}"';
//     }
//     return value;
//   }

//   Future<void> importCSVData() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom, allowedExtensions: ['csv'], withData: true, 
//     );

//     if (result != null && result.files.single.bytes != null) {
//       isImporting.value = true;
      
//       await Future.delayed(const Duration(milliseconds: 100)); 

//       try {
//         var bytes = result.files.single.bytes!;
//         final csvString = utf8.decode(bytes); 
        
//         List<String> rows = csvString.split(RegExp(r'\r\n|\r|\n'));

//         for (int i = 1; i < rows.length; i++) {
//           if (rows[i].trim().isEmpty) continue;
          
//           List<String> row = rows[i].split(',');
//           if (row.isEmpty || row[0].isEmpty) continue;

//           String cityName = row[0].replaceAll('"', '').trim().toUpperCase();
          
//           if (forecastGrid.containsKey(cityName)) {
//             for (int day = 0; day < 7; day++) {
//               int colOffset = 1 + (day * 4);
//               if (row.length > colOffset + 3) {
//                 forecastGrid[cityName]![day]['cond'] = row[colOffset].replaceAll('"', '').trim();
//                 forecastGrid[cityName]![day]['min'] = _formatCSVNumber(row[colOffset + 1]);
//                 forecastGrid[cityName]![day]['max'] = _formatCSVNumber(row[colOffset + 2]);
//                 forecastGrid[cityName]![day]['prob'] = _formatCSVNumber(row[colOffset + 3]);
//               }
//             }
//           }
//         }
        
//         forecastGrid.refresh();
//         tableKey.value = UniqueKey();
//         Get.snackbar("Success", "CSV Data Imported.", backgroundColor: const Color(0xFF3DD68C).withOpacity(0.9), colorText: Colors.black);
//       } catch (e) {
//         debugPrint("CSV Parse Error: $e");
//         Get.snackbar("Error", "Failed to parse CSV file. Ensure you used the template.", backgroundColor: Colors.redAccent, colorText: Colors.white);
//       } finally {
//         isImporting.value = false;
//       }
//     }
//   }

//   String _formatCSVNumber(dynamic rawValue) {
//     if (rawValue == null) return '';
//     String val = rawValue.toString().replaceAll('"', '').trim();
//     if (val.endsWith('.0')) return val.substring(0, val.length - 2);
//     return val;
//   }
// }