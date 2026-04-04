// lib/app/helpers/color_helper.dart
import 'package:flutter/material.dart';

class ColorHelper {
  static Color fromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red[400]!;
      case 'yellow':
        return Colors.yellow[600]!;
      case 'green':
        return Colors.green[400]!;
      case 'orange':
        return Colors.orange[400]!;
      case 'blue':
        return Colors.blue[400]!;
      case 'purple':
        return Colors.purple[400]!;
      default:
        return Colors.grey;
    }
  }
  
  static Color getRiskColor(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'A':
      case 'D':
      case 'G':
        return Colors.green[400]!;
      case 'B':
      case 'C':
      case 'E':
        return Colors.yellow[600]!;
      case 'F':
      case 'H':
        return Colors.orange[400]!;
      case 'I':
        return Colors.red[400]!;
      default:
        return Colors.grey;
    }
  }
}