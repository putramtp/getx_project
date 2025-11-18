import 'dart:developer';
import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
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
      log("⚠️ Invalid or missing arguments in receiveOrder: $args");
    }
  }

  /// 🔹 Fetch items for this order
  Future<void> loadReceiveOrderDetail() async {
    try {
      isLoading.value = true;
      final orderId = curretReceiveOrder.id;
      final ReceiveOrderDetail data = await provider.getReceiveOrderDetail(orderId);
      receiveOrderDetail.value = data;
      // ✅ Pretty JSON log
      // log("✅ loadReceiveOrderDetail success:\n${data.toJson()}",name: "ReceiveOrderDetail");
    } catch (e) {
      errorAlertBottom('Unable to load receive order items.\nError: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
