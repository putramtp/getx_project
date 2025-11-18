import 'dart:developer';
import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/models/outflow_order_detail_model.dart';
import 'package:getx_project/app/models/outflow_order_model.dart';
import 'package:getx_project/app/modules/outflow_order/providers/outflow_order_provider.dart';

class OutflowOrderListDetailController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();

 final outflowOrderDetail = Rxn<OutflowOrderDetail>();
  var isLoading = false.obs;
  late final OutflowOrder curretOutflowOrder;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args != null && args is OutflowOrder) {
      curretOutflowOrder = args;
      loadOutflowOrderDetail();
    } else {
      log("⚠️ Invalid or missing arguments in outflowOrder: $args");
    }
  }

  /// 🔹 Fetch items for this order
  Future<void> loadOutflowOrderDetail() async {
    try {
      isLoading.value = true;
      final orderId = curretOutflowOrder.id;
      final OutflowOrderDetail data = await provider.getOutflowOrderDetail(orderId);
      outflowOrderDetail.value = data;
      // ✅ Pretty JSON log
      // log("✅ loadOutflowOrderDetail success:\n${data.toJson()}",name: "OutflowOrderDetail");
    } catch (e) {
      errorAlertBottom('Unable to load outflow order items.\nError: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
