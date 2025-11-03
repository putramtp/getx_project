import 'package:get/get.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_by_supplier_controller.dart';
import 'package:getx_project/app/modules/receive_order/providers/receive_order_provider.dart';

class ReceiveOrderBySupplierBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderBySupplierController>(() => ReceiveOrderBySupplierController());
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
  }
}
