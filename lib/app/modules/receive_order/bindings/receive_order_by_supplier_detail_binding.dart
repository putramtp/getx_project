import 'package:get/get.dart';
import '../controllers/receive_order_by_supplier_detail_controller.dart';
import '../../../data/providers/receive_order_provider.dart';

class ReceiveOrderBySupplierDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderBySupplierDetailController>(() => ReceiveOrderBySupplierDetailController());
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
  }
}
