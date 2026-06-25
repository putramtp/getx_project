import 'package:getx_project/app/data/providers/api_providers.dart';

class StockTransactionProvider extends ApiProvider {
  Future<Map<String, dynamic>> getStockTransactions({String? cursor, Map<String, String>? params}) async {
    final response = await get(
      '/stock-transaction/pagination',
      query: {
        if (params != null) ...params,
        if (cursor != null) 'cursor': cursor,
      },
    );
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }
}
