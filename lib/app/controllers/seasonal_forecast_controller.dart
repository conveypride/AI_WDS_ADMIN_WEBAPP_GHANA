// lib/app/controllers/seasonal_forecast_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SeasonalForecastController extends GetxController with GetSingleTickerProviderStateMixin {
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
  // 1. HISTORY TAB STATE
  // ========================================================================
  var currentPage = 1.obs;
  final int totalPages = 1;

  var history = <Map<String, dynamic>>[
    {"id": "SF-2026", "title": "2026 Annual Season Outlook", "status": "Published", "date": "10 Jan 2026", "author": "Admin"},
    {"id": "SF-2025", "title": "2025 Annual Season Outlook", "status": "Published", "date": "15 Jan 2025", "author": "J. Mensah"},
  ].obs;

  void nextPage() { if (currentPage.value < totalPages) currentPage.value++; }
  void previousPage() { if (currentPage.value > 1) currentPage.value--; }

  // ========================================================================
  // 2. GENERAL OUTLOOK STATE
  // ========================================================================
  var seasonTitle = "2026 Annual Rainfall Outlook".obs;
  var seasonSummary = "".obs;

  // Fixed 12 Months
  final forecastMonths = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  // ========================================================================
  // 3. ZONAL DATA & 12-MONTH BUILDER STATE
  // ========================================================================
  final List<String> sectors = ["Northern Sector", "Middle Sector", "Coastal Sector"];
  final List<String> anomalyOptions = ["Above Normal", "Normal", "Below Normal"];

  // Zonal Milestones
  var zonalData = <String, Map<String, dynamic>>{
    "Northern Sector": {"onset": "", "cessation": "", "anomaly": "Normal"},
    "Middle Sector": {"onset": "", "cessation": "", "anomaly": "Normal"},
    "Coastal Sector": {"onset": "", "cessation": "", "anomaly": "Normal"},
  }.obs;

  // 12-Month Data: monthlyData[Sector][MonthIndex 0-11] = { rain: double, isWet: bool }
  var monthlyData = <String, List<Map<String, dynamic>>>{
    "Northern Sector": List.generate(12, (i) => {"rain": "", "isWet": false}),
    "Middle Sector": List.generate(12, (i) => {"rain": "", "isWet": false}),
    "Coastal Sector": List.generate(12, (i) => {"rain": "", "isWet": false}),
  }.obs;

  void updateZonalData(String sector, String key, dynamic value) {
    zonalData[sector]![key] = value;
    zonalData.refresh(); // Triggers UI & Map update
  }

  void updateMonthlyRain(String sector, int monthIndex, String value) {
    monthlyData[sector]![monthIndex]['rain'] = value;
  }

  void toggleMonthlyWetDry(String sector, int monthIndex, bool value) {
    monthlyData[sector]![monthIndex]['isWet'] = value;
    monthlyData.refresh();
  }

  // ========================================================================
  // 4. THEMATIC MAP STATE (Auto-calculated)
  // ========================================================================
  final Map<String, List<LatLng>> sectorPolygons = {
    "Northern Sector": [const LatLng(11.1, -2.9), const LatLng(11.1, 0.0), const LatLng(8.5, 0.6), const LatLng(8.5, -2.9)],
    "Middle Sector": [const LatLng(8.5, -2.9), const LatLng(8.5, 0.6), const LatLng(6.0, 1.0), const LatLng(6.0, -3.2)],
    "Coastal Sector": [const LatLng(6.0, -3.2), const LatLng(6.0, 1.0), const LatLng(4.7, 1.0), const LatLng(4.7, -2.5)],
  };

  Color getAnomalyColor(String sector) {
    final anomaly = zonalData[sector]!['anomaly'];
    if (anomaly == "Above Normal") return Colors.green.shade600;
    if (anomaly == "Below Normal") return Colors.red.shade400;
    return Colors.yellow.shade600; // Normal
  }

  // ========================================================================
  // 5. PUBLISHING
  // ========================================================================
  var isPublishing = false.obs;

  void publishForecast() async {
    isPublishing.value = true;
    await Future.delayed(const Duration(seconds: 2)); 
    isPublishing.value = false;
    
    Get.snackbar(
      "Published!", "Annual Seasonal Forecast successfully pushed to database.",
      backgroundColor: Colors.green.shade600, colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(20),
      icon:  Icon(PhosphorIcons.checkCircle(), color: Colors.white),
    );
    tabController.animateTo(0);
  }
}