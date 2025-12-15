import 'package:get/get.dart';

import '../controllers/receive_order_by_supplier_controller.dart';
import '../../../data/providers/receive_order_provider.dart';

class ReceiveOrderBySupplierBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderBySupplierController>(() => ReceiveOrderBySupplierController());
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
  }
}
