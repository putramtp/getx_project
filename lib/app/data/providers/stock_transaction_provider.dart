

import 'package:getx_project/app/data/providers/api_providers.dart';

class StockTransactionProvider extends ApiProvider {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = '';
  // }


  Future<Map<String, dynamic>> getStockTransactions({String? cursor, Map<String, String>? params}) async {
     final response = await get(
      '/stock-transaction/pagination',
      query: {
        if (params != null) ...params,
        if (cursor != null) 'cursor': cursor,
      },
    );
    final resBody =  response.body;
    if (response.statusCode == 200 && resBody != null && resBody['success'] == true) {
      return resBody;
    } else {
      throw Exception( 'Failed to load getStockTransactions: ${response.statusText}');
    }
  }


}
