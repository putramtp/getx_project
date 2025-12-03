import 'package:get/get.dart';
import 'package:getx_project/app/modules/product/controllers/product_detail.controller.dart';

class ProductDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductDetailController>(() => ProductDetailController());
  }
}
