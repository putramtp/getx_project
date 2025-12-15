import 'package:get/get.dart';
import '../../../modules/outflow_order/controllers/outflow_order_by_customer_controller.dart';
import '../../../data/providers/outflow_order_provider.dart';


class OutflowOrderByCustomerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OutflowOrderByCustomerController>(() => OutflowOrderByCustomerController());
    Get.lazyPut<OutflowOrderProvider>(() => OutflowOrderProvider());
  }
}
