import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart'; // Ensure this path is correct

class WeatherConditionsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController conditionController = TextEditingController();
  
  // Changed to List<String> to match SettingsModel
  final RxList<String> conditions = <String>[].obs;

  String get _userDepartment {
    try {
      final auth = Get.find<AuthController>();
      return auth.currentUser.value?.department ?? 'All'; 
    } catch (e) {
      return 'All'; // Fallback
    }
  }

  // Target the specific settings document for this department
  DocumentReference get _settingsDoc => 
      _firestore.collection('settings').doc('${_userDepartment}_settings');

  @override
  void onInit() {
    super.onInit();
    _fetchConditions();
  }

  void _fetchConditions() {
    _settingsDoc.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        conditions.value = List<String>.from(data['weatherConditions'] ?? []);
      } else {
        conditions.value = [];
      }
    });
  }

  Future<void> addCondition() async {
    final newCondition = conditionController.text.trim();
    if (newCondition.isEmpty) {
      Get.snackbar(
        'Required', 'Please enter a weather condition', 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

// 2. CHECK FOR DUPLICATES (Case-insensitive)
    bool alreadyExists = conditions.any((item) => 
      item.toLowerCase() == newCondition.toLowerCase()
    );

    if (alreadyExists) {
      Get.snackbar(
        'Duplicate', 'This weather condition already exists.', 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent.withOpacity(0.9), // Orange for warnings
        colorText: Colors.white,
        icon: const Icon(Icons.warning, color: Colors.white),
      );
      return; // Stop execution here
    }

    // 3. Add to Firestore if validation passes
    try {
      // arrayUnion adds the string to the list only if it doesn't already exist
      // SetOptions(merge: true) creates the document if it doesn't exist yet
      await _settingsDoc.set({
        'weatherConditions': FieldValue.arrayUnion([newCondition.toUpperCase()])
      }, SetOptions(merge: true));
      
      conditionController.clear();
      Get.snackbar(
        'Success', 'Weather condition added to $_userDepartment',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to add condition: $e');
    }
  }

  Future<void> deleteCondition(String condition) async {
    try {
      // arrayRemove deletes the specific string from the list
      await _settingsDoc.update({
        'weatherConditions': FieldValue.arrayRemove([condition])
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete condition: $e');
    }
  }
}