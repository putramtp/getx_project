import 'package:get/get.dart';

import 'package:getx_project/app/data/providers/product_provider.dart';
import 'package:getx_project/app/modules/product-brand/controllers/product_brand_controller.dart';

class ProductBrandBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductBrandController());
    Get.lazyPut(() => ProductProvider());
  }
}
