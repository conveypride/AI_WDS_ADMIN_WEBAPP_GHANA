import 'package:get/get.dart';

class DashboardController extends GetxController {
  // KPI State (Used in the HomeView Dashboard)
  var totalActiveChats = 1240.obs;
  var alertReach = "85%".obs;
  var criticalReports = 12.obs;
  var pendingApprovals = 3.obs; 
}