// // lib/app/views/dashboard_view.dart

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:weather_admin_dashboard/app/views/cafo_unified_view.dart';
// import 'package:weather_admin_dashboard/app/views/five_day_forecast_view.dart';
// import 'package:weather_admin_dashboard/app/views/seasonal_forecast_view.dart';
// import 'package:weather_admin_dashboard/app/views/weekly_forecast_view.dart';
// import '../controllers/dashboard_controller.dart';
// import '../theme/app_theme.dart';
// import '../routes/app_routes.dart'; // Ensure routes are imported

// // VIEWS
// import 'notifications_view.dart';
// import 'forecast_view.dart';
// import 'community_hub_view.dart';
// import 'alerts_view.dart';
// import 'reports_view.dart';
// import 'marine_forecast_view.dart';
// import 'settings_view.dart';
// import 'homeView.dart';

// class DashboardView extends GetView<DashboardController> {
//   const DashboardView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         // Breakpoints: Mobile < 800, Tablet < 1200, Desktop >= 1200
//         final isMobile = constraints.maxWidth < 800;
//         final isTablet = constraints.maxWidth >= 800 && constraints.maxWidth < 1200;

//         return Scaffold(
//           // Mobile gets a drawer, Desktop/Tablet get sidebar
//           drawer: isMobile ? Drawer(child: _buildSidebarContent(context, isCompact: false)) : null,
//           appBar: isMobile
//               ? AppBar(
//                   title: const Text("Weather Admin"),
//                   leading: Builder(
//                     builder: (context) => IconButton(
//                       icon: Icon(PhosphorIcons.list()),
//                       onPressed: () => Scaffold.of(context).openDrawer(),
//                     ),
//                   ),
//                 )
//               : null,
//           body: Row(
//             children: [
//               // --- SIDEBAR (Hidden on Mobile) ---
//               if (!isMobile)
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   width: isTablet ? 80 : 280, // Slim sidebar for Tablet
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).cardColor,
//                     border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
//                   ),
//                   child: _buildSidebarContent(context, isCompact: isTablet),
//                 ),

//               // --- MAIN CONTENT ---
//               Expanded(
//                 child: Column(
//                   children: [
//                     if (!isMobile) _buildTopBar(context), // Mobile has standard AppBar
//                     Expanded(
//                       child: Obx(() => Container(
//                         // Add subtle background pattern or gradient here if desired
//                         color: Theme.of(context).scaffoldBackgroundColor,
//                         child: _getSelectedView(),
//                       )),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // --- SIDEBAR ---
//   Widget _buildSidebarContent(BuildContext context, {required bool isCompact}) {
//     return Column(
//       children: [
//         // Logo Section
//         Container(
//           height: 80,
//           alignment: Alignment.center,
//           padding: const EdgeInsets.all(16),
//           child: isCompact
//               ? Icon(PhosphorIcons.cloudSun(PhosphorIconsStyle.fill), size: 32, color: Theme.of(context).primaryColor)
//               : Row(
//                   children: [
//                     Icon(PhosphorIcons.cloudSun(PhosphorIconsStyle.fill), size: 32, color: Theme.of(context).primaryColor),
//                     const SizedBox(width: 12),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text("WeatherAdmin", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
//                         Text("Meteorology Unit", style: Theme.of(context).textTheme.bodySmall),
//                       ],
//                     ),
//                   ],
//                 ),
//         ),
        
//         if (!isCompact) const Divider(height: 1),

//         // Menu Items
//         Expanded(
//           child: ListView(
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             children: [
//               _buildNavItem(context, icon: PhosphorIcons.house(), label: 'Home', index: 0, isCompact: isCompact),
//               _buildNavItem(context, icon: PhosphorIcons.bell(), label: 'Notifications', index: 1, badge: '3', isCompact: isCompact),
              
//               if (!isCompact) _buildSectionHeader(context, "FORECASTING"),
              
//               // UPDATED: Now uses the Dropdown Logic
//               _buildNavItemWithDropdown(
//                 context: context, 
//                 icon: PhosphorIcons.fileText(), 
//                 label: 'CAFO Forecast', 
//                 index: 7, 
//                 isCompact: isCompact
//               ),

//               _buildNavItem(context, icon: PhosphorIcons.waves(), label: 'Marine Forecast', index: 8, isCompact: isCompact),
//               // _buildNavItem(context, icon: PhosphorIcons.cloudSun(), label: 'Forecast Input', index: 2, isCompact: isCompact),
              
//               if (!isCompact) _buildSectionHeader(context, "COMMUNITY"),
//               _buildNavItem(context, icon: PhosphorIcons.users(), label: 'Community Hub', index: 3, isCompact: isCompact),
//               _buildNavItem(context, icon: PhosphorIcons.warning(), label: 'Weather Alerts', index: 4, badge: '5', isCompact: isCompact),
//               _buildNavItem(context, icon: PhosphorIcons.chartBar(), label: 'Reports', index: 5, isCompact: isCompact),
              
//               const Divider(height: 32),
//               _buildNavItem(context, icon: PhosphorIcons.gear(), label: 'Settings', index: 6, isCompact: isCompact),
//             ],
//           ),
//         ),

//         // User Profile (Bottom)
//         if (!isCompact)
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
//             child: Row(
//               children: [
//                 CircleAvatar(backgroundColor: Theme.of(context).primaryColor, child: const Text("AF", style: TextStyle(color: Colors.white))),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text("Admin User", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
//                       Text("admin@meteo.gov", style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
//                     ],
//                   ),
//                 ),
//                 IconButton(icon: Icon(PhosphorIcons.signOut()), onPressed: () {}),
//               ],
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildSectionHeader(BuildContext context, String title) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
//       child: Text(
//         title,
//         style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 1.2, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   // --- STANDARD NAV ITEM ---
//   Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required int index, String? badge, required bool isCompact}) {
//     return Obx(() {
//       final isSelected = controller.selectedIndex.value == index;
//       final color = isSelected ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color;
//       final bgColor = isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent;

//       if (isCompact) {
//         return Tooltip(
//           message: label,
//           child: Container(
//             margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//             decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
//             child: IconButton(
//               icon: Icon(icon, color: color),
//               onPressed: () => controller.changeView(index),
//             ),
//           ),
//         );
//       }

//       return Container(
//         margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
//         decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
//         child: ListTile(
//           onTap: () => controller.changeView(index),
//           leading: Icon(icon, color: color, size: 22),
//           title: Text(label, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
//           trailing: badge != null
//               ? Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(color: AppTheme.dangerColor, borderRadius: BorderRadius.circular(10)),
//                   child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
//                 )
//               : null,
//           dense: true,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//       );
//     });
//   }

//   // --- DROPDOWN NAV ITEM (NEW) ---
//   Widget _buildNavItemWithDropdown({
//     required IconData icon,
//     required String label,
//     required int index,
//     required BuildContext context,
//     required bool isCompact, // Added to handle tablet mode gracefully
//     String? badge,
//   }) {
//     return Obx(() {
//       final isSelected = controller.selectedIndex.value == index;
//       final color = isSelected ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color;
//       final bgColor = isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent;
      
//       // Compact Mode (Tablet) - Show Icon Only, triggers menu on tap
//       if (isCompact) {
//         return Tooltip(
//           message: label,
//           child: Container(
//             margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//             decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
//             child: Builder(
//               builder: (buttonContext) {
//                 return IconButton(
//                   icon: Icon(icon, color: color),
//                   onPressed: () => _showCAFODropdown(buttonContext),
//                 );
//               }
//             ),
//           ),
//         );
//       }

//       // Full Mode (Desktop)
//       return Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         child: Material(
//           color: Colors.transparent,
//           child: Builder(
//             builder: (BuildContext buttonContext) {
//               return InkWell(
//                 onTap: () => _showCAFODropdown(buttonContext),
//                 borderRadius: BorderRadius.circular(12),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   margin: const EdgeInsets.symmetric(horizontal: 12),
//                   decoration: BoxDecoration(
//                     color: bgColor,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         icon,
//                         size: 20,
//                         color: color,
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           label,
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                             color: color,
//                           ),
//                         ),
//                       ),
//                       Icon(
//                         PhosphorIcons.caretDown(),
//                         size: 16,
//                         color: color,
//                       ),
//                       if (badge != null)
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: AppTheme.dangerColor,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Text(
//                             badge,
//                             style: const TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             }
//           ),
//         ),
//       );
//     });
//   }

//  void _showCAFODropdown(BuildContext context) {
//     final RenderBox button = context.findRenderObject() as RenderBox;
//     final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
//     final RelativeRect position = RelativeRect.fromRect(
//       Rect.fromPoints(
//         button.localToGlobal(Offset.zero, ancestor: overlay),
//         button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
//       ),
//       Offset.zero & overlay.size,
//     );

//     showMenu<String>(
//       context: context,
//       position: position,
//       elevation: 8,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       color: Theme.of(context).cardColor,
//       items: [
//         PopupMenuItem<String>(
//           value: 'daily',
//           child: _buildDropdownItem(PhosphorIcons.calendar(), 'Daily Forecast (24H)'),
//         ),
//         PopupMenuItem<String>(
//           value: '5day',
//           child: _buildDropdownItem(PhosphorIcons.calendarCheck(), '5-Day Forecast'),
//         ),
//         PopupMenuItem<String>(
//           value: 'weekly',
//           child: _buildDropdownItem(PhosphorIcons.chartLine(), 'Weekly Forecast'),
//         ),
//         PopupMenuItem<String>(
//           value: 'seasonal',
//           child: _buildDropdownItem(PhosphorIcons.sun(), 'Seasonal Forecast'),
//         ),
//       ],
//     ).then((value) {
//       if (value != null) {
//         // FIX: Use changeView to stay inside the Dashboard layout
//         switch (value) {
//           case 'daily':
//             controller.changeView(7); // Index 7 = CAFO Unified View
//             break;
//           case '5day':
//             controller.changeView(9); // Index 9 = 5-Day View
//             case 'weekly': 
//             controller.changeView(10);
//             case 'seasonal':
//            controller.changeView(11);

//             break;
//           // Add other cases if you have views for them
//         }
//       }
//     });
//   }

//   // --- TOP BAR (Desktop/Tablet) ---
//   Widget _buildTopBar(BuildContext context) {
//     return Container(
//       height: 70,
//       padding: const EdgeInsets.symmetric(horizontal: 32),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
//       ),
//       child: Row(
//         children: [
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Obx(() => Text(_getViewTitle(), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
//               Text(DateFormat('EEEE, d MMMM y').format(DateTime.now()), style: Theme.of(context).textTheme.bodySmall),
//             ],
//           ),
//           const Spacer(),
//           // Actions
//           IconButton(icon: Icon(PhosphorIcons.magnifyingGlass()), onPressed: () {}),
//           const SizedBox(width: 8),
//           IconButton(
//             icon: Icon(Get.isDarkMode ? PhosphorIcons.sun() : PhosphorIcons.moon()),
//             onPressed: () => Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark),
//           ),
//           const SizedBox(width: 8),
//           IconButton(icon: Icon(PhosphorIcons.bell()), onPressed: () => controller.changeView(1)),
//         ],
//       ),
//     );
//   }

//   // --- HELPER METHODS ---
//   // Helper widget for dropdown items
//   Widget _buildDropdownItem(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: Colors.blue),
//         const SizedBox(width: 12),
//         Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
//       ],
//     );
//   }
 

//   Widget _getSelectedView() {
//     switch (controller.selectedIndex.value) {
//       case 0: return const HomeView();
//       case 1: return const NotificationsView();
//       case 2: return const ForecastView();
//       case 3: return const CommunityHubView();
//       case 4: return const AlertsView();
//       case 5: return const ReportsView();
//       case 6: return const SettingsView();
      
//       case 7: return  CAFOUnifiedView(); 
      
//       case 8: return const MarineForecastView();
//       case 9: return const FiveDayForecastView();
//       case 10: return const WeeklyForecastView();
//       case 11: return const SeasonalForecastView();
//       default: return const HomeView();
//     }
//   }

//   String _getViewTitle() {
//     switch (controller.selectedIndex.value) {
//       case 0:
//         return 'Dashboard';
//       case 1:
//         return 'Notifications';
//       case 2:
//         return 'Forecast Input';
//       case 3:
//         return 'Community Hub';
//       case 4:
//         return 'Weather Alerts';
//       case 5:
//         return 'Reports';
//       case 6:
//         return 'Settings';
//       case 7:
//         return 'CAFO Forecast';
//       case 8:
//         return 'Marine Forecast';
//       default:
//         return 'Dashboard';
//     }
//   }
// }