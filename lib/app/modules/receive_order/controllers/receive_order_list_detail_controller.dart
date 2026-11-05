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
  late final ReceiveOrderModel currentReceiveOrder;

  /// Whether this RO has labels of `manage_sn` items — the only ones the
  /// Confirm Serials pass scans. The detail response doesn't say which item is
  /// `manage_sn`, so it is read from the RO's serial list.
  final hasConfirmableSerials = false.obs;
  final isLoadingSerials = false.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args != null && args is ReceiveOrderModel) {
      currentReceiveOrder = args;
      loadReceiveOrderDetail();
    } else {
      errorAlert("⚠️ Invalid or missing arguments in receiveOrder: $args");
    }
  }

  /// 🔹 Fetch items for this order
  Future<void> loadReceiveOrderDetail() async {
    final orderId = currentReceiveOrder.id;
    final data = await ApiExecutor.run<ReceiveOrderDetailModel>(
      isLoading: isLoading,
      task: () => provider.getReceiveOrderDetail(orderId),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;
    receiveOrderDetail.value = data;
    await _loadConfirmableSerials(data);
  }

  Future<void> _loadConfirmableSerials(ReceiveOrderDetailModel detail) async {
    final hasSerials =
        detail.receiveOrderLines.any((l) => l.serialNumbers.isNotEmpty);
    if (!hasSerials) {
      hasConfirmableSerials.value = false;
      return;
    }
    final serials = await ApiExecutor.run(
      isLoading: isLoadingSerials,
      task: () => provider.getReceiveOrderSerials(currentReceiveOrder.id),
    );
    if (serials == null) return;
    hasConfirmableSerials.value =
        serials.any((s) => s.manageSn);
  }
}
