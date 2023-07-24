import 'package:get/get.dart';

import '../controllers/receive_controller.dart';
import '../controllers/receive_detail_controller.dart';

class ReceiveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveController>(
      () => ReceiveController(),
    );
    Get.lazyPut<ReceiveDetailController>(
      () => ReceiveDetailController(),
    );
  }
}
