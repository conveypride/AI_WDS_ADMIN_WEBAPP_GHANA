import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart'; // Ensure this path is correct

class CitiesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController cityController = TextEditingController();
  
  // Changed to List<String> to match SettingsModel
  final RxList<String> cities = <String>[].obs;
  
  String get _userDepartment {
    try {
      final auth = Get.find<AuthController>();
      return auth.currentUser.value?.department ?? 'All'; 
    } catch (e) {
      return 'All'; // Fallback if auth is not fully initialized
    }
  }

  // Target the specific settings document for this department
   DocumentReference get _settingsDoc => 
      _firestore.collection('settings').doc('${_userDepartment}_settings');
      
  @override
  void onInit() {
    super.onInit();
    _fetchCities();
  }

  void _fetchCities() {
    _settingsDoc.snapshots().listen((snapshot) {
      print('Listening to cities for $_userDepartment department...');
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        print('Fetched cities for $_userDepartment: ${data['cities']}');
        cities.value = List<String>.from(data['cities'] ?? []);
      } else {
        cities.value = [];
      }
    });
  }

  Future<void> addCity() async {
    final newCity = cityController.text.trim();
    if (newCity.isEmpty) {
      Get.snackbar(
        'Required', 'Please enter a city name',
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
// 2. CHECK FOR DUPLICATES (Case-insensitive)
    bool alreadyExists = cities.any((item) => 
      item.toLowerCase() == newCity.toLowerCase()
    );

    if (alreadyExists) {
      Get.snackbar(
        'Duplicate', 'This city already exists in your department.', 
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
      await _settingsDoc.set({
        'cities': FieldValue.arrayUnion([newCity.toUpperCase()])
      }, SetOptions(merge: true));
      
      cityController.clear();
      Get.snackbar(
        'Success', 'City added to $_userDepartment department',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to add city: $e');
    }
  }

  Future<void> deleteCity(String city) async {
    try {
      // arrayRemove deletes the specific string from the list
      await _settingsDoc.update({
        'cities': FieldValue.arrayRemove([city])
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete city: $e');
    }
  }
}