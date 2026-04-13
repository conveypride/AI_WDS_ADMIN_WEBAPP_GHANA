// lib/app/routes/app_pages.dart
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/bindings/cafo_binding.dart'; 
import 'package:weather_admin_dashboard/app/bindings/dashboard_binding.dart'; 
import 'package:weather_admin_dashboard/app/bindings/seasonal_forecast_binding.dart';
import 'package:weather_admin_dashboard/app/views/city_management/add_cities_view.dart';
import 'package:weather_admin_dashboard/app/views/weather_condition_management/add_weather_conditions_view.dart'; 
import 'package:weather_admin_dashboard/app/views/alert_notification_view.dart';
import 'package:weather_admin_dashboard/app/views/auth/login_view.dart';
import 'package:weather_admin_dashboard/app/views/Cafo_daily_forecast/cafo_unified_view.dart';
import 'package:weather_admin_dashboard/app/views/cafo_weekend_forecast/weekend_ibf_view.dart';
import 'package:weather_admin_dashboard/app/views/marine_forecast/coastline/coastline_forecast_view.dart';
import 'package:weather_admin_dashboard/app/views/community_hub_view.dart'; 
import 'package:weather_admin_dashboard/app/views/forecast_view.dart';
import 'package:weather_admin_dashboard/app/views/homeView.dart';
import 'package:weather_admin_dashboard/app/views/marine_forecast/inland/inland_forecast_view.dart';
import 'package:weather_admin_dashboard/app/views/layout/admin_layout.dart'; 
import 'package:weather_admin_dashboard/app/views/cafo_mid_week_forecast/mid_week_ibf_view.dart';
import 'package:weather_admin_dashboard/app/views/notifications_view.dart';
import 'package:weather_admin_dashboard/app/views/reports_view.dart';
import 'package:weather_admin_dashboard/app/views/seasonal_forecast/seasonal_forecast_view.dart';
import 'package:weather_admin_dashboard/app/views/settings_view.dart';
import 'package:weather_admin_dashboard/app/views/cafo_7_days_forecast/seven_day_forecast_view.dart';
import 'package:weather_admin_dashboard/app/views/user_management/user_management_view.dart'; 
 
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = AppRoutes.login;

  static final pages = [
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const AdminLayout(
        activeRoute: AppRoutes.dashboard, 
        title: 'Dashboard', 
        child: HomeView()
      ),
      binding: DashboardBinding(),
      transition: Transition.noTransition, 
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const AdminLayout(
        activeRoute: AppRoutes.notifications, 
        title: 'Notifications', 
        child: NotificationsView()
      ),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.forecast,
      page: () => const AdminLayout(
        activeRoute: AppRoutes.forecast, 
        title: 'Forecast Input', 
        child: ForecastView()
      ),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.cafoUnified,
      page: () => AdminLayout(
        activeRoute: AppRoutes.cafoUnified, 
        title: 'CAFO Forecast', 
        child: CAFOUnifiedView()
      ),
      binding: CAFOBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.cafo, // Redirect to Unified
      page: () => AdminLayout(
        activeRoute: AppRoutes.cafoUnified, 
        title: 'CAFO Forecast', 
        child: CAFOUnifiedView()
      ),
      binding: CAFOBinding(),
      transition: Transition.noTransition,
    ),
     GetPage(
      name: AppRoutes.sevenDayForecast,
      page: () => const AdminLayout(
        activeRoute: AppRoutes.sevenDayForecast, 
        title: '7-Day Forecast', 
        child: SevenDayForecastView()
      ),
      transition: Transition.noTransition,
    ), 
    GetPage(
      name: AppRoutes.seasonalForecast,
      page: () => const AdminLayout(
        activeRoute: AppRoutes.seasonalForecast, 
        title: 'Seasonal Forecast', 
        child: SeasonalForecastView()
      ),
      binding: SeasonalForecastBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
  name: AppRoutes.userManagement,
  page: () => const AdminLayout(
    activeRoute: AppRoutes.userManagement, 
    title: 'User Management', 
    child: UserManagementView()
  ),
  transition: Transition.noTransition,
),
GetPage(
      name: AppRoutes.midWeekIBF,
      page: () => const AdminLayout(
        activeRoute: AppRoutes.midWeekIBF, 
        title: 'Mid-Week IBF', 
        child: MidWeekIBFView()
      ),  
      binding: CAFOBinding(), 
      transition: Transition.noTransition,
    ),
GetPage(
  name: AppRoutes.weekendIBF,
  page: () => const AdminLayout(
    activeRoute: AppRoutes.weekendIBF, 
    title: 'Weekend IBF', 
    child: WeekendIBFView()
  ),
  transition: Transition.noTransition,
),
    GetPage(
  name: AppRoutes.adminCommunity,
  page: () => const AdminLayout(
    activeRoute: AppRoutes.adminCommunity, 
    title: 'Community Hub', 
    child: AdminCommunityView()
  ),
  transition: Transition.noTransition,
),
    GetPage(
      name: AppRoutes.coastlineForecast,
      page: () => const AdminLayout(
        activeRoute: AppRoutes.coastlineForecast, 
        title: 'Coastline Forecast', 
        child: CoastlineForecastView() // We will create this below
      ),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.inlandForecast,
      page: () =>   AdminLayout(
        activeRoute: AppRoutes.inlandForecast, 
        title: 'Inland Forecast', 
        child: InlandForecastView() // We will create this below
      ),
      transition: Transition.noTransition,
    ),
   GetPage(
  name: AppRoutes.alertNotification,
  page: () => const AdminLayout(
    activeRoute: AppRoutes.alertNotification, 
    title: 'Alerts', 
    child: AlertNotificationView()
  ),
  transition: Transition.noTransition,
),
    GetPage(
      name: AppRoutes.reports,
      page: () => const AdminLayout(
        activeRoute: AppRoutes.reports, 
        title: 'Reports', 
        child: ReportsView()
      ),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const AdminLayout(
        activeRoute: AppRoutes.settings, 
        title: 'Settings', 
        child: SettingsView()
      ),
      transition: Transition.noTransition,
    ),

GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      transition: Transition.fadeIn,
    ),
     GetPage(
      name: AppRoutes.addCities,
      page: () => const AdminLayout(
        activeRoute: AppRoutes.addCities, 
        title: 'Manage Cities', 
        child: AddCitiesView()
      ),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.addWeatherConditions,
      page: () => const AdminLayout(
        activeRoute: AppRoutes.addWeatherConditions, 
        title: 'Manage Weather Conditions', 
        child: AddWeatherConditionsView()
      ),
      transition: Transition.noTransition,
    )

  ];
}

// // lib/app/routes/app_pages.dart
// import 'package:get/get.dart';
// import '../views/dashboard_view.dart';
// import '../views/notifications_view.dart';
// import '../views/forecast_view.dart';
// import '../views/cafo_unified_view.dart';  // ✅ Import unified view
// import '../views/five_day_forecast_view.dart';
// import '../views/weekly_forecast_view.dart';
// import '../views/seasonal_forecast_view.dart';
// import '../views/community_hub_view.dart';
// import '../views/marine_forecast_view.dart';
// import '../views/alerts_view.dart';
// import '../views/reports_view.dart';
// import '../views/settings_view.dart';
// import '../bindings/dashboard_binding.dart';
// import '../bindings/cafo_binding.dart';
// import '../bindings/five_day_forecast_binding.dart';
// import '../bindings/weekly_forecast_binding.dart';
// import '../bindings/seasonal_forecast_binding.dart';
// import '../bindings/community_hub_binding.dart';
// import '../bindings/marine_forecast_binding.dart';
// import 'app_routes.dart';

// class AppPages {
//   AppPages._();

//   static const INITIAL = AppRoutes.dashboard;

//   static final pages = [
//     GetPage(
//       name: AppRoutes.dashboard,
//       page: () => const DashboardView(),
//       binding: DashboardBinding(),
//       transition: Transition.fadeIn,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//     GetPage(
//       name: AppRoutes.notifications,
//       page: () => const NotificationsView(),
//       transition: Transition.fadeIn,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//     GetPage(
//       name: AppRoutes.forecast,
//       page: () => const ForecastView(),
//       transition: Transition.fadeIn,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//     // ✅ UNIFIED CAFO VIEW (Primary route)
//     GetPage(
//       name: AppRoutes.cafoUnified,
//       page: () =>  CAFOUnifiedView(),
//       binding: CAFOBinding(),
//       transition: Transition.rightToLeft,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//     // ✅ Redirect old CAFO route to unified view
//     GetPage(
//       name: AppRoutes.cafo,
//       page: () =>  CAFOUnifiedView(),  // Same as unified
//       binding: CAFOBinding(),
//       transition: Transition.rightToLeft,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//     GetPage(
//       name: AppRoutes.fiveDayForecast,
//       page: () => const FiveDayForecastView(),
//       binding: FiveDayForecastBinding(),
//       transition: Transition.rightToLeft,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//     GetPage(
//       name: AppRoutes.weeklyForecast,
//       page: () => const WeeklyForecastView(),
//       binding: WeeklyForecastBinding(),
//       transition: Transition.rightToLeft,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//     GetPage(
//       name: AppRoutes.seasonalForecast,
//       page: () => const SeasonalForecastView(),
//       binding: SeasonalForecastBinding(),
//       transition: Transition.rightToLeft,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//     GetPage(
//       name: AppRoutes.communityHub,
//       page: () => const CommunityHubView(),
//       binding: CommunityHubBinding(),
//       transition: Transition.fadeIn,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//     GetPage(
//       name: AppRoutes.marineForecast,
//       page: () => const MarineForecastView(),
//       binding: MarineForecastBinding(),
//       transition: Transition.fadeIn,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//     GetPage(
//       name: AppRoutes.alerts,
//       page: () => const AlertsView(),
//       transition: Transition.fadeIn,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//     GetPage(
//       name: AppRoutes.reports,
//       page: () => const ReportsView(),
//       transition: Transition.fadeIn,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//     GetPage(
//       name: AppRoutes.settings,
//       page: () => const SettingsView(),
//       transition: Transition.fadeIn,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),
//   ];
// }