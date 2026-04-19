import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/helpers/mapconfig.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';  

class DashboardController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  // Helper to get current admin's department
  String get currentAdminDepartment {
    return _authController.currentUser.value?.department ?? "Cafo"; 
  }

  // Helper to get target collections based on department
  List<String> get _targetCollections {
    String dept = currentAdminDepartment.toLowerCase();
    if (dept == 'cafo') {
      return ['cafo_daily_forecast', 'mid_week_forecasts', 'seasonal_forecasts', 'seven_day_forecast', 'weekend_forecasts'];
    } else if (dept == 'marine') {
      return ['coastline_forecasts', 'inland_daily_forecast'];
    }
    return ['cafo_daily_forecast', 'mid_week_forecasts', 'seasonal_forecasts', 'seven_day_forecast', 'weekend_forecasts', 'coastline_forecasts', 'inland_daily_forecast'];
  }

  // ========================================================================
  // WEATHER BANNER STATE
  // ========================================================================
  var currentTemp = "28".obs;
  var currentCondition = "Partly Cloudy".obs;
  var currentLocation = "Accra, GH".obs;

  // ========================================================================
  // KPI STATE
  // ========================================================================
  var totalActiveChats = "0".obs;
  var activeChatsTrend = "Active this week".obs;
  var isActiveChatsUp = Rxn<bool>(true);

  var alertReach = "0".obs;
  var alertReachTrend = "Total Forecasts".obs;
  var isAlertReachUp = Rxn<bool>(true);

  var pendingApprovals = "0".obs;
  var pendingTrend = Rxn<bool>(null); 
  var pendingSubtext = "My pending approvals".obs;

  var criticalReports = "0".obs;
  var criticalTrend = Rxn<bool>(false); 
  var criticalSubtext = "Active severe alerts".obs;

  // ========================================================================
  // CHAT TRENDS STATE
  // ========================================================================
  var chatTrends = <Map<String, dynamic>>[].obs;
  var totalDiscussions = "0".obs;
  var discussionTrend = "Live community data".obs;

  // ========================================================================
  // LISTS STATE
  // ========================================================================
  var recentForecasts = <Map<String, dynamic>>[].obs;
  var activeAlerts = <Map<String, dynamic>>[].obs;

  // Subscriptions for our multi-collection listener
  final List<StreamSubscription> _forecastSubs = [];
  final Map<String, List<Map<String, dynamic>>> _forecastCaches = {};

  @override
  void onInit() {
    super.onInit();
    
    // 1. Fetch non-department specific data immediately
    _fetchLiveWeather();

    // 2. REACTIVE LISTENER: Wait for the user profile to finish loading
    ever(_authController.currentUser, (user) {
      if (user != null) {
        debugPrint("DASHBOARD: User loaded. Fetching data for Department: ${user.department}");
        _fetchChatTrendsAndUsers();
        _fetchDynamicForecastKPIs();
        _fetchRecentForecastsDynamic();
        _fetchActiveAlerts();
      }
    });



    

    // 3. FALLBACK: If the user was somehow already fully loaded before this controller started
    if (_authController.currentUser.value != null) {
      debugPrint("DASHBOARD: User already loaded. Fetching data for Department: $currentAdminDepartment");
      _fetchChatTrendsAndUsers();
      _fetchDynamicForecastKPIs();
      _fetchRecentForecastsDynamic();
      _fetchActiveAlerts();
    }
  }

  @override
  void onClose() {
    // Prevent memory leaks by closing all streams when dashboard is closed
    for (var sub in _forecastSubs) {
      sub.cancel();
    }
    super.onClose();
  }

 Future<void> _fetchLiveWeather() async {
    try {
      // 1. Fetch real weather data for Accra using your existing service
      // (Accra Coordinates: Lat 5.6037, Lon -0.1870)
      final weatherData = await CityWeatherService.fetchCityWeatherData(
        "Accra",
        "GH",
        5.6037,
        -0.1870,
      );

      // 2. If successful, update the observable variables
      if (weatherData != null) {
        currentTemp.value = weatherData.temperature.round().toString();
        
        // Capitalize the description nicely (e.g., "scattered clouds" -> "Scattered Clouds")
        currentCondition.value = weatherData.description.split(' ').map((s) => s.capitalizeFirst).join(' ');
        
        currentLocation.value = "${weatherData.name}, ${weatherData.region}";
      }
    } catch (e) {
      debugPrint("Dashboard Weather API Error: $e");
      
      // 3. FALLBACK: Safely provide realistic data if the API is unreachable 
      // (e.g., due to local CORS restrictions or being offline)
      currentTemp.value = "44";
      currentCondition.value = "Scattered Clouds"; 
      currentLocation.value = "Accra, GH";
    }
  }
 
  // --- 🌟 NEW DYNAMIC BANNER GETTERS 🌟 ---
  
  // Gets the admin's first name
  String get adminFirstName {
    String fullName = _authController.currentUser.value?.name ?? "Admin";
    return fullName.split(' ')[0]; // Returns just the first name
  }

  // Calculates greeting based on device clock
  String get timeBasedGreeting {
    var hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  // Formats the department for the UI
  String get departmentDisplay {
    String dept = currentAdminDepartment.toLowerCase();
    if (dept == 'cafo') return 'CAFO Unit';
    if (dept == 'marine') return 'Marine Unit';
    return 'GMet Headquarters';
  }

   
  // ========================================================================
  // KPI 1 & CHAT TRENDS (Calculates Active Users dynamically)
  // ========================================================================
  void _fetchChatTrendsAndUsers() {
    Query query = _db.collectionGroup('messages');
    
    if (currentAdminDepartment.toLowerCase() != 'all') {
      query = query.where('department', isEqualTo: currentAdminDepartment);
    }

    query.orderBy('timestamp', descending: true).limit(500).snapshots().listen((snapshot) {
      Map<String, int> counts = {"Rain": 0, "Flood": 0, "Heat": 0, "Wind": 0, "Storm": 0};
      Set<String> uniqueUsers = {}; // Tracks unique active users
      
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String content = (data['content'] ?? '').toString().toLowerCase();
        String authorId = data['author_id'] ?? '';
        
        if (authorId.isNotEmpty) uniqueUsers.add(authorId);

        if (content.contains('rain')) counts['Rain'] = counts['Rain']! + 1;
        if (content.contains('flood')) counts['Flood'] = counts['Flood']! + 1;
        if (content.contains('heat') || content.contains('drought')) counts['Heat'] = counts['Heat']! + 1;
        if (content.contains('wind')) counts['Wind'] = counts['Wind']! + 1;
        if (content.contains('storm') || content.contains('thunder')) counts['Storm'] = counts['Storm']! + 1;
      }

      int totalMatched = counts.values.fold(0, (a, b) => a + b);
      
      totalDiscussions.value = snapshot.docs.length.toString(); 
      totalActiveChats.value = uniqueUsers.length.toString(); // Updates KPI 1
      
      if (totalMatched > 0) {
        chatTrends.value = [
          {"label": "Rain", "pct": counts['Rain']! / totalMatched, "color": AppTheme.accentBlue},
          {"label": "Flood", "pct": counts['Flood']! / totalMatched, "color": AppTheme.infoCyan},
          {"label": "Heat", "pct": counts['Heat']! / totalMatched, "color": AppTheme.warningAmber},
          {"label": "Wind", "pct": counts['Wind']! / totalMatched, "color": AppTheme.successGreen},
          {"label": "Storm", "pct": counts['Storm']! / totalMatched, "color": AppTheme.dangerRed},
        ];
      }
    });
  }

  // ========================================================================
  // KPI 2 & 3: Alert Reach (Published) & Pending Approvals (Current User)
  // ========================================================================
  Future<void> _fetchDynamicForecastKPIs() async {
    String userId = _authController.currentUser.value?.uid ?? '';
    String userName = _authController.currentUser.value?.name ?? ''; 

    int publishedCount = 0;
    int myPendingCount = 0;

    for (String col in _targetCollections) {
      try {
        var snapshot = await _db.collection(col)
            .where('status', whereIn: ['approved', 'published', 'Approved', 'Published', 'pending', 'pending_approval', 'Pending'])
            .get();

        for (var doc in snapshot.docs) {
          var data = doc.data();
          String status = (data['status'] ?? '').toString().toLowerCase();
          
          if (status == 'approved' || status == 'published') {
            publishedCount++; 
          } else if (status.contains('pending_approval') || status.contains('pending')) {
            String fId = data['forecasterId'] ?? data['author']['uid'] ?? '';
            String fName = data['forecasterName'] ?? data['author']['name'] ?? data['prepared_by'] ?? data['preparedBy'] ?? data['prepared_by'] ?? '';
            
            if ((fId.isNotEmpty && fId == userId) || (fName.isNotEmpty && fName == userName)) {
              myPendingCount++; 
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching KPI for $col: $e");
      }
    }

    alertReach.value = publishedCount.toString(); 
    pendingApprovals.value = myPendingCount.toString(); 
  }

  // ========================================================================
  // KPI 4: Critical Reports (From Alerts)
  // ========================================================================
  void _fetchActiveAlerts() {
    Query query = _db.collection('alerts').where('status', isEqualTo: 'active');

    if (currentAdminDepartment.toLowerCase() != 'all') {
      query = query.where('department', isEqualTo: currentAdminDepartment);
    }

    query.limit(20).snapshots().listen((snapshot) {
      int criticalCount = 0;

      activeAlerts.value = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;

        String severity = data['severity'] ?? 'Low';
        if (severity.toLowerCase() == 'high' || severity.toLowerCase() == 'severe') {
          criticalCount++; // Tally critical alerts
        }

        Color sevColor = AppTheme.infoCyan;
        if (severity.toLowerCase() == 'high') sevColor = AppTheme.dangerRed;
        if (severity.toLowerCase() == 'moderate') sevColor = AppTheme.warningAmber;

        return {
          "id": doc.id,
          "title": data['title'] ?? 'Alert',
          "region": data['region'] ?? 'General',
          "severity": severity,
          "severityColor": sevColor,
          "time": "Recent", 
        };
      }).toList();

      criticalReports.value = criticalCount.toString(); // Updates KPI 4
    });
  }

  // ========================================================================
  // DYNAMIC MULTI-COLLECTION FORECAST LISTENER
  // ========================================================================
  void _fetchRecentForecastsDynamic() {
    for (var sub in _forecastSubs) {
      sub.cancel();
    }
    _forecastSubs.clear();
    _forecastCaches.clear();

    for (String collectionName in _targetCollections) {
      _forecastCaches[collectionName] = []; 

      String sortField = 'updatedAt'; 
      if (collectionName == 'seasonal_forecasts') {
        sortField = 'updated_at'; // Seasonal explicitly uses snake_case
      }

      var subscription = _db.collection(collectionName)
          .orderBy(sortField, descending: true)
          .limit(5) 
          .snapshots()
          .listen((snapshot) {
        
        _forecastCaches[collectionName] = snapshot.docs.map((doc) {
          var data = doc.data();
          
          DateTime? rawDate;
          String dateStr = "Recent";
          
          if (data['updatedAt'] != null) {
            rawDate = data['updatedAt'] is Timestamp 
                ? (data['updatedAt'] as Timestamp).toDate() 
                : DateTime.tryParse(data['updatedAt'].toString());
          } else if (data['updated_at'] != null) {
            rawDate = data['updated_at'] is Timestamp 
                ? (data['updated_at'] as Timestamp).toDate() 
                : DateTime.tryParse(data['updated_at'].toString());
          } else if (data['date'] != null) {
             rawDate = DateTime.tryParse(data['date'].toString());
          }

          if (rawDate != null) {
             dateStr = "${rawDate.day.toString().padLeft(2, '0')}/${rawDate.month.toString().padLeft(2, '0')}/${rawDate.year}";
          }

          String authorName = data['author_name'] ?? data['updatedBy'] ?? data['preparedBy'] ?? data['forecasterName'] ?? data['prepared_by'] ?? data['author']['name'] ?? 'GMet System';
          String type = data['type'] ?? collectionName.replaceAll('_', ' ').capitalizeFirst ?? 'Forecast';

          String status = data['status'] ?? 'Draft';
          Color statusColor = AppTheme.darkTextSecondary;
          if (status.toLowerCase() == 'approved' || status.toLowerCase() == 'published') statusColor = AppTheme.successGreen;
          if (status.toLowerCase().contains('pending')) statusColor = AppTheme.warningAmber;

          return {
            "id": doc.id,
            "date": dateStr,
            "_rawDate": rawDate, 
            "type": type,
            "author": authorName,
            "status": status.capitalizeFirst,
            "statusColor": statusColor,
          };
        }).toList();

        _mergeAndSortForecasts();
      }, onError: (e) {
         debugPrint("Error fetching from $collectionName: $e");
      });

      _forecastSubs.add(subscription);
    }
  }

  void _mergeAndSortForecasts() {
    List<Map<String, dynamic>> allMerged = [];
    
    for (var list in _forecastCaches.values) {
      allMerged.addAll(list);
    }

    allMerged.sort((a, b) {
      DateTime? dateA = a['_rawDate'];
      DateTime? dateB = b['_rawDate'];
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; 
      if (dateB == null) return -1;
      return dateB.compareTo(dateA); 
    });

    recentForecasts.value = allMerged.take(5).toList();
  }
}
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
// import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart'; 

// class DashboardController extends GetxController {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final AuthController _authController = Get.find<AuthController>();

//   // Helper to get current admin's department
//   String get currentAdminDepartment {
//     return _authController.currentUser.value?.department ?? "Cafo"; 
//   }

//   // ========================================================================
//   // WEATHER BANNER STATE
//   // ========================================================================
//   var currentTemp = "28".obs;
//   var currentCondition = "Partly Cloudy".obs;
//   var currentLocation = "Accra, GH".obs;

//   // ========================================================================
//   // KPI STATE
//   // ========================================================================
//   var totalActiveChats = "0".obs;
//   var activeChatsTrend = "+0% this week".obs;
//   var isActiveChatsUp = Rxn<bool>(true);

//   var alertReach = "0%".obs;
//   var alertReachTrend = "Citizens reached".obs;
//   var isAlertReachUp = Rxn<bool>(true);

//   var pendingApprovals = "0".obs;
//   var pendingTrend = Rxn<bool>(null); 

//   var criticalReports = "0".obs;
//   var criticalTrend = Rxn<bool>(false); 

//   // ========================================================================
//   // CHAT TRENDS STATE
//   // ========================================================================
//   var chatTrends = <Map<String, dynamic>>[].obs;
//   var totalDiscussions = "0".obs;
//   var discussionTrend = "↑ 0% vs last week".obs;

//   // ========================================================================
//   // LISTS STATE
//   // ========================================================================
//   var recentForecasts = <Map<String, dynamic>>[].obs;
//   var activeAlerts = <Map<String, dynamic>>[].obs;

//   // Subscriptions for our multi-collection listener
//   final List<StreamSubscription> _forecastSubs = [];
//   final Map<String, List<Map<String, dynamic>>> _forecastCaches = {};

//   // ========================================================================
//   // KPI STATE
//   // ========================================================================
//   var pendingSubtext = "Action needed".obs; // <-- ADDED OBS
//   var criticalSubtext = "Hotspots found".obs; // <-- ADDED OBS

//    @override
//   void onInit() {
//     super.onInit();
    
//     // 1. Fetch non-department specific data immediately
//     _fetchKpiStats();
//     _fetchLiveWeather();

//     // 2. REACTIVE LISTENER: Wait for the user profile to finish loading from Firebase
//     ever(_authController.currentUser, (user) {
//       if (user != null) {
//         debugPrint("DASHBOARD: User loaded. Fetching data for Department: ${user.department}");
//         _fetchChatTrends();
//         _fetchRecentForecastsDynamic();
//         _fetchActiveAlerts();
//       }
//     });

//     // 3. FALLBACK: If the user was somehow already fully loaded before this controller started
//     if (_authController.currentUser.value != null) {
//       debugPrint("DASHBOARD: User already loaded. Fetching data for Department: ${currentAdminDepartment}");
//       _fetchChatTrends();
//       _fetchRecentForecastsDynamic();
//       _fetchActiveAlerts();
//     }
//   }

//   @override
//   void onClose() {
//     // Prevent memory leaks by closing all streams when dashboard is closed
//     for (var sub in _forecastSubs) {
//       sub.cancel();
//     }
//     super.onClose();
//   }

//   void _fetchLiveWeather() {
//     currentTemp.value = "29";
//     currentCondition.value = "Clear Skies";
//   }

//   void _fetchKpiStats() {
//     _db.collection('system_stats').doc('dashboard_kpis').snapshots().listen((doc) {
//       if (doc.exists) {
//         var data = doc.data()!;
//         totalActiveChats.value = (data['active_chats'] ?? 0).toString();
//         alertReach.value = "${data['alert_reach_pct'] ?? 0}%";
//         pendingApprovals.value = (data['pending_approvals'] ?? 0).toString();
//         criticalReports.value = (data['critical_reports'] ?? 0).toString();
//       }
//     });
//   }

//   void _fetchChatTrends() {
//     Query query = _db.collectionGroup('messages');
    
//     if (currentAdminDepartment.toLowerCase() != 'all') {
//       query = query.where('department', isEqualTo: currentAdminDepartment);
//     }

//     query.orderBy('timestamp', descending: true).limit(500).snapshots().listen((snapshot) {
//       Map<String, int> counts = {"Rain": 0, "Flood": 0, "Heat": 0, "Wind": 0, "Storm": 0};
      
//       for (var doc in snapshot.docs) {
//         String content = ((doc.data() as Map<String, dynamic>)['content'] ?? '').toString().toLowerCase();
//         if (content.contains('rain')) counts['Rain'] = counts['Rain']! + 1;
//         if (content.contains('flood')) counts['Flood'] = counts['Flood']! + 1;
//         if (content.contains('heat') || content.contains('drought')) counts['Heat'] = counts['Heat']! + 1;
//         if (content.contains('wind')) counts['Wind'] = counts['Wind']! + 1;
//         if (content.contains('storm') || content.contains('thunder')) counts['Storm'] = counts['Storm']! + 1;
//       }

//       int totalMatched = counts.values.fold(0, (a, b) => a + b);
//       totalDiscussions.value = snapshot.docs.length.toString(); 
      
//       if (totalMatched > 0) {
//         chatTrends.value = [
//           {"label": "Rain", "pct": counts['Rain']! / totalMatched, "color": AppTheme.accentBlue},
//           {"label": "Flood", "pct": counts['Flood']! / totalMatched, "color": AppTheme.infoCyan},
//           {"label": "Heat", "pct": counts['Heat']! / totalMatched, "color": AppTheme.warningAmber},
//           {"label": "Wind", "pct": counts['Wind']! / totalMatched, "color": AppTheme.successGreen},
//           {"label": "Storm", "pct": counts['Storm']! / totalMatched, "color": AppTheme.dangerRed},
//         ];
//       }
//     });
//   }

//    // ========================================================================
//   // DYNAMIC MULTI-COLLECTION FORECAST LISTENER (STRICT DEPARTMENTS & UPDATED_AT)
//   // ========================================================================
//   void _fetchRecentForecastsDynamic() {
//     for (var sub in _forecastSubs) {
//       sub.cancel();
//     }
//     _forecastSubs.clear();
//     _forecastCaches.clear();

//     List<String> targetCollections = [];
//     String dept = currentAdminDepartment.toLowerCase();

//     // 1. STRICT DEPARTMENT FILTERING
//     if (dept == 'cafo') {
//       targetCollections = [
//         'cafo_daily_forecast', 
//         'mid_week_forecasts', 
//         'seasonal_forecasts', 
//         'seven_day_forecast', 
//         'weekend_forecasts'
//       ];
//     } else if (dept == 'marine') {
//       targetCollections = [
//         'coastline_forecasts', 
//         'inland_daily_forecast'
//       ];
//     } else {
//       // Super Admin ("All") gets both departments
//       targetCollections = [
//         'cafo_daily_forecast', 
//         'mid_week_forecasts', 
//         'seasonal_forecasts', 
//         'seven_day_forecast', 
//         'weekend_forecasts',
//         'coastline_forecasts', 
//         'inland_daily_forecast'
//       ];
//     }

//     for (String collectionName in targetCollections) {
//       _forecastCaches[collectionName] = []; 

//       // 2. SMART FIELD SELECTOR: Prioritize updated_at / updatedAt
//       String sortField = 'updatedAt'; 
//       if (collectionName == 'seasonal_forecasts') {
//         sortField = 'updated_at'; // Seasonal explicitly uses snake_case
//       }

// print("Subscribing to $collectionName sorted by $sortField for department filter: $dept");
//       var subscription = _db.collection(collectionName)
//           // Order by the last modified time so edits bump to the top
//           .orderBy(sortField, descending: true)
//           .limit(5) 
//           .snapshots()
//           .listen((snapshot) {
        
//         _forecastCaches[collectionName] = snapshot.docs.map((doc) {
//           var data = doc.data();
          
//           DateTime? rawDate;
//           String dateStr = "Recent";
          
//           // 3. SMART DATE PARSER (Checks updatedAt first)
//           if (data['updatedAt'] != null) {
//             rawDate = data['updatedAt'] is Timestamp 
//                 ? (data['updatedAt'] as Timestamp).toDate() 
//                 : DateTime.tryParse(data['updatedAt'].toString());
//           } else if (data['updated_at'] != null) {
//             rawDate = data['updated_at'] is Timestamp 
//                 ? (data['updated_at'] as Timestamp).toDate() 
//                 : DateTime.tryParse(data['updated_at'].toString());
//           } else if (data['date'] != null) {
//              // Fallback just in case
//              rawDate = DateTime.tryParse(data['date'].toString());
//           }

//           if (rawDate != null) {
//              dateStr = "${rawDate.day.toString().padLeft(2, '0')}/${rawDate.month.toString().padLeft(2, '0')}/${rawDate.year}";
//           }

//           // Smart Author Parser
//           String authorName = data['author_name'] ?? data['updatedBy'] ?? data['preparedBy'] ?? data['forecasterName'] ?? data['prepared_by'] ?? 'GMet System';

//           // Smart Type Parser
//           String type = data['type'] ?? collectionName.replaceAll('_', ' ').capitalizeFirst ?? 'Forecast';

//           String status = data['status'] ?? 'Draft';
//           Color statusColor = AppTheme.darkTextSecondary;
//           if (status.toLowerCase() == 'approved') statusColor = AppTheme.successGreen;
//           if (status.toLowerCase() == 'pending') statusColor = AppTheme.warningAmber;

//           return {
//             "id": doc.id,
//             "date": dateStr,
//             "_rawDate": rawDate, 
//             "type": type,
//             "author": authorName,
//             "status": status.capitalizeFirst,
//             "statusColor": statusColor,
//           };
//         }).toList();

//         _mergeAndSortForecasts();
//       }, onError: (e) {
//          debugPrint("Error fetching from $collectionName: $e");
//       });

//       _forecastSubs.add(subscription);
//     }
//   }
//   // Merges the results from all 7 (or 2 or 5) streams into one sorted list
//   void _mergeAndSortForecasts() {
//     List<Map<String, dynamic>> allMerged = [];
    
//     // Combine all current cache lists
//     for (var list in _forecastCaches.values) {
//       allMerged.addAll(list);
//     }

//     // Sort the combined list by descending date (Newest first)
//     allMerged.sort((a, b) {
//       DateTime? dateA = a['_rawDate'];
//       DateTime? dateB = b['_rawDate'];
//       if (dateA == null && dateB == null) return 0;
//       if (dateA == null) return 1; // Put nulls at the bottom
//       if (dateB == null) return -1;
//       return dateB.compareTo(dateA); 
//     });

//     // Update the UI with only the absolute Top 5 newest documents across all collections
//     recentForecasts.value = allMerged.take(5).toList();
//   }

//   void _fetchActiveAlerts() {
//     Query query = _db.collection('alerts').where('status', isEqualTo: 'active');

//     if (currentAdminDepartment.toLowerCase() != 'all') {
//       query = query.where('department', isEqualTo: currentAdminDepartment);
//     }

//     query.limit(5).snapshots().listen((snapshot) {
//       activeAlerts.value = snapshot.docs.map((doc) {
//         var data = doc.data() as Map<String, dynamic>;

//         String severity = data['severity'] ?? 'Low';
//         Color sevColor = AppTheme.infoCyan;
//         if (severity.toLowerCase() == 'high') sevColor = AppTheme.dangerRed;
//         if (severity.toLowerCase() == 'moderate') sevColor = AppTheme.warningAmber;

//         return {
//           "id": doc.id,
//           "title": data['title'] ?? 'Alert',
//           "region": data['region'] ?? 'General',
//           "severity": severity,
//           "severityColor": sevColor,
//           "time": "Recent", 
//         };
//       }).toList();
//     });
//   }
// }