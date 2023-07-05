import 'package:get/get.dart';

import 'package:getx_project/app/modules/home/controllers/receiving_order_controller.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceivingOrderController>(
      () => ReceivingOrderController(),
    );
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
  }
}
