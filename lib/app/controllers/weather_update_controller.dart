import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/controllers/auth_controller.dart';
import 'package:weather_admin_dashboard/app/model/forecastData.dart';
import 'package:weather_admin_dashboard/app/model/weather_update_editable_point.dart';
import 'package:weather_admin_dashboard/app/model/weeklyItemType.dart';
import 'package:weather_admin_dashboard/app/model/weather_update_map_item.dart';
import 'package:weather_admin_dashboard/app/model/weather_update_map_region.dart';
import 'package:weather_admin_dashboard/app/model/affected_area_row.dart';
import 'package:printing/printing.dart';
import 'package:weather_admin_dashboard/app/services/weather_update_pdf_service.dart';
import 'package:weather_admin_dashboard/app/services/weather_update_image_generator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

class WeatherUpdateController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  final AuthController _authCtrl = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController summaryController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    _autoSetIssueTime();
    _initializeAffectedAreas();
  }

  @override
  void onReady() {
    super.onReady();
    if (_authCtrl.currentUser.value != null) {
      _initDynamicData();
    }
    ever(_authCtrl.currentUser, (user) {
      if (user != null) _initDynamicData();
    });
  }

  @override
  void onClose() {
    tabController.dispose();
    summaryController.dispose();
    for (var row in affectedAreas) { row.dispose(); }
    super.onClose();
  }

  // ========================================================================
  // 1. HISTORY TAB & ANALYTICS STATE
  // ========================================================================
  var kpiTotal = 0.obs;
  var kpiDraft = 0.obs;
  var kpiPending = 0.obs;
  var kpiPublished = 0.obs;

  var isLoadingList = true.obs;
  var isFetchingMore = false.obs;
  var hasMore = true.obs;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 10;

  var forecastsList = <Map<String, dynamic>>[].obs;

  var isAdmin = false.obs; 
  var isSuperAdmin = false.obs; 
  var currentForecast = Rxn<ForecastData>(); 
  var editingDocId = RxnString(); // Track if we are editing
  var availableGroups = <Map<String, dynamic>>[].obs;
  var selectedGroupIds = <String>[].obs;

  Future<void> _initDynamicData() async {
    final user = _authCtrl.currentUser.value;
    if (user != null) {
      isAdmin.value = user.role.contains('admin') || user.role.contains('super_admin');
      isSuperAdmin.value = user.role.contains('admin') || user.role.contains('super_admin');
    }
    await fetchAnalytics();
    await fetchForecastHistory();
    await fetchDepartmentGroups();
  }

  Future<void> fetchAnalytics() async {
    final user = _authCtrl.currentUser.value;
    if (user == null) return;

    Query baseQuery = _firestore.collection('weather_updates');
    if (!isAdmin.value) {
      baseQuery = baseQuery.where('author.uid', isEqualTo: user.uid);
    }

    try {
      final total = await baseQuery.count().get();
      final draft = await baseQuery.where('status', isEqualTo: 'draft').count().get();
      final pending = await baseQuery.where('status', isEqualTo: 'pending_approval').count().get();
      final published = await baseQuery.where('status', isEqualTo: 'published').count().get();

      kpiTotal.value = total.count ?? 0;
      kpiDraft.value = draft.count ?? 0;
      kpiPending.value = pending.count ?? 0;
      kpiPublished.value = published.count ?? 0;
    } catch (e) {
      print("Error fetching analytics: $e");
    }
  }

  Future<void> fetchForecastHistory() async {
    isLoadingList.value = true;
    _lastDocument = null;
    hasMore.value = true;
    forecastsList.clear();

    try {
      final user = _authCtrl.currentUser.value;
      if (user == null) return;

      Query query = _firestore.collection('weather_updates').orderBy('createdAt', descending: true).limit(_pageSize);
      if (!isAdmin.value) {
        query = query.where('author.uid', isEqualTo: user.uid);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        forecastsList.assignAll(snapshot.docs.map((doc) => { 'id': doc.id, ...doc.data() as Map<String, dynamic> }).toList());
      }
      hasMore.value = snapshot.docs.length == _pageSize;
    } catch (e) {
      print("Error fetching history: $e");
    } finally {
      isLoadingList.value = false;
    }
  }

  Future<void> fetchMoreForecasts() async {
    if (isFetchingMore.value || !hasMore.value) return;
    isFetchingMore.value = true;

    try {
      final user = _authCtrl.currentUser.value;
      if (user == null) return;

      Query query = _firestore.collection('weather_updates').orderBy('createdAt', descending: true).startAfterDocument(_lastDocument!).limit(_pageSize);
      if (!isAdmin.value) {
        query = query.where('author.uid', isEqualTo: user.uid);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        forecastsList.addAll(snapshot.docs.map((doc) => { 'id': doc.id, ...doc.data() as Map<String, dynamic> }).toList());
      }
      hasMore.value = snapshot.docs.length == _pageSize;
    } catch (e) {
      print("Error fetching more: $e");
    } finally {
      isFetchingMore.value = false;
    }
  }

  void createNewForecast() {
    _resetInputState();
    tabController.animateTo(1);
  }

  Future<void> fetchDepartmentGroups() async {
    final user = _authCtrl.currentUser.value;
    if (user == null) return;

    final dept = user.department.toLowerCase();

    try {
      List<String> targetRoles = ['general'];
      if (dept == 'cafo') {
        targetRoles.addAll(['farmer']);
      } else if (dept == 'marine') {
        targetRoles.addAll(['fisherfolk']);
      } else if (dept == 'all') {
        targetRoles.addAll(['farmer', 'fisherfolk']);
      }

      Query query = _firestore.collection('groups');
      if (dept != 'all') {
        query = query.where('target_role', whereIn: targetRoles);
      }
      
      final snap = await query.get();
      availableGroups.assignAll(snap.docs.map((doc) {
        var d = doc.data() as Map<String, dynamic>;
        d['id'] = doc.id;
        return d;
      }).toList());

      debugPrint("Loaded ${availableGroups.length} available groups for department: $dept");
    } catch (e) {
      debugPrint("Error fetching department groups: $e");
    }
  }

  void _resetInputState() {
    editingDocId.value = null; // Clear editing ID
    selectedGroupIds.clear();
    validFrom.value = DateTime.now();
    _autoSetIssueTime();
    summary.value = '';
    summaryController.clear();
    finishedRegions.clear();
    editablePoints.clear();
    mapItems.clear();
    _initializeAffectedAreas();
  }

  // ========================================================================
  // 2. TIME & DATE CONTROLS
  // ========================================================================
  var validFrom = DateTime.now().obs;
  var selectedIssueTime = '1445'.obs; // Default based on image
  final issueTimeOptions = ['0500', '1100', '1445', '1700', '2300'];

  void updateStartDate(DateTime date) => validFrom.value = date;

  void updateIssueTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    selectedIssueTime.value = '$hour$minute';
  }

  void _autoSetIssueTime() {
    final hour = DateTime.now().toUtc().hour;
    // Simple logic, can be refined
    if (hour < 6) selectedIssueTime.value = '0500';
    else if (hour < 12) selectedIssueTime.value = '1100';
    else if (hour < 15) selectedIssueTime.value = '1445';
    else if (hour < 18) selectedIssueTime.value = '1700';
    else selectedIssueTime.value = '2300';
  }

  // ========================================================================
  // 3. MAP DRAWING ENGINE
  // ========================================================================
  final mapController = MapController();
  var isDrawing = false.obs;
  var selectedColor = 'green'.obs;
  var draggedPointIndex = RxnInt();
  WeatherUpdateMapRegion? _originalRegionToEdit; 

  final finishedRegions = <WeatherUpdateMapRegion>[].obs;
  final editablePoints = <WeatherUpdateEditablePoint>[].obs;
  final mapItems = <WeatherUpdateMapItem>[].obs;
  final List<List<WeatherUpdateEditablePoint>> _undoStack = [];

  void startDrawing() { isDrawing.value = true; _originalRegionToEdit = null; }
  void setColor(String c) => selectedColor.value = c;
  
  Color get activeColor {
    switch (selectedColor.value) {
      case 'red': return Colors.red; case 'orange': return Colors.orange; case 'yellow': return Colors.yellow; case 'green': return Colors.green; default: return Colors.blue;
    }
  }

  void addEditablePoint(LatLng point) => editablePoints.add(WeatherUpdateEditablePoint(point, editablePoints.length));
  void updateEditablePoint(int index, LatLng newPos) {
    if (index >= 0 && index < editablePoints.length) { editablePoints[index].position = newPos; editablePoints.refresh(); }
  }
  void removeEditablePoint(int index) {
    if (index >= 0 && index < editablePoints.length) { saveUndoState(); editablePoints.removeAt(index); }
  }

  void finishDrawing() {
    if (editablePoints.length < 3) { Get.snackbar("Invalid Polygon", "You need at least 3 points.", backgroundColor: Colors.red, colorText: Colors.white); return; }
    finishedRegions.add(WeatherUpdateMapRegion(points: editablePoints.map((e) => e.position).toList(), color: selectedColor.value));
    _clearActiveDrawingState();
  }

  void cancelDrawing() {
    if (_originalRegionToEdit != null) finishedRegions.add(_originalRegionToEdit!); 
    _clearActiveDrawingState();
  }

  void deleteActiveDrawing() => _clearActiveDrawingState(); 
  void _clearActiveDrawingState() { editablePoints.clear(); _undoStack.clear(); isDrawing.value = false; _originalRegionToEdit = null; }
  void saveUndoState() => _undoStack.add(editablePoints.map((e) => WeatherUpdateEditablePoint(e.position, e.id)).toList());

  void undo() {
    if (_undoStack.isNotEmpty) {
      editablePoints.assignAll(_undoStack.removeLast());
    } else if (editablePoints.isNotEmpty) {editablePoints.removeLast();}
  }

  void selectPolygonForEditing(LatLng tapPoint) {
    for (int i = finishedRegions.length - 1; i >= 0; i--) {
      final regionToEdit = finishedRegions.removeAt(i);
      _originalRegionToEdit = WeatherUpdateMapRegion(points: List.from(regionToEdit.points), color: regionToEdit.color);
      setColor(regionToEdit.color);
      editablePoints.assignAll(regionToEdit.points.asMap().entries.map((e) => WeatherUpdateEditablePoint(e.value, e.key)));
      _undoStack.clear(); isDrawing.value = true; break; 
    }
  }

  // ========================================================================
  // 4. ICONS & LETTERS LOGIC
  // ========================================================================
  void addMapItem(WeeklyItemType type, String value, LatLng spawnPoint) {
    mapItems.add(WeatherUpdateMapItem(id: DateTime.now().millisecondsSinceEpoch.toString(),
           type: type, value: value, position: spawnPoint));
  }

  void updateMapItemPos(String id, LatLng newPos) {
    final index = mapItems.indexWhere((item) => item.id == id);
    if (index != -1) { mapItems[index].position = newPos; mapItems.refresh(); }
  }
  void deleteMapItem(String id) => mapItems.removeWhere((item) => item.id == id);

  // ========================================================================
  // 5. WEATHER UPDATE SPECIFIC DATA
  // ========================================================================
  var summary = ''.obs;
  var affectedAreas = <AffectedAreaRow>[].obs;

  void _initializeAffectedAreas() {
    affectedAreas.assignAll([
      AffectedAreaRow(areas: '', validTime: ''),
      AffectedAreaRow(areas: '', validTime: ''),
      AffectedAreaRow(areas: '', validTime: ''),
    ]);
  }

  void addAffectedAreaRow() {
    affectedAreas.add(AffectedAreaRow(areas: '', validTime: ''));
  }

  void removeAffectedAreaRow(int index) {
    if (affectedAreas.length > 1) affectedAreas.removeAt(index);
  }

  Color getMatrixColor(String letter) {
    switch (letter) {
      case 'A': return Colors.green;
      case 'B': return Colors.green;
      case 'C': return Colors.yellow;
      case 'D': return Colors.green;
      case 'E': return Colors.yellow;
      case 'F': return Colors.orange;
      case 'G': return Colors.yellow;
      case 'H': return Colors.orange;
      case 'I': return Colors.red;
      default: return Colors.transparent;
    }
  }

  // ========================================================================
  // 6. PUBLISHING
  // ========================================================================
  var isPublishing = false.obs;

  Future<void> publishForecast({bool isDraft = false}) async {
    // Validation: Require at least one group if not a draft
    if (!isDraft && selectedGroupIds.isEmpty) {
      Get.snackbar("Target Groups Required", "Please select at least one community group to post to.", backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isPublishing.value = true;
    try {
      final user = _authCtrl.currentUser.value;
      if (user == null) throw Exception("User session expired.");

      final finalStatus = isDraft ? 'draft' : (isSuperAdmin.value ? 'published' : 'pending_approval');
      
      final payload = {
        'status': finalStatus,
        'validFrom': validFrom.value.toIso8601String(),
        'issueTime': selectedIssueTime.value,
        'summary': summaryController.text, // Use controller text
        'targetGroups': selectedGroupIds.toList(), // Save target groups
        'affectedAreas': affectedAreas.map((e) => e.toJson()).toList(),
        'regions': finishedRegions.map((e) => {
          'points': e.points.map((p) => { 'lat': p.latitude, 'lng': p.longitude }).toList(),
          'color': e.color,
        }).toList(),
        'mapItems': mapItems.map((e) => {
          'id': e.id,
          'type': e.type.toString(),
          'value': e.value,
          'lat': e.position.latitude,
          'lng': e.position.longitude,
        }).toList(),
        'author': {
          'uid': user.uid,
          'name': user.name,
          'email': user.email,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If not editing, add createdAt
      if (editingDocId.value == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      final docId = editingDocId.value ?? DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      await _updateCountersWithBatch(docId, finalStatus, payload, user.uid);

      if (finalStatus == 'published') {
        await _autoPostWeatherUpdateToCommunityGroups(docId);
      }

      Get.snackbar("Success", isDraft ? "Draft saved." : "Forecast submitted.", backgroundColor: Colors.green, colorText: Colors.white);
      fetchAnalytics();
      fetchForecastHistory();
      tabController.animateTo(0);
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isPublishing.value = false;
    }
  }

  Future<void> _updateCountersWithBatch(String docId, String newStatus, Map<String, dynamic> payload, String authorUid) async {
    final docRef = _firestore.collection('weather_updates').doc(docId);
    final userRef = _firestore.collection('users').doc(authorUid);
    final globalRef = _firestore.collection('analytics').doc('weather_update_global');

    final existingDoc = await docRef.get();
    String? oldStatus;
    if (existingDoc.exists) {
      oldStatus = (existingDoc.data() as Map<String, dynamic>)['status'];
    }

    WriteBatch batch = _firestore.batch();
    batch.set(docRef, payload, SetOptions(merge: true));

    if (oldStatus != newStatus) {
      Map<String, dynamic> statIncrements = {};
      if (oldStatus == null) {
        statIncrements['total'] = FieldValue.increment(1);
        statIncrements[newStatus] = FieldValue.increment(1);
      } else {
        statIncrements[oldStatus] = FieldValue.increment(-1);
        statIncrements[newStatus] = FieldValue.increment(1);
      }
      batch.set(userRef, { 'weather_update_stats': statIncrements }, SetOptions(merge: true));
      batch.set(globalRef, statIncrements, SetOptions(merge: true));
    }
    await batch.commit();
  }

  void changeForecastStatus(String docId, String newStatus, String authorUid) async {
    try {
      await _updateCountersWithBatch(docId, newStatus, { 'status': newStatus, 'updatedAt': FieldValue.serverTimestamp() }, authorUid);
      
      if (newStatus == 'published') {
        await _autoPostWeatherUpdateToCommunityGroups(docId);
      }

      fetchAnalytics();
      fetchForecastHistory();
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void showApprovalGroupDialog(String docId, Map<String, dynamic> data, String authorUid) {
    // Load existing groups into the selection state for the Super Admin to review/edit
    selectedGroupIds.assignAll(List<String>.from(data['targetGroups'] ?? []));

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: Colors.green),
            const SizedBox(width: 12),
            const Text("Approve & Post", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Please verify the target community groups for this update. You can add or remove groups before final posting."),
              const SizedBox(height: 20),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(() {
                  if (availableGroups.isEmpty) {
                    return const Center(child: Text("No available groups found."));
                  }
                  return ListView.builder(
                    itemCount: availableGroups.length,
                    itemBuilder: (context, index) {
                      final group = availableGroups[index];
                      final id = group['id'];
                      return Obx(() => CheckboxListTile(
                        title: Text(group['name'] ?? 'Unnamed Group', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text("${group['department']} • ${group['target_role']}", style: const TextStyle(fontSize: 11)),
                        value: selectedGroupIds.contains(id),
                        onChanged: (_) => toggleGroupSelection(id),
                        activeColor: AppTheme.accentBlue,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ));
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("CANCEL", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () async {
              if (selectedGroupIds.isEmpty) {
                Get.snackbar("Selection Required", "You must select at least one group to approve this update.", backgroundColor: Colors.orange, colorText: Colors.white);
                return;
              }
              Get.back();
              
              // 1. Update the document with the final group selection
              await _firestore.collection('weather_updates').doc(docId).update({
                'targetGroups': selectedGroupIds.toList(),
              });

              // 2. Trigger the status change and auto-post
              changeForecastStatus(docId, 'published', authorUid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: const Text("APPROVE & POST NOW", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void loadForecastForEditing(Map<String, dynamic> data, {bool isViewOnly = false}) {
    _resetInputState();
    editingDocId.value = data['id']; // Set the ID for updating
    
    if (data['validFrom'] != null) {
      validFrom.value = DateTime.parse(data['validFrom']);
    }
    selectedIssueTime.value = data['issueTime'] ?? '1445';
    summary.value = data['summary'] ?? '';
    summaryController.text = summary.value;
    
    if (data['targetGroups'] != null) {
      selectedGroupIds.assignAll(List<String>.from(data['targetGroups']));
    }

    if (data['affectedAreas'] != null) {
      affectedAreas.assignAll((data['affectedAreas'] as List).map((e) => AffectedAreaRow.fromJson(e)).toList());
    }

    if (data['regions'] != null) {
      finishedRegions.assignAll((data['regions'] as List).map((r) {
        return WeatherUpdateMapRegion(
          points: (r['points'] as List).map((p) => LatLng(p['lat'], p['lng'])).toList(),
          color: r['color'],
        );
      }).toList());
    }

    if (data['mapItems'] != null) {
      mapItems.assignAll((data['mapItems'] as List).map((item) {
        // Handle potential WeeklyItemType string conversion
        WeeklyItemType type = WeeklyItemType.icon;
        if (item['type']?.toString().contains('text') == true) type = WeeklyItemType.text;

        return WeatherUpdateMapItem(
          id: item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          value: item['value'] ?? '',
          position: LatLng(item['lat'], item['lng']),
        );
      }).toList());
    }

    tabController.animateTo(1);
  }

  Future<void> downloadForecastPdfAndImage(BuildContext context, Map<String, dynamic> data) async {
    try {
      Get.snackbar("Processing", "Generating PDF report...", backgroundColor: Colors.blue, colorText: Colors.white, duration: const Duration(seconds: 2));
      
      final mapImageBytes = await WeatherUpdateImageGenerator.generateMapImage(
        regions: data['regions'] ?? [],
        mapItems: data['mapItems'] ?? [],
        context: context,
      );

      if (mapImageBytes == null) throw Exception("Failed to capture map image.");

      final pdfBytes = await WeatherUpdatePdfService.generatePdf(data, mapImageBytes);

      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "Weather_Update_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);

      Get.snackbar("Success", "PDF downloaded successfully.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print("Error generating/downloading PDF: $e");
      Get.snackbar("Error", "Failed to generate PDF: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ========================================================================
  // 8. AUTO-POST TO COMMUNITY GROUPS
  // ========================================================================
  Future<void> _autoPostWeatherUpdateToCommunityGroups(String docId) async {
    const String functionName = 'Weather Update Auto-Post';
    Get.snackbar(functionName, 'Generating files and sharing with groups...',
        showProgressIndicator: true, duration: const Duration(seconds: 15));

    try {
      final docSnapshot = await _firestore.collection('weather_updates').doc(docId).get();
      if (!docSnapshot.exists) return;

      final data = Map<String, dynamic>.from(docSnapshot.data()!);
      final targetGroupIds = List<String>.from(data['targetGroups'] ?? []);
      
      if (targetGroupIds.isEmpty) {
        print("Auto-post: No target groups found in document.");
        return;
      }

      final validDate = data['validFrom'] ?? '';
      final formattedDate = validDate.isNotEmpty 
          ? DateFormat('dd/MM/yyyy').format(DateTime.tryParse(validDate) ?? DateTime.now()) 
          : DateFormat('dd/MM/yyyy').format(DateTime.now());

      List<String> postedFiles = [];

      // 1. Generate Image from Map
      print("Auto-post: Generating map image...");
      final mapImageBytes = await WeatherUpdateImageGenerator.generateMapImage(
        regions: data['regions'] ?? [],
        mapItems: data['mapItems'] ?? [],
        context: Get.context!,
      );

      if (mapImageBytes == null) throw Exception("Could not capture map image from UI.");

      // 2. Generate PDF
      print("Auto-post: Generating PDF...");
      final pdfBytes = await WeatherUpdatePdfService.generatePdf(data, mapImageBytes);
      String? pdfUrl;
      if (pdfBytes.isNotEmpty) {
        pdfUrl = await _uploadToStorage(
          fileBytes: pdfBytes,
          fileName: 'WeatherUpdate_$docId.pdf',
          type: 'file',
        );
        postedFiles.add('PDF Report');
      }

      // 3. Generate Raster Image
      print("Auto-post: Rasterizing PDF to image...");
      String? imageUrl;
      final imageBytes = await _rasterizePdfToImage(pdfBytes);
      if (imageBytes.isNotEmpty) {
        imageUrl = await _uploadToStorage(
          fileBytes: imageBytes,
          fileName: 'WeatherUpdate_$docId.png',
          type: 'image',
        );
        postedFiles.add('Report Image');
      }

      // 4. Post to Selected Groups
      print("Auto-post: Posting to ${targetGroupIds.length} groups...");
      for (final groupId in targetGroupIds) {
        if (pdfUrl != null) {
          await _postUrlToGroup(
            groupId: groupId,
            mediaUrl: pdfUrl,
            content: 'Impact-Based Weather Update for $formattedDate',
            type: 'file',
          );
        }
        if (imageUrl != null) {
          await _postUrlToGroup(
            groupId: groupId,
            mediaUrl: imageUrl,
            content: 'Weather Update Summary for $formattedDate',
            type: 'image',
          );
        }
      }

      if (postedFiles.isNotEmpty) {
        await _markWeatherUpdateAsPosted(docId);
        Get.snackbar('Auto-Post Successful', 'Shared with ${targetGroupIds.length} community groups.', backgroundColor: Colors.green, colorText: Colors.white);
      }

    } catch (e) {
      print('Auto-post error details: $e');
      Get.snackbar('Share Error', 'The update was saved, but we couldn\'t post to community groups: ${e.toString()}', 
        backgroundColor: Colors.orange, colorText: Colors.white, duration: const Duration(seconds: 8));
    }
  }

  Future<String> _uploadToStorage({required Uint8List fileBytes, required String fileName, required String type}) async {
    try {
      final folder = type == 'image' ? 'chat_images' : 'chat_documents';
      final storageRef = FirebaseStorage.instance.ref().child('$folder/$fileName');
      
      final uploadTask = storageRef.putData(
        fileBytes, 
        SettableMetadata(contentType: type == 'image' ? 'image/png' : 'application/pdf')
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      print("Firebase Storage Error ($type): ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("General Storage Error ($type): $e");
      rethrow;
    }
  }

  Future<void> _postUrlToGroup({required String groupId, required String mediaUrl, required String content, required String type}) async {
    await _firestore.collection('groups').doc(groupId).collection('messages').add({
      'author_name': _authCtrl.currentUser.value?.name ?? 'GMet Admin',
      'author_id': _authCtrl.currentUser.value?.uid ?? 'system',
      'author_role': 'admin',
      'content': content,
      'type': type,
      'media_url': mediaUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'is_admin': true,
      'department': 'cafo',
    });
  }

  Future<void> _markWeatherUpdateAsPosted(String docId) async {
    try {
      await _firestore.collection('weather_updates').doc(docId).update({
        'postedToCommunity': true,
        'postedToCommunityAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {}
  }

  Future<Uint8List> _rasterizePdfToImage(Uint8List pdfBytes) async {
    final List<int> imageBytesList = [];
    await for (var page in Printing.raster(pdfBytes, pages: [0], dpi: 300)) {
      final bytes = await page.toPng();
      imageBytesList.addAll(bytes);
    }
    return Uint8List.fromList(imageBytesList);
  }

  void showGroupSelectionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Select Target Groups", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Obx(() {
            if (availableGroups.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No groups found for your department."),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: availableGroups.length,
              itemBuilder: (context, index) {
                final group = availableGroups[index];
                final id = group['id'];
                return Obx(() => CheckboxListTile(
                  title: Text(group['name'] ?? 'Unnamed Group'),
                  subtitle: Text("${group['department']} - ${group['target_role']}"),
                  value: selectedGroupIds.contains(id),
                  onChanged: (_) => toggleGroupSelection(id),
                  activeColor: AppTheme.accentBlue,
                ));
              },
            );
          }),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("DONE", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void toggleGroupSelection(String groupId) {
    if (selectedGroupIds.contains(groupId)) {
      selectedGroupIds.remove(groupId);
    } else {
      selectedGroupIds.add(groupId);
    }
  }
}
