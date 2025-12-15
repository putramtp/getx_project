import 'package:get/get.dart';
import '../../../modules/receive_order/controllers/receive_order_by_po_detail_controller.dart';
import '../../../data/providers/receive_order_provider.dart';

class ReceiveOrderByPoDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderByPoDetailController>(() => ReceiveOrderByPoDetailController());
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
  }
}
