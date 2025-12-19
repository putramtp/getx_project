import 'package:get/get.dart';
import 'package:getx_project/app/data/providers/product_provider.dart';
import 'package:getx_project/app/modules/product-brand/controllers/product_by_brand_controller.dart';
class ProductByBrandBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductByBrandController());
    Get.lazyPut(() => ProductProvider());
  }
}
