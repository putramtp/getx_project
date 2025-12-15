import 'package:get/get.dart';
import '../../../modules/outflow_order/controllers/outflow_order_list_detail_controller.dart';
import '../../../data/providers/outflow_order_provider.dart';

class OutflowOrderListDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OutflowOrderListDetailController>(() => OutflowOrderListDetailController());
    Get.lazyPut<OutflowOrderProvider>(() => OutflowOrderProvider());
  }
}
