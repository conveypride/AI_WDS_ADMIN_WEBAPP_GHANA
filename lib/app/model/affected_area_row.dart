import 'package:flutter/material.dart';

class AffectedAreaRow {
  String areas;
  String validTime;
  String t1; 
  String t2; 
  String t3; 
  String outlook; 

  late TextEditingController areaController;
  late TextEditingController timeController;

  AffectedAreaRow({
    required this.areas,
    required this.validTime,
    this.t1 = 'A',
    this.t2 = 'A',
    this.t3 = 'A',
    this.outlook = 'A',
  }) {
    areaController = TextEditingController(text: areas);
    timeController = TextEditingController(text: validTime);
  }

  Map<String, dynamic> toJson() => {
    'areas': areaController.text,
    'validTime': timeController.text,
    't1': t1,
    't2': t2,
    't3': t3,
    'outlook': outlook,
  };

  factory AffectedAreaRow.fromJson(Map<String, dynamic> json) => AffectedAreaRow(
    areas: json['areas'] ?? '',
    validTime: json['validTime'] ?? '',
    t1: json['t1'] ?? 'A',
    t2: json['t2'] ?? 'A',
    t3: json['t3'] ?? 'A',
    outlook: json['outlook'] ?? 'A',
  );

  void dispose() {
    areaController.dispose();
    timeController.dispose();
  }
}
