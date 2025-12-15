import 'package:get/get.dart';

import '../controllers/product_controller.dart';
import '../../../data/providers/product_provider.dart';
class ProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductController());
    Get.lazyPut(() => ProductProvider());
  }
}
