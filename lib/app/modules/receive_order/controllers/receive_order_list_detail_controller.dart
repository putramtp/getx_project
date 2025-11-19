import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/helpers/api_excecutor.dart';
import 'package:getx_project/app/models/receive_order_detail_model.dart';
import 'package:getx_project/app/models/receive_order_model.dart';
import 'package:getx_project/app/modules/receive_order/providers/receive_order_provider.dart';

class ReceiveOrderListDetailController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();

  final receiveOrderDetail = Rxn<ReceiveOrderDetail>();
  var isLoading = false.obs;
  late final ReceiveOrder curretReceiveOrder;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args != null && args is ReceiveOrder) {
      curretReceiveOrder = args;
      loadReceiveOrderDetail();
    } else {
      errorAlert("⚠️ Invalid or missing arguments in receiveOrder: $args");
    }
  }

  /// 🔹 Fetch items for this order
  Future<void> loadReceiveOrderDetail() async {
    final orderId = curretReceiveOrder.id;

    final data = await ApiExecutor.run<ReceiveOrderDetail>(
      isLoading: isLoading,
      task: () => provider.getReceiveOrderDetail(orderId),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;
    receiveOrderDetail.value = data;

  }
}
