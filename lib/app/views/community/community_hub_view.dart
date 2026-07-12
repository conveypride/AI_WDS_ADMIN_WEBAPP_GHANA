// lib/app/views/community_hub_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; 
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // REQUIRED for parsing timestamps
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

import 'package:weather_admin_dashboard/app/controllers/admin_community_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

class AdminCommunityView extends StatelessWidget {
  const AdminCommunityView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AdminCommunityController());
    final wc = context.wColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── TAB BAR ──────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: wc.card,
            border: Border(bottom: BorderSide(color: wc.border)),
          ),
          child: TabBar(
            controller: ctrl.tabController,
            labelColor: AppTheme.accentBlue,
            unselectedLabelColor: wc.textMuted,
            indicatorColor: AppTheme.accentBlue,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, 
              fontSize: 13,
              letterSpacing: 0.5,
            ),
            tabs: [
              Tab(icon: Icon(PhosphorIcons.usersThree()), text: "GROUPS MANAGEMENT"),
              Tab(icon: Icon(PhosphorIcons.chartLineUp()), text: "INTELLIGENCE & ANALYTICS"),
            ],
          ),
        ),
        
        // ── TAB CONTENT ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: ctrl.tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _GroupsManagementTab(ctrl: ctrl),
              _MapAnalyticsTab(ctrl: ctrl),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 1: GROUPS MANAGEMENT (MASTER-DETAIL)
// ============================================================================
class _GroupsManagementTab extends StatelessWidget {
  final AdminCommunityController ctrl;
  const _GroupsManagementTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;

    return Row(
      children: [
        // ── LEFT PANEL: List of Groups ────────────────────────────────────────
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: wc.card,
            border: Border(right: BorderSide(color: wc.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Community Channels", 
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: wc.textPrimary,
                      ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (ctrl.groups.isEmpty) {
                     return Center(
                       child: Text("No groups found for ${ctrl.currentAdminDepartment}.", 
                         style: TextStyle(color: wc.textMuted, fontSize: 14), textAlign: TextAlign.center),
                     );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: ctrl.groups.length + 1, // +1 for the Create Button
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildCreateGroupButton(context);
                      
                      final group = ctrl.groups[index - 1];
                      final isSelected = ctrl.selectedGroupId.value == group['id'];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (group['color'] as Color).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(group['icon'], color: group['color'], size: 20),
                          ),
                          title: Text(
                            group['name'] ?? 'Unnamed Group', 
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, 
                              color: wc.textPrimary,
                              fontSize: 14,
                            ), 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            "${group['subscribers']} members • ${group['type'].toString().capitalizeFirst} • Target: ${group['target_role']?.toString().capitalizeFirst ?? 'General'}", 
                            style: TextStyle(fontSize: 12, color: wc.textMuted, fontWeight: FontWeight.w500),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppTheme.accentBlue.withOpacity(0.08),
                          hoverColor: wc.elevated,
                          onTap: () => ctrl.selectGroup(group['id']),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),

        // ── RIGHT PANEL: Active Group Feed & Controls ─────────────────────────
        Expanded(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Obx(() {
              if (ctrl.selectedGroupId.value == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill), size: 48, color: wc.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        "Select a group to manage", 
                        style: TextStyle(color: wc.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }
              if (ctrl.isChatLoading.value) {
                return Center(child: CircularProgressIndicator(color: AppTheme.accentBlue));
              }

              final group = ctrl.groups.firstWhere((g) => g['id'] == ctrl.selectedGroupId.value, orElse: () => {});
              if (group.isEmpty) return const SizedBox();

              return Column(
                children: [
                  // Chat Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: wc.card, 
                      border: Border(bottom: BorderSide(color: wc.borderSoft)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (group['color'] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(group['icon'], color: group['color'], size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group['name'] ?? 'Unnamed', 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: wc.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                group['type'] == 'official' ? "Official Control Center" : "Social Group Moderation", 
                                style: TextStyle(fontSize: 12, color: wc.textMuted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        // Global Group Actions
                        OutlinedButton.icon(
                          onPressed: () => _showGroupSettingsDialog(context, group, ctrl), // <--- UPDATED
                          icon: Icon(PhosphorIcons.gearSix(), size: 16), 
                          label: const Text("Group Settings", style: TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: wc.textPrimary,
                            side: BorderSide(color: wc.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chat Feed
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(32),
                      reverse: true,
                      itemCount: ctrl.activeChatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = ctrl.activeChatMessages[index];
                        return _buildAdminMessageCard(msg, context);
                      },
                    ),
                  ),

                  
                  // Admin Input Area (Upgraded with Media Preview & Pickers)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: wc.card,
                      border: Border(top: BorderSide(color: wc.borderSoft)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PREVIEW AREA: Shows selected file before sending
                        Obx(() {
                          if (ctrl.selectedFileBytes.value == null) return const SizedBox.shrink();
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: wc.elevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.accentBlue.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ctrl.selectedMediaType.value == 'image' ? PhosphorIcons.image() : PhosphorIcons.filePdf(),
                                  color: AppTheme.accentBlue,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    ctrl.selectedFileName.value,
                                    style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: ctrl.clearSelectedMedia,
                                  child: Icon(PhosphorIcons.xCircle(PhosphorIconsStyle.fill), color: wc.textMuted),
                                )
                              ],
                            ),
                          );
                        }),

// -- REPLYING TO PREVIEW UI --
                        Obx(() {
                          if (ctrl.replyToMessage.value == null) return const SizedBox.shrink();
                          final replyMsg = ctrl.replyToMessage.value!;
                          String content = replyMsg['content'] ?? '';
                          if (content.isEmpty) content = "Attached ${replyMsg['type']}";
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(PhosphorIcons.arrowBendDownRight(), color: AppTheme.accentBlue, size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Replying to ${replyMsg['author_name'] ?? 'User'}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.accentBlue)),
                                      Text(content, style: TextStyle(color: wc.textPrimary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(PhosphorIcons.x(), color: wc.textMuted, size: 18),
                                  onPressed: ctrl.cancelReply,
                                )
                              ],
                            ),
                          );
                        }),
                        // INPUT ROW
                        Row(
                          children: [
                            // ATTACHMENT MENU
                            PopupMenuButton<String>(
                              icon: Icon(PhosphorIcons.paperclip(), color: wc.textMuted),
                              color: wc.elevated,
                              offset: const Offset(0, -120),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: wc.borderSoft)),
                              onSelected: (value) {
                                if (value == 'image') ctrl.pickAdminImage();
                                if (value == 'file') ctrl.pickAdminDocument();
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'image', child: Row(children: [Icon(PhosphorIcons.image(), color: wc.textPrimary, size: 20), const SizedBox(width: 12), Text("Attach Image", style: TextStyle(color: wc.textPrimary))])),
                                PopupMenuItem(value: 'file', child: Row(children: [Icon(PhosphorIcons.filePdf(), color: wc.textPrimary, size: 20), const SizedBox(width: 12), Text("Attach Document", style: TextStyle(color: wc.textPrimary))])),
                              ],
                            ),
                            const SizedBox(width: 8),
                            
                            // TEXT FIELD
                            Expanded(
                              child: TextField(
                                controller: ctrl.chatTextController,
                                style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: "Broadcast official message or reply...",
                                  hintStyle: TextStyle(color: wc.textMuted),
                                  filled: true, 
                                  fillColor: wc.elevated,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                ),
                                onSubmitted: (_) => ctrl.sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // SEND BUTTON (With Loading State)
                            Obx(() => FloatingActionButton(
                              elevation: 0,
                              backgroundColor: ctrl.isUploading.value ? wc.textMuted : AppTheme.accentBlue,
                              onPressed: ctrl.isUploading.value ? null : ctrl.sendMessage,
                              child: ctrl.isUploading.value 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Icon(PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill), color: Colors.white, size: 20),
                            ))
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateGroupButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0, left: 4, right: 4),
      child: InkWell(
        onTap: () => _showCreateGroupDialog(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.accentBlue.withOpacity(0.5), style: BorderStyle.solid, width: 1.5), 
            borderRadius: BorderRadius.circular(10), 
            color: AppTheme.accentBlue.withOpacity(0.05),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.plusCircle(), color: AppTheme.accentBlue),
              const SizedBox(width: 8),
              const Text(
                "Create New Group", 
                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accentBlue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final wc = context.wColors;
    String name = "";
    String type = "Official"; 
    
    // Dynamically get allowed roles based on department and capitalize for UI
    List<String> availableTargetRoles = ctrl.allowedTargetRoles.map((e) => e.capitalizeFirst!).toList();
    String targetRole = availableTargetRoles.isNotEmpty ? availableTargetRoles.first : "General";

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: wc.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: wc.border),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Create Community Group", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: wc.textPrimary)),
                  const SizedBox(height: 6),
                  
                  // Shows the admin exactly which department they are binding to
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      "Department: ${ctrl.currentAdminDepartment}", 
                      style: const TextStyle(fontSize: 12, color: AppTheme.accentBlue, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    decoration: _inputDecoration("Group Name", wc), 
                    style: TextStyle(color: wc.textPrimary),
                    onChanged: (v) => name = v,
                  ),
                  const SizedBox(height: 16),
                  
                  // DROPDOWN 1: Group Type (Official vs Social)
                  DropdownButtonFormField<String>(
                    value: type, 
                    dropdownColor: wc.elevated,
                    style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                    items: ["Official", "Social"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {
                      setState(() => type = v!);
                    }, 
                    decoration: _inputDecoration("Group Type", wc),
                  ),
                  const SizedBox(height: 16),

                  // DROPDOWN 2: Target Audience (Restricted by Department)
                  DropdownButtonFormField<String>(
                    initialValue: targetRole, 
                    dropdownColor: wc.elevated,
                    style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                    items: availableTargetRoles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {
                      setState(() => targetRole = v!);
                    }, 
                    decoration: _inputDecoration("Target Audience", wc),
                  ),
                  const SizedBox(height: 12),
                  
                  // Helper Context
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(PhosphorIcons.info(), size: 16, color: wc.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          type == "Official" 
                            ? "Only Admins can post. Target audience will only read and comment."
                            : "All end-users in the target audience can create posts and interact.",
                          style: TextStyle(fontSize: 12, color: wc.textMuted, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(), 
                        style: TextButton.styleFrom(foregroundColor: wc.textSecondary),
                        child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (name.trim().isNotEmpty) {
                             ctrl.createNewGroup(name.trim(), type, targetRole);
                          } else {
                             Get.snackbar("Required", "Please enter a group name", backgroundColor: AppTheme.warningAmber, colorText: Colors.white);
                          }
                        }, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Create", style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  )
                ],
              );
            }
          ),
        ),
      )
    );
  }

void _openMediaLink(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    try {
      final Uri uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        // LaunchMode.externalApplication forces it to open in a new browser tab safely
        await launchUrl(uri, mode: LaunchMode.externalApplication); 
      } else {
        Get.snackbar("Error", "Could not open the file link.", backgroundColor: AppTheme.dangerRed, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Invalid file link.", backgroundColor: AppTheme.dangerRed, colorText: Colors.white);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SMART TIMESTAMP FORMATTER (INSIDE CLASS)
  // ─────────────────────────────────────────────────────────────────────────────
  String _formatSmartTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return "Just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}min ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else if (diff.inDays == 1) {
      return "Yesterday ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } else if (diff.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return "${weekdays[dt.weekday - 1]} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } else {
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ADMIN MESSAGE CARD BUILDER
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildAdminMessageCard(Map<String, dynamic> msg, BuildContext context) {
    final wc = context.wColors;
    bool isAdminMsg = msg['is_admin'] == true;
    final currentUserId = ctrl.currentAdminId;
    
    // SMART TIMESTAMP PARSING
    String timeString = "Just now";
    if (msg['timestamp'] != null) {
      if (msg['timestamp'] is Timestamp) {
        DateTime dt = (msg['timestamp'] as Timestamp).toDate();
        timeString = _formatSmartTimestamp(dt);
      } else if (msg['timestamp'] is String) {
        timeString = msg['timestamp']; 
      }
    }

    // MATCHING YOUR SCHEMA FIELDS
    String authorName = msg['author_name'] ?? msg['author'] ?? 'Community Member'; 
    String authorId = msg['author_id'] ?? '';
    bool isOwnMessage = authorId == currentUserId;
    String type = msg['type'] ?? 'text';
    String content = msg['content'] ?? '';
    String? mediaUrl = msg['media_url'];
    

// DYNAMIC MESSAGE BODY BUILDER
  Widget buildMessageBody() {
    if (type == 'audio') {
        // 1. Wrapped in InkWell to make the whole pill clickable
        return InkWell(
          onTap: () => _openMediaLink(mediaUrl),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAdminMsg ? AppTheme.accentBlue.withOpacity(0.1) : wc.elevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isAdminMsg ? AppTheme.accentBlue.withOpacity(0.3) : wc.borderSoft),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.playCircle(PhosphorIconsStyle.fill), color: isAdminMsg ? AppTheme.accentBlue : wc.textPrimary, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Voice Message", style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text("Click to play in browser", style: TextStyle(color: wc.textMuted, fontSize: 11)), // Updated text
                  ],
                ),
                const SizedBox(width: 32),
                Icon(PhosphorIcons.waveform(), color: wc.textMuted),
              ],
            ),
          ),
        );
      } else if (type == 'file') {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
             color: wc.elevated,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: wc.borderSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.dangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(PhosphorIcons.filePdf(PhosphorIconsStyle.fill), color: AppTheme.dangerRed),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content, style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("Document attachment", style: TextStyle(color: wc.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(PhosphorIcons.downloadSimple(), color: AppTheme.accentBlue),
                // 2. Added the link trigger here
                onPressed: () => _openMediaLink(mediaUrl),
              )
            ],
          ),
        );
      } else if (type == 'image') {
         return GestureDetector(
           onTap: () {
             if (mediaUrl != null && mediaUrl.isNotEmpty) {
               Get.dialog(
                 Dialog(
                   backgroundColor: Colors.transparent,
                   insetPadding: const EdgeInsets.all(16),
                   child: Stack(
                     alignment: Alignment.center,
                     children: [
                       InteractiveViewer(
                         panEnabled: true,
                         minScale: 0.8,
                         maxScale: 4.0,
                         child: ClipRRect(
                           borderRadius: BorderRadius.circular(16),
                           child: Image.network(mediaUrl),
                         ),
                       ),
                       Positioned(
                         top: 0,
                         right: 0,
                         child: IconButton(
                           icon: Container(
                             padding: const EdgeInsets.all(8),
                             decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                             child: const Icon(Icons.close, color: Colors.white, size: 24),
                           ),
                           onPressed: () => Get.back(),
                         ),
                       )
                     ],
                   ),
                 ),
               );
             }
           },
           child: Container(
             padding: const EdgeInsets.all(4),
             decoration: BoxDecoration(
               color: isAdminMsg ? AppTheme.accentBlue.withOpacity(0.15) : wc.elevated,
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: isAdminMsg ? AppTheme.accentBlue.withOpacity(0.3) : wc.borderSoft),
             ),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(12),
               child: Image.network(
                 mediaUrl ?? '', 
                 height: 200, 
                 width: 250, 
                 fit: BoxFit.cover,
                 loadingBuilder: (context, child, loadingProgress) {
                   if (loadingProgress == null) return child;
                   return Container(
                     height: 200, width: 250, color: wc.elevated,
                     child: Center(
                       child: CircularProgressIndicator(
                         color: AppTheme.accentBlue,
                         value: loadingProgress.expectedTotalBytes != null
                             ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                             : null,
                       ),
                     ),
                   );
                 },
                 // We added debugPrint here to print the exact reason for failure to your console!
                 errorBuilder: (context, error, stackTrace) {
                   debugPrint("❌ Image Load Error: $error"); 
                   return Container(
                     height: 200, width: 250, color: wc.elevated,
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(PhosphorIcons.imageBroken(), color: wc.textMuted, size: 32),
                         const SizedBox(height: 8),
                         Text("Image unavailable", style: TextStyle(color: wc.textMuted, fontSize: 12)),
                       ],
                     ),
                   );
                 }
               ),
             ),
           ),
         );
      }
      
      // Default: TEXT
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isAdminMsg ? AppTheme.accentBlue.withOpacity(0.08) : wc.card, 
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ), 
          border: Border.all(color: isAdminMsg ? AppTheme.accentBlue.withOpacity(0.3) : wc.borderSoft),
        ),
        child: Text(
          content, 
          style: TextStyle(color: wc.textPrimary, height: 1.5, fontWeight: FontWeight.w500),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAdminMsg ? AppTheme.accentBlue.withOpacity(0.15) : wc.elevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAdminMsg ? PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill) : PhosphorIcons.user(PhosphorIconsStyle.fill), 
              color: isAdminMsg ? AppTheme.accentBlue : wc.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      authorName, 
                      style: TextStyle(
                        fontWeight: FontWeight.w700, 
                        color: isAdminMsg ? AppTheme.accentBlue : wc.textPrimary,
                        fontSize: 14,
                      )
                    ),
                    if (msg['author_role'] != null && !isAdminMsg) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: wc.elevated, borderRadius: BorderRadius.circular(4)),
                        child: Text(msg['author_role'].toString().capitalizeFirst ?? '', style: TextStyle(fontSize: 10, color: wc.textMuted)),
                      )
                    ],
                    const SizedBox(width: 12),
                    Text(
                      timeString, 
                      style: TextStyle(fontSize: 11, color: wc.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // -- START OF NEW REPLY RENDERER --
                if (msg['reply_to_id'] != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 16),
                    decoration: BoxDecoration(
                      color: wc.elevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(left: BorderSide(color: AppTheme.accentBlue, width: 4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['reply_to_author'] ?? 'Unknown',
                          style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['reply_to_content'] ?? '',
                          style: TextStyle(color: wc.textMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              
                buildMessageBody(), // <--- Calls the dynamic UI builder we created above
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ADMIN POWER CONTROLS
          PopupMenuButton<String>(
            icon: Icon(PhosphorIcons.dotsThreeVertical(), color: wc.textMuted),
            color: wc.elevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: wc.borderSoft)),
            onSelected: (action) {
             if (action == 'reply') ctrl.setReplyTo(msg); // <--- ADD THIS
              if (action == 'delete') ctrl.deleteMessage(msg['id']);
              if (action == 'ban') ctrl.banUser(authorId, authorName);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'reply', child: Text("Reply to Post", style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500))),
              if (isAdminMsg || isOwnMessage) PopupMenuItem(value: 'delete', child: Text("Delete Post", style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.w600))),
              if (!isAdminMsg && !isOwnMessage) PopupMenuItem(value: 'ban', child: Text("Ban User", style: TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.w600))),
            ],
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, WColors wc) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: wc.textSecondary),
      filled: true,
      fillColor: wc.elevated,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: wc.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5), width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: wc.borderSoft),
      ),
    );
  }

  void _showGroupSettingsDialog(BuildContext context, Map<String, dynamic> group, AdminCommunityController ctrl) {
    final wc = context.wColors;
    
    // Pre-fill existing data
    String name = group['name'] ?? '';
    String type = (group['type'] ?? 'official').toString().capitalizeFirst!;
    String targetRole = (group['target_role'] ?? 'general').toString().capitalizeFirst!;
    
    List<String> availableTargetRoles = ctrl.allowedTargetRoles.map((e) => e.capitalizeFirst!).toList();
    if (!availableTargetRoles.contains(targetRole)) availableTargetRoles.add(targetRole); // Failsafe

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: wc.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: wc.border)),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Group Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: wc.textPrimary)),
                      // DELETE BUTTON IN THE HEADER
                      TextButton.icon(
                        onPressed: () {
                          Get.defaultDialog(
                            title: "Delete Group?",
                            middleText: "This action cannot be undone and will remove all messages.",
                            textConfirm: "Delete Forever",
                            confirmTextColor: Colors.white,
                            buttonColor: AppTheme.dangerRed,
                            onConfirm: () => ctrl.deleteGroup(group['id']),
                          );
                        }, 
                        icon: const Icon(Icons.delete_outline, size: 16), 
                        label: const Text("Delete Group"),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // NAME FIELD
                  TextFormField(
                    initialValue: name,
                    decoration: _inputDecoration("Group Name", wc), 
                    style: TextStyle(color: wc.textPrimary),
                    onChanged: (v) => name = v,
                  ),
                  const SizedBox(height: 16),
                  
                  // TYPE DROPDOWN
                  DropdownButtonFormField<String>(
                    value: type, 
                    dropdownColor: wc.elevated,
                    style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                    items: ["Official", "Social"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => type = v!), 
                    decoration: _inputDecoration("Group Type", wc),
                  ),
                  const SizedBox(height: 16),

                  // TARGET ROLE DROPDOWN
                  DropdownButtonFormField<String>(
                    value: targetRole, 
                    dropdownColor: wc.elevated,
                    style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                    items: availableTargetRoles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => targetRole = v!), 
                    decoration: _inputDecoration("Target Audience", wc),
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(), 
                        child: Text("Cancel", style: TextStyle(color: wc.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (name.trim().isNotEmpty) {
                             ctrl.updateGroupSettings(group['id'], name.trim(), type, targetRole);
                          }
                        }, 
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue, foregroundColor: Colors.white),
                        child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  )
                ],
              );
            }
          ),
        ),
      )
    );
  }
}

// ============================================================================
// TAB 2: INTELLIGENCE MAP & ADVANCED ANALYTICS 
// ============================================================================
class _MapAnalyticsTab extends StatelessWidget {
  final AdminCommunityController ctrl;
  const _MapAnalyticsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Stack(
      children: [
        Positioned.fill(
          child: Obx(() => FlutterMap(
            mapController: ctrl.mapController,
            options: const MapOptions(initialCenter: LatLng(7.9465, -1.0232), initialZoom: 6.5),
            children: [
              ColorFiltered(
                colorFilter: isDark 
                  ? const ColorFilter.matrix([
                      0.28, 0.28, 0.28, 0, -30,
                      0.28, 0.28, 0.28, 0, -30,
                      0.28, 0.28, 0.28, 0, -30,
                      0,    0,    0,    1,   0,
                    ]) 
                  : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                child: TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', 
                  userAgentPackageName: 'com.gmet.weather'
                ),
              ),
              if (ctrl.showHeatmap.value)
                MarkerLayer(
                  markers: ctrl.userDensity.map((density) => Marker(
                    point: LatLng(density['lat'], density['lng']),
                    width: density['radius'] * 2, height: density['radius'] * 2,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.dangerRed.withOpacity(density['intensity']),
                            AppTheme.dangerRed.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              if (ctrl.showLiveUsers.value)
                MarkerLayer(
                  markers: ctrl.liveUsers.map((user) => Marker(
                    point: LatLng(user['lat'], user['lng']),
                    width: 36,  // Increased from 24 to safely fit the borders and shadow
                    height: 36, // Increased from 24
                    child: Container( // Removed the unnecessary Column wrapper
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: user['color'], 
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.white, width: 2), 
                        boxShadow: [
                          BoxShadow(
                            color: (user['color'] as Color).withOpacity(0.6), 
                            blurRadius: 8, 
                            spreadRadius: 2
                          )
                        ],
                      ),
                      child: Icon(
                        PhosphorIcons.user(PhosphorIconsStyle.fill), 
                        color: Colors.white, 
                        size: 16
                      ),
                    ),
                  )).toList(),
                ),
              if (ctrl.showReports.value)
                MarkerLayer(
                  markers: ctrl.citizenReports.map((report) => Marker(
                    point: LatLng(report['lat'], report['lng']), width: 60, height: 60,
                    child: Tooltip(
                      message: "${report['type']}: ${report['desc']} (${report['time']})",
                      preferBelow: false,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getReportColor(report['type']).withOpacity(0.6),
                              blurRadius: 12, spreadRadius: 4,
                            )
                          ]
                        ),
                        child: CircleAvatar(
                          backgroundColor: _getReportColor(report['type']),
                          child: Icon(_getReportIcon(report['type']), color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  )).toList(),
                )
            ],
          )),
        ),
        Positioned(
          top: 24, left: 24,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.85), 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: wc.border.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    _buildMapToggle("Heatmap", PhosphorIcons.fire(), ctrl.showHeatmap, context),
                    _buildMapToggle("Live Activity", PhosphorIcons.users(), ctrl.showLiveUsers, context),
                    _buildMapToggle("Reports", PhosphorIcons.warningCircle(), ctrl.showReports, context),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 24, bottom: 24, right: 24,
          width: 380, 
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151E32).withOpacity(0.85) : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: wc.borderSoft.withOpacity(0.5), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Live Intelligence", 
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: wc.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(child: _buildMiniKPI("Total Users", ctrl.totalUsers.value, AppTheme.accentBlue, context)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildMiniKPI("Active Now", ctrl.activeReporters.value, AppTheme.successGreen, context)),
                        ],
                      ),
                      const SizedBox(height: 36),
                      Text("Engagement Trend (7 Days)", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary, fontSize: 13)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false), 
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: ctrl.engagementTrend.map((e) => FlSpot(e['day']!, e['value']!)).toList(),
                                isCurved: true,
                                color: AppTheme.accentBlue,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppTheme.accentBlue.withOpacity(0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text("Citizen Report Types", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textSecondary, fontSize: 13)),
                      const SizedBox(height: 20),
                     // DYNAMIC PIE CHART
                      SizedBox(
                        height: 180,
                        child: ctrl.reportDistribution.isEmpty || ctrl.citizenReports.isEmpty
                         ? Center(child: Text("No recent reports", style: TextStyle(color: wc.textMuted)))
                         : Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 2, centerSpaceRadius: 55,
                                  sections: [
                                    PieChartSectionData(
                                      color: AppTheme.accentBlue, 
                                      value: ctrl.reportDistribution['Rain/Flood'] ?? 0, 
                                      title: '${(ctrl.reportDistribution['Rain/Flood'] ?? 0).toStringAsFixed(0)}%', // Dynamic Title
                                      radius: 22, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)
                                    ),
                                    PieChartSectionData(
                                      color: AppTheme.warningAmber, 
                                      value: ctrl.reportDistribution['Storm'] ?? 0, 
                                      title: '${(ctrl.reportDistribution['Storm'] ?? 0).toStringAsFixed(0)}%', // Dynamic Title
                                      radius: 22, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)
                                    ),
                                    PieChartSectionData(
                                      color: AppTheme.dangerRed, 
                                      value: ctrl.reportDistribution['Drought'] ?? 0, 
                                      title: '${(ctrl.reportDistribution['Drought'] ?? 0).toStringAsFixed(0)}%', // Dynamic Title
                                      radius: 22, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)
                                    ),
                                    PieChartSectionData(
                                      color: AppTheme.darkTextSecondary, 
                                      value: ctrl.reportDistribution['Other'] ?? 0, 
                                      title: '${(ctrl.reportDistribution['Other'] ?? 0).toStringAsFixed(0)}%', // Dynamic Title
                                      radius: 22, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // DYNAMIC TOTAL NUMBER IN THE CENTER
                                  Text(ctrl.totalUsers.value, style: TextStyle(fontFamily: 'Syne', fontSize: 28, fontWeight: FontWeight.w900, color: wc.textPrimary)),
                                  Text("Reports", style: TextStyle(fontSize: 11, color: wc.textMuted, fontWeight: FontWeight.w600)),
                                ],
                              )
                            ],
                          ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16, runSpacing: 12,
                        children: [
                         // 1. UPDATED THIS LABEL TO "Rain / Flood"
                          _buildLegendItem(AppTheme.accentBlue, "Rain / Flood", context), 
                          _buildLegendItem(AppTheme.warningAmber, "Storm", context),
                          _buildLegendItem(AppTheme.dangerRed, "Drought", context),
                          _buildLegendItem(AppTheme.darkTextSecondary, "Other", context),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapToggle(String label, IconData icon, RxBool toggle, BuildContext context) {
    final wc = context.wColors;
    return Obx(() {
      final isSelected = toggle.value;
      return InkWell(
        onTap: () => toggle.value = !toggle.value,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4), 
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentBlue.withOpacity(0.15) : Colors.transparent, 
            borderRadius: BorderRadius.circular(10)
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? AppTheme.accentBlue : wc.textMuted), 
              const SizedBox(width: 8),
              Text(
                label, 
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, 
                  color: isSelected ? AppTheme.accentBlue : wc.textSecondary,
                )
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMiniKPI(String title, String value, Color color, BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: wc.elevated.withOpacity(0.5), 
        border: Border.all(color: wc.borderSoft),
        borderRadius: BorderRadius.circular(16)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: wc.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.wColors.textSecondary)),
      ],
    );
  }

  Color _getReportColor(String type) {
    // Explicitly check for "rain"
    if (type.toLowerCase().contains('rain') || type.toLowerCase().contains('flood')) return AppTheme.accentBlue;
    if (type.toLowerCase().contains('storm') || type.toLowerCase().contains('wind')) return AppTheme.warningAmber;
    if (type.toLowerCase().contains('drought') || type.toLowerCase().contains('heat')) return AppTheme.dangerRed;
    return AppTheme.darkTextSecondary;
  }

  IconData _getReportIcon(String type) {
    // Upgraded the icon to cloudRain to better represent both Rain and Floods
    if (type.toLowerCase().contains('rain') || type.toLowerCase().contains('flood')) return PhosphorIcons.cloudRain(PhosphorIconsStyle.fill);
    if (type.toLowerCase().contains('storm') || type.toLowerCase().contains('wind')) return PhosphorIcons.wind(PhosphorIconsStyle.fill);
    if (type.toLowerCase().contains('drought') || type.toLowerCase().contains('heat')) return PhosphorIcons.sun(PhosphorIconsStyle.fill);
    return PhosphorIcons.warningCircle(PhosphorIconsStyle.fill);
  }
}