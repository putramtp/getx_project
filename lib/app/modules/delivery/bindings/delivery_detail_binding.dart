import 'package:get/get.dart';

import '../../../data/providers/delivery_provider.dart';
import '../controllers/delivery_detail_controller.dart';

class DeliveryDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeliveryDetailController>(() => DeliveryDetailController());
    Get.lazyPut<DeliveryProvider>(() => DeliveryProvider());
  }
}
