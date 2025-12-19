import 'package:get/get.dart';

import 'package:getx_project/app/data/providers/product_provider.dart';
import 'package:getx_project/app/modules/product-category/controllers/product_category_controller.dart';

class ProductCategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductCategoryController());
    Get.lazyPut(() => ProductProvider());
  }
}
