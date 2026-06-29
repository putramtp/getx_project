import 'package:get/get.dart';

import '../../../data/providers/delivery_provider.dart';
import '../controllers/delivery_list_controller.dart';

class DeliveryListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeliveryListController>(() => DeliveryListController());
    Get.lazyPut<DeliveryProvider>(() => DeliveryProvider());
  }
}
