import 'package:get/get.dart';
import '../../../modules/receive_order/controllers/receive_order_list_detail_controller.dart';
import '../../../data/providers/receive_order_provider.dart';

class ReceiveOrderListDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderListDetailController>(() => ReceiveOrderListDetailController());
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
  }
}
