import 'package:get/get.dart';
import '../../../modules/outflow_order/controllers/outflow_order_list_controller.dart';
import '../../../data/providers/outflow_order_provider.dart';

class OutflowOrderListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OutflowOrderListController>(() => OutflowOrderListController());
    Get.lazyPut<OutflowOrderProvider>(() => OutflowOrderProvider());
  }
}
