import 'package:get/get.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_by_supplier_detail_controller.dart';
import 'package:getx_project/app/modules/receive_order/providers/receive_order_provider.dart';

class ReceiveOrderSupplierDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiveOrderBySupplierDetailController>(() => ReceiveOrderBySupplierDetailController());
    Get.lazyPut<ReceiveOrderProvider>(() => ReceiveOrderProvider());
  }
}
