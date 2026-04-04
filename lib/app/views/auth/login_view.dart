import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart'; // IMPORTANT: Import the controller
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 1. Find the AuthController we initialized in main.dart
    final authCtrl = Get.find<AuthController>(); 
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(PhosphorIcons.cloudSun(PhosphorIconsStyle.fill), size: 60, color: AppTheme.accentBlue),
                const SizedBox(height: 24),
                Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  "Login to access the forecasting dashboard",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                
                // Email Field
                TextFormField(
                  controller: authCtrl.emailController, // 2. Connect Email Controller
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: Icon(PhosphorIcons.envelopeSimple()),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: authCtrl.passwordController, // 3. Connect Password Controller
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(PhosphorIcons.lockKey()),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Login Button (Wrapped in Obx to show loading state)
                Obx(() => ElevatedButton(
                  onPressed: authCtrl.isLoading.value 
                      ? null // Disable button while loading
                      : () {
                          authCtrl.login(); // 4. Trigger the login function!
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: authCtrl.isLoading.value 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                )),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}