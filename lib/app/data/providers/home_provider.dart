import 'dart:async';

import 'api_providers.dart';
import '../models/dashboard_model.dart';
import '../models/stock_transaction_model.dart';

class HomeProvider extends ApiProvider {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = 'https://dummyjson.com/';
  // }

 Future<DashboardModel> getDashboard({required int year}) async {
    final response = await get('/dashboard-inventory', 
      query: {
        'year': year.toString(),
      },);
    final resBody = response.body;

    if (response.statusCode == 200 && resBody != null && resBody['success'] == true) {
      return DashboardModel.fromJson(resBody['data']);
    } else {
      throw Exception('Failed to load dashboard: ${response.statusText}');
    }
  }

  Future<List<StockTransactionModel>> getLatestTransaction({
      required int limit,
    }) async {
      try {
        final response = await get('/stock-transaction/latest',query: {'limit': limit.toString()});
        final resBody = response.body;
        if (response.statusCode == 200 && resBody != null && resBody['success'] == true) {
          final List data = resBody['data'];
          return data.map((e) => StockTransactionModel.fromJson(e)).toList();
        }

        throw Exception(
          'Server error: ${response.statusCode} | ${response.statusText}',
        );
      } on TimeoutException {
        throw Exception('Request timeout: getLatestTransaction');
      } catch (e) {
        rethrow; // ✅ Let ApiExecutor catch it
      }
    }


}