class InlandForecastData {
  String date;
  String timeIssued;
  String validFrom;
  String warningType;
  String weatherSummary;
  String caution;
  String notaBene;
  String seastate; 

  InlandForecastData({
    required this.date,
    required this.timeIssued,
    required this.validFrom,
    required this.warningType,
    required this.weatherSummary,
    required this.caution,
    required this.notaBene, 
    required this.seastate,
  });

  // ✅ Added copyWith method to fix the error
  InlandForecastData copyWith({
    String? date,
    String? timeIssued,
    String? validFrom,
    String? warningType,
    String? weatherSummary,
    String? caution,
    String? notaBene,
    String? seastate, 
  }) {
    return InlandForecastData(
      seastate: seastate ?? this.seastate,
      date: date ?? this.date,
      timeIssued: timeIssued ?? this.timeIssued,
      validFrom: validFrom ?? this.validFrom,
      warningType: warningType ?? this.warningType,
      weatherSummary: weatherSummary ?? this.weatherSummary,
      caution: caution ?? this.caution,
      notaBene: notaBene ?? this.notaBene, 
    );
  }
}