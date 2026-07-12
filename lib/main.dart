// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure google_fonts is in pubspec.yaml
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'package:weather_admin_dashboard/firebase_options.dart';
import 'app/routes/app_pages.dart';
import 'app/controllers/dashboard_controller.dart';
import 'app/controllers/notifications_controller.dart';
import 'package:firebase_core/firebase_core.dart'; // NEW IMPORT
import 'package:pdfrx/pdfrx.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ── FIREBASE INITIALIZATION MUST GO HERE ──
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Required because the PDF forecast import opens a PdfDocument directly,
  // rather than through a pdfrx widget (which would self-initialize).
  await pdfrxFlutterInitialize();
  _initializeCoreControllers();
  runApp(const MyApp());
}

void _initializeCoreControllers() {
  Get.put(AuthController(), permanent: true);
  Get.put(DashboardController(), permanent: true);
  Get.put(NotificationsController(), permanent: true);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Weather Admin Dashboard',
      debugShowCheckedModeBanner: false,
     
      
      theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,  // Auto-switch (can be controlled via Get.changeThemeMode)

      initialRoute: AppPages.INITIAL,
      getPages: AppPages.pages,
      defaultTransition: Transition.fadeIn, // Smoother for web/desktop
    );
  }
}