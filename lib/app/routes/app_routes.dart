abstract class AppRoutes {
  AppRoutes._();
  static const String login = '/login';       // NEW 
  static const String dashboard = '/dashboard';
  static const String notifications = '/notifications';
  static const String forecast = '/forecast';
  static const String cafo = '/cafo';
  static const String cafoUnified = '/cafo-unified';  // ✅ MUST HAVE THIS 
  static const String sevenDayForecast = '/seven-day-forecast';
  static const String weeklyForecast = '/weekly-forecast';
  static const String seasonalForecast = '/seasonal-forecast'; 
  static const String adminCommunity = '/admin-community';
  static const String coastlineForecast = '/coastline-forecast';
  static const String inlandForecast = '/inland-forecast';

  static const String alertNotification = '/alert-notification';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String userManagement = '/user-management';
  static const String midWeekIBF = '/mid-week-ibf';
  static const String weekendIBF = '/weekend-ibf';
  // NEW ROUTES
  static const String addCities = '/add-cities';
  static const String addWeatherConditions = '/add-weather-conditions';

  static List<String> get all => [
        login, 
        dashboard,
        notifications,
        forecast,
        cafo,
        cafoUnified,   
        sevenDayForecast,
        weeklyForecast,
        seasonalForecast,
        adminCommunity,
        coastlineForecast,
        inlandForecast,
        alertNotification,
        reports,
        settings,
        userManagement,
        midWeekIBF,
        weekendIBF,
        addCities,
        addWeatherConditions,
      ];
}