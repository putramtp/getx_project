import 'dart:async';

import 'package:getx_project/app/data/providers/api_providers.dart';
import 'package:getx_project/app/data/models/dashboard_model.dart';
import 'package:getx_project/app/data/models/stock_transaction_model.dart';

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
        final response = await get(
          '/stock-transaction/latest',
          query: {
            'limit': limit.toString(),
          },
        ).timeout(const Duration(seconds: 15)); // ✅ FORCE COMPLETION

        final resBody = response.body;

        if (response.statusCode == 200 &&
            resBody != null &&
            resBody['success'] == true &&
            resBody['data'] is List) {
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