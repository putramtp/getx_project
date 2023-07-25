import 'package:get/get.dart';

import '../controllers/dispatch_controller.dart';
import '../controllers/dispatch_detail_controller.dart';

class DispatchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DispatchController>(
      () => DispatchController(),
    );
    Get.lazyPut<DispatchDetailController>(
      () => DispatchDetailController(),
    );
  }
}
