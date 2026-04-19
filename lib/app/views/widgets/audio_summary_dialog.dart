import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/controllers/audio_summary_controller.dart'; 

class AudioSummaryDialog extends StatefulWidget {
  final String forecastId;
  final String collectionName;
  final String summaryText;
  final Map<String, dynamic> existingAudios;

  const AudioSummaryDialog({
    super.key,
    required this.forecastId,
    required this.collectionName,
    required this.summaryText,
    required this.existingAudios,
  });

  @override
  State<AudioSummaryDialog> createState() => _AudioSummaryDialogState();
}

class _AudioSummaryDialogState extends State<AudioSummaryDialog> {
  late AudioSummaryController controller;

  @override
  void initState() {
    super.initState();
    // 1. Force delete any lingering instance from memory before creating a new one
    Get.delete<AudioSummaryController>(force: true);
    
    // 2. Initialize a fresh controller with the new parameters
    controller = Get.put(AudioSummaryController(
      forecastId: widget.forecastId,
      collectionName: widget.collectionName,
      initialAudios: widget.existingAudios,
    ));
  }

  @override
  void dispose() {
    // 3. Clean up the controller completely when the dialog closes
    Get.delete<AudioSummaryController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Manage Audio Summaries",
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(PhosphorIcons.x()),
                  onPressed: () => Get.back(),
                )
              ],
            ),
            const Divider(height: 32),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Forecast Summary (Read this):",
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                          const SizedBox(height: 8),
                          Text(widget.summaryText, // <-- updated to use widget.summaryText
                              style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.black87)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text("Recordings by Language",
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    ...controller.languages
                        .map((lang) => _buildLanguageRow(controller, lang['code']!, lang['name']!))
                        .toList(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey.shade700)),
                ),
                const SizedBox(width: 16),
                Obx(() => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: controller.isSaving.value ? null : () => controller.saveAndUploadAll(),
                  child: controller.isSaving.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("Save & Upload Changes", style: GoogleFonts.inter(color: Colors.white)),
                )),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageRow(AudioSummaryController controller, String langCode, String langName) {
    return Obx(() {
      bool hasLocal = controller.localBlobUrls.containsKey(langCode);
      bool hasDb = controller.savedDbUrls.containsKey(langCode);
      bool hasAudio = hasLocal || hasDb;
      
      bool isRecordingThis = controller.isRecording.value && controller.activeRecordLang.value == langCode;
      bool isPlayingThis = controller.isPlaying.value && controller.activePlayLang.value == langCode;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isRecordingThis ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isRecordingThis ? Colors.red.shade200 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(langName, style: GoogleFonts.inter(fontWeight: FontWeight.w500))),
            if (hasLocal)
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)), child: Text("New Record", style: GoogleFonts.inter(fontSize: 10, color: Colors.orange.shade800)))
            else if (hasDb)
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)), child: Text("Saved", style: GoogleFonts.inter(fontSize: 10, color: Colors.green.shade800))),
            const Spacer(),
            IconButton(
              icon: Icon(isRecordingThis ? PhosphorIcons.stopCircle(PhosphorIconsStyle.fill) : PhosphorIcons.microphone()),
              color: isRecordingThis ? Colors.red : Colors.grey.shade600,
              tooltip: isRecordingThis ? "Stop Recording" : (hasAudio ? "Overwrite Recording" : "Start Recording"),
              onPressed: () => controller.toggleRecording(langCode),
            ),
            if (hasAudio && !isRecordingThis) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(isPlayingThis ? PhosphorIcons.pauseCircle(PhosphorIconsStyle.fill) : PhosphorIcons.playCircle(PhosphorIconsStyle.fill)),
                color: const Color(0xFF1565C0),
                tooltip: isPlayingThis ? "Pause" : "Preview",
                onPressed: () => controller.toggleAudio(langCode),
              ),
            ],
            if (hasLocal && !isRecordingThis) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(PhosphorIcons.trash()),
                color: Colors.red.shade300,
                tooltip: "Remove New Recording",
                onPressed: () => controller.deleteLocalRecording(langCode),
              ),
            ]
          ],
        ),
      );
    });
  }
}
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:weather_admin_dashboard/app/controllers/audio_summary_controller.dart'; 

// class AudioSummaryDialog extends StatelessWidget {
//   final String forecastId;
//   final String collectionName;
//   final String summaryText;
//   final Map<String, dynamic> existingAudios;

//   const AudioSummaryDialog({
//     super.key,
//     required this.forecastId,
//     required this.collectionName,
//     required this.summaryText,
//     required this.existingAudios,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Initialize the controller specific to this dialog
//     final controller = Get.put(AudioSummaryController(
//       forecastId: forecastId,
//       collectionName: collectionName,
//       initialAudios: existingAudios,
//     ));

//     return  Dialog(
//   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//   backgroundColor: Colors.white,
//   child: Container(
//     width: 600,
//     constraints: const BoxConstraints(maxHeight: 700), // 👈 cap the height
//     padding: const EdgeInsets.all(32),
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // --- HEADER (stays fixed) ---
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text("Manage Audio Summaries",
//                 style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
//             IconButton(
//               icon: Icon(PhosphorIcons.x()),
//               onPressed: () => Get.back(),
//             )
//           ],
//         ),
//         const Divider(height: 32),

//         // --- SCROLLABLE MIDDLE SECTION ---
//         Flexible(                          // 👈 lets this shrink/grow within Column
//           child: SingleChildScrollView(    // 👈 makes content scrollable
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // --- FORECAST SUMMARY BOX ---
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.blueGrey.shade50,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.blueGrey.shade100),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text("Forecast Summary (Read this):",
//                           style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
//                       const SizedBox(height: 8),
//                       Text(summaryText,
//                           style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.black87)),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // --- LANGUAGE ROWS ---
//                 Text("Recordings by Language",
//                     style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
//                 const SizedBox(height: 16),

//                 ...controller.languages
//                     .map((lang) => _buildLanguageRow(controller, lang['code']!, lang['name']!))
//                     .toList(),

//                 const SizedBox(height: 32),
//               ],
//             ),
//           ),
//         ),

//         // --- ACTION BUTTONS (stays fixed at bottom) ---
//         Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             TextButton(
//               onPressed: () => Get.back(),
//               child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey.shade700)),
//             ),
//             const SizedBox(width: 16),
//             Obx(() => ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1565C0),
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               onPressed: controller.isSaving.value ? null : () => controller.saveAndUploadAll(),
//               child: controller.isSaving.value
//                   ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                   : Text("Save & Upload Changes", style: GoogleFonts.inter(color: Colors.white)),
//             )),
//           ],
//         )
//       ],
//     ),
//   ),
// );
//   }

//   Widget _buildLanguageRow(AudioSummaryController controller, String langCode, String langName) {
//     return Obx(() {
//       bool hasLocal = controller.localBlobUrls.containsKey(langCode);
//       bool hasDb = controller.savedDbUrls.containsKey(langCode);
//       bool hasAudio = hasLocal || hasDb;
      
//       bool isRecordingThis = controller.isRecording.value && controller.activeRecordLang.value == langCode;
//       bool isPlayingThis = controller.isPlaying.value && controller.activePlayLang.value == langCode;

//       return Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: isRecordingThis ? Colors.red.shade50 : Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: isRecordingThis ? Colors.red.shade200 : Colors.grey.shade200),
//         ),
//         child: Row(
//           children: [
//             SizedBox(width: 120, child: Text(langName, style: GoogleFonts.inter(fontWeight: FontWeight.w500))),
            
//             // STATUS BADGE
//             if (hasLocal)
//               Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)), child: Text("New Record", style: GoogleFonts.inter(fontSize: 10, color: Colors.orange.shade800)))
//             else if (hasDb)
//               Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)), child: Text("Saved", style: GoogleFonts.inter(fontSize: 10, color: Colors.green.shade800))),
            
//             const Spacer(),

//             // RECORD / STOP RECORD BUTTON
//             IconButton(
//               icon: Icon(isRecordingThis ? PhosphorIcons.stopCircle(PhosphorIconsStyle.fill) : PhosphorIcons.microphone()),
//               color: isRecordingThis ? Colors.red : Colors.grey.shade600,
//               tooltip: isRecordingThis ? "Stop Recording" : (hasAudio ? "Overwrite Recording" : "Start Recording"),
//               onPressed: () => controller.toggleRecording(langCode),
//             ),

//             // PLAY BUTTON (Only if audio exists)
//             if (hasAudio && !isRecordingThis) ...[
//               const SizedBox(width: 8),
//               IconButton(
//                 icon: Icon(isPlayingThis ? PhosphorIcons.pauseCircle(PhosphorIconsStyle.fill) : PhosphorIcons.playCircle(PhosphorIconsStyle.fill)),
//                 color: const Color(0xFF1565C0),
//                 tooltip: isPlayingThis ? "Pause" : "Preview",
//                 onPressed: () => controller.toggleAudio(langCode),
//               ),
//             ],

//             // UNDO/DELETE LOCAL RECORDING
//             if (hasLocal && !isRecordingThis) ...[
//               const SizedBox(width: 8),
//               IconButton(
//                 icon: Icon(PhosphorIcons.trash()),
//                 color: Colors.red.shade300,
//                 tooltip: "Remove New Recording",
//                 onPressed: () => controller.deleteLocalRecording(langCode),
//               ),
//             ]
//           ],
//         ),
//       );
//     });
//   }
// }