import 'package:get/get.dart';

import '../controllers/product_transaction_list_controller.dart';
import '../../../data/providers/product_provider.dart';

class ProductTransactionListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductTransactionListController());
    Get.lazyPut(() => ProductProvider());
  }
}
