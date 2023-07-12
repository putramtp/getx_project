import 'package:get/get.dart';

import '../controllers/category_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/item_controller.dart';

class InventoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryController>(
      () => CategoryController(),
    );
    
    Get.lazyPut<ItemController>(
      () => ItemController(),
    );
    
    Get.lazyPut<InventoryController>(
      () => InventoryController(),
    );
  }
}
