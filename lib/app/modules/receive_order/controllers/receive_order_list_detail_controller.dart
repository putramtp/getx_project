import 'package:get/get.dart';
import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/receive_order_detail_model.dart';
import '../../../data/models/receive_order_model.dart';
import '../../../data/providers/receive_order_provider.dart';

class ReceiveOrderListDetailController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();

  final receiveOrderDetail = Rxn<ReceiveOrderDetailModel>();
  var isLoading = false.obs;
  late final ReceiveOrderModel curretReceiveOrder;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args != null && args is ReceiveOrderModel) {
      curretReceiveOrder = args;
      loadReceiveOrderDetail();
    } else {
      errorAlert("⚠️ Invalid or missing arguments in receiveOrder: $args");
    }
  }

  /// 🔹 Fetch items for this order
  Future<void> loadReceiveOrderDetail() async {
    final orderId = curretReceiveOrder.id;
    final data = await ApiExecutor.run<ReceiveOrderDetailModel>(
      isLoading: isLoading,
      task: () => provider.getReceiveOrderDetail(orderId),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;
    receiveOrderDetail.value = data;

  }
}
