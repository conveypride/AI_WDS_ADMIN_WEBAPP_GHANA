import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class AudioSummaryController extends GetxController {
  final String forecastId;
  final String collectionName; // e.g., 'cafo_forecasts' or 'marine_forecasts'
  final Map<String, dynamic> initialAudios;

  AudioSummaryController({
    required this.forecastId,
    required this.collectionName,
    required this.initialAudios,
  });

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  // State Management
  var isRecording = false.obs;
  var activeRecordLang = "".obs; // Which language is currently recording
  
  var isPlaying = false.obs;
  var activePlayLang = "".obs;   // Which language is currently playing

  var isSaving = false.obs;

  // Storing URLs
  var savedDbUrls = <String, String>{}.obs; // URLs already in Firebase
  var localBlobUrls = <String, String>{}.obs; // Newly recorded web URLs

  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'twi', 'name': 'Twi (Akan)'},
    {'code': 'ga', 'name': 'Ga'},
  ];

  @override
  void onInit() {
    super.onInit();
    // Load existing audios passed from the list view
    initialAudios.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        savedDbUrls[key] = value.toString();
      }
    });

    // Listen to player completion to reset play button
    _player.onPlayerComplete.listen((event) {
      isPlaying.value = false;
      activePlayLang.value = "";
    });
  }

  @override
  void onClose() {
    _recorder.dispose();
    _player.dispose();
    super.onClose();
  }

  // --- RECORDING LOGIC (Web Safe) ---
  Future<void> toggleRecording(String langCode) async {
    if (isRecording.value && activeRecordLang.value == langCode) {
      // STOP RECORDING
      final String? path = await _recorder.stop();
      isRecording.value = false;
      activeRecordLang.value = "";
      
      if (path != null) {
        localBlobUrls[langCode] = path; // On web, this is a blob:// URL
      }
    } else {
     // START RECORDING
      if (await _recorder.hasPermission()) {
        if (isPlaying.value) await stopAudio();
        
        // ---> THE FIX: Use AAC encoding for cross-platform metadata support
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), 
          path: ''
        );
        
        isRecording.value = true;
        activeRecordLang.value = langCode;
      }else {
        Get.snackbar("Permission Denied", "Please allow microphone access in your browser.");
      }
    }
  }

  // --- PLAYBACK LOGIC ---
  Future<void> toggleAudio(String langCode) async {
    if (isPlaying.value && activePlayLang.value == langCode) {
      await stopAudio();
    } else {
      await stopAudio(); // Stop any currently playing audio
      
      String? urlToPlay = localBlobUrls[langCode] ?? savedDbUrls[langCode];
      
      if (urlToPlay != null) {
        isPlaying.value = true;
        activePlayLang.value = langCode;
        await _player.play(UrlSource(urlToPlay));
      }
    }
  }

  Future<void> stopAudio() async {
    await _player.stop();
    isPlaying.value = false;
    activePlayLang.value = "";
  }

  void deleteLocalRecording(String langCode) {
    localBlobUrls.remove(langCode);
  }

  // --- UPLOAD & SAVE LOGIC ---
  Future<void> saveAndUploadAll() async {
    if (localBlobUrls.isEmpty) {
      Get.back(); // Nothing new to save
      return;
    }

    isSaving.value = true;
    try {
      Map<String, String> finalUrlsToSave = Map.from(savedDbUrls);

      // Loop through all newly recorded blob URLs
      for (var entry in localBlobUrls.entries) {
        String lang = entry.key;
        String blobUrl = entry.value;
 // 1. Fetch bytes from the browser Blob URL
        final http.Response response = await http.get(Uri.parse(blobUrl));
        final bytes = response.bodyBytes;

        // 2. Upload to Firebase Storage
        // ---> THE FIX: Save as .m4a
        String fileName = 'forecast_audios/${forecastId}_${lang}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        
        // ---> THE FIX: Use audio/mp4 content type
        UploadTask uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'audio/mp4'));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        finalUrlsToSave[lang] = downloadUrl;
      }

print("collectionName: $collectionName, forecastId: $forecastId, finalUrlsToSave: $finalUrlsToSave");
      // 3. Update Firestore Document
      await FirebaseFirestore.instance.collection(collectionName).doc(forecastId).update({
        'audio_summaries': finalUrlsToSave,
      });

      Get.back(); // Close Dialog
      Get.snackbar("Success", "Audio summaries updated successfully!", 
          backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      Get.snackbar("Upload Error", "Failed to upload audio: $e", 
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }
}