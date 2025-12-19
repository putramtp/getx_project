import 'package:get/get.dart';
import 'package:getx_project/app/data/providers/product_provider.dart';
import 'package:getx_project/app/modules/product-category/controllers/product_by_category_controller.dart';
class ProductByCategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductByCategoryController());
    Get.lazyPut(() => ProductProvider());
  }
}
