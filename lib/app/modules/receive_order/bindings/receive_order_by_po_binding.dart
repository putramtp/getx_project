import 'package:get/get.dart';
import '../../../modules/receive_order/controllers/receive_order_by_po_controller.dart';
import '../../../data/providers/receive_order_provider.dart';

class ReceiveOrderByPoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderByPoController>(() => ReceiveOrderByPoController());
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
  }
}
