// lib/app/bindings/seasonal_forecast_binding.dart
import 'package:get/get.dart';
import '../controllers/seasonal_forecast_controller.dart';

class SeasonalForecastBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SeasonalForecastController>(
      () => SeasonalForecastController(),
      fenix: true,
    );
  }
}