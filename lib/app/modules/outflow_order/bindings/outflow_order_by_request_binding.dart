import 'package:get/get.dart';
import '../../../modules/outflow_order/controllers/outflow_order_by_request_controller.dart';
import '../../../data/providers/outflow_order_provider.dart';


class OutflowOrderByRequestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OutflowOrderByRequestController>(() => OutflowOrderByRequestController());
    Get.lazyPut<OutflowOrderProvider>(() => OutflowOrderProvider());
  }
}
