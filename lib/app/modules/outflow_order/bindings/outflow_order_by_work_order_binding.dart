import 'package:get/get.dart';
import '../../../data/providers/outflow_order_provider.dart';
import '../controllers/outflow_order_by_customer_controller.dart';
import '../controllers/outflow_order_by_work_order_controller.dart';

/// The By Customer list view serves By Work Order: it finds the list
/// controller by the shared type, here the work-order one.
class OutflowOrderByWorkOrderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OutflowOrderByCustomerController>(() => OutflowOrderByWorkOrderController());
    Get.lazyPut<OutflowOrderProvider>(() => OutflowOrderProvider());
  }
}
