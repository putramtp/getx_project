import 'package:get/get.dart';
import '../controllers/product_detail.controller.dart';
import '../../../data/providers/product_provider.dart';

class ProductDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductDetailController());
    Get.lazyPut(() => ProductProvider());
  }
}
