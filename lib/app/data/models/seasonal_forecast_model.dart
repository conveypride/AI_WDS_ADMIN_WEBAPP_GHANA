import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// ZONAL FORECAST MODEL
// Represents one zone's forecast parameters for a season.
// ============================================================================
class ZonalForecast {
  final String zone;
  final String onsetCategory;
  final String onsetDateRange;
  final String rainfallCategory;
  final String rainfallRangeMm;
  final String earlyDrySpellCategory;
  final String earlyDrySpellDays;
  final String lateDrySpellCategory;
  final String lateDrySpellDays;
  final String cessationCategory;
  final String cessationDateRange;
  final String seasonLengthCategory;
  final String seasonLengthDays;

  ZonalForecast({
    required this.zone,
    required this.onsetCategory,
    required this.onsetDateRange,
    required this.rainfallCategory,
    required this.rainfallRangeMm,
    required this.earlyDrySpellCategory,
    required this.earlyDrySpellDays,
    required this.lateDrySpellCategory,
    required this.lateDrySpellDays,
    required this.cessationCategory,
    required this.cessationDateRange,
    required this.seasonLengthCategory,
    required this.seasonLengthDays,
  });

  factory ZonalForecast.fromMap(String zone, Map<String, dynamic> m) {
    return ZonalForecast(
      zone: zone,
      onsetCategory: m['onset_category'] ?? 'Normal',
      onsetDateRange: m['onset_date_range'] ?? '',
      rainfallCategory: m['rainfall_category'] ?? 'Normal',
      rainfallRangeMm: m['rainfall_range_mm'] ?? '',
      earlyDrySpellCategory: m['early_dry_spell_category'] ?? 'Normal (11-15 days)',
      earlyDrySpellDays: m['early_dry_spell_days'] ?? '',
      lateDrySpellCategory: m['late_dry_spell_category'] ?? 'Normal (11-15 days)',
      lateDrySpellDays: m['late_dry_spell_days'] ?? '',
      cessationCategory: m['cessation_category'] ?? 'Normal',
      cessationDateRange: m['cessation_date_range'] ?? '',
      seasonLengthCategory: m['season_length_category'] ?? 'Normal',
      seasonLengthDays: m['season_length_days'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'onset_category': onsetCategory,
    'onset_date_range': onsetDateRange,
    'rainfall_category': rainfallCategory,
    'rainfall_range_mm': rainfallRangeMm,
    'early_dry_spell_category': earlyDrySpellCategory,
    'early_dry_spell_days': earlyDrySpellDays,
    'late_dry_spell_category': lateDrySpellCategory,
    'late_dry_spell_days': lateDrySpellDays,
    'cessation_category': cessationCategory,
    'cessation_date_range': cessationDateRange,
    'season_length_category': seasonLengthCategory,
    'season_length_days': seasonLengthDays,
  };

  ZonalForecast copyWith({
    String? onsetCategory,
    String? onsetDateRange,
    String? rainfallCategory,
    String? rainfallRangeMm,
    String? earlyDrySpellCategory,
    String? earlyDrySpellDays,
    String? lateDrySpellCategory,
    String? lateDrySpellDays,
    String? cessationCategory,
    String? cessationDateRange,
    String? seasonLengthCategory,
    String? seasonLengthDays,
  }) {
    return ZonalForecast(
      zone: zone,
      onsetCategory: onsetCategory ?? this.onsetCategory,
      onsetDateRange: onsetDateRange ?? this.onsetDateRange,
      rainfallCategory: rainfallCategory ?? this.rainfallCategory,
      rainfallRangeMm: rainfallRangeMm ?? this.rainfallRangeMm,
      earlyDrySpellCategory: earlyDrySpellCategory ?? this.earlyDrySpellCategory,
      earlyDrySpellDays: earlyDrySpellDays ?? this.earlyDrySpellDays,
      lateDrySpellCategory: lateDrySpellCategory ?? this.lateDrySpellCategory,
      lateDrySpellDays: lateDrySpellDays ?? this.lateDrySpellDays,
      cessationCategory: cessationCategory ?? this.cessationCategory,
      cessationDateRange: cessationDateRange ?? this.cessationDateRange,
      seasonLengthCategory: seasonLengthCategory ?? this.seasonLengthCategory,
      seasonLengthDays: seasonLengthDays ?? this.seasonLengthDays,
    );
  }
}

// ============================================================================
// SEASONAL FORECAST MODEL
// One complete seasonal forecast document stored in Firestore.
// Firestore path: seasonal_forecasts/{docId}
// ============================================================================
class SeasonalForecastModel {
  final String? id;            // Firestore document ID (null when creating)
  final String title;
  final String season;         // e.g. "SON", "MAM", "JJAS"
  final String year;
  final String issuedDate;
  final String preparedBy;
  final String executiveSummary;
  final String status;         // "draft" | "published"
  final String accuracy;       // Verification score, filled post-season
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Zone forecasts: key = zone name, value = ZonalForecast
  final Map<String, ZonalForecast> zonalForecasts;

  // Advisories for farmers
  final List<String> advisories;

  SeasonalForecastModel({
    this.id,
    required this.title,
    required this.season,
    required this.year,
    required this.issuedDate,
    required this.preparedBy,
    required this.executiveSummary,
    required this.status,
    required this.accuracy,
    required this.zonalForecasts,
    required this.advisories,
    this.createdAt,
    this.updatedAt,
  });

  // ── Deserialise from Firestore ──────────────────────────────────────────
  factory SeasonalForecastModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Rebuild zonalForecasts map from nested Firestore map
    final rawZones = data['zonal_forecasts'] as Map<String, dynamic>? ?? {};
    final zonalForecasts = rawZones.map((zone, rawData) {
      return MapEntry(
        zone,
        ZonalForecast.fromMap(zone, rawData as Map<String, dynamic>),
      );
    });

    return SeasonalForecastModel(
      id: doc.id,
      title: data['title'] ?? '',
      season: data['season'] ?? '',
      year: data['year'] ?? '',
      issuedDate: data['issued_date'] ?? '',
      preparedBy: data['prepared_by'] ?? '',
      executiveSummary: data['executive_summary'] ?? '',
      status: data['status'] ?? 'draft',
      accuracy: data['accuracy'] ?? '--',
      zonalForecasts: zonalForecasts,
      advisories: List<String>.from(data['advisories'] ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  // ── Serialise to Firestore ──────────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
    'title': title,
    'season': season,
    'year': year,
    'issued_date': issuedDate,
    'prepared_by': preparedBy,
    'executive_summary': executiveSummary,
    'status': status,
    'accuracy': accuracy,
    'zonal_forecasts': zonalForecasts.map((k, v) => MapEntry(k, v.toMap())),
    'advisories': advisories,
    'updated_at': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toFirestoreCreate() => {
    ...toFirestore(),
    'created_at': FieldValue.serverTimestamp(),
  };

  SeasonalForecastModel copyWith({
    String? id,
    String? title,
    String? season,
    String? year,
    String? issuedDate,
    String? preparedBy,
    String? executiveSummary,
    String? status,
    String? accuracy,
    Map<String, ZonalForecast>? zonalForecasts,
    List<String>? advisories,
  }) {
    return SeasonalForecastModel(
      id: id ?? this.id,
      title: title ?? this.title,
      season: season ?? this.season,
      year: year ?? this.year,
      issuedDate: issuedDate ?? this.issuedDate,
      preparedBy: preparedBy ?? this.preparedBy,
      executiveSummary: executiveSummary ?? this.executiveSummary,
      status: status ?? this.status,
      accuracy: accuracy ?? this.accuracy,
      zonalForecasts: zonalForecasts ?? this.zonalForecasts,
      advisories: advisories ?? this.advisories,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ============================================================================
// FORECAST CONFIG MODEL
// Stored once at: app_config/forecast_config
// Holds zones list, category options — editable from Firebase Console.
// This avoids hardcoding categories in the app binary.
// ============================================================================
class ForecastConfig {
  final List<String> zones;
  final List<String> onsetCategories;
  final List<String> rainfallCategories;
  final List<String> drySpellCategories;
  final List<String> cessationCategories;
  final List<String> seasonLengthCategories;
  final List<String> seasonOptions; // e.g. ["MAM", "JJAS", "SON"]

  ForecastConfig({
    required this.zones,
    required this.onsetCategories,
    required this.rainfallCategories,
    required this.drySpellCategories,
    required this.cessationCategories,
    required this.seasonLengthCategories,
    required this.seasonOptions,
  });

  // Sensible defaults used when Firestore doc hasn't been created yet
  factory ForecastConfig.defaults() => ForecastConfig(
    zones: [
      "Northern Sector",
      "Transition Zone",
      "Forest Zone",
      "West Coast",
      "East Coast",
    ],
    onsetCategories: ["Early", "Normal", "Late"],
    rainfallCategories: ["Below Normal", "Normal", "Above Normal"],
    drySpellCategories: [
      "Short (5-10 days)",
      "Normal (11-15 days)",
      "Long (16+ days)",
    ],
    cessationCategories: ["Early", "Normal", "Late"],
    seasonLengthCategories: ["Short", "Normal", "Long"],
    seasonOptions: ["MAM", "JJAS", "SON"],
  );

  factory ForecastConfig.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ForecastConfig(
      zones: List<String>.from(d['zones'] ?? []),
      onsetCategories: List<String>.from(d['onset_categories'] ?? []),
      rainfallCategories: List<String>.from(d['rainfall_categories'] ?? []),
      drySpellCategories: List<String>.from(d['dry_spell_categories'] ?? []),
      cessationCategories: List<String>.from(d['cessation_categories'] ?? []),
      seasonLengthCategories: List<String>.from(d['season_length_categories'] ?? []),
      seasonOptions: List<String>.from(d['season_options'] ?? []),
    );
  }
}