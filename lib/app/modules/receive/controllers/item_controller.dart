import 'package:get/get.dart';

import '../../../models/product_model.dart';
import '../providers/receive_provider.dart';

class ItemController extends GetxController
    with StateMixin<List<ProductModel>> {
  final String title = Get.arguments["title"];
  final ReceiveProvider _receiveProvider = ReceiveProvider();
  @override
  void onInit() {
    getListPorduct();
    super.onInit();
  }

  // @override
  // void onReady() {
  //   super.onReady();
  // }

  // @override
  // void onClose() {
  //   super.onClose();
  // }

  void getListPorduct() {
    _receiveProvider.products(title).then((response) {
      change(response, status: RxStatus.success());
    }, onError: (err) {
      change(null, status: RxStatus.error(err.toString()));
    });
  }
}
