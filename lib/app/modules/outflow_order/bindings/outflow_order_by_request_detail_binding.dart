import 'package:get/get.dart';
import '../../../modules/outflow_order/controllers/outflow_order_by_request_detail_controller.dart';
import '../../../data/providers/outflow_order_provider.dart';


class OutflowOrderByRequestDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OutflowOrderByRequestDetailController>(() => OutflowOrderByRequestDetailController());
    Get.lazyPut<OutflowOrderProvider>(() => OutflowOrderProvider());
  }
}
