import 'package:latlong2/latlong.dart';
import 'package:weather_admin_dashboard/app/model/weekendItemType.dart';

class WeekendMapItem {
  final String id;
  final WeekendItemType type;
  final String value;
  LatLng position;
  WeekendMapItem({required this.id, required this.type, required this.value, required this.position});
}
