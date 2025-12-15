import 'package:get/get.dart';
import '../../../modules/receive_order/controllers/receive_order_list_controller.dart';
import '../../../data/providers/receive_order_provider.dart';

class ReceiveOrderListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderListController>(() => ReceiveOrderListController());
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
  }
}
