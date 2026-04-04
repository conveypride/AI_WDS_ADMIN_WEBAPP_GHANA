import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:weather_admin_dashboard/app/routes/app_routes.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String activeRoute;
  final String title;

  const AdminLayout({
    super.key,
    required this.child,
    required this.activeRoute,
    required this.title,
  });

  void _navigate(BuildContext context, String route) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
    if (Get.currentRoute != route) {
      Get.toNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        final isTablet = constraints.maxWidth >= 800 && constraints.maxWidth < 1200;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: isMobile
              ? Drawer(
                  width: 280,
                  child: Builder(
                    builder: (innerContext) =>
                        _buildSidebarContent(innerContext, isCompact: false),
                  ),
                )
              : null,
          appBar: isMobile
              ? _buildMobileAppBar(context)
              : null,
          body: Row(
            children: [
              if (!isMobile)
                _Sidebar(
                  isCompact: isTablet,
                  sidebarContent: Builder(
                    builder: (innerContext) =>
                        _buildSidebarContent(innerContext, isCompact: isTablet),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (!isMobile) _buildTopBar(context),
                    Expanded(
                      child: child,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    final wc = context.wColors;
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: wc.card, // Replaced surface with card to match app_theme.dart
          border: Border(bottom: BorderSide(color: wc.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Builder(
                  builder: (ctx) => _IconBtn(
                    icon: PhosphorIcons.list(),
                    onTap: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    _BrandIcon(),
                    const SizedBox(width: 10),
                    Text(
                      'WeatherAdmin',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const Spacer(),
                _ThemeToggle(),
                const SizedBox(width: 4),
                _NotifBtn(onTap: () => _navigate(context, AppRoutes.notifications)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context, {required bool isCompact}) {
    final wc = context.wColors;
    return Column(
      children: [
        // ─── BRAND ────────────────────────────────────
        Container(
          height: 68,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 0 : 20,
          ),
          alignment: isCompact ? Alignment.center : Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: wc.border)),
          ),
          child: isCompact
              ? _BrandIcon()
              : Row(
                  children: [
                    _BrandIcon(),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WeatherAdmin',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Meteorology Unit',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: wc.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
        ),

        // ─── NAV ──────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              _NavItem(
                icon: PhosphorIcons.house(),
                activeIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                label: 'Dashboard',
                route: AppRoutes.dashboard,
                activeRoute: activeRoute,
                isCompact: isCompact,
                onNavigate: (r) => _navigate(context, r),
              ),
              _NavItem(
                icon: PhosphorIcons.bell(),
                activeIcon: PhosphorIcons.bell(PhosphorIconsStyle.fill),
                label: 'Notifications',
                route: AppRoutes.notifications,
                activeRoute: activeRoute,
                isCompact: isCompact,
                badge: '3',
                badgeColor: AppTheme.dangerRed,
                onNavigate: (r) => _navigate(context, r),
              ),
              if (!isCompact) const _SectionLabel(label: 'FORECASTING'),
              _DropdownNavItem(
                icon: PhosphorIcons.fileText(),
                activeIcon: PhosphorIcons.fileText(PhosphorIconsStyle.fill),
                label: 'CAFO Forecast',
                isCompact: isCompact,
                isSelected: [
                  AppRoutes.cafoUnified,
                  AppRoutes.sevenDayForecast,
                  AppRoutes.seasonalForecast,
                  AppRoutes.midWeekIBF,
                  AppRoutes.weekendIBF,
                ].contains(activeRoute),
                children: [
                  _DropdownChild(
                    icon: PhosphorIcons.calendar(),
                    label: 'Daily Forecast (24H)',
                    route: AppRoutes.cafoUnified,
                    onNavigate: (r) => _navigate(context, r),
                  ),
                  _DropdownChild(
                    icon: PhosphorIcons.calendarCheck(),
                    label: '7-Day Forecast',
                    route: AppRoutes.sevenDayForecast,
                    onNavigate: (r) => _navigate(context, r),
                  ),
                  _DropdownChild(
                    icon: PhosphorIcons.calendarDot(),
                    label: 'Mid-Week IBF',
                    route: AppRoutes.midWeekIBF,
                    onNavigate: (r) => _navigate(context, r),
                  ),
                  _DropdownChild(
                    icon: PhosphorIcons.calendarPlus(),
                    label: 'Weekend IBF',
                    route: AppRoutes.weekendIBF,
                    onNavigate: (r) => _navigate(context, r),
                  ),
                  _DropdownChild(
                    icon: PhosphorIcons.sun(),
                    label: 'Seasonal Forecast',
                    route: AppRoutes.seasonalForecast,
                    onNavigate: (r) => _navigate(context, r),
                  ),
                ],
              ),
              _DropdownNavItem(
                icon: PhosphorIcons.waves(),
                activeIcon: PhosphorIcons.waves(PhosphorIconsStyle.fill),
                label: 'Marine Forecast',
                isCompact: isCompact,
                isSelected: [
                  AppRoutes.coastlineForecast,
                  AppRoutes.inlandForecast,
                ].contains(activeRoute),
                children: [
                  _DropdownChild(
                    icon: PhosphorIcons.anchor(),
                    label: 'Coastline Forecast',
                    route: AppRoutes.coastlineForecast,
                    onNavigate: (r) => _navigate(context, r),
                  ),
                  _DropdownChild(
                    icon: PhosphorIcons.mapTrifold(),
                    label: 'Inland Forecast',
                    route: AppRoutes.inlandForecast,
                    onNavigate: (r) => _navigate(context, r),
                  ),
                ],
              ),
              if (!isCompact) const _SectionLabel(label: 'COMMUNITY'),
              _NavItem(
                icon: PhosphorIcons.users(),
                activeIcon: PhosphorIcons.users(PhosphorIconsStyle.fill),
                label: 'Community Hub',
                route: AppRoutes.adminCommunity,
                activeRoute: activeRoute,
                isCompact: isCompact,
                onNavigate: (r) => _navigate(context, r),
              ),
              _NavItem(
                icon: PhosphorIcons.warning(),
                activeIcon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
                label: 'Alerts',
                route: AppRoutes.alertNotification,
                activeRoute: activeRoute,
                isCompact: isCompact,
                badge: '5',
                badgeColor: AppTheme.warningAmber,
                onNavigate: (r) => _navigate(context, r),
              ),
              _NavItem(
                icon: PhosphorIcons.chartBar(),
                activeIcon: PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
                label: 'Reports',
                route: AppRoutes.reports,
                activeRoute: activeRoute,
                isCompact: isCompact,
                onNavigate: (r) => _navigate(context, r),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 16 : 20,
                  vertical: 8,
                ),
                child: Divider(color: context.wColors.border, height: 1),
              ),
              _NavItem(
                icon: PhosphorIcons.gear(),
                activeIcon: PhosphorIcons.gear(PhosphorIconsStyle.fill),
                label: 'Settings',
                route: AppRoutes.settings,
                activeRoute: activeRoute,
                isCompact: isCompact,
                onNavigate: (r) => _navigate(context, r),
              ),
             _NavItem(
                icon: PhosphorIcons.chartBar(),
                activeIcon: PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
                label: 'Reports',
                route: AppRoutes.reports,
                activeRoute: activeRoute,
                isCompact: isCompact,
                onNavigate: (r) => _navigate(context, r),
              ),

              // NEW: CONFIGURATION SECTION
              if (!isCompact) const _SectionLabel(label: 'CONFIGURATION'),
              _NavItem(
                icon: PhosphorIcons.mapPin(),
                activeIcon: PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                label: 'Cities',
                route: AppRoutes.addCities,
                activeRoute: activeRoute,
                isCompact: isCompact,
                onNavigate: (r) => _navigate(context, r),
              ),
              _NavItem(
                icon: PhosphorIcons.cloud(),
                activeIcon: PhosphorIcons.cloud(PhosphorIconsStyle.fill),
                label: 'Weather Conditions',
                route: AppRoutes.addWeatherConditions,
                activeRoute: activeRoute,
                isCompact: isCompact,
                onNavigate: (r) => _navigate(context, r),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 16 : 20,
                  vertical: 8,
                ),
                child: Divider(color: context.wColors.border, height: 1),
              ),

_NavItem(
                icon: PhosphorIcons.userGear(),
                activeIcon: PhosphorIcons.userGear(PhosphorIconsStyle.fill),
                label: 'User Management',
                route: AppRoutes.userManagement,
                activeRoute: activeRoute,
                isCompact: isCompact,
                onNavigate: (r) => _navigate(context, r),
              )


            ],
          ),
        ),

        // ─── USER PROFILE ─────────────────────────────
        if (!isCompact)
          _UserFooter(onLogout: () {}),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final wc = context.wColors;
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: wc.card, // Replaced surface with card
        border: Border(bottom: BorderSide(color: wc.border)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 1),
              Text(
                DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: wc.textMuted),
              ),
            ],
          ),
          const Spacer(),

          // Search
          const _SearchBar(),
          const SizedBox(width: 8),

          // Theme toggle
          const _ThemeToggle(),
          const SizedBox(width: 4),

          // Notifications
          _NotifBtn(onTap: () => _navigate(context, AppRoutes.notifications)),
          const SizedBox(width: 12),

          // Avatar
          const _TopBarAvatar(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR SHELL
// ─────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final bool isCompact;
  final Widget sidebarContent;

  const _Sidebar({required this.isCompact, required this.sidebarContent});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: isCompact ? 72 : 272,
      decoration: BoxDecoration(
        color: wc.card, // Replaced surface with card
        border: Border(right: BorderSide(color: wc.border)),
      ),
      child: sidebarContent,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BRAND ICON
// ─────────────────────────────────────────────────────────────────────────────
class _BrandIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentBlue.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.wColors.textMuted,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NAV ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final String activeRoute;
  final bool isCompact;
  final String? badge;
  final Color? badgeColor;
  final void Function(String) onNavigate;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.activeRoute,
    required this.isCompact,
    required this.onNavigate,
    this.badge,
    this.badgeColor,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.activeRoute == widget.route;
    final wc = context.wColors;
    final color = isSelected
        ? AppTheme.accentBlue
        : _hovered
            ? wc.textPrimary
            : wc.textSecondary;
    final bg = isSelected
        ? AppTheme.accentBlue.withOpacity(0.1)
        : _hovered
            ? wc.elevated
            : Colors.transparent;

    if (widget.isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Tooltip(
          message: widget.label,
          preferBelow: false,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: () => widget.onNavigate(widget.route),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 48,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: AppTheme.accentBlue.withOpacity(0.3))
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isSelected ? widget.activeIcon : widget.icon,
                      size: 20,
                      color: color,
                    ),
                    if (widget.badge != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _Badge(
                          text: widget.badge!,
                          color: widget.badgeColor ?? AppTheme.dangerRed,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => widget.onNavigate(widget.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppTheme.accentBlue.withOpacity(0.25))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? widget.activeIcon : widget.icon,
                  size: 19,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.badge != null)
                  _Badge(
                    text: widget.badge!,
                    color: widget.badgeColor ?? AppTheme.dangerRed,
                  ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DROPDOWN NAV ITEM (expandable)
// ─────────────────────────────────────────────────────────────────────────────
class _DropdownChild {
  final IconData icon;
  final String label;
  final String route;
  final void Function(String) onNavigate;

  const _DropdownChild({
    required this.icon,
    required this.label,
    required this.route,
    required this.onNavigate,
  });
}

class _DropdownNavItem extends StatefulWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isCompact;
  final bool isSelected;
  final List<_DropdownChild> children;

  const _DropdownNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isCompact,
    required this.isSelected,
    required this.children,
  });

  @override
  State<_DropdownNavItem> createState() => _DropdownNavItemState();
}

class _DropdownNavItemState extends State<_DropdownNavItem>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isSelected;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: _expanded ? 1.0 : 0.0,
    );
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final color = widget.isSelected
        ? AppTheme.accentBlue
        : _hovered
            ? wc.textPrimary
            : wc.textSecondary;
    final bg = widget.isSelected
        ? AppTheme.accentBlue.withOpacity(0.1)
        : _hovered
            ? wc.elevated
            : Colors.transparent;

    if (widget.isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Tooltip(
          message: widget.label,
          preferBelow: false,
          child: Builder(
            builder: (ctx) => MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: GestureDetector(
                onTap: () => _showCompactMenu(ctx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: widget.isSelected
                        ? Border.all(
                            color: AppTheme.accentBlue.withOpacity(0.3))
                        : null,
                  ),
                  child: Icon(
                    widget.isSelected
                        ? (widget.activeIcon ?? widget.icon)
                        : widget.icon,
                    size: 20,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: widget.isSelected
                      ? Border.all(
                          color: AppTheme.accentBlue.withOpacity(0.25))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isSelected
                          ? (widget.activeIcon ?? widget.icon)
                          : widget.icon,
                      size: 19,
                      color: color,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: color,
                              fontWeight: widget.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        PhosphorIcons.caretDown(),
                        size: 14,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnim,
          child: Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Column(
              children: widget.children
                  .map((child) => _DropdownChildItem(child: child))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _showCompactMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
            button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    showMenu<String>(
      context: context,
      position: position,
      items: widget.children
          .map((c) => PopupMenuItem(
                value: c.route,
                child: Row(
                  children: [
                    Icon(c.icon, size: 16, color: AppTheme.accentBlue),
                    const SizedBox(width: 10),
                    Text(c.label),
                  ],
                ),
              ))
          .toList(),
    ).then((route) {
      if (route != null) {
        final match =
            widget.children.firstWhere((c) => c.route == route);
        match.onNavigate(route);
      }
    });
  }
}

class _DropdownChildItem extends StatefulWidget {
  final _DropdownChild child;
  const _DropdownChildItem({required this.child});

  @override
  State<_DropdownChildItem> createState() => _DropdownChildItemState();
}

class _DropdownChildItemState extends State<_DropdownChildItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.child.onNavigate(widget.child.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? wc.elevated : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: _hovered ? AppTheme.accentBlue : wc.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                widget.child.icon,
                size: 15,
                color: _hovered ? AppTheme.accentBlue : wc.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.child.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _hovered ? AppTheme.accentBlue : wc.textSecondary,
                        fontWeight:
                            _hovered ? FontWeight.w500 : FontWeight.w400,
                      ),
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
// USER FOOTER
// ─────────────────────────────────────────────────────────────────────────────
class _UserFooter extends StatelessWidget {
  final VoidCallback onLogout;
  const _UserFooter({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: wc.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.accentBlue,
                  Color(0xFF6366F1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'AF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin User',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: wc.textPrimary),
                ),
                Text(
                  'admin@meteo.gov',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: wc.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _IconBtn(
            icon: PhosphorIcons.signOut(),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  const _SearchBar();

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _focused ? 220 : 180,
      height: 38,
      decoration: BoxDecoration(
        color: wc.elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focused ? AppTheme.accentBlue.withOpacity(0.5) : wc.border,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(
            PhosphorIcons.magnifyingGlass(),
            size: 16,
            color: wc.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: wc.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: wc.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => setState(() => _focused = true),
              onEditingComplete: () => setState(() => _focused = false),
              onSubmitted: (_) => setState(() => _focused = false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return _IconBtn(
      icon: isDark ? PhosphorIcons.sun() : PhosphorIcons.moon(),
      onTap: () => Get.changeThemeMode(
        isDark ? ThemeMode.light : ThemeMode.dark,
      ),
    );
  }
}

class _NotifBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _NotifBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _IconBtn(icon: PhosphorIcons.bell(), onTap: onTap),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppTheme.dangerRed,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBarAvatar extends StatefulWidget {
  const _TopBarAvatar();

  @override
  State<_TopBarAvatar> createState() => _TopBarAvatarState();
}

class _TopBarAvatarState extends State<_TopBarAvatar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? context.wColors.elevated : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? context.wColors.borderSoft
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'AF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Admin User',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: context.wColors.textPrimary),
                  ),
                  Text(
                    'Meteorologist',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.wColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(
                PhosphorIcons.caretDown(),
                size: 12,
                color: context.wColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED PRIMITIVES
// ─────────────────────────────────────────────────────────────────────────────
class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _hovered ? wc.elevated : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hovered ? wc.border : Colors.transparent,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _hovered ? wc.textPrimary : wc.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}