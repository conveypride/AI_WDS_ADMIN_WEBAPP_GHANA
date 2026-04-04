import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

class NotificationsController extends GetxController
    with GetSingleTickerProviderStateMixin {
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

  // ── INBOX STATE ──────────────────────────────────────────────────────────
  var notifications = <Map<String, dynamic>>[
    {
      "id": "1",
      "title": "Alert Dispatched Successfully",
      "message":
          "Your 'Severe Thunderstorm Warning' was successfully delivered to 45,000 users in the Greater Accra region.",
      "type": "success",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 5)),
      "isRead": false,
    },
    {
      "id": "2",
      "title": "System Update: New Radar Model",
      "message":
          "The spatial analysis server has been updated with the latest Q2 satellite data models. Existing forecasts are unaffected.",
      "type": "info",
      "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
      "isRead": false,
    },
    {
      "id": "3",
      "title": "High Server Load Detected",
      "message":
          "The CAFO database is experiencing higher than normal load. Map generation may be delayed by a few seconds.",
      "type": "warning",
      "timestamp": DateTime.now().subtract(const Duration(hours: 5)),
      "isRead": false,
    },
    {
      "id": "4",
      "title": "Weekly Report Generated",
      "message":
          "Your automated weekly forecasting performance report is ready for download.",
      "type": "info",
      "timestamp": DateTime.now().subtract(const Duration(days: 1)),
      "isRead": true,
    },
    {
      "id": "5",
      "title": "Shift Handover Log",
      "message":
          "J. Mensah has submitted the morning shift handover log. Please review before publishing the afternoon models.",
      "type": "alert",
      "timestamp": DateTime.now().subtract(const Duration(days: 2)),
      "isRead": true,
    },
  ].obs;

  List<Map<String, dynamic>> get unreadNotifications =>
      notifications.where((n) => !n['isRead']).toList();

  List<Map<String, dynamic>> get readNotifications =>
      notifications.where((n) => n['isRead']).toList();

  // ── ACTIONS ───────────────────────────────────────────────────────────────
  void markAsRead(String id) {
    final idx = notifications.indexWhere((n) => n['id'] == id);
    if (idx != -1 && !notifications[idx]['isRead']) {
      final updated = Map<String, dynamic>.from(notifications[idx]);
      updated['isRead'] = true;
      notifications[idx] = updated;
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i]['isRead']) {
        final updated = Map<String, dynamic>.from(notifications[i]);
        updated['isRead'] = true;
        notifications[i] = updated;
      }
    }
    Get.snackbar(
      'Inbox Cleared',
      'All notifications marked as read.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      backgroundColor: AppTheme.successGreen,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void deleteNotification(String id) {
    notifications.removeWhere((n) => n['id'] == id);
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class NotificationsController extends GetxController with GetSingleTickerProviderStateMixin {
//   late TabController tabController;

//   @override
//   void onInit() {
//     super.onInit();
//     tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void onClose() {
//     tabController.dispose();
//     super.onClose();
//   }

//   // ========================================================================
//   // INBOX STATE
//   // ========================================================================
  
//   // Mock received notifications for the forecaster
//   var notifications = <Map<String, dynamic>>[
//     {
//       "id": "1",
//       "title": "Alert Dispatched Successfully",
//       "message": "Your 'Severe Thunderstorm Warning' was successfully delivered to 45,000 users in the Greater Accra region.",
//       "type": "success",
//       "timestamp": DateTime.now().subtract(const Duration(minutes: 5)),
//       "isRead": false,
//     },
//     {
//       "id": "2",
//       "title": "System Update: New Radar Model",
//       "message": "The spatial analysis server has been updated with the latest Q2 satellite data models.",
//       "type": "info",
//       "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
//       "isRead": false,
//     },
//     {
//       "id": "3",
//       "title": "High Server Load Detected",
//       "message": "The CAFO database is experiencing higher than normal load. Map generation may be delayed by a few seconds.",
//       "type": "warning",
//       "timestamp": DateTime.now().subtract(const Duration(hours: 5)),
//       "isRead": false,
//     },
//     {
//       "id": "4",
//       "title": "Weekly Report Generated",
//       "message": "Your automated weekly forecasting performance report is ready for download.",
//       "type": "info",
//       "timestamp": DateTime.now().subtract(const Duration(days: 1)),
//       "isRead": true,
//     },
//     {
//       "id": "5",
//       "title": "Shift Handover Log",
//       "message": "J. Mensah has submitted the morning shift handover log. Please review before publishing the afternoon models.",
//       "type": "alert",
//       "timestamp": DateTime.now().subtract(const Duration(days: 2)),
//       "isRead": true,
//     },
//   ].obs;

//   // Computed Lists
//   List<Map<String, dynamic>> get unreadNotifications => notifications.where((n) => !n['isRead']).toList();
//   List<Map<String, dynamic>> get readNotifications => notifications.where((n) => n['isRead']).toList();

//   // --- ACTIONS ---

//   void markAsRead(String id) {
//     int index = notifications.indexWhere((n) => n['id'] == id);
//     if (index != -1 && !notifications[index]['isRead']) {
//       var updated = Map<String, dynamic>.from(notifications[index]);
//       updated['isRead'] = true;
//       notifications[index] = updated;
//     }
//   }

//   void markAllAsRead() {
//     for (int i = 0; i < notifications.length; i++) {
//       if (!notifications[i]['isRead']) {
//         var updated = Map<String, dynamic>.from(notifications[i]);
//         updated['isRead'] = true;
//         notifications[i] = updated;
//       }
//     }
//     Get.snackbar("Inbox Updated", "All notifications marked as read.", backgroundColor: Colors.black87, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20));
//   }

//   void deleteNotification(String id) {
//     notifications.removeWhere((n) => n['id'] == id);
//   }
// }