import 'package:get/get.dart';
import 'package:getx_project/app/modules/outflow_order/controllers/outflow_order_controller.dart';
import 'package:getx_project/app/modules/outflow_order/providers/outflow_order_provider.dart';

class OutflowOrderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OutflowOrderController>(() => OutflowOrderController());
    Get.lazyPut<OutflowOrderProvider>(() => OutflowOrderProvider());
  }
}
