import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';

class AdminCommunityController extends GetxController with GetSingleTickerProviderStateMixin {
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

  // ========================================================================
  // TAB 1: GROUPS MANAGEMENT (Master-Detail State)
  // ========================================================================
  var selectedGroupId = RxnString();
  var isChatLoading = false.obs;

  // Mock List of Groups
  var groups = <Map<String, dynamic>>[
    {"id": "g1", "name": "General Public (Official)", "type": "official", "subscribers": 45200, "icon": Icons.verified, "color": Colors.blue},
    {"id": "g2", "name": "Marine & Fisherfolk", "type": "marine", "subscribers": 8430, "icon": Icons.directions_boat, "color": Colors.indigo},
    {"id": "g3", "name": "Agro-Meteorology", "type": "agro", "subscribers": 12500, "icon": Icons.eco, "color": Colors.green},
    {"id": "g4", "name": "Accra Flash Floods Alert", "type": "social", "subscribers": 3200, "icon": Icons.warning, "color": Colors.orange},
  ].obs;

  // Mock Chat History for the Selected Group
  var activeChatMessages = <Map<String, dynamic>>[].obs;
  final chatTextController = TextEditingController();

  void selectGroup(String id) async {
    selectedGroupId.value = id;
    isChatLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate fetch
    
    // Load mock messages for demonstration
    activeChatMessages.value = [
      {"id": "m1", "author": "John Doe", "content": "It's raining heavily in East Legon.", "time": "10:42 AM", "upvotes": 12, "is_admin": false},
      {"id": "m2", "author": "GMet Admin", "content": "Please stay indoors and avoid the boundary road.", "time": "10:45 AM", "upvotes": 45, "is_admin": true},
      {"id": "m3", "author": "Spammer123", "content": "Buy cheap crypto here!!! link.com", "time": "10:46 AM", "upvotes": 0, "is_admin": false},
    ];
    isChatLoading.value = false;
  }

  void sendMessage() {
    if (chatTextController.text.trim().isEmpty) return;
    activeChatMessages.insert(0, {
      "id": DateTime.now().toString(),
      "author": "GMet Admin",
      "content": chatTextController.text,
      "time": "Just now",
      "upvotes": 0,
      "is_admin": true,
    });
    chatTextController.clear();
  }

  void deleteMessage(String id) {
    activeChatMessages.removeWhere((msg) => msg['id'] == id);
    Get.snackbar("Post Deleted", "The message was removed from the community.", backgroundColor: Colors.red.shade600, colorText: Colors.white);
  }

  void banUser(String authorName) {
    Get.snackbar("User Banned", "$authorName has been permanently banned from this group.", backgroundColor: Colors.orange.shade800, colorText: Colors.white);
  }

  // --- Create Group Logic ---
  void createNewGroup(String name, String type) {
    groups.insert(0, {
      "id": "g_${DateTime.now().millisecondsSinceEpoch}",
      "name": name,
      "type": type.toLowerCase(),
      "subscribers": 0,
      "icon": type == 'Official' ? Icons.verified : Icons.group,
      "color": Colors.blue,
    });
    Get.back(); // Close dialog
    Get.snackbar("Group Created", "$name is now live.", backgroundColor: Colors.green.shade600, colorText: Colors.white);
  }

   // ========================================================================
  // TAB 2: INTELLIGENCE MAP & ANALYTICS (ADVANCED)
  // ========================================================================
  final mapController = MapController();

  // Map Layers Toggles
  var showHeatmap = true.obs;
  var showReports = true.obs;
  var showLiveUsers = true.obs; // New toggle for Snapchat feel

  // Mock Citizen Reports (Glowing Pins)
  final List<Map<String, dynamic>> citizenReports = [
    {"lat": 5.6037, "lng": -0.1870, "type": "Flood", "desc": "Road flooded near airport", "time": "2 mins ago"}, 
    {"lat": 6.6666, "lng": -1.6163, "type": "Storm", "desc": "Roofs blown off by strong winds", "time": "15 mins ago"}, 
    {"lat": 9.4008, "lng": -0.8393, "type": "Drought", "desc": "Crops drying up rapidly", "time": "1 hour ago"},
    {"lat": 4.9016, "lng": -1.7831, "type": "Storm", "desc": "High waves crashing on shore", "time": "Just now"},
  ];

  // Mock Heatmap/User Density (Simulated by rendering glowing circles)
  final List<Map<String, dynamic>> userDensity = [
    {"lat": 5.6037, "lng": -0.1870, "radius": 50.0, "intensity": 0.5}, // Accra
    {"lat": 6.6666, "lng": -1.6163, "radius": 40.0, "intensity": 0.4}, // Kumasi
    {"lat": 4.8934, "lng": -1.7554, "radius": 30.0, "intensity": 0.3}, // Takoradi
    {"lat": 9.4008, "lng": -0.8393, "radius": 35.0, "intensity": 0.3}, // Tamale
  ];

  // Live Users (Snapchat style avatars on map)
  final List<Map<String, dynamic>> liveUsers = [
    {"lat": 5.65, "lng": -0.15, "name": "Kwame", "color": Colors.purple},
    {"lat": 6.70, "lng": -1.60, "name": "Ama", "color": Colors.orange},
    {"lat": 5.55, "lng": -0.20, "name": "Kojo", "color": Colors.teal},
  ];

  // --- ADVANCED ANALYTICS DATA ---
  var totalUsers = "124.5K".obs;
  var activeReporters = "1,432".obs;
  
  // Data for Line Chart (Engagement over last 7 days)
  final List<Map<String, double>> engagementTrend = [
    {"day": 1, "value": 200}, {"day": 2, "value": 450}, {"day": 3, "value": 300},
    {"day": 4, "value": 800}, {"day": 5, "value": 600}, {"day": 6, "value": 950}, {"day": 7, "value": 1200},
  ];

  // Data for Doughnut Chart (Report Distribution)
  final Map<String, double> reportDistribution = {
    "Flood": 45.0,
    "Storm/Wind": 30.0,
    "Heat/Drought": 15.0,
    "Other": 10.0,
  };
}