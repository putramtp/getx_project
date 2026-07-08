import 'package:getx_project/app/data/providers/api_providers.dart';

class StockTransactionProvider extends ApiProvider {
  Future<Map<String, dynamic>> getStockTransactions({String? cursor, Map<String, String>? params}) {
    return getMap('/stock-transaction/pagination', query: {
      if (params != null) ...params,
      if (cursor != null) 'cursor': cursor,
    });
  }
}
