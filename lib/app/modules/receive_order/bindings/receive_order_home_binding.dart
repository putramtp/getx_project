import 'package:get/get.dart';

import '../controllers/receive_order_home_controller.dart';
import '../../../data/providers/receive_order_provider.dart';

class ReceiveOrderHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
    Get.lazyPut<ReceiveOrderHomeController>(() => ReceiveOrderHomeController());
  }
}
