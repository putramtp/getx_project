import 'package:get/get.dart';

import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/outflow_order_detail_model.dart';
import '../../../data/models/outflow_order_model.dart';
import '../../../data/providers/outflow_order_provider.dart';
import '../../../modules/delivery/delivery_actions.dart';
import '../../../routes/app_pages.dart';

class OutflowOrderListDetailController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();

  final outflowOrderDetail = Rxn<OutflowOrderDetailModel>();
  var isLoading = false.obs;
  var isCreatingDelivery = false.obs;
  late final OutflowOrderModel curretOutflowOrder;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args != null && args is OutflowOrderModel) {
      curretOutflowOrder = args;
      loadOutflowOrderDetail();
    } else {
      errorAlert("⚠️ Invalid or missing arguments in outflowOrder: $args");
    }
  }

  /// 🔹 Fetch items for this order
  Future<void> loadOutflowOrderDetail() async {
    final orderId = curretOutflowOrder.id;
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getOutflowOrderDetail(orderId),
    );
    outflowOrderDetail.value = data;
  }

  /// Whether this order already has a delivery (drives the CTA label).
  bool get hasDelivery => outflowOrderDetail.value?.isHaveDelivery ?? false;

  /// Whether this order can be delivered (`is_deliverable` from the backend —
  /// true only for `DO` orders). Hides the CTA for any other type (e.g. `SI`).
  bool get isDeliverable => outflowOrderDetail.value?.isDeliverable ?? false;

  /// Create a delivery for this outflow order, then route to the delivery list.
  Future<void> createDelivery() async {
    await createDeliveryForOutflow(curretOutflowOrder.id,
        isLoading: isCreatingDelivery);
  }

  /// Open the delivery list (used when a delivery already exists).
  void viewDeliveries() => Get.toNamed(AppPages.deliveryListPage);
}
