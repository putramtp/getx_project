import 'package:get/get.dart';
import 'package:getx_project/app/modules/product/controllers/product_controller.dart';
import 'package:getx_project/app/modules/product/providers/product_provider.dart';
class ProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductController>(
      () => ProductController(),
    );
    Get.lazyPut<ProductProvider>(
      () => ProductProvider(),
    );
    
  }
}
