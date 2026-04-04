import 'package:latlong2/latlong.dart';
import 'package:weather_admin_dashboard/app/model/midWeekItemType.dart';

class MidWeekMapItem {
  final String id;
  final MidWeekItemType type;
  final String value;
  LatLng position;
  MidWeekMapItem({required this.id, required this.type, required this.value, required this.position});
}
