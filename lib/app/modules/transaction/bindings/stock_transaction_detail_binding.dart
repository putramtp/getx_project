import 'package:get/get.dart';
import 'package:getx_project/app/data/providers/stock_transaction_provider.dart';

import '../controllers/stock_transaction_detail_controller.dart';

class ReceiveOrderListDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StockTransactionDetailController());
    Get.lazyPut(() => StockTransactionProvider());
  }
}
