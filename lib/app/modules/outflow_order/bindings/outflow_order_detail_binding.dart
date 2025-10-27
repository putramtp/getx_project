import 'package:get/get.dart';
import 'package:getx_project/app/modules/outflow_order/controllers/outflow_order_detail_controller.dart';
import 'package:getx_project/app/modules/outflow_order/providers/outflow_order_provider.dart';

class OutflowOrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OutflowOrderDetailController>(() => OutflowOrderDetailController());
    Get.lazyPut<OutflowOrderProvider>(() => OutflowOrderProvider());
  }
}
