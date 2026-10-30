import 'package:get/get.dart';
import '../../../data/providers/outflow_order_provider.dart';
import '../controllers/outflow_order_by_customer_detail_controller.dart';
import '../controllers/outflow_order_by_work_order_detail_controller.dart';

/// The By Customer Item Summary and scan views serve By Work Order: they find
/// the detail controller by the shared type, here the work-order one.
class OutflowOrderByWorkOrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OutflowOrderByCustomerDetailController>(() => OutflowOrderByWorkOrderDetailController());
    Get.lazyPut<OutflowOrderProvider>(() => OutflowOrderProvider());
  }
}
