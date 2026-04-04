// lib/app/services/polygon_drawing_service.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class PolygonDrawingService {
  static LatLng convertScreenToLatLng(
    Offset screenPosition,
    MapController mapController,
    BuildContext context,
  ) {
    try {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final localPosition = box.globalToLocal(screenPosition);
      final camera = mapController.camera;
      final bounds = camera.visibleBounds;
      final size = box.size;
      
      final xFraction = localPosition.dx / size.width;
      final yFraction = localPosition.dy / size.height;
      
      final lng = bounds.west + (bounds.east - bounds.west) * xFraction;
      final lat = bounds.north - (bounds.north - bounds.south) * yFraction;
      
      return LatLng(lat, lng);
    } catch (e) {
      throw Exception('Failed to convert screen to latlng: $e');
    }
  }
  
  static bool isPolygonClosed(List<LatLng> points, {double thresholdKm = 5.0}) {
    if (points.length < 3) return false;
    
    try {
      final first = points.first;
      final last = points.last;
      final distance = const Distance().distance(first, last) / 1000;
      
      return distance < thresholdKm;
    } catch (e) {
      return false;
    }
  }
  
  static LatLng calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(7.9465, -1.0232);
    
    double latSum = 0;
    double lngSum = 0;
    
    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    
    return LatLng(latSum / points.length, lngSum / points.length);
  }
  
  static List<LatLng> convertDynamicPoints(List<dynamic> points) {
    final List<LatLng> latLngPoints = [];
    
    for (var point in points) {
      if (point is LatLng) {
        latLngPoints.add(point);
      } else if (point is Map<String, dynamic>) {
        final lat = point['latitude'] ?? point['lat'] ?? 0.0;
        final lng = point['longitude'] ?? point['lng'] ?? point['lon'] ?? 0.0;
        latLngPoints.add(LatLng(lat.toDouble(), lng.toDouble()));
      } else if (point is List && point.length >= 2) {
        latLngPoints.add(LatLng(
          (point[0] ?? 0.0).toDouble(),
          (point[1] ?? 0.0).toDouble(),
        ));
      }
    }
    
    return latLngPoints;
  }
}