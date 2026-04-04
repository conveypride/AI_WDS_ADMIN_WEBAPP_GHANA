
import 'package:flutter_map/flutter_map.dart';

class ForecastFrame {
  final String timeslot;
  final int offset;
  final String timeParam;

  ForecastFrame({
    required this.timeslot,
    required this.offset,
    required this.timeParam,
  });

  // ── FIX 1: All fields null-safe with fallbacks ──────────────────────────────
  factory ForecastFrame.fromJson(Map<String, dynamic> json) {
    // 'timeslot' may be keyed differently or null — try several keys
    final rawTimeslot =
        (json['timeslot'] ?? json['time'] ?? json['datetime'] ?? '')
            .toString()
            .trim();

    // If we still have an empty string, use "now" as a sentinel
    final timeslot =
        rawTimeslot.isNotEmpty ? rawTimeslot : DateTime.now().toIso8601String();

    DateTime date;
    try {
      date = DateTime.parse(timeslot);
    } catch (_) {
      date = DateTime.now();
    }

    final timeParam =
        "${date.year}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.day.toString().padLeft(2, '0')}/"
        "${date.hour.toString().padLeft(2, '0')}/"
        "${date.minute.toString().padLeft(2, '0')}";

    // 'offset' may be int, double, or null
    final rawOffset = json['offset'];
    final offset = rawOffset is int
        ? rawOffset
        : rawOffset is double
            ? rawOffset.round()
            : rawOffset is String
                ? int.tryParse(rawOffset) ?? 0
                : 0;

    return ForecastFrame(
      timeslot: timeslot,
      offset: offset,
      timeParam: timeParam,
    );
  }
}

class CachedFrame {
  final List<Polygon> crrPolygons;
  final List<Polygon> rdtPolygons;
  final List<Polyline> rdtPolylines;
  final DateTime timestamp;

  CachedFrame({
    required this.crrPolygons,
    required this.rdtPolygons,
    required this.rdtPolylines,
    required this.timestamp,
  });
}