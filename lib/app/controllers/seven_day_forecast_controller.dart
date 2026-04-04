import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SevenDayForecastController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
  }


@override
  void onReady() {
    super.onReady();
    // onReady fires a split-second AFTER the page has fully loaded
    _initializeForecastData(); 
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  // ========================================================================
  // TAB 1: HISTORY & PAGINATION STATE
  // ========================================================================
  var currentPage = 1.obs;
  final int totalPages = 5;

  // Dummy data for the frontend
  var forecastHistory = <Map<String, dynamic>>[
    {"id": "7D-104", "dateRange": "22 Feb - 28 Feb 2026", "status": "Published", "author": "Admin User"},
    {"id": "7D-103", "dateRange": "15 Feb - 21 Feb 2026", "status": "Published", "author": "J. Mensah"},
    {"id": "7D-102", "dateRange": "08 Feb - 14 Feb 2026", "status": "Published", "author": "Admin User"},
    {"id": "7D-101", "dateRange": "01 Feb - 07 Feb 2026", "status": "Draft", "author": "E. Osei"},
    {"id": "7D-100", "dateRange": "25 Jan - 31 Jan 2026", "status": "Published", "author": "Admin User"},
  ].obs;

  void nextPage() {
    if (currentPage.value < totalPages) currentPage.value++;
  }

  void previousPage() {
    if (currentPage.value > 1) currentPage.value--;
  }

  // ========================================================================
  // TAB 2: DATA ENTRY STATE
  // ========================================================================
  var startDate = DateTime.now().obs;
  var isPublishing = false.obs;

  final List<String> locations = [
    "AFLAO", "ACCRA", "KUMASI", "TAMALE", "TAKORADI", "HO", "SUNYANI", "WA", "BOLGATANGA"
  ];

  final List<String> weatherOptions = [
    "CLEAR", "SUNNY", "P'CLOUDY", "CLOUDY", "MIST", "FOG", "HAZY", "RAIN", "T-STORM", "DRIZZLE", "SHOWERS"
  ];

  final List<String> probOptions = List.generate(100, (i) => (i + 1).toString());

  // Data Structure: forecastData[locationName][dayIndex] = { cond, prob, min, max }
  var forecastGrid = <String, List<Map<String, dynamic>>>{}.obs;

  void _initializeForecastData() {
    for (var loc in locations) {
      forecastGrid[loc] = List.generate(7, (index) => {
        "cond": "",
        "prob": "",
        "min": "",
        "max": ""
      });
    }
  }

  // Generates the 7 consecutive dates starting from the selected Start Date
  List<DateTime> get dynamicDates {
    return List.generate(7, (index) => startDate.value.add(Duration(days: index)));
  }

  void updateStartDate(DateTime date) {
    startDate.value = date;
  }

  void publishForecast() async {
    isPublishing.value = true;
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    isPublishing.value = false;
    
    Get.snackbar(
      "Published!", "7-Day Forecast successfully saved to database.",
      backgroundColor: Colors.green.shade600, colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20),
    );
    
    // Automatically switch back to history tab after publishing
    tabController.animateTo(0);
  }
}