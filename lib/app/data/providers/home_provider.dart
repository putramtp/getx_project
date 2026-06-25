import 'api_providers.dart';
import '../models/dashboard_model.dart';
import '../models/stock_transaction_model.dart';

class HomeProvider extends ApiProvider {
  Future<DashboardModel> getDashboard({required int year}) async {
    final response = await get('/dashboard-inventory', query: {'year': year.toString()});
    checkResponse(response);
    return DashboardModel.fromJson(response.body['data']);
  }

  Future<List<StockTransactionModel>> getLatestTransaction({required int limit}) async {
    final response = await get('/stock-transaction/latest', query: {'limit': limit.toString()});
    checkResponse(response);
    final List data = response.body['data'];
    return data.map((e) => StockTransactionModel.fromJson(e)).toList();
  }
}
