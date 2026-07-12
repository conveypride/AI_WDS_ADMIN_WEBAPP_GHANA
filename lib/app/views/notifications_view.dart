import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:intl/intl.dart';
import 'package:weather_admin_dashboard/app/controllers/notifications_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(NotificationsController());

    return Column(
      children: [
        _NotifHeader(ctrl: ctrl),
        _NotifTabBar(ctrl: ctrl),
        Expanded(
          child: TabBarView(
            controller: ctrl.tabController,
            children: [
              _NotifList(ctrl: ctrl, showUnread: true),
              _NotifList(ctrl: ctrl, showUnread: false),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _NotifHeader extends StatelessWidget {
  final NotificationsController ctrl;
  const _NotifHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 28, 28, 20),
      decoration: BoxDecoration(
        color: wc.card,
        border: Border(bottom: BorderSide(color: wc.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              PhosphorIcons.bell(PhosphorIconsStyle.fill),
              size: 22,
              color: AppTheme.accentBlue,
            ),
          ),
          const SizedBox(width: 14),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: wc.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Obx(() {
                  final unread = ctrl.unreadNotifications.length;
                  return Text(
                    unread > 0
                        ? '$unread unread alert${unread == 1 ? '' : 's'} need your attention'
                        : 'You\'re all caught up — no unread notifications',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: wc.textMuted),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Mark all read button
          Obx(() {
            final hasUnread = ctrl.unreadNotifications.isNotEmpty;
            return _HeaderAction(
              label: 'Mark all read',
              icon: PhosphorIcons.checks(),
              enabled: hasUnread,
              onTap: hasUnread ? ctrl.markAllAsRead : null,
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _HeaderAction({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_HeaderAction> createState() => _HeaderActionState();
}

class _HeaderActionState extends State<_HeaderAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final active = widget.enabled && (_hovered);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.successGreen.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? AppTheme.successGreen.withOpacity(0.4)
                  : (widget.enabled ? wc.borderSoft : wc.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.enabled
                    ? (active ? AppTheme.successGreen : wc.textSecondary)
                    : wc.textMuted,
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: widget.enabled
                          ? (active ? AppTheme.successGreen : wc.textSecondary)
                          : wc.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM TAB BAR
// ─────────────────────────────────────────────────────────────────────────────
class _NotifTabBar extends StatelessWidget {
  final NotificationsController ctrl;
  const _NotifTabBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return Container(
      color: wc.card,
      child: TabBar(
        controller: ctrl.tabController,
        labelColor: AppTheme.accentBlue,
        unselectedLabelColor: wc.textSecondary,
        indicatorColor: AppTheme.accentBlue,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: wc.border,
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.accentBlue,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
            ),
        unselectedLabelStyle:
            Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: wc.textSecondary,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('UNREAD'),
                const SizedBox(width: 8),
                Obx(() {
                  final count = ctrl.unreadNotifications.length;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('READ'),
                const SizedBox(width: 8),
                Obx(() {
                  final count = ctrl.readNotifications.length;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.wColors.textMuted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION LIST
// ─────────────────────────────────────────────────────────────────────────────
class _NotifList extends StatelessWidget {
  final NotificationsController ctrl;
  final bool showUnread;

  const _NotifList({required this.ctrl, required this.showUnread});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Obx(() {
        final list =
            showUnread ? ctrl.unreadNotifications : ctrl.readNotifications;

        if (list.isEmpty) {
          return _EmptyState(showUnread: showUnread);
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 28,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final notif = list[index];
                return _NotifCard(ctrl: ctrl, notif: notif);
              },
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool showUnread;
  const _EmptyState({required this.showUnread});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: wc.elevated,
              shape: BoxShape.circle,
              border: Border.all(color: wc.border),
            ),
            child: Icon(
              showUnread
                  ? PhosphorIcons.bellZ(PhosphorIconsStyle.fill)
                  : PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              size: 36,
              color: wc.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            showUnread ? 'All caught up!' : 'No read notifications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: wc.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            showUnread
                ? 'No new notifications right now.\nCheck back later.'
                : 'Notifications you\'ve already read will appear here.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: wc.textMuted, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _NotifCard extends StatefulWidget {
  final NotificationsController ctrl;
  final Map<String, dynamic> notif;

  const _NotifCard({required this.ctrl, required this.notif});

  @override
  State<_NotifCard> createState() => _NotifCardState();
}

class _NotifCardState extends State<_NotifCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    // Stagger entrance animation
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── derive type styles ────────────────────────────────────────────────────
  _TypeStyle _getTypeStyle(String type) {
    switch (type) {
      case 'success':
        return _TypeStyle(
          color: AppTheme.successGreen,
          bg: AppTheme.successGreen.withOpacity(0.1),
          icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
          label: 'Success',
        );
      case 'warning':
        return _TypeStyle(
          color: AppTheme.warningAmber,
          bg: AppTheme.warningAmber.withOpacity(0.1),
          icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
          label: 'Warning',
        );
      case 'alert':
        return _TypeStyle(
          color: AppTheme.dangerRed,
          bg: AppTheme.dangerRed.withOpacity(0.1),
          icon: PhosphorIcons.bellRinging(PhosphorIconsStyle.fill),
          label: 'Alert',
        );
      default:
        return _TypeStyle(
          color: AppTheme.infoCyan,
          bg: AppTheme.infoCyan.withOpacity(0.1),
          icon: PhosphorIcons.info(PhosphorIconsStyle.fill),
          label: 'Info',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;
    final notif = widget.notif;
    final bool isRead = notif['isRead'] as bool;
    final ts = _getTypeStyle(notif['type'] as String);

    return FadeTransition(
      opacity: _slideAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_slideAnim),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () {
              if (!isRead) widget.ctrl.markAsRead(notif['id'] as String);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isRead
                    ? (_hovered ? wc.elevated : wc.card)
                    : (_hovered
                        ? AppTheme.accentBlue.withOpacity(isDark ? 0.1 : 0.06)
                        : AppTheme.accentBlue.withOpacity(isDark ? 0.07 : 0.04)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRead
                      ? (_hovered ? wc.borderSoft : wc.border)
                      : AppTheme.accentBlue.withOpacity(isDark ? 0.25 : 0.2),
                  width: isRead ? 1 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: _hovered ? 20 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Accent bar ─────────────────────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 4,
                      decoration: BoxDecoration(
                        color: isRead
                            ? Colors.transparent
                            : ts.color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                    ),

                    // ── Card content ───────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type icon
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: ts.bg,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(ts.icon, color: ts.color, size: 20),
                            ),
                            const SizedBox(width: 14),

                            // Text content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif['title'] as String,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: wc.textPrimary,
                                                fontWeight: isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.w800,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Timestamp + unread dot
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!isRead) ...[
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentBlue,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.accentBlue
                                                        .withOpacity(0.5),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            _formatTimestamp(
                                                notif['timestamp']
                                                    as DateTime),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: isRead
                                                      ? wc.textMuted
                                                      : AppTheme.accentBlue,
                                                  fontWeight: isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notif['message'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: wc.textSecondary,
                                          height: 1.55,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),

                                  // Bottom meta row
                                  Row(
                                    children: [
                                      // Type pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: ts.bg,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          ts.label.toUpperCase(),
                                          style: TextStyle(
                                            color: ts.color,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!isRead)
                                        GestureDetector(
                                          onTap: () => widget.ctrl.markAsRead(
                                              notif['id'] as String),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentBlue
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'MARK READ',
                                              style: TextStyle(
                                                color: AppTheme.accentBlue,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Delete button
                            const SizedBox(width: 6),
                            _DeleteBtn(
                              onTap: () => widget.ctrl.deleteNotification(
                                  notif['id'] as String),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(timestamp);
  }
}

class _TypeStyle {
  final Color color;
  final Color bg;
  final IconData icon;
  final String label;
  const _TypeStyle(
      {required this.color,
      required this.bg,
      required this.icon,
      required this.label});
}

// ── Delete button ─────────────────────────────────────────────────────────────
class _DeleteBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _DeleteBtn({required this.onTap});

  @override
  State<_DeleteBtn> createState() => _DeleteBtnState();
}

class _DeleteBtnState extends State<_DeleteBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.dangerRed.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? AppTheme.dangerRed.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Icon(
            PhosphorIcons.trash(),
            size: 15,
            color: _hovered
                ? AppTheme.dangerRed
                : context.wColors.textMuted,
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
// import 'package:intl/intl.dart';
// import 'package:weather_admin_dashboard/app/controllers/notifications_controller.dart';
// import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

// class NotificationsView extends StatelessWidget {
//   const NotificationsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ctrl = Get.put(NotificationsController());

//     return Column(
//       children: [
//         _NotifHeader(ctrl: ctrl),
//         _NotifTabBar(ctrl: ctrl),
//         Expanded(
//           child: TabBarView(
//             controller: ctrl.tabController,
//             children: [
//               _NotifList(ctrl: ctrl, showUnread: true),
//               _NotifList(ctrl: ctrl, showUnread: false),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // HEADER
// // ─────────────────────────────────────────────────────────────────────────────
// class _NotifHeader extends StatelessWidget {
//   final NotificationsController ctrl;
//   const _NotifHeader({required this.ctrl});

//   @override
//   Widget build(BuildContext context) {
//     final wc = context.wColors;
//     return Container(
//       padding: const EdgeInsets.fromLTRB(32, 28, 28, 20),
//       decoration: BoxDecoration(
//         color: wc.surface,
//         border: Border(bottom: BorderSide(color: wc.border)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Icon badge
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: AppTheme.accentBlue.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               PhosphorIcons.bell(PhosphorIconsStyle.fill),
//               size: 22,
//               color: AppTheme.accentBlue,
//             ),
//           ),
//           const SizedBox(width: 14),

//           // Title + subtitle
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Notifications',
//                   style: Theme.of(context).textTheme.headlineSmall,
//                 ),
//                 const SizedBox(height: 3),
//                 Obx(() {
//                   final unread = ctrl.unreadNotifications.length;
//                   return Text(
//                     unread > 0
//                         ? '$unread unread alert${unread == 1 ? '' : 's'} need your attention'
//                         : 'You\'re all caught up — no unread notifications',
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodySmall
//                         ?.copyWith(color: wc.textMuted),
//                   );
//                 }),
//               ],
//             ),
//           ),

//           const SizedBox(width: 16),

//           // Mark all read button
//           Obx(() {
//             final hasUnread = ctrl.unreadNotifications.isNotEmpty;
//             return _HeaderAction(
//               label: 'Mark all read',
//               icon:  PhosphorIcons.checks() ,
//               enabled: hasUnread,
//               onTap: hasUnread ? ctrl.markAllAsRead : null,
//             );
//           }),
//         ],
//       ),
//     );
//   }
// }

// class _HeaderAction extends StatefulWidget {
//   final String label;
//   final IconData icon;
//   final bool enabled;
//   final VoidCallback? onTap;

//   const _HeaderAction({
//     required this.label,
//     required this.icon,
//     required this.enabled,
//     required this.onTap,
//   });

//   @override
//   State<_HeaderAction> createState() => _HeaderActionState();
// }

// class _HeaderActionState extends State<_HeaderAction> {
//   bool _hovered = false;

//   @override
//   Widget build(BuildContext context) {
//     final wc = context.wColors;
//     final active = widget.enabled && (_hovered);
//     return MouseRegion(
//       onEnter: (_) => setState(() => _hovered = true),
//       onExit: (_) => setState(() => _hovered = false),
//       child: GestureDetector(
//         onTap: widget.onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 150),
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
//           decoration: BoxDecoration(
//             color: active
//                 ? AppTheme.successGreen.withOpacity(0.1)
//                 : Colors.transparent,
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(
//               color: active
//                   ? AppTheme.successGreen.withOpacity(0.4)
//                   : (widget.enabled ? wc.borderSoft : wc.border),
//             ),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 widget.icon,
//                 size: 15,
//                 color: widget.enabled
//                     ? (active ? AppTheme.successGreen : wc.textSecondary)
//                     : wc.textMuted,
//               ),
//               const SizedBox(width: 7),
//               Text(
//                 widget.label,
//                 style: Theme.of(context).textTheme.labelLarge?.copyWith(
//                       color: widget.enabled
//                           ? (active ? AppTheme.successGreen : wc.textSecondary)
//                           : wc.textMuted,
//                     ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // CUSTOM TAB BAR
// // ─────────────────────────────────────────────────────────────────────────────
// class _NotifTabBar extends StatelessWidget {
//   final NotificationsController ctrl;
//   const _NotifTabBar({required this.ctrl});

//   @override
//   Widget build(BuildContext context) {
//     final wc = context.wColors;
//     return Container(
//       color: wc.surface,
//       child: TabBar(
//         controller: ctrl.tabController,
//         labelColor: AppTheme.accentBlue,
//         unselectedLabelColor: wc.textSecondary,
//         indicatorColor: AppTheme.accentBlue,
//         indicatorWeight: 2,
//         indicatorSize: TabBarIndicatorSize.label,
//         dividerColor: wc.border,
//         labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
//               color: AppTheme.accentBlue,
//               letterSpacing: 0.5,
//             ),
//         unselectedLabelStyle:
//             Theme.of(context).textTheme.labelLarge?.copyWith(
//                   color: wc.textSecondary,
//                   letterSpacing: 0.5,
//                 ),
//         padding: const EdgeInsets.symmetric(horizontal: 24),
//         tabs: [
//           Tab(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text('UNREAD'),
//                 const SizedBox(width: 8),
//                 Obx(() {
//                   final count = ctrl.unreadNotifications.length;
//                   if (count == 0) return const SizedBox.shrink();
//                   return Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: AppTheme.dangerRed,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       '$count',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//           Tab(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text('READ'),
//                 const SizedBox(width: 8),
//                 Obx(() {
//                   final count = ctrl.readNotifications.length;
//                   if (count == 0) return const SizedBox.shrink();
//                   return Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: context.wColors.textMuted,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       '$count',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // NOTIFICATION LIST
// // ─────────────────────────────────────────────────────────────────────────────
// class _NotifList extends StatelessWidget {
//   final NotificationsController ctrl;
//   final bool showUnread;

//   const _NotifList({required this.ctrl, required this.showUnread});

//   @override
//   Widget build(BuildContext context) {
//     final wc = context.wColors;
//     return Container(
//       color: Theme.of(context).scaffoldBackgroundColor,
//       child: Obx(() {
//         final list =
//             showUnread ? ctrl.unreadNotifications : ctrl.readNotifications;

//         if (list.isEmpty) {
//           return _EmptyState(showUnread: showUnread);
//         }

//         return Center(
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 780),
//             child: ListView.builder(
//               padding: EdgeInsets.symmetric(
//                 horizontal: 28,
//                 vertical: 28,
//               ),
//               itemCount: list.length,
//               itemBuilder: (context, index) {
//                 final notif = list[index];
//                 return _NotifCard(ctrl: ctrl, notif: notif);
//               },
//             ),
//           ),
//         );
//       }),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // EMPTY STATE
// // ─────────────────────────────────────────────────────────────────────────────
// class _EmptyState extends StatelessWidget {
//   final bool showUnread;
//   const _EmptyState({required this.showUnread});

//   @override
//   Widget build(BuildContext context) {
//     final wc = context.wColors;
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               color: wc.elevated,
//               shape: BoxShape.circle,
//               border: Border.all(color: wc.border),
//             ),
//             child: Icon(
//               showUnread
//                   ? PhosphorIcons.bellZ(PhosphorIconsStyle.fill)
//                   : PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
//               size: 36,
//               color: wc.textMuted,
//             ),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             showUnread ? 'All caught up!' : 'No read notifications',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   color: wc.textPrimary,
//                   fontWeight: FontWeight.w700,
//                 ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             showUnread
//                 ? 'No new notifications right now.\nCheck back later.'
//                 : 'Notifications you\'ve already read will appear here.',
//             style: Theme.of(context)
//                 .textTheme
//                 .bodySmall
//                 ?.copyWith(color: wc.textMuted, height: 1.6),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // NOTIFICATION CARD
// // ─────────────────────────────────────────────────────────────────────────────
// class _NotifCard extends StatefulWidget {
//   final NotificationsController ctrl;
//   final Map<String, dynamic> notif;

//   const _NotifCard({required this.ctrl, required this.notif});

//   @override
//   State<_NotifCard> createState() => _NotifCardState();
// }

// class _NotifCardState extends State<_NotifCard>
//     with SingleTickerProviderStateMixin {
//   bool _hovered = false;
//   late AnimationController _slideCtrl;
//   late Animation<double> _slideAnim;

//   @override
//   void initState() {
//     super.initState();
//     _slideCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 320),
//     );
//     _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
//     // Stagger entrance animation
//     Future.delayed(const Duration(milliseconds: 60), () {
//       if (mounted) _slideCtrl.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _slideCtrl.dispose();
//     super.dispose();
//   }

//   // ── derive type styles ────────────────────────────────────────────────────
//   _TypeStyle _getTypeStyle(String type) {
//     switch (type) {
//       case 'success':
//         return _TypeStyle(
//           color: AppTheme.successGreen,
//           bg: AppTheme.successGreen.withOpacity(0.1),
//           icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
//           label: 'Success',
//         );
//       case 'warning':
//         return _TypeStyle(
//           color: AppTheme.warningAmber,
//           bg: AppTheme.warningAmber.withOpacity(0.1),
//           icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
//           label: 'Warning',
//         );
//       case 'alert':
//         return _TypeStyle(
//           color: AppTheme.dangerRed,
//           bg: AppTheme.dangerRed.withOpacity(0.1),
//           icon: PhosphorIcons.bellRinging(PhosphorIconsStyle.fill),
//           label: 'Alert',
//         );
//       default:
//         return _TypeStyle(
//           color: AppTheme.infoCyan,
//           bg: AppTheme.infoCyan.withOpacity(0.1),
//           icon: PhosphorIcons.info(PhosphorIconsStyle.fill),
//           label: 'Info',
//         );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final wc = context.wColors;
//     final isDark = context.isDark;
//     final notif = widget.notif;
//     final bool isRead = notif['isRead'] as bool;
//     final ts = _getTypeStyle(notif['type'] as String);

//     return FadeTransition(
//       opacity: _slideAnim,
//       child: SlideTransition(
//         position: Tween<Offset>(
//           begin: const Offset(0, 0.06),
//           end: Offset.zero,
//         ).animate(_slideAnim),
//         child: MouseRegion(
//           onEnter: (_) => setState(() => _hovered = true),
//           onExit: (_) => setState(() => _hovered = false),
//           child: GestureDetector(
//             onTap: () {
//               if (!isRead) widget.ctrl.markAsRead(notif['id'] as String);
//             },
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 160),
//               margin: const EdgeInsets.only(bottom: 12),
//               decoration: BoxDecoration(
//                 color: isRead
//                     ? (_hovered ? wc.elevated : wc.card)
//                     : (_hovered
//                         ? AppTheme.accentBlue.withOpacity(isDark ? 0.1 : 0.06)
//                         : AppTheme.accentBlue.withOpacity(isDark ? 0.07 : 0.04)),
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(
//                   color: isRead
//                       ? (_hovered ? wc.borderSoft : wc.border)
//                       : AppTheme.accentBlue.withOpacity(isDark ? 0.25 : 0.2),
//                   width: isRead ? 1 : 1.5,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
//                     blurRadius: _hovered ? 20 : 8,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: IntrinsicHeight(
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     // ── Accent bar ─────────────────────────────────────────
//                     AnimatedContainer(
//                       duration: const Duration(milliseconds: 160),
//                       width: 4,
//                       decoration: BoxDecoration(
//                         color: isRead
//                             ? Colors.transparent
//                             : ts.color,
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(14),
//                           bottomLeft: Radius.circular(14),
//                         ),
//                       ),
//                     ),

//                     // ── Card content ───────────────────────────────────────
//                     Expanded(
//                       child: Padding(
//                         padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Type icon
//                             Container(
//                               width: 42,
//                               height: 42,
//                               decoration: BoxDecoration(
//                                 color: ts.bg,
//                                 borderRadius: BorderRadius.circular(11),
//                               ),
//                               child: Icon(ts.icon, color: ts.color, size: 20),
//                             ),
//                             const SizedBox(width: 14),

//                             // Text content
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Expanded(
//                                         child: Text(
//                                           notif['title'] as String,
//                                           style: Theme.of(context)
//                                               .textTheme
//                                               .titleSmall
//                                               ?.copyWith(
//                                                 color: wc.textPrimary,
//                                                 fontWeight: isRead
//                                                     ? FontWeight.w500
//                                                     : FontWeight.w700,
//                                               ),
//                                           maxLines: 1,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 12),
//                                       // Timestamp + unread dot
//                                       Row(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//                                           if (!isRead) ...[
//                                             Container(
//                                               width: 7,
//                                               height: 7,
//                                               decoration: BoxDecoration(
//                                                 color: AppTheme.accentBlue,
//                                                 shape: BoxShape.circle,
//                                                 boxShadow: [
//                                                   BoxShadow(
//                                                     color: AppTheme.accentBlue
//                                                         .withOpacity(0.5),
//                                                     blurRadius: 6,
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                             const SizedBox(width: 6),
//                                           ],
//                                           Text(
//                                             _formatTimestamp(
//                                                 notif['timestamp']
//                                                     as DateTime),
//                                             style: Theme.of(context)
//                                                 .textTheme
//                                                 .bodySmall
//                                                 ?.copyWith(
//                                                   color: isRead
//                                                       ? wc.textMuted
//                                                       : AppTheme.accentBlue,
//                                                   fontWeight: isRead
//                                                       ? FontWeight.w400
//                                                       : FontWeight.w600,
//                                                 ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 6),
//                                   Text(
//                                     notif['message'] as String,
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall
//                                         ?.copyWith(
//                                           color: wc.textSecondary,
//                                           height: 1.55,
//                                         ),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   const SizedBox(height: 10),

//                                   // Bottom meta row
//                                   Row(
//                                     children: [
//                                       // Type pill
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 8, vertical: 3),
//                                         decoration: BoxDecoration(
//                                           color: ts.bg,
//                                           borderRadius:
//                                               BorderRadius.circular(20),
//                                         ),
//                                         child: Text(
//                                           ts.label.toUpperCase(),
//                                           style: TextStyle(
//                                             color: ts.color,
//                                             fontSize: 9,
//                                             fontWeight: FontWeight.w800,
//                                             letterSpacing: 0.8,
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       if (!isRead)
//                                         GestureDetector(
//                                           onTap: () => widget.ctrl.markAsRead(
//                                               notif['id'] as String),
//                                           child: Container(
//                                             padding: const EdgeInsets.symmetric(
//                                                 horizontal: 8, vertical: 3),
//                                             decoration: BoxDecoration(
//                                               color: AppTheme.accentBlue
//                                                   .withOpacity(0.1),
//                                               borderRadius:
//                                                   BorderRadius.circular(20),
//                                             ),
//                                             child: Text(
//                                               'MARK READ',
//                                               style: TextStyle(
//                                                 color: AppTheme.accentBlue,
//                                                 fontSize: 9,
//                                                 fontWeight: FontWeight.w800,
//                                                 letterSpacing: 0.8,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),

//                             // Delete button
//                             const SizedBox(width: 6),
//                             _DeleteBtn(
//                               onTap: () => widget.ctrl.deleteNotification(
//                                   notif['id'] as String),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   String _formatTimestamp(DateTime timestamp) {
//     final diff = DateTime.now().difference(timestamp);
//     if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
//     if (diff.inHours < 24) return '${diff.inHours}h ago';
//     if (diff.inDays < 7) return '${diff.inDays}d ago';
//     return DateFormat('MMM d, yyyy').format(timestamp);
//   }
// }

// class _TypeStyle {
//   final Color color;
//   final Color bg;
//   final IconData icon;
//   final String label;
//   const _TypeStyle(
//       {required this.color,
//       required this.bg,
//       required this.icon,
//       required this.label});
// }

// // ── Delete button ─────────────────────────────────────────────────────────────
// class _DeleteBtn extends StatefulWidget {
//   final VoidCallback onTap;
//   const _DeleteBtn({required this.onTap});

//   @override
//   State<_DeleteBtn> createState() => _DeleteBtnState();
// }

// class _DeleteBtnState extends State<_DeleteBtn> {
//   bool _hovered = false;

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       onEnter: (_) => setState(() => _hovered = true),
//       onExit: (_) => setState(() => _hovered = false),
//       child: GestureDetector(
//         onTap: widget.onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 130),
//           width: 32,
//           height: 32,
//           decoration: BoxDecoration(
//             color: _hovered
//                 ? AppTheme.dangerRed.withOpacity(0.1)
//                 : Colors.transparent,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: _hovered
//                   ? AppTheme.dangerRed.withOpacity(0.3)
//                   : Colors.transparent,
//             ),
//           ),
//           child: Icon(
//             PhosphorIcons.trash(),
//             size: 15,
//             color: _hovered
//                 ? AppTheme.dangerRed
//                 : context.wColors.textMuted,
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
// import 'package:intl/intl.dart';
// import 'package:weather_admin_dashboard/app/controllers/notifications_controller.dart'; 

// class NotificationsView extends StatelessWidget {
//   const NotificationsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ctrl = Get.put(NotificationsController());
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final primaryColor = isDark ? Colors.blueAccent : const Color(0xFF0B4EA2);

//     return Column(
//       children: [
//         // HEADER & TABS
//         Container(
//           color: isDark ? const Color(0xFF252525) : Colors.white,
//           child: Column(
//             children: [
//               // Top Header Row
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("System Notifications", style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
//                         const SizedBox(height: 4),
//                         Text("Alerts, updates, and system logs for your account.", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
//                       ],
//                     ),
//                     OutlinedButton.icon(
//                       onPressed: ctrl.markAllAsRead,
//                       icon: const Icon(Icons.done_all, size: 18),
//                       label: const Text("Mark all as read"),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: isDark ? Colors.grey.shade300 : Colors.black87,
//                         side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
              
//               // Tab Bar
//               TabBar(
//                 controller: ctrl.tabController,
//                 labelColor: primaryColor,
//                 unselectedLabelColor: Colors.grey,
//                 indicatorColor: primaryColor,
//                 indicatorWeight: 3,
//                 labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 14),
//                 tabs: [
//                   Tab(
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text("UNREAD"),
//                         const SizedBox(width: 8),
//                         Obx(() => ctrl.unreadNotifications.isNotEmpty
//                             ? Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                 decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
//                                 child: Text("${ctrl.unreadNotifications.length}", style: const TextStyle(color: Colors.white, fontSize: 11)),
//                               )
//                             : const SizedBox.shrink())
//                       ],
//                     ),
//                   ),
//                   const Tab(text: "READ"),
//                 ],
//               ),
//             ],
//           ),
//         ),

//         // TAB CONTENT
//         Expanded(
//           child: Container(
//             color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
//             child: TabBarView(
//               controller: ctrl.tabController,
//               children: [
//                 _buildNotificationList(ctrl, true, isDark),  // Unread
//                 _buildNotificationList(ctrl, false, isDark), // Read
//               ],
//             ),
//           ),
//         )
//       ],
//     );
//   }

//   Widget _buildNotificationList(NotificationsController ctrl, bool showUnread, bool isDark) {
//     return Obx(() {
//       final list = showUnread ? ctrl.unreadNotifications : ctrl.readNotifications;

//       if (list.isEmpty) {
//         return Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(showUnread ? PhosphorIcons.bellZ() : PhosphorIcons.checkCircle(), size: 64, color: Colors.grey.shade400),
//               const SizedBox(height: 16),
//               Text(showUnread ? "You're all caught up!" : "No read notifications.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
//             ],
//           ),
//         );
//       }

//       return Center(
//         child: Container(
//           constraints: const BoxConstraints(maxWidth: 800), // Centers the inbox nicely on a wide screen
//           child: ListView.builder(
//             padding: const EdgeInsets.all(32),
//             itemCount: list.length,
//             itemBuilder: (context, index) {
//               final notif = list[index];
//               return _buildNotificationCard(ctrl, notif, isDark);
//             },
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildNotificationCard(NotificationsController ctrl, Map<String, dynamic> notif, bool isDark) {
//     final bool isRead = notif['isRead'];
//     final String type = notif['type'];
    
//     // Determine icon and color based on notification type
//     Color typeColor;
//     IconData typeIcon;
//     switch (type) {
//       case 'success': typeColor = Colors.green; typeIcon = PhosphorIcons.checkCircle(PhosphorIconsStyle.fill); break;
//       case 'warning': typeColor = Colors.orange; typeIcon = PhosphorIcons.warning(PhosphorIconsStyle.fill); break;
//       case 'alert': typeColor = Colors.red; typeIcon = PhosphorIcons.bellRinging(PhosphorIconsStyle.fill); break;
//       default: typeColor = Colors.blue; typeIcon = PhosphorIcons.info(PhosphorIconsStyle.fill);
//     }

//     return InkWell(
//       onTap: () {
//         if (!isRead) ctrl.markAsRead(notif['id']);
//         // Add specific navigation logic here if needed (e.g., clicking the weekly report takes you to reports page)
//       },
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: isRead ? (isDark ? const Color(0xFF1E1E1E) : Colors.white) : (isDark ? Colors.blue.withOpacity(0.05) : Colors.blue.shade50),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: isRead ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200) : Colors.blue.shade300, width: isRead ? 1 : 1.5),
//           boxShadow: [if (!isRead && !isDark) BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Status Icon
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(color: typeColor.withOpacity(0.1), shape: BoxShape.circle),
//               child: Icon(typeIcon, color: typeColor, size: 24),
//             ),
//             const SizedBox(width: 16),
            
//             // Content
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           notif['title'], 
//                           style: GoogleFonts.notoSans(fontSize: 16, fontWeight: isRead ? FontWeight.w600 : FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
//                           maxLines: 1, overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       Text(
//                         _formatTimestamp(notif['timestamp']),
//                         style: TextStyle(fontSize: 12, color: isRead ? Colors.grey.shade500 : Colors.blue.shade700, fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
//                       )
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     notif['message'],
//                     style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.4),
//                   ),
//                 ],
//               ),
//             ),
            
//             // Delete Action
//             const SizedBox(width: 16),
//             IconButton(
//               icon: Icon(PhosphorIcons.trash(), size: 20, color: Colors.grey.shade400),
//               tooltip: "Delete notification",
//               onPressed: () => ctrl.deleteNotification(notif['id']),
//               hoverColor: Colors.red.withOpacity(0.1),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   // Helper to make timestamps look human-friendly
//   String _formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final difference = now.difference(timestamp);

//     if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
//     if (difference.inHours < 24) return "${difference.inHours}h ago";
//     if (difference.inDays < 7) return "${difference.inDays}d ago";
    
//     return DateFormat('MMM d, yyyy').format(timestamp);
//   }
// }