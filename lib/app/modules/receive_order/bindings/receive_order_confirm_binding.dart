import 'package:get/get.dart';

import '../controllers/receive_order_confirm_controller.dart';
import '../../../data/providers/receive_order_provider.dart';

class ReceiveOrderConfirmBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
    Get.lazyPut<ReceiveOrderConfirmController>(() => ReceiveOrderConfirmController());
  }
}
