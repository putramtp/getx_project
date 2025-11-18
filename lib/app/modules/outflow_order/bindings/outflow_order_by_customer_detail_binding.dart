import 'package:get/get.dart';
import 'package:getx_project/app/modules/outflow_order/controllers/outflow_order_by_customer_detail_controller.dart';
import 'package:getx_project/app/modules/outflow_order/providers/outflow_order_provider.dart';


class OutflowOrderByCustomerDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OutflowOrderByCustomerDetailController>(() => OutflowOrderByCustomerDetailController());
    Get.lazyPut<OutflowOrderProvider>(() => OutflowOrderProvider());
  }
}
