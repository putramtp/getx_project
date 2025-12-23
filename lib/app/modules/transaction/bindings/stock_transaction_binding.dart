import 'package:get/get.dart';
import 'package:getx_project/app/data/providers/stock_transaction_provider.dart';
import 'package:getx_project/app/modules/transaction/controllers/stock_transaction_controller.dart';


class StockTransactionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StockTransactionController());
    Get.lazyPut(() => StockTransactionProvider());
  }
}
