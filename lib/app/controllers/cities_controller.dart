import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';

class CitiesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController cityController = TextEditingController();
  
  final RxList<String> cities = <String>[].obs;
  final RxBool isLoading = false.obs;
  
  String? _currentDepartment;
  
  String get _userDepartment {
    try {
      final auth = Get.find<AuthController>();
      final department = auth.currentUser.value?.department ?? 'All';
      print('AUTH: Current department retrieved: $department');
      return department;
    } catch (e) {
      print('AUTH ERROR: Could not get department - $e');
      return 'All';
    }
  }

  DocumentReference get _settingsDoc => 
      _firestore.collection('settings').doc('${_userDepartment}_settings');
      
  @override
  void onInit() {
    super.onInit();
    // Wait for next frame to ensure AuthController is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCities();
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Listen for changes in the user's department
    ever(Get.find<AuthController>().currentUser, (_) {
      print('AUTH: Detected change in currentUser - reinitializing cities');
      _initializeCities();
    });
  }

  void _initializeCities() {
    final department = _userDepartment;
    
    // Only set up listener if department changed or first time
    if (_currentDepartment != department) {
      _currentDepartment = department;
      print('CITIES: Initializing for department: $department');
      _fetchCities();
    }
  }

  void _fetchCities() {
    isLoading.value = true;
    
    final docPath = '${_currentDepartment}_settings';
    print('CITIES: Listening to document: $docPath');
    
    _firestore
        .collection('settings')
        .doc(docPath)
        .snapshots()
        .listen(
          (snapshot) {
            isLoading.value = false;
            
            if (snapshot.exists) {
              final data = snapshot.data() as Map<String, dynamic>;
              final citiesList = data['cities'];
              
              print('CITIES: Snapshot exists - cities data: $citiesList');
              
              if (citiesList != null) {
                cities.value = List<String>.from(citiesList);
                print('CITIES: Updated cities list: ${cities.length} cities');
              } else {
                cities.value = [];
                print('CITIES: No cities array in document');
              }
            } else {
              cities.value = [];
              print('CITIES: Document does not exist: $docPath');
            }
          },
          onError: (error) {
            isLoading.value = false;
            print('CITIES ERROR: Failed to listen to Firestore - $error');
            Get.snackbar(
              'Error',
              'Failed to load cities: $error',
              backgroundColor: Colors.red.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        );
  }

  Future<void> addCity() async {
    final newCity = cityController.text.trim();
    
    if (newCity.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter a city name',
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      return;
    }

    // Check for duplicates (case-insensitive)
    bool alreadyExists = cities.any(
      (item) => item.toLowerCase() == newCity.toLowerCase()
    );

    if (alreadyExists) {
      Get.snackbar(
        'Duplicate',
        'This city already exists in your department.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent.withOpacity(0.9),
        colorText: Colors.white,
        icon: const Icon(Icons.warning, color: Colors.white),
      );
      return;
    }

    // Add to Firestore
    try {
      final cityToAdd = newCity.toUpperCase();
      print('CITIES: Adding city: $cityToAdd to ${_currentDepartment}_settings');
      
      await _settingsDoc.set({
        'cities': FieldValue.arrayUnion([cityToAdd])
      }, SetOptions(merge: true));
      
      cityController.clear();
      
      Get.snackbar(
        'Success',
        'City added to $_currentDepartment department',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
      
      print('CITIES: Successfully added $cityToAdd');
    } catch (e) {
      print('CITIES ERROR: Failed to add city - $e');
      Get.snackbar(
        'Error',
        'Failed to add city: $e',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteCity(String city) async {
    try {
      print('CITIES: Deleting city: $city from ${_currentDepartment}_settings');
      
      await _settingsDoc.update({
        'cities': FieldValue.arrayRemove([city])
      });
      
      Get.snackbar(
        'Success',
        'City removed successfully',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
      
      print('CITIES: Successfully deleted $city');
    } catch (e) {
      print('CITIES ERROR: Failed to delete city - $e');
      Get.snackbar(
        'Error',
        'Failed to delete city: $e',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    cityController.dispose();
    super.onClose();
  }
}