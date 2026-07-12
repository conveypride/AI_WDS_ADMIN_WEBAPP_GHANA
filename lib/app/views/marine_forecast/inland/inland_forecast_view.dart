import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/theme/phosphor_icons.dart'; 
import 'package:weather_admin_dashboard/app/controllers/inland_forecast_controller.dart';
import 'package:weather_admin_dashboard/app/theme/app_theme.dart';
import 'package:weather_admin_dashboard/app/views/marine_forecast/inland/inland_daily_ibf_content_tab.dart';
import 'package:weather_admin_dashboard/app/views/marine_forecast/inland/inland_daily_table_tab.dart';
import 'package:weather_admin_dashboard/app/views/marine_forecast/inland/inland_forecasts_list_tab.dart';
import 'package:weather_admin_dashboard/app/views/widgets/inland_official_header.dart';  

class InlandForecastView extends StatelessWidget {
  InlandForecastView({super.key});

  final InlandForecastController ctrl = Get.put(InlandForecastController());

  @override
  Widget build(BuildContext context) {
    final wc = context.wColors;
    final isDark = context.isDark;

    return Column(
      children: [
        InlandOfficialHeader(isDark: isDark),

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
            onTap: (index) {
              // IBF is now at index 2. Table is at index 1.
              if (index == 2 && !ctrl.isTableComplete.value) {
                ctrl.tabController.index = 1; // Send them back to the Table tab
                Get.snackbar(
                  "Restricted", 
                  "Fill the table first!", 
                  backgroundColor: AppTheme.dangerRed.withOpacity(0.9), 
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              }
            },
            tabs: [
              // 1st Tab: Analytics & List (Index 0)
              Tab(
                icon: Icon(PhosphorIcons.folders()), 
                text: "MY FORECASTS"
              ),
              // 2nd Tab: Table (Index 1)
              Tab(
                icon: Icon(PhosphorIcons.table()), 
                text: "DAILY FORECAST TABLE"
              ),
              // 3rd Tab: IBF (Index 2)
              Tab(
                icon: Icon(PhosphorIcons.mapTrifold()), 
                text: "IMPACT-BASED FORECAST"
              ),
            ],
          ),
        ),

        // ── TAB VIEWS ────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: ctrl.tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Must perfectly match the order of the tabs above!
              InlandListTab(ctrl: ctrl), // Index 0
              InlandDailyTableTab(ctrl: ctrl, onNext: ctrl.goToNextTab), // Index 1
              IBFContentTab(ctrl: ctrl), // Index 2
            ],
          ),
        ),
      ],
    );
  }
}