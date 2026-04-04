import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AlertNotificationController extends GetxController with GetSingleTickerProviderStateMixin {
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
  // 1. COMPOSE ALERT STATE
  // ========================================================================
  var alertTitle = "".obs;
  var alertMessage = "".obs;
  var selectedUrgency = "Information".obs;
  
  // Multi-select for audiences
  var selectedAudiences = <String>["All Users"].obs;
  final List<String> audienceOptions = [
    "All Users", "General Public", "Farmers (Agro)", "Fisherfolk (Marine)",
  ];

  // Multi-select for targeted regions (Optional)
  var selectedRegions = <String>[].obs;
  final List<String> regionOptions = [
    "Nationwide", "Greater Accra", "Ashanti", "Northern", "Western", "Volta", "Eastern"
  ];

  var isSending = false.obs;

  void toggleAudience(String audience) {
    if (audience == "All Users") {
      selectedAudiences.assignAll(["All Users"]);
    } else {
      selectedAudiences.remove("All Users");
      if (selectedAudiences.contains(audience)) {
        selectedAudiences.remove(audience);
      } else {
        selectedAudiences.add(audience);
      }
    }
    if (selectedAudiences.isEmpty) selectedAudiences.add("All Users");
  }

  void toggleRegion(String region) {
    if (region == "Nationwide") {
      selectedRegions.assignAll(["Nationwide"]);
    } else {
      selectedRegions.remove("Nationwide");
      if (selectedRegions.contains(region)) {
        selectedRegions.remove(region);
      } else {
        selectedRegions.add(region);
      }
    }
    if (selectedRegions.isEmpty) selectedRegions.add("Nationwide");
  }

  void sendPushNotification() async {
    if (alertTitle.value.trim().isEmpty || alertMessage.value.trim().isEmpty) {
      Get.snackbar("Error", "Title and Message cannot be empty.", backgroundColor: Colors.red.shade600, colorText: Colors.white);
      return;
    }

    isSending.value = true;
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call to Firebase Cloud Messaging (FCM)
    isSending.value = false;

    // Add to history optimistically
    alertHistory.insert(0, {
      "id": "ALT-${DateTime.now().millisecondsSinceEpoch}",
      "title": alertTitle.value,
      "message": alertMessage.value,
      "urgency": selectedUrgency.value,
      "audience": selectedAudiences.join(", "),
      "date": "Just now",
      "stats": {"sent": 0, "delivered": 0, "read": 0} // New alert starts at 0
    });

    Get.snackbar(
      "Alert Dispatched", "Push notifications are being sent to selected users.",
      backgroundColor: Colors.green.shade600, colorText: Colors.white,
      icon:  Icon(PhosphorIcons.bellRinging(), color: Colors.white),
      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20),
    );

    // Reset Form
    alertTitle.value = "";
    alertMessage.value = "";
    selectedUrgency.value = "Information";
    selectedAudiences.assignAll(["All Users"]);
    selectedRegions.assignAll(["Nationwide"]);
    
    // Switch to history tab to view it
    tabController.animateTo(1);
  }

  // ========================================================================
  // 2. HISTORY & ANALYTICS STATE
  // ========================================================================
  var selectedHistoryId = RxnString();

  // Mock past alerts with analytics data
  var alertHistory = <Map<String, dynamic>>[
    {
      "id": "ALT-003", "title": "Flash Flood Warning: Accra", "message": "Heavy rains expected. Avoid boundary road and low-lying areas.",
      "urgency": "Critical", "audience": "General Public, Greater Accra", "date": "20 Feb 2026, 14:30",
      "stats": {"sent": 45000, "delivered": 43200, "read": 38500}
    },
    {
      "id": "ALT-002", "title": "High Tides Alert", "message": "Rough seas expected this weekend. Small crafts should stay in port.",
      "urgency": "Warning", "audience": "Fisherfolk (Marine)", "date": "19 Feb 2026, 09:00",
      "stats": {"sent": 8500, "delivered": 8100, "read": 6200}
    },
    {
      "id": "ALT-001", "title": "Harmattan Advisory", "message": "Increased dust particles in the atmosphere. Visibility reduced.",
      "urgency": "Information", "audience": "All Users", "date": "15 Feb 2026, 06:00",
      "stats": {"sent": 124000, "delivered": 118000, "read": 95000}
    },
  ].obs;

  void selectHistoryAlert(String id) {
    selectedHistoryId.value = id;
  }
}