import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class UserManagementController extends GetxController {
  final searchQuery = ''.obs;
  final selectedRole = 'All Roles'.obs;
  final selectedStatus = 'All Status'.obs;

  final roles = ['All Roles', 'Admin', 'Meteorologist', 'Forecaster', 'Viewer'];
  final statuses = ['All Status', 'Active', 'Pending', 'Suspended'];

  // Mock Metrics
  final totalUsers = 1245.obs;
  final activeAdmins = 12.obs;
  final pendingApprovals = 8.obs;
  final suspendedAccounts = 3.obs;

  // Mock User Data
  final users = <Map<String, dynamic>>[
    {
      'id': 'USR-001',
      'name': 'Theophilus Kwofie',
      'email': 'tkwofie@meteo.gov',
      'role': 'Admin',
      'status': 'Active',
      'lastLogin': '2 mins ago',
      'initials': 'TK',
      'color1': const Color(0xFF1D4ED8),
      'color2': const Color(0xFF3B82F6),
    },
    {
      'id': 'USR-002',
      'name': 'Abena Nancy Kwofie',
      'email': 'nancy.k@meteo.gov',
      'role': 'Meteorologist',
      'status': 'Active',
      'lastLogin': '1 hour ago',
      'initials': 'AK',
      'color1': const Color(0xFF059669),
      'color2': const Color(0xFF10B981),
    },
    {
      'id': 'USR-003',
      'name': 'Kwame Mensah',
      'email': 'kmensah@meteo.gov',
      'role': 'Forecaster',
      'status': 'Pending',
      'lastLogin': 'Never',
      'initials': 'KM',
      'color1': const Color(0xFFD97706),
      'color2': const Color(0xFFF59E0B),
    },
    {
      'id': 'USR-004',
      'name': 'Sarah Osei',
      'email': 'sosei@meteo.gov',
      'role': 'Viewer',
      'status': 'Suspended',
      'lastLogin': '3 days ago',
      'initials': 'SO',
      'color1': const Color(0xFFDC2626),
      'color2': const Color(0xFFEF4444),
    },
    {
      'id': 'USR-005',
      'name': 'David Addo',
      'email': 'daddo@meteo.gov',
      'role': 'Forecaster',
      'status': 'Active',
      'lastLogin': '5 hours ago',
      'initials': 'DA',
      'color1': const Color(0xFF7C3AED),
      'color2': const Color(0xFF8B5CF6),
    },
  ].obs;

  void updateSearch(String query) => searchQuery.value = query;
  void updateRole(String role) => selectedRole.value = role;
  void updateStatus(String status) => selectedStatus.value = status;

  void deleteUser(String id) {
    Get.defaultDialog(
      title: 'Delete User',
      titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      middleText: 'Are you sure you want to remove this user? This cannot be undone.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      cancelTextColor: AppTheme.dangerRed,
      buttonColor: AppTheme.dangerRed,
      radius: 12,
      onConfirm: () {
        users.removeWhere((u) => u['id'] == id);
        Get.back();
        Get.snackbar(
          'User Deleted',
          'User account has been permanently removed.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppTheme.successGreen.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      },
    );
  }

  void openAddUserModal() {
    Get.snackbar(
      'Add User',
      'Opening user creation modal...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppTheme.accentBlue.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW
// ─────────────────────────────────────────────────────────────────────────────
class UserManagementView extends StatelessWidget {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(UserManagementController());
    final wc = context.wColors;
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ────────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIcons.users(PhosphorIconsStyle.fill),
                  size: 24,
                  color: AppTheme.accentBlue,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Management',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: wc.textPrimary,
                          fontWeight: FontWeight.w800,
                        ) ?? const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage administrator and staff access to the dashboard',
                    style: TextStyle(fontSize: 13, color: wc.textMuted),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: ctrl.openAddUserModal,
                icon: Icon(PhosphorIcons.userPlus(), size: 18),
                label: const Text('Add New User', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppTheme.accentBlue.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // ── KPI METRICS ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Users', ctrl.totalUsers.value.toString(), PhosphorIcons.users(), AppTheme.accentBlue, context)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Active Admins', ctrl.activeAdmins.value.toString(), PhosphorIcons.shieldCheck(), AppTheme.successGreen, context)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Pending Approvals', ctrl.pendingApprovals.value.toString(), PhosphorIcons.clock(), AppTheme.warningAmber, context)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Suspended', ctrl.suspendedAccounts.value.toString(), PhosphorIcons.userMinus(), AppTheme.dangerRed, context)),
            ],
          ),
          
          const SizedBox(height: 32),

          // ── FILTERS & SEARCH ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(context),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    onChanged: ctrl.updateSearch,
                    style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Search users by name or email...',
                      hintStyle: TextStyle(color: wc.textMuted),
                      prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), color: wc.textMuted),
                      filled: true,
                      fillColor: wc.elevated,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5), width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Obx(() => DropdownButtonFormField<String>(
                    value: ctrl.selectedRole.value,
                    dropdownColor: wc.elevated,
                    icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
                    style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                    decoration: _dropdownDecoration(wc),
                    items: ctrl.roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) { if (v != null) ctrl.updateRole(v); },
                  )),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Obx(() => DropdownButtonFormField<String>(
                    value: ctrl.selectedStatus.value,
                    dropdownColor: wc.elevated,
                    icon: Icon(PhosphorIcons.caretDown(), size: 16, color: wc.textMuted),
                    style: TextStyle(color: wc.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                    decoration: _dropdownDecoration(wc),
                    items: ctrl.statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) { if (v != null) ctrl.updateStatus(v); },
                  )),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── USERS TABLE ───────────────────────────────────────────────────
          Container(
            decoration: _cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: wc.elevated, 
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: wc.borderSoft)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _buildHeader("USER", context)),
                      Expanded(flex: 2, child: _buildHeader("ROLE", context)),
                      Expanded(flex: 2, child: _buildHeader("STATUS", context)),
                      Expanded(flex: 2, child: _buildHeader("LAST LOGIN", context)),
                      Expanded(flex: 1, child: _buildHeader("ACTIONS", context, alignRight: true)),
                    ],
                  ),
                ),
                
                // Table Rows
                Obx(() => ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ctrl.users.length, 
                  separatorBuilder: (_, __) => Divider(height: 1, color: wc.borderSoft),
                  itemBuilder: (ctx, idx) {
                    final user = ctrl.users[idx];
                    return _buildUserRow(user, ctrl, context);
                  }
                )),

                // Pagination Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: wc.borderSoft))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Showing 1 to 5 of 1,245 entries", style: TextStyle(fontSize: 12, color: wc.textMuted, fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          _PaginationBtn(icon: PhosphorIcons.caretLeft(), onPressed: (){}),
                          const SizedBox(width: 8),
                          Text("Page 1 of 249", style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary, fontSize: 12)),
                          const SizedBox(width: 8),
                          _PaginationBtn(icon: PhosphorIcons.caretRight(), onPressed: (){}),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPER WIDGETS ────────────────────────────────────────────────────────

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = context.isDark;
    return BoxDecoration(
      color: context.wColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.wColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration(WColors wc) {
    return InputDecoration(
      filled: true,
      fillColor: wc.elevated,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: wc.borderSoft)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.accentBlue.withOpacity(0.5))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: wc.textSecondary)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 32, fontWeight: FontWeight.w800, color: wc.textPrimary, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildHeader(String text, BuildContext context, {bool alignRight = false}) {
    return Text(
      text, 
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontWeight: FontWeight.w800, 
        fontSize: 11, 
        color: context.wColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user, UserManagementController ctrl, BuildContext context) {
    final wc = context.wColors;
    
    // Status Logic
    Color statusColor;
    switch (user['status']) {
      case 'Active': statusColor = AppTheme.successGreen; break;
      case 'Pending': statusColor = AppTheme.warningAmber; break;
      case 'Suspended': statusColor = AppTheme.dangerRed; break;
      default: statusColor = wc.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // User Info (Avatar + Name/Email)
          Expanded(
            flex: 3, 
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [user['color1'], user['color2']], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(user['initials'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'], style: TextStyle(fontWeight: FontWeight.w700, color: wc.textPrimary, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(user['email'], style: TextStyle(color: wc.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Role
          Expanded(
            flex: 2, 
            child: Text(user['role'], style: TextStyle(color: wc.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          
          // Status Pill
          Expanded(
            flex: 2, 
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      user['status'], 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Last Login
          Expanded(
            flex: 2, 
            child: Text(user['lastLogin'], style: TextStyle(color: wc.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          
          // Actions
          Expanded(
            flex: 1, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _TableActionBtn(icon: PhosphorIcons.pencilSimple(), color: AppTheme.accentBlue),
                const SizedBox(width: 6),
                _TableActionBtn(
                  icon: PhosphorIcons.trash(), 
                  color: AppTheme.dangerRed,
                  onTap: () => ctrl.deleteUser(user['id']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  
  const _TableActionBtn({required this.icon, required this.color, this.onTap});

  @override
  State<_TableActionBtn> createState() => _TableActionBtnState();
}

class _TableActionBtnState extends State<_TableActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap ?? (){},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? widget.color.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _hovered ? widget.color : wc.textMuted,
          ),
        ),
      ),
    );
  }
}

class _PaginationBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _PaginationBtn({required this.icon, required this.onPressed});

  @override
  State<_PaginationBtn> createState() => _PaginationBtnState();
}

class _PaginationBtnState extends State<_PaginationBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _hovered ? wc.elevated : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _hovered ? wc.borderSoft : wc.border),
          ),
          child: Icon(widget.icon, size: 16, color: wc.textSecondary),
        ),
      ),
    );
  }
}