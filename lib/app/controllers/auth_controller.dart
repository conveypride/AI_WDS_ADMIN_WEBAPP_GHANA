import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weather_admin_dashboard/app/data/models/user_model.dart';
import 'package:weather_admin_dashboard/app/routes/app_routes.dart';

class AuthController extends GetxController {
  // Instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables
  var isLoading = false.obs;
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // Text Controllers for Login View
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    
  }

@override
  void onReady() {
    super.onReady();
    // Listen to Firebase Auth state changes here, safely AFTER the app is drawn
    _auth.authStateChanges().listen(_handleAuthChanged);
  }
 
 /// Automatically triggered when a user logs in or out
  Future<void> _handleAuthChanged(User? firebaseUser) async {
    // Slightly longer delay ensures the Flutter Web Router is fully awake
    await Future.delayed(const Duration(milliseconds: 300));

    if (firebaseUser == null) {
      currentUser.value = null;
      Get.offAllNamed(AppRoutes.login);
    } else {
      print("AUTH: Firebase user found (${firebaseUser.email}). Fetching database profile...");
      await _fetchFirestoreUser(firebaseUser.uid);
      
      if (currentUser.value != null && 
         (currentUser.value!.role.contains('admin') || currentUser.value!.role.contains('forecaster'))) {
        
        print("AUTH: Profile valid. User is ${currentUser.value!.name}");
        
        // Only route to dashboard if they are on the login page or the root '' path
        if (Get.currentRoute == AppRoutes.login || Get.currentRoute == '') {
           Get.offAllNamed(AppRoutes.dashboard);
        }
      } else {
        print("AUTH ERROR: Profile is NULL or lacks permissions! Logging out.");
        await logout();
        Get.snackbar("Access Denied", "No valid profile found in database.", 
          backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  /// Fetch user metadata from the 'users' collection
  Future<void> _fetchFirestoreUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        currentUser.value = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  /// Triggered by the Login Button
  Future<void> login() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      Get.snackbar("Error", "Please enter both email and password");
      return;
    }

    try {
      isLoading.value = true;
    final status =  await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      print("Login successful for ${status.user?.email}");
      // _handleAuthChanged will automatically catch the success and route the user
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Login Failed", e.message ?? "An error occurred during login.", 
        backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  /// Triggered by a Logout Button in the app
  Future<void> logout() async {
    await _auth.signOut();
    emailController.clear();
    passwordController.clear();
  }
}