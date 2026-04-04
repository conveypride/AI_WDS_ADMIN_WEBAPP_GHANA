// lib/app/bindings/five_day_forecast_binding.dart
import 'package:get/get.dart';
import '../controllers/five_day_forecast_controller.dart';

class FiveDayForecastBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FiveDayForecastController>(
      () => FiveDayForecastController(),
      fenix: true,
    );
  }
}