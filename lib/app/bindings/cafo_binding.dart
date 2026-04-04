// lib/app/bindings/cafo_binding.dart
import 'package:get/get.dart';
import '../controllers/cafo_controller.dart';

class CAFOBinding implements Bindings {
  @override
  void dependencies() {
    // Remove the 'tag' and 'fenix' parameters - they cause issues
    Get.lazyPut<CAFOController>(
      () => CAFOController(),
    );
  }
}