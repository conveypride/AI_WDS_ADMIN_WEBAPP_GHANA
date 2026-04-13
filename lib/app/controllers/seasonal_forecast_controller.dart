import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:weather_admin_dashboard/app/data/models/seasonal_forecast_model.dart';
import 'package:weather_admin_dashboard/app/services/seasonal_forecast_service.dart'; 

class SeasonalForecastController extends GetxController
    with GetTickerProviderStateMixin {
  late TabController tabController;

  final _svc = SeasonalForecastService.instance;

  // ── Loading / Error state ──────────────────────────────────────────────────
  var isLoadingConfig   = true.obs;
  var isLoadingArchives = true.obs;
  var isSavingDraft     = false.obs;
  var isPublishing      = false.obs;
  var isLoadingMore     = false.obs;   // for archive pagination
  var errorMessage      = ''.obs;

  // ── Config (zones, category options — loaded from Firestore) ──────────────
  var config = ForecastConfig.defaults().obs;

  // ── Draft being composed ───────────────────────────────────────────────────
  // We hold the whole model in one observable so rebuilds are predictable.
  var draft = _emptyDraft().obs;

  // Tracks the Firestore doc ID of the draft once first saved
  String? _draftId;
  StreamSubscription<DocumentSnapshot>? _draftListener;

  // ── Archives list ──────────────────────────────────────────────────────────
  var archives = <SeasonalForecastModel>[].obs;
  var archivesExhausted = false.obs;

  // ==========================================================================
  // LIFECYCLE
  // ==========================================================================

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    _boot();
  }

  @override
  void onClose() {
    tabController.dispose();
    _svc.cancelDraftListener();
    _draftListener?.cancel();
    super.onClose();
  }

  Future<void> _boot() async {
    await Future.wait([_loadConfig(), _loadArchives()]);
    _resetDraftFromConfig();
  }

  // ==========================================================================
  // CONFIG
  // ==========================================================================

  Future<void> _loadConfig() async {
    try {
      isLoadingConfig.value = true;
      config.value = await _svc.getConfig();
    } catch (e) {
      errorMessage.value = 'Failed to load config: $e';
    } finally {
      isLoadingConfig.value = false;
    }
  }

  // ==========================================================================
  // DRAFT — compose new forecast
  // ==========================================================================

  /// Wipe the form and start a fresh draft, building empty zonal entries
  /// from whatever zones came back from Firestore config.
  void _resetDraftFromConfig() {
    _draftId = null;
    _svc.cancelDraftListener();
    draft.value = _emptyDraftFromConfig(config.value);
  }

  void startNewForecast() {
    _resetDraftFromConfig();
    tabController.animateTo(1);
  }

  // ── Field setters — each triggers a single obs rebuild ───────────────────

  void setTitle(String v)            => draft.value = draft.value.copyWith(title: v);
  void setSeason(String v)           => draft.value = draft.value.copyWith(season: v);
  void setYear(String v)             => draft.value = draft.value.copyWith(year: v);
  void setIssuedDate(String v)       => draft.value = draft.value.copyWith(issuedDate: v);
  void setPreparedBy(String v)       => draft.value = draft.value.copyWith(preparedBy: v);
  void setExecutiveSummary(String v) => draft.value = draft.value.copyWith(executiveSummary: v);

  void updateZonalField(String zone, String key, String value) {
    final current = Map<String, ZonalForecast>.from(draft.value.zonalForecasts);
    final existing = current[zone]!;
    current[zone] = _applyZonalField(existing, key, value);
    draft.value = draft.value.copyWith(zonalForecasts: current);
  }

  ZonalForecast _applyZonalField(ZonalForecast z, String key, String v) {
    switch (key) {
      case 'onset_category':           return z.copyWith(onsetCategory: v);
      case 'onset_date_range':         return z.copyWith(onsetDateRange: v);
      case 'rainfall_category':        return z.copyWith(rainfallCategory: v);
      case 'rainfall_range_mm':        return z.copyWith(rainfallRangeMm: v);
      case 'early_dry_spell_category': return z.copyWith(earlyDrySpellCategory: v);
      case 'early_dry_spell_days':     return z.copyWith(earlyDrySpellDays: v);
      case 'late_dry_spell_category':  return z.copyWith(lateDrySpellCategory: v);
      case 'late_dry_spell_days':      return z.copyWith(lateDrySpellDays: v);
      case 'cessation_category':       return z.copyWith(cessationCategory: v);
      case 'cessation_date_range':     return z.copyWith(cessationDateRange: v);
      case 'season_length_category':   return z.copyWith(seasonLengthCategory: v);
      case 'season_length_days':       return z.copyWith(seasonLengthDays: v);
      default: return z;
    }
  }

  void addAdvisory(String text) {
    if (text.trim().isEmpty) return;
    final list = List<String>.from(draft.value.advisories)..add(text.trim());
    draft.value = draft.value.copyWith(advisories: list);
  }

  void removeAdvisory(int index) {
    final list = List<String>.from(draft.value.advisories)..removeAt(index);
    draft.value = draft.value.copyWith(advisories: list);
  }

  // ==========================================================================
  // SAVE DRAFT
  // ==========================================================================

  Future<void> saveDraft() async {
    try {
      isSavingDraft.value = true;
      errorMessage.value = '';

      final toSave = draft.value.copyWith(status: 'draft');
      final id = await _svc.saveDraft(toSave.copyWith(id: _draftId));

      // After first save, store the ID so subsequent saves are updates
      if (_draftId == null) {
        _draftId = id;
        draft.value = draft.value.copyWith(id: id);
      }

      Get.snackbar(
        "Draft Saved",
        "Forecast saved — you can continue editing.",
        backgroundColor: Colors.blue.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
        icon: Icon(PhosphorIcons.floppyDisk(), color: Colors.white),
      );
    } catch (e) {
      errorMessage.value = 'Save failed: $e';
      Get.snackbar(
        "Save Failed",
        e.toString(),
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
      );
    } finally {
      isSavingDraft.value = false;
    }
  }

  // ==========================================================================
  // PUBLISH
  // ==========================================================================

  Future<void> publishForecast() async {
    try {
      isPublishing.value = true;
      errorMessage.value = '';

      // Save latest state first, then flip status to published
      final id = await _svc.saveDraft(
        draft.value.copyWith(id: _draftId, status: 'published'),
      );
      _draftId ??= id;

      // Minimal update: just flip status (cheapest possible write)
      await _svc.publishForecast(id);

      draft.value = draft.value.copyWith(id: id, status: 'published');

      Get.snackbar(
        "Published!",
        "Forecast is now visible to farmers and stakeholders.",
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
        icon: Icon(PhosphorIcons.checkCircle(), color: Colors.white),
        duration: const Duration(seconds: 4),
      );

      // Refresh archives and go back to the list
      await _refreshArchives();
      tabController.animateTo(0);
    } catch (e) {
      errorMessage.value = 'Publish failed: $e';
      Get.snackbar(
        "Publish Failed",
        e.toString(),
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
      );
    } finally {
      isPublishing.value = false;
    }
  }

  // ==========================================================================
  // ARCHIVES
  // ==========================================================================

  Future<void> _loadArchives() async {
    try {
      isLoadingArchives.value = true;
      _svc.resetArchivePagination();
      archives.value = await _svc.fetchArchivesPage();
    } catch (e) {
      errorMessage.value = 'Failed to load archives: $e';
    } finally {
      isLoadingArchives.value = false;
    }
  }

  Future<void> _refreshArchives() async {
    _svc.resetArchivePagination();
    archives.value = await _svc.fetchArchivesPage();
    archivesExhausted.value = false;
  }

  Future<void> refreshArchives() => _refreshArchives();

  Future<void> loadMoreArchives() async {
    if (isLoadingMore.value || archivesExhausted.value) return;
    try {
      isLoadingMore.value = true;
      final more = await _svc.fetchArchivesPage();
      if (more.isEmpty) {
        archivesExhausted.value = true;
      } else {
        archives.addAll(more);
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Load a past forecast into the editor for viewing/editing
  Future<void> loadForecastForEditing(String id) async {
    try {
      isLoadingConfig.value = true;
      final forecast = await _svc.fetchForecast(id);
      if (forecast == null) return;
      draft.value = forecast;
      _draftId = id;
      tabController.animateTo(1);
    } finally {
      isLoadingConfig.value = false;
    }
  }

  // ==========================================================================
  // MAP COLOUR HELPERS
  // ==========================================================================

  Color getRegionColor(String region) {
    final zone = regionToZone[region] ?? '';
    final zf = draft.value.zonalForecasts[zone];
    if (zf == null) return Colors.grey.shade400;
    switch (zf.rainfallCategory) {
      case 'Above Normal': return Colors.green.shade600;
      case 'Below Normal': return Colors.red.shade400;
      default:             return Colors.yellow.shade600;
    }
  }

  // ==========================================================================
  // STATIC GEOGRAPHIC DATA
  // (boundary coordinates never change — kept static, not in Firestore)
  // ==========================================================================

  static const Map<String, String> regionToZone = {
    "Northern Region":     "Northern Sector",
    "Savannah Region":     "Northern Sector",
    "North East Region":   "Northern Sector",
    "Upper East Region":   "Northern Sector",
    "Upper West Region":   "Northern Sector",
    "Bono Region":         "Transition Zone",
    "Bono East Region":    "Transition Zone",
    "Ahafo Region":        "Transition Zone",
    "Oti Region":          "Transition Zone",
    "Ashanti Region":      "Forest Zone",
    "Eastern Region":      "Forest Zone",
    "Western Region":      "West Coast",
    "Western North Region":"West Coast",
    "Central Region":      "West Coast",
    "Volta Region":        "East Coast",
    "Greater Accra Region":"East Coast",
  };

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  static SeasonalForecastModel _emptyDraft() =>
      _emptyDraftFromConfig(ForecastConfig.defaults());

  static SeasonalForecastModel _emptyDraftFromConfig(ForecastConfig cfg) {
    final zones = Map.fromEntries(
      cfg.zones.map((z) => MapEntry(z, _defaultZonalForecast(z, cfg))),
    );
    return SeasonalForecastModel(
      title: '',
      season: cfg.seasonOptions.isNotEmpty ? cfg.seasonOptions.first : '',
      year: DateTime.now().year.toString(),
      issuedDate: '',
      preparedBy: '',
      executiveSummary: '',
      status: 'draft',
      accuracy: '--',
      zonalForecasts: zones,
      advisories: [],
    );
  }

  static ZonalForecast _defaultZonalForecast(String zone, ForecastConfig cfg) {
    return ZonalForecast(
      zone: zone,
      onsetCategory: cfg.onsetCategories.contains('Normal')
          ? 'Normal' : cfg.onsetCategories.first,
      onsetDateRange: '',
      rainfallCategory: cfg.rainfallCategories.contains('Normal')
          ? 'Normal' : cfg.rainfallCategories.first,
      rainfallRangeMm: '',
      earlyDrySpellCategory: cfg.drySpellCategories.contains('Normal (11-15 days)')
          ? 'Normal (11-15 days)' : cfg.drySpellCategories.first,
      earlyDrySpellDays: '',
      lateDrySpellCategory: cfg.drySpellCategories.contains('Normal (11-15 days)')
          ? 'Normal (11-15 days)' : cfg.drySpellCategories.first,
      lateDrySpellDays: '',
      cessationCategory: cfg.cessationCategories.contains('Normal')
          ? 'Normal' : cfg.cessationCategories.first,
      cessationDateRange: '',
      seasonLengthCategory: cfg.seasonLengthCategories.contains('Normal')
          ? 'Normal' : cfg.seasonLengthCategories.first,
      seasonLengthDays: '',
    );
  }
}