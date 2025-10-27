import 'package:get/get.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_controller.dart';
import 'package:getx_project/app/modules/receive_order/providers/receive_order_provider.dart';

class ReceiveOrderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderController>(() => ReceiveOrderController());
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
  }
}
