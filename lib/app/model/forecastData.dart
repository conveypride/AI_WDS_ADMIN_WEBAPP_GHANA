class ForecastData {
  String date;
  String timeIssued;
  String validFrom;
  String warningType;
  String weatherSummary;
  String caution;
  String notaBene;
  String seastate;
  // Using Dart Records for min/max
  Map<String, ({int min, int max})> sectorTemperatures;

  ForecastData({
    required this.date,
    required this.timeIssued,
    required this.validFrom,
    required this.warningType,
    required this.weatherSummary,
    required this.caution,
    required this.notaBene,
    required this.sectorTemperatures,
    required this.seastate,
  });

  // ✅ Added copyWith method to fix the error
  ForecastData copyWith({
    String? date,
    String? timeIssued,
    String? validFrom,
    String? warningType,
    String? weatherSummary,
    String? caution,
    String? notaBene,
    String? seastate,
    Map<String, ({int min, int max})>? sectorTemperatures,
  }) {
    return ForecastData(
      seastate: seastate ?? this.seastate,
      date: date ?? this.date,
      timeIssued: timeIssued ?? this.timeIssued,
      validFrom: validFrom ?? this.validFrom,
      warningType: warningType ?? this.warningType,
      weatherSummary: weatherSummary ?? this.weatherSummary,
      caution: caution ?? this.caution,
      notaBene: notaBene ?? this.notaBene,
      sectorTemperatures: sectorTemperatures ?? this.sectorTemperatures,
    );
  }
}