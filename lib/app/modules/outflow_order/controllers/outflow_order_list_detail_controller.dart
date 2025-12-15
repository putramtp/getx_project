import 'package:get/get.dart';

import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/outflow_order_detail_model.dart';
import '../../../data/models/outflow_order_model.dart';
import '../../../data/providers/outflow_order_provider.dart';

class OutflowOrderListDetailController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();

  final outflowOrderDetail = Rxn<OutflowOrderDetailModel>();
  var isLoading = false.obs;
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
}
