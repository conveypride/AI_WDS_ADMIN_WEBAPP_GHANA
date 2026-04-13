import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';
import 'package:weather_admin_dashboard/app/data/models/user_model.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'dart:math';

class UserManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authCtrl = Get.find<AuthController>();

  // ── State Variables ────────────────────────────────────────────────────────
  var isLoading = true.obs;
  var isSaving = false.obs;

  // Real Data Lists
  var allUsers = <UserModel>[].obs;
  var filteredUsers = <UserModel>[].obs;

  // Filters
  final searchQuery = ''.obs;
  final selectedRole = 'All Roles'.obs;
  final selectedStatus = 'All Status'.obs;

  // Dynamic filter options based on fetched data
  final roles = <String>['All Roles'].obs;
  final statuses = <String>['All Status', 'Active', 'Pending', 'Suspended'].obs;

  // Real-time Metrics
  final totalUsers = 0.obs;
  final activeAdmins = 0.obs;
  final pendingApprovals = 0.obs;
  final suspendedAccounts = 0.obs;

  // ── Security Getter ───────────────────────────────────────────────────────
  bool get isSuperAdmin {
    final user = _authCtrl.currentUser.value;
    if (user == null) return false;
    // Strict check: User must have 'super_admin' in their role string
    return user.role.toLowerCase().contains('super_admin');
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _fetchUsersForDepartment();
    
    // Automatically re-apply filters whenever search or dropdowns change
    everAll([searchQuery, selectedRole, selectedStatus], (_) => _applyFilters());
  }

  // ── Database Reads ────────────────────────────────────────────────────────
  Future<void> _fetchUsersForDepartment() async {
    try {
      isLoading.value = true;
      final currentUser = _authCtrl.currentUser.value;
      
      if (currentUser == null) {
        Get.snackbar('Error', 'Authentication error. Please log in again.');
        return;
      }

      Query query = _firestore.collection('users');

      // Restrict query to the Admin's department, unless they are the master "All" admin
      if (currentUser.department.toLowerCase() != 'all') {
        print('Fetching users for department: ${currentUser.department}');
        query = query.where('department', isEqualTo: currentUser.department);
      }

      final snapshot = await query.get();
      
      allUsers.value = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
          
      // Extract unique roles from the database to populate the dropdown
      final uniqueRoles = allUsers.map((u) => u.role).toSet().toList();
      roles.value = ['All Roles', ...uniqueRoles];

      _calculateMetrics();
      _applyFilters();
    } catch (e) {
      Get.snackbar('Database Error', 'Failed to load users: $e', 
          backgroundColor: AppTheme.dangerRed, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Logic & Filtering ─────────────────────────────────────────────────────
  void _applyFilters() {
    var result = allUsers.toList();

    // 1. Search Query (matches name or email)
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result.where((u) => 
        u.name.toLowerCase().contains(q) || 
        u.email.toLowerCase().contains(q)
      ).toList();
    }

    // 2. Role Filter
    if (selectedRole.value != 'All Roles') {
      result = result.where((u) => u.role == selectedRole.value).toList();
    }

    // Update the UI list
    filteredUsers.value = result;
  }

  void _calculateMetrics() {
    totalUsers.value = allUsers.length;
    activeAdmins.value = allUsers.where((u) => u.role.contains('admin')).length;
    
    // Defaulting to 0 since UserModel does not strictly track these states yet
    pendingApprovals.value = 0; 
    suspendedAccounts.value = 0;
  }

  // ── UI Triggers ───────────────────────────────────────────────────────────
  void updateSearch(String query) => searchQuery.value = query;
  void updateRole(String role) => selectedRole.value = role;
  void updateStatus(String status) => selectedStatus.value = status;

  // ── Database Writes (Delete) ──────────────────────────────────────────────
  void deleteUser(UserModel user) {
    if (!isSuperAdmin) {
      Get.snackbar('Access Denied', 'Only Super Admins can delete users.', 
          backgroundColor: AppTheme.dangerRed, colorText: Colors.white);
      return;
    }

    Get.defaultDialog(
      title: 'Delete User',
      titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      middleText: 'Are you sure you want to completely remove ${user.name}? This action cannot be undone.',
      textConfirm: 'Delete Permanently',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      cancelTextColor: AppTheme.dangerRed,
      buttonColor: AppTheme.dangerRed,
      radius: 12,
      onConfirm: () async {
        try {
          Get.back(); // Close dialog immediately
          isLoading.value = true;
          
          // Delete from Firestore
          await _firestore.collection('users').doc(user.uid).delete();
          
          // Remove locally to avoid a full database refetch
          allUsers.removeWhere((u) => u.uid == user.uid);
          _calculateMetrics();
          _applyFilters();
          
          Get.snackbar('Success', '${user.name} has been removed.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: AppTheme.successGreen.withOpacity(0.9),
              colorText: Colors.white);
        } catch (e) {
          Get.snackbar('Error', 'Failed to delete user: $e', 
              backgroundColor: AppTheme.dangerRed, colorText: Colors.white);
        } finally {
          isLoading.value = false;
        }
      },
    );
  }

 
  // ── Database Writes (Add User Modal) ──────────────────────────────────────
  void openAddUserModal() {
    if (!isSuperAdmin) {
      Get.snackbar('Access Denied', 'Only Super Admins can create new users.', 
          backgroundColor: AppTheme.dangerRed, colorText: Colors.white);
      return;
    }

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    // Auto-assign department based on current admin's department
    String newDepartment = _authCtrl.currentUser.value?.department ?? 'Unknown';
    if (newDepartment == 'All') newDepartment = 'Cafo'; // Default fallback if global admin
    
    String selectedNewRole = '${newDepartment.toLowerCase()}_forecaster';

    // Helper function to generate a secure random password
    void generateRandomPassword() {
      const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$%^&*';
      Random rnd = Random();
      String pass = String.fromCharCodes(Iterable.generate(
          12, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
      passwordController.text = pass;
    }

    Get.defaultDialog(
      title: 'Add New Staff',
      titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
      radius: 12,
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Password Field with Auto-Generate Button
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: Tooltip(
                  message: 'Generate Random Password',
                  child: IconButton(
                    icon: const Icon(Icons.autorenew),
                    onPressed: generateRandomPassword,
                    color: AppTheme.accentBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedNewRole,
              decoration: const InputDecoration(
                labelText: 'Assign Role',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: '${newDepartment.toLowerCase()}_forecaster', child: const Text('Forecaster')),
                DropdownMenuItem(value: '${newDepartment.toLowerCase()}_admin', child: const Text('Admin')),
                DropdownMenuItem(value: '${newDepartment.toLowerCase()}_super_admin', child: const Text('Super Admin')),
              ],
              onChanged: (val) {
                if (val != null) selectedNewRole = val;
              },
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Text(
                'Department assigned: $newDepartment',
                style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
      textConfirm: 'Create User',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.accentBlue,
      onConfirm: () async {
        final email = emailController.text.trim();
        final password = passwordController.text.trim();
        final name = nameController.text.trim();

        if (name.isEmpty || email.isEmpty || password.isEmpty) {
          Get.snackbar('Missing Info', 'Name, Email, and Password are required.');
          return;
        }
        if (password.length < 6) {
          Get.snackbar('Weak Password', 'Password must be at least 6 characters long.');
          return;
        }

        try {
          Get.back(); // Close dialog immediately
          isLoading.value = true;

          // 1. Create a Secondary Firebase App to register the user
          // This prevents the Super Admin from being logged out!
          FirebaseApp tempApp = await Firebase.initializeApp(
            name: 'TemporaryRegistrationApp',
            options: Firebase.app().options,
          );

          // 2. Create the user in Firebase Authentication
          UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
              .createUserWithEmailAndPassword(email: email, password: password);
          
          final String newUid = userCredential.user!.uid;

          // 3. Delete the temporary app to clean up memory
          await tempApp.delete();

          // 4. Create the UserModel with the exact UID from Firebase Auth
          final newUser = UserModel(
            uid: newUid,
            name: name,
            email: email.toLowerCase(),
            role: selectedNewRole,
            department: newDepartment,
            language: 'English',
            followedGroups: [],
            createdAt: DateTime.now(),
          );

          // 5. Save to Firestore database using the Auth UID as the Document ID
          await _firestore.collection('users').doc(newUid).set(newUser.toFirestore());

          // 6. Update UI lists locally
          allUsers.add(newUser);
          
          final uniqueRoles = allUsers.map((u) => u.role).toSet().toList();
          roles.value = ['All Roles', ...uniqueRoles];

          _calculateMetrics();
          _applyFilters();

          // Ideally, you would trigger an email to the user here with their temporary password.
          Get.snackbar('Success', 'Profile created! Please share the password ($password) securely with $name.',
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 8), // Longer duration so admin can copy the password
              backgroundColor: AppTheme.successGreen.withOpacity(0.9),
              colorText: Colors.white);
              
        } on FirebaseAuthException catch (e) {
           Get.snackbar('Auth Error', e.message ?? 'Failed to create authentication credentials.',
              backgroundColor: AppTheme.dangerRed, colorText: Colors.white);
        } catch (e) {
          Get.snackbar('Database Error', 'Authentication succeeded, but database failed: $e',
              backgroundColor: AppTheme.dangerRed, colorText: Colors.white);
        } finally {
          isLoading.value = false;
        }
      },
    );
  }


// ── Database Writes (Edit User Modal) ─────────────────────────────────────
  void openEditUserModal(UserModel user) {
    if (!isSuperAdmin) {
      Get.snackbar('Access Denied', 'Only Super Admins can edit users.', 
          backgroundColor: AppTheme.dangerRed, colorText: Colors.white);
      return;
    }

    final nameController = TextEditingController(text: user.name);
    
    // Ensure the current role is properly selected, even if it's slightly different
    String selectedEditRole = user.role;
    final departmentPrefix = user.department.toLowerCase();
    
    // Standard roles for this user's department
    final standardRoles = [
      '${departmentPrefix}_forecaster',
      '${departmentPrefix}_admin',
      '${departmentPrefix}_super_admin'
    ];
    
    // If somehow their current role isn't in the standard list, add it so the dropdown doesn't crash
    if (!standardRoles.contains(selectedEditRole)) {
      standardRoles.add(selectedEditRole);
    }

    Get.defaultDialog(
      title: 'Edit Staff Profile',
      titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
      radius: 12,
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Email is read-only (Firebase Auth restriction)
            TextField(
              controller: TextEditingController(text: user.email),
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email Address (Cannot be changed)',
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
                fillColor: Colors.grey.withOpacity(0.1),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedEditRole,
              decoration: const InputDecoration(
                labelText: 'Assign Role',
                border: OutlineInputBorder(),
              ),
              items: standardRoles.map((role) {
                // Format the role to look nice (e.g., "cafo_super_admin" -> "Super Admin")
                String displayName = role.replaceAll('${departmentPrefix}_', '').replaceAll('_', ' ').capitalizeFirst ?? role;
                return DropdownMenuItem(value: role, child: Text(displayName));
              }).toList(),
              onChanged: (val) {
                if (val != null) selectedEditRole = val;
              },
            ),
          ],
        ),
      ),
      textConfirm: 'Save Changes',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.accentBlue,
      onConfirm: () async {
        final newName = nameController.text.trim();

        if (newName.isEmpty) {
          Get.snackbar('Missing Info', 'Name cannot be empty.');
          return;
        }

        try {
          Get.back(); // Close dialog immediately
          isLoading.value = true;

          // 1. Update in Firestore
          await _firestore.collection('users').doc(user.uid).update({
            'name': newName,
            'role': selectedEditRole,
          });

          // 2. Create an updated UserModel to replace the old one locally
          final updatedUser = UserModel(
            uid: user.uid,
            name: newName,
            email: user.email,
            role: selectedEditRole,
            department: user.department,
            language: user.language,
            followedGroups: user.followedGroups,
            createdAt: user.createdAt,
          );

          // 3. Update the local list
          final index = allUsers.indexWhere((u) => u.uid == user.uid);
          if (index != -1) {
            allUsers[index] = updatedUser;
          }
          
          // Re-evaluate roles array for the filters in case a new role was added
          final uniqueRoles = allUsers.map((u) => u.role).toSet().toList();
          roles.value = ['All Roles', ...uniqueRoles];

          _applyFilters();

          Get.snackbar('Success', '${updatedUser.name}\'s profile has been updated.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: AppTheme.successGreen.withOpacity(0.9),
              colorText: Colors.white);
              
        } catch (e) {
          Get.snackbar('Database Error', 'Failed to update user: $e',
              backgroundColor: AppTheme.dangerRed, colorText: Colors.white);
        } finally {
          isLoading.value = false;
        }
      },
    );
  }





}