import 'package:latlong2/latlong.dart';
import 'package:weather_admin_dashboard/app/model/weeklyItemType.dart';

class WeeklyMapItem {
  final String id;
  final WeeklyItemType type;
  final String value;
  LatLng position;
  WeeklyMapItem({required this.id, required this.type, required this.value, required this.position});
}
