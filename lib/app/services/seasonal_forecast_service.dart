import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weather_admin_dashboard/app/data/models/seasonal_forecast_model.dart'; 

// ============================================================================
// SEASONAL FORECAST SERVICE
//
// COST OPTIMISATION STRATEGY (important for startup budget):
//
// 1. CACHE-FIRST for config: ForecastConfig is fetched once per session and
//    cached in memory. Config almost never changes, so no listener is kept open.
//
// 2. PAGINATION for archives: we load 10 forecasts at a time with a cursor,
//    never pulling the whole collection in one go.
//
// 3. SINGLE REAL-TIME LISTENER for the draft being edited: only the active
//    draft document gets a live snapshot listener. All others are one-shot gets.
//
// 4. SINGLE ATOMIC WRITE: saveDraft() and publishForecast() use a single
//    set() call. No multi-step transactions needed because one document = one
//    forecast.
//
// 5. SERVER TIMESTAMPS: updated_at and created_at use FieldValue.serverTimestamp()
//    so the client never sends a clock value.
//
// 6. NO SUBCOLLECTIONS: zonal_forecasts is nested inside the forecast document
//    as a map, not a subcollection — saves read charges (1 read vs 5+ reads).
//
// Firestore structure:
//   seasonal_forecasts/{forecastId}          ← one document per forecast
//   app_config/forecast_config               ← single config document
// ============================================================================

class SeasonalForecastService {
  SeasonalForecastService._();
  static final SeasonalForecastService instance = SeasonalForecastService._();

  final _db = FirebaseFirestore.instance;

  // Collection refs
  CollectionReference<Map<String, dynamic>> get _forecastsCol =>
      _db.collection('seasonal_forecasts');

  DocumentReference<Map<String, dynamic>> get _configDoc =>
      _db.collection('app_config').doc('forecast_config');

  // ── In-memory session cache for config (zero re-reads per session) ────────
  ForecastConfig? _cachedConfig;

  // ── Pagination cursor for archives ────────────────────────────────────────
  DocumentSnapshot? _lastArchiveDoc;
  bool _archivesExhausted = false;
  static const int _pageSize = 10;

  void resetArchivePagination() {
    _lastArchiveDoc = null;
    _archivesExhausted = false;
  }

  // ==========================================================================
  // CONFIG  (1 read per session max)
  // ==========================================================================

  Future<ForecastConfig> getConfig() async {
    if (_cachedConfig != null) return _cachedConfig!;

    try {
      final doc = await _configDoc.get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists) {
        _cachedConfig = ForecastConfig.fromFirestore(doc);
      } else {
        // First run — bootstrap the config document so future reads are free
        _cachedConfig = ForecastConfig.defaults();
        await _bootstrapConfig(_cachedConfig!);
      }
    } catch (_) {
      _cachedConfig = ForecastConfig.defaults();
    }

    return _cachedConfig!;
  }

  /// Write defaults to Firestore once on first ever run.
  Future<void> _bootstrapConfig(ForecastConfig cfg) async {
    await _configDoc.set({
      'zones': cfg.zones,
      'onset_categories': cfg.onsetCategories,
      'rainfall_categories': cfg.rainfallCategories,
      'dry_spell_categories': cfg.drySpellCategories,
      'cessation_categories': cfg.cessationCategories,
      'season_length_categories': cfg.seasonLengthCategories,
      'season_options': cfg.seasonOptions,
    });
  }

  // ==========================================================================
  // ARCHIVES — paginated, published + draft both visible to admin
  // ==========================================================================

  /// Returns the next page of forecasts.  Call [resetArchivePagination] first
  /// whenever the user refreshes or changes filters.
  Future<List<SeasonalForecastModel>> fetchArchivesPage() async {
    if (_archivesExhausted) return [];

    Query<Map<String, dynamic>> query = _forecastsCol
        .orderBy('created_at', descending: true)
        .limit(_pageSize);

    if (_lastArchiveDoc != null) {
      query = query.startAfterDocument(_lastArchiveDoc!);
    }

    final snap = await query.get(const GetOptions(source: Source.serverAndCache));

    if (snap.docs.isEmpty || snap.docs.length < _pageSize) {
      _archivesExhausted = true;
    }

    if (snap.docs.isNotEmpty) {
      _lastArchiveDoc = snap.docs.last;
    }

    return snap.docs.map(SeasonalForecastModel.fromFirestore).toList();
  }

  // ==========================================================================
  // SINGLE FORECAST — one-shot read (no listener = no ongoing cost)
  // ==========================================================================

  Future<SeasonalForecastModel?> fetchForecast(String id) async {
    final doc = await _forecastsCol.doc(id).get(
      const GetOptions(source: Source.serverAndCache),
    );
    if (!doc.exists) return null;
    return SeasonalForecastModel.fromFirestore(doc);
  }

  // ==========================================================================
  // REAL-TIME LISTENER — only active while editing a specific draft
  // ==========================================================================

  StreamSubscription<DocumentSnapshot>? _draftSubscription;

  /// Open a real-time listener on one draft document.
  /// Cancels any previous listener automatically.
  StreamSubscription<DocumentSnapshot> listenToDraft(
    String id,
    void Function(SeasonalForecastModel) onData,
    void Function(Object) onError,
  ) {
    _draftSubscription?.cancel();
    _draftSubscription = _forecastsCol.doc(id).snapshots().listen(
      (snap) {
        if (snap.exists) onData(SeasonalForecastModel.fromFirestore(snap));
      },
      onError: onError,
    );
    return _draftSubscription!;
  }

  void cancelDraftListener() {
    _draftSubscription?.cancel();
    _draftSubscription = null;
  }

  // ==========================================================================
  // SAVE DRAFT — single document write
  // ==========================================================================

  /// Creates a new draft (returns the generated doc ID) or updates existing.
  Future<String> saveDraft(SeasonalForecastModel forecast) async {
    if (forecast.id == null) {
      // New document — let Firestore generate the ID
      final ref = await _forecastsCol.add(forecast.toFirestoreCreate());
      return ref.id;
    } else {
      await _forecastsCol.doc(forecast.id).set(
        forecast.toFirestore(),
        SetOptions(merge: true),
      );
      return forecast.id!;
    }
  }

  // ==========================================================================
  // PUBLISH — updates status field only (minimal write)
  // ==========================================================================

  Future<void> publishForecast(String id) async {
    await _forecastsCol.doc(id).update({
      'status': 'published',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================================
  // DELETE DRAFT
  // ==========================================================================

  Future<void> deleteForecast(String id) async {
    await _forecastsCol.doc(id).delete();
  }
}