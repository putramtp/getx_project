import 'package:get/get.dart';

import '../controllers/receive_order_list_controller.dart';
import '../../../data/providers/receive_order_provider.dart';

class ReceiveOrderListBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    final pending = args is Map && args['serial_status'] == 'pending';
    Get.lazyPut<ReceiveOrderListController>(() => ReceiveOrderListController(pendingSerialOnly: pending));
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
  }
}
