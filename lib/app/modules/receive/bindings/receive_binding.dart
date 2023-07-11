import 'package:get/get.dart';

import '../controllers/category_controller.dart';
import '../controllers/item_controller.dart';
import '../controllers/receive_controller.dart';

class ReceiveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryController>(
      () => CategoryController(),
    );
    
    Get.lazyPut<ItemController>(
      () => ItemController(),
    );
    
    Get.lazyPut<ReceiveController>(
      () => ReceiveController(),
    );
  }
}
