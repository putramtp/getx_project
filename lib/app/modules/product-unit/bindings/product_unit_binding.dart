import 'package:get/get.dart';

import 'package:getx_project/app/data/providers/product_provider.dart';
import 'package:getx_project/app/modules/product-unit/controllers/product_unit_controller.dart';

class ProductUnitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductUnitController());
    Get.lazyPut(() => ProductProvider());
  }
}
