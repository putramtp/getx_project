import 'package:get/get.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_list_controller.dart';
import 'package:getx_project/app/modules/receive_order/providers/receive_order_provider.dart';

class ReceiveOrderListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderListController>(() => ReceiveOrderListController());
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
  }
}
