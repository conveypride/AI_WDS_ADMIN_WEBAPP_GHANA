import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart';
import 'package:weather_admin_dashboard/app/controllers/cities_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';

class AddCitiesView extends StatelessWidget {
  const AddCitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CitiesController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0A0A0A),
                  const Color(0xFF121212),
                ]
              : [
                  const Color(0xFFFAFAFA),
                  const Color(0xFFF5F5F5),
                ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            

            // Add City Section - Ultra Modern
            _GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        color:AppTheme.accentBlue.withOpacity(isDark ? 0.12 : 0.35),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.plusCircle(PhosphorIconsStyle.bold),
                              size: 16,
                              color: const Color(0xFF667EEA),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'NEW LOCATION',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: const Color(0xFF667EEA),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.03)
                                : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: TextField(
                            controller: controller.cityController,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter city name...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.3),
                                letterSpacing: -0.2,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Icon(
                                  PhosphorIcons.mapPin(PhosphorIconsStyle.duotone),
                                  color: isDark
                                      ? Colors.white.withOpacity(0.4)
                                      : Colors.black.withOpacity(0.4),
                                  size: 20,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                            onSubmitted: (_) => controller.addCity(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ModernButton(
                        onPressed: controller.addCity,
                        label: 'Add Location',
                        icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Header with Count Badge
            Row(
              children: [
                Text(
                  'Active Locations',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() => _CountBadge(count: controller.cities.length)),
              ],
            ),

            const SizedBox(height: 20),

            // Cities Grid
            Expanded(
              child: Obx(() {
                if (controller.cities.isEmpty) {
                  return _EmptyState(isDark: isDark);
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 4.2,
                    mainAxisExtent: 80,
                  ),
                  itemCount: controller.cities.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) {
                    final cityName = controller.cities[index];
                    return _CityCard(
                      cityName: cityName,
                      index: index,
                      isDark: isDark,
                      onDelete: () => controller.deleteCity(cityName),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
  
// Glassmorphic Container
class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: child,
    );
  }
}

// Modern Button
class _ModernButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const _ModernButton({
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  State<_ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<_ModernButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered
                  ? [
                      const Color.fromARGB(255, 0, 9, 112),
                      const Color(0xFF667EEA),
                    ]
                  : [
                      const Color.fromARGB(255, 2, 25, 127),
                      const Color.fromARGB(255, 55, 49, 244),
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(_isHovered ? 0.4 : 0.3),
                blurRadius: _isHovered ? 24 : 16,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Count Badge
class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA).withOpacity(0.2),
            const Color(0xFF764BA2).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.4),
        ),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF667EEA),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// City Card with Modern Design
class _CityCard extends StatefulWidget {
  final String cityName;
  final int index;
  final bool isDark;
  final VoidCallback onDelete;

  const _CityCard({
    required this.cityName,
    required this.index,
    required this.isDark,
    required this.onDelete,
  });

  @override
  State<_CityCard> createState() => _CityCardState();
}

class _CityCardState extends State<_CityCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withOpacity(_isHovered ? 0.08 : 0.04)
              : Colors.white.withOpacity(_isHovered ? 1 : 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF667EEA).withOpacity(0.5)
                : (widget.isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06)),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? const Color(0xFF667EEA).withOpacity(0.2)
                  : Colors.black.withOpacity(widget.isDark ? 0.2 : 0.04),
              blurRadius: _isHovered ? 20 : 12,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF667EEA).withOpacity(0.2),
                    const Color(0xFF764BA2).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                PhosphorIcons.buildings(PhosphorIconsStyle.duotone),
                color: const Color(0xFF667EEA),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.cityName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: widget.isDark ? Colors.white : const Color(0xFF1A1A1A),
                      
                    ),
                  // Only take needed space
maxLines: 1,                      // Prevent text wrapping
overflow: TextOverflow.ellipsis,  // Clip long city names

                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Active',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: widget.isDark
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFF666666),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _DeleteButton(
              onPressed: () => _showDeleteDialog(context),
              isDark: widget.isDark,
              isHovered: _isHovered,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => _ModernDialog(
        cityName: widget.cityName,
        onConfirm: widget.onDelete,
        isDark: widget.isDark,
      ),
    );
  }
}
  
// Delete Button
class _DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDark;
  final bool isHovered;

  const _DeleteButton({
    required this.onPressed,
    required this.isDark,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isHovered
              ? const Color(0xFFEF4444).withOpacity(0.15)
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHovered
                ? const Color(0xFFEF4444).withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          PhosphorIcons.trash(PhosphorIconsStyle.bold),
          size: 18,
          color: const Color(0xFFEF4444),
        ),
      ),
    );
  }
}

// Modern Dialog
class _ModernDialog extends StatelessWidget {
  final String cityName;
  final VoidCallback onConfirm;
  final bool isDark;

  const _ModernDialog({
    required this.cityName,
    required this.onConfirm,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFEF4444),
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Remove Location',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to remove "$cityName" from your monitoring list? This action cannot be undone.',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.6,
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                    isPrimary: false,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'Remove',
                    onPressed: () {
                      onConfirm();
                      Navigator.of(context).pop();
                    },
                    isPrimary: true,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog Button
class _DialogButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDark;

  const _DialogButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
    required this.isDark,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? const Color(0xFFEF4444)
                : (widget.isDark
                    ? Colors.white.withOpacity(_isHovered ? 0.1 : 0.05)
                    : Colors.black.withOpacity(_isHovered ? 0.06 : 0.03)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.transparent
                  : (widget.isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1)),
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isPrimary
                    ? Colors.white
                    : (widget.isDark ? Colors.white : const Color(0xFF1A1A1A)),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Empty State
class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.1),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.mapTrifold(PhosphorIconsStyle.duotone),
              size: 48,
              color: const Color(0xFF667EEA).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No locations yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF666666),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first city to start monitoring',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}