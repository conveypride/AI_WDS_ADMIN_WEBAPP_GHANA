import 'package:get/get.dart';
import 'package:weather_admin_dashboard/app/controllers/weather_update_controller.dart';

class WeatherUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WeatherUpdateController>(
      () => WeatherUpdateController(),
    );
  }
}
