import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsModel {
  final List<String> cities;
  final List<String> weatherConditions;

  SettingsModel({
    required this.cities,
    required this.weatherConditions,
  });

  factory SettingsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SettingsModel(
      cities: List<String>.from(data['cities'] ?? []),
      weatherConditions: List<String>.from(data['weatherConditions'] ?? []),
    );
  }

  // Optional: If you want super admins to be able to add new cities/weather from the app
  Map<String, dynamic> toFirestore() {
    return {
      'cities': cities,
      'weatherConditions': weatherConditions,
    };
  }
}