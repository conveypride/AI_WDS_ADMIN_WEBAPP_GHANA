import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data'; // Needed for Flutter Web files
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

class AdminCommunityController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  final AuthController _authController = Get.find<AuthController>();
var selectedFileBytes = Rx<Uint8List?>(null);
  var selectedFileName = "".obs;
  var selectedMediaType = "text".obs; // 'text', 'image', 'file'
  var isUploading = false.obs;
  var replyToMessage = Rxn<Map<String, dynamic>>();
  // ========================================================================
  // AUTHENTICATION & USER DATA 
  // ========================================================================
  
  String get currentAdminDepartment {
    return _authController.currentUser.value?.department ?? "Cafo"; 
  }

  String get currentAdminName {
    return _authController.currentUser.value?.name ?? "GMet Admin";
  }

  String get currentAdminId {
    return _authController.currentUser.value?.uid ?? "unknown_admin_id";
  }

  String get currentAdminRole {
    return _authController.currentUser.value?.role ?? " forecaster";
  }

  // --- NEW: Target Roles based on Department ---
  List<String> get allowedTargetRoles {
    final dept = currentAdminDepartment.toLowerCase();
    if (dept == 'cafo') {
      return ['farmer', 'general'];
    } else if (dept == 'marine') {
      return ['fisherfolk'];
    } else if (dept == 'all') {
      return ['farmer', 'general', 'fisherfolk']; 
    }
    return ['general']; // Safe fallback
  }

  // ========================================================================
  // TAB 1: GROUPS MANAGEMENT 
  // ========================================================================
  var selectedGroupId = RxnString();
  var isChatLoading = false.obs;

  var groups = <Map<String, dynamic>>[].obs;
  var activeChatMessages = <Map<String, dynamic>>[].obs;
  final chatTextController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);

     if (_authController.currentUser.value != null) {
      fetchDepartmentGroups(); 
       fetchAnalyticsData();
    } else {
      ever(_authController.currentUser, (user) {
        if (user != null) {
          fetchDepartmentGroups(); 
          fetchAnalyticsData();
        }
      });
    }
   
  }

  @override
  void onClose() {
    tabController.dispose();
    chatTextController.dispose();
    super.onClose();
  }


// --- Pick an Image ---
  Future<void> pickAdminImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // CRITICAL FOR WEB: Reads the file into memory
    );

    if (result != null && result.files.single.bytes != null) {
      selectedFileBytes.value = result.files.single.bytes;
      selectedFileName.value = result.files.single.name;
      selectedMediaType.value = 'image';
    }
  }

  // --- Pick a Document ---
  Future<void> pickAdminDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      withData: true, // CRITICAL FOR WEB
    );

    if (result != null && result.files.single.bytes != null) {
      // Optional: Check file size (e.g., limit to 10MB)
      if (result.files.single.size > 10 * 1024 * 1024) {
        Get.snackbar("File too large", "Please select a file under 10MB.", backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      
      selectedFileBytes.value = result.files.single.bytes;
      selectedFileName.value = result.files.single.name;
      selectedMediaType.value = 'file';
    }
  }
// ========================================================================
  // LOCATION HELPER
  // ========================================================================
  
  Future<Position?> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null; // Permission denied, fallback to default
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null; // Permanently denied, fallback to default
      } 

      // If permissions are granted, get the actual position
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint("Geolocation Error: $e");
      return null;
    }
  }
  // --- Clear Selection ---
  void clearSelectedMedia() {
    selectedFileBytes.value = null;
    selectedFileName.value = "";
    selectedMediaType.value = "text";
  }

  // --- Fetch Groups using target_role constraints ---
  void fetchDepartmentGroups() {
    Query query = _db.collection('groups');

    // If not a Super Admin ("All"), restrict visibility to their target roles
    if (currentAdminDepartment.toLowerCase() != 'all') {
      query = query.where('target_role', whereIn: allowedTargetRoles);
    }

    query.snapshots().listen((snapshot) {
      groups.value = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        
        String type = data['type'] ?? 'social';
        data['icon'] = type == 'official' ? Icons.verified : Icons.group;
        data['color'] = type == 'official' ? Colors.blue : Colors.green;
        data['subscribers'] = data['subscribers'] ?? 0;
        
        return data;
      }).toList();
    }, onError: (e) {
      debugPrint("Error fetching groups: $e");
    });
  }

  void selectGroup(String id) {
    selectedGroupId.value = id;
    isChatLoading.value = true;
    
    _db.collection('groups').doc(id).collection('messages')
       .orderBy('timestamp', descending: true)
       .snapshots()
       .listen((snapshot) {
      activeChatMessages.value = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      isChatLoading.value = false;
    }, onError: (e) {
      isChatLoading.value = false;
      debugPrint("Error fetching messages: $e");
    });
  }

// ========================================================================
  // REPLY STATE
  // ========================================================================


  void setReplyTo(Map<String, dynamic> msg) {
    replyToMessage.value = msg;
  }

  void cancelReply() {
    replyToMessage.value = null;
  }


// ========================================================================
  // UPDATED SEND MESSAGE LOGIC
  // ========================================================================
Future<void> sendMessage() async {
    String text = chatTextController.text.trim();
    
    if ((text.isEmpty && selectedFileBytes.value == null) || selectedGroupId.value == null) return;

    isUploading.value = true; 
    String? mediaUrl;

    try {
      // 1. GET REAL LOCATION OR FALLBACK TO ACCRA
      double finalLat = 5.6037; 
      double finalLng = -0.1870;
      
      Position? actualPosition = await _getUserLocation();
      if (actualPosition != null) {
        finalLat = actualPosition.latitude;
        finalLng = actualPosition.longitude;
      }

      // 2. UPLOAD TO FIREBASE STORAGE
      if (selectedFileBytes.value != null) {
        String folder = selectedMediaType.value == 'image' ? 'chat_images' : 'chat_documents';
        String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_${currentAdminId}_${selectedFileName.value}';
        
        Reference storageRef = FirebaseStorage.instance.ref().child('$folder/$uniqueFileName');
        UploadTask uploadTask = storageRef.putData(selectedFileBytes.value!);
        
        TaskSnapshot snapshot = await uploadTask;
        mediaUrl = await snapshot.ref.getDownloadURL();
      }

      if (selectedMediaType.value == 'file' && text.isEmpty) {
        text = selectedFileName.value;
      }

      // 3. CREATE MESSAGE DATA WITH REAL LAT/LNG
      Map<String, dynamic> messageData = {
        "author_name": currentAdminName,
        "author_id": currentAdminId,
        "author_role": "admin",
        "content": text,
        "type": selectedMediaType.value, 
        "media_url": mediaUrl,           
        "timestamp": FieldValue.serverTimestamp(),
        "comments_count": 0,
        "verified_count": 0,
        "disputed_count": 0,
        "is_admin": true,
        "department": currentAdminDepartment,
        "lat": finalLat, // Dynamic Location
        "lng": finalLng, // Dynamic Location
      };

      // ATTACH REPLY METADATA
      if (replyToMessage.value != null) {
        messageData['reply_to_id'] = replyToMessage.value!['id'];
        messageData['reply_to_author'] = replyToMessage.value!['author_name'] ?? replyToMessage.value!['author'] ?? 'User';
        
        String replyContent = replyToMessage.value!['content'] ?? '';
        if (replyContent.isEmpty && replyToMessage.value!['type'] != 'text') {
          replyContent = "Attached ${replyToMessage.value!['type']}";
        }
        messageData['reply_to_content'] = replyContent;
      }

      // SAVE TO FIRESTORE
      await _db.collection('groups').doc(selectedGroupId.value).collection('messages').add(messageData);

      // CLEANUP UI
      chatTextController.clear();
      clearSelectedMedia();
      cancelReply(); 

    } catch (e) {
      Get.snackbar("Upload Error", "Failed to send message: $e", backgroundColor: Colors.red.shade600, colorText: Colors.white);
    } finally {
      isUploading.value = false;
    }
  }

  // ========================================================================
  // GROUP SETTINGS & DELETION
  // ========================================================================
  
  Future<void> updateGroupSettings(String groupId, String newName, String newType, String newTargetRole) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      await _db.collection('groups').doc(groupId).update({
        'name': newName,
        'type': newType.toLowerCase(),
        'target_role': newTargetRole.toLowerCase(),
      });
      Get.back(); // close loading
      Get.back(); // close dialog
      Get.snackbar("Success", "Group settings updated.", backgroundColor: Colors.green.shade600, colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Failed to update group: $e", backgroundColor: Colors.red.shade600, colorText: Colors.white);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      // Delete the main group document
      await _db.collection('groups').doc(groupId).delete();
      
      selectedGroupId.value = null; // Clear the active view
      Get.back(); // close loading
      Get.back(); // close dialog
      Get.snackbar("Deleted", "Group removed successfully.", backgroundColor: AppTheme.dangerRed, colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Failed to delete group: $e", backgroundColor: Colors.red.shade600, colorText: Colors.white);
    }
  }
   
  Future<void> deleteMessage(String messageId) async {
    if (selectedGroupId.value == null) return;
    
    try {
      final msgDoc = await _db.collection('groups').doc(selectedGroupId.value).collection('messages').doc(messageId).get();
      if (!msgDoc.exists) return;
      
      final msgData = msgDoc.data() as Map<String, dynamic>;
      final authorId = msgData['author_id'] ?? '';
      
      final isAdmin = currentAdminRole.contains('admin') || currentAdminRole.contains('super_admin');
      if (!isAdmin && authorId != currentAdminId) {
        Get.snackbar("Error", "You can only delete your own messages.", backgroundColor: Colors.red.shade600, colorText: Colors.white);
        return;
      }
      
      await _db.collection('groups').doc(selectedGroupId.value).collection('messages').doc(messageId).delete();
      Get.snackbar("Post Deleted", "The message was removed.", backgroundColor: Colors.red.shade600, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Could not delete message: $e", backgroundColor: Colors.red.shade600, colorText: Colors.white);
    }
  }

  Future<void> banUser(String authorId, String authorName) async {
    if (authorId.isEmpty || authorId == currentAdminId) return;

    try {
      await _db.collection('banned_users').doc(authorId).set({
        'uid': authorId,
        'name': authorName,
        'banned_by_id': currentAdminId,
        'banned_by_name': currentAdminName,
        'department': currentAdminDepartment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(authorId).update({
        'isBanned': true,
      });

      Get.snackbar("User Banned", "$authorName has been banned.", backgroundColor: Colors.orange.shade800, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Could not ban user: $e", backgroundColor: Colors.red.shade600, colorText: Colors.white);
    }
  }

  // --- Create Group Logic Updated with Target Role ---
  Future<void> createNewGroup(String name, String type, String targetRole) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      await _db.collection('groups').add({
        "name": name,
        "type": type.toLowerCase(), 
        "target_role": targetRole.toLowerCase(), // Bind to the selected target audience
        "department": currentAdminDepartment, 
        "subscribers": 0,
        "created_at": FieldValue.serverTimestamp(),
        "created_by_id": currentAdminId,
        "created_by_name": currentAdminName,
      });
      
      Get.back(); 
      Get.snackbar("Group Created", "$name is now live for $targetRole.", backgroundColor: Colors.green.shade600, colorText: Colors.white);
    } catch (e) {
      Get.back(); 
      Get.snackbar("Error", "Failed to create group: $e", backgroundColor: Colors.red.shade600, colorText: Colors.white);
    }
  }

 // ========================================================================
  // TAB 2: INTELLIGENCE MAP & ANALYTICS (DYNAMIC FROM MESSAGES)
  // ========================================================================
  final mapController = MapController();

  // Map Layers Toggles
  var showHeatmap = true.obs;
  var showReports = true.obs;
  var showLiveUsers = true.obs;

  // Dynamic Reactive Variables
  var totalUsers = "0".obs;
  var activeReporters = "0".obs;
  
  var citizenReports = <Map<String, dynamic>>[].obs;
  var userDensity = <Map<String, dynamic>>[].obs;
  var liveUsers = <Map<String, dynamic>>[].obs; // Optional presence layer
  
  var engagementTrend = <Map<String, double>>[].obs;
  var reportDistribution = <String, double>{}.obs;

  // ========================================================================
  // UPDATED ANALYTICS LOGIC (WITH EXPLICIT "RAIN" FILTER)
  // ========================================================================

  void fetchAnalyticsData() {
    Query query = _db.collectionGroup('messages');

    if (currentAdminDepartment.toLowerCase() != 'all') {
      query = query.where('department', isEqualTo: currentAdminDepartment);
    }

    query = query.orderBy('timestamp', descending: true).limit(400);

    query.snapshots().listen((snapshot) {
         
      Set<String> uniqueUsers = {};
      Map<int, int> trendData = {1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0}; 
      
      // Updated Categories to explicitly feature Rain
      Map<String, int> typeCounts = {"Rain/Flood": 0, "Storm": 0, "Drought": 0, "Other": 0};
      
      List<Map<String, dynamic>> tempReports = [];
      List<Map<String, dynamic>> tempHeatmap = [];

      DateTime now = DateTime.now();
      int validMessageCount = 0; 

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>; 
        
        // Skip messages without coordinates
        if (data['lat'] == null || data['lng'] == null) continue; 

        double actualLat = (data['lat'] is num) ? (data['lat'] as num).toDouble() : double.tryParse(data['lat'].toString()) ?? 0.0;
        double actualLng = (data['lng'] is num) ? (data['lng'] as num).toDouble() : double.tryParse(data['lng'].toString()) ?? 0.0;

        validMessageCount++; 

        String content = (data['content'] ?? '').toString().toLowerCase();
        String authorId = data['author_id'] ?? '';
        
        if (authorId.isNotEmpty) uniqueUsers.add(authorId);

        if (data['timestamp'] != null) {
          DateTime dt = (data['timestamp'] as Timestamp).toDate();
          int daysAgo = now.difference(dt).inDays;
          if (daysAgo >= 0 && daysAgo < 7) {
            int chartDay = 7 - daysAgo; 
            trendData[chartDay] = (trendData[chartDay] ?? 0) + 1;
          }
        }

        // --- UPDATED KEYWORD CLASSIFICATION ---
        String categorizedType = "Other";
        
        // Explicitly looking for "rain" first
        if (content.contains('rain') || content.contains('flood') || content.contains('water') || content.contains('spill')) {
          categorizedType = "Rain/Flood";
          typeCounts["Rain/Flood"] = typeCounts["Rain/Flood"]! + 1;
        } else if (content.contains('storm') || content.contains('wind') || content.contains('thunder') || content.contains('cloud')) {
          categorizedType = "Storm";
          typeCounts["Storm"] = typeCounts["Storm"]! + 1;
        } else if (content.contains('drought') || content.contains('heat') || content.contains('dry') || content.contains('sun')) {
          categorizedType = "Drought";
          typeCounts["Drought"] = typeCounts["Drought"]! + 1;
        } else {
          typeCounts["Other"] = typeCounts["Other"]! + 1;
        }

        // MAP DATA GENERATION
        if (categorizedType != "Other" && tempReports.length < 50) {
          tempReports.add({
            "lat": actualLat, 
            "lng": actualLng,
            "type": categorizedType,
            "desc": content.length > 25 ? "${content.substring(0, 25)}..." : content,
            "time": data['timestamp'] != null ? "Recent" : "Just now",
          });
          
          tempHeatmap.add({
            "lat": actualLat, 
            "lng": actualLng, 
            "radius": 40.0, 
            "intensity": 0.5
          });
        }
      }

      activeReporters.value = uniqueUsers.length.toString(); 
      totalUsers.value = validMessageCount.toString(); 
      
      citizenReports.value = tempReports;
      userDensity.value = tempHeatmap;

      engagementTrend.value = trendData.entries.map((e) => {"day": e.key.toDouble(), "value": e.value.toDouble()}).toList();
      
      int totalClassified = typeCounts.values.reduce((a, b) => a + b);
      if (totalClassified > 0) {
        reportDistribution.value = {
          "Rain/Flood": (typeCounts["Rain/Flood"]! / totalClassified) * 100,
          "Storm": (typeCounts["Storm"]! / totalClassified) * 100,
          "Drought": (typeCounts["Drought"]! / totalClassified) * 100,
          "Other": (typeCounts["Other"]! / totalClassified) * 100,
        };
      } else {
        reportDistribution.clear();
      }
      
    }, onError: (e) => debugPrint("Error fetching message analytics: $e"));
  }
}