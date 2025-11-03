import 'package:get/get.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_detail_controller.dart';
import 'package:getx_project/app/modules/receive_order/providers/receive_order_provider.dart';

class ReceiveOrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderDetailController>(() => ReceiveOrderDetailController());
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
  }
}
