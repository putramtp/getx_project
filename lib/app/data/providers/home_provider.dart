import 'api_providers.dart';
import '../models/dashboard_model.dart';
import '../models/delivery_model.dart';
import '../models/stock_transaction_model.dart';

class HomeProvider extends ApiProvider {
  Future<DashboardModel> getDashboard({required int year}) async {
    final response = await get('/dashboard-inventory', query: {'year': year.toString()});
    checkResponse(response);
    return DashboardModel.fromJson(response.body['data']);
  }

  Future<List<StockTransactionModel>> getLatestTransaction({required int limit}) {
    return getList(
      '/stock-transaction/latest',
      StockTransactionModel.fromJson,
      query: {'limit': limit.toString()},
    );
  }

  /// Number of deliveries still in "Pending". `GET /delivery` has no count or
  /// status filter on the backend, so this counts the full (unpaginated) list.
  Future<int> getPendingDeliveryCount() async {
    final deliveries = await getList('/delivery', DeliveryModel.fromJson);
    return deliveries.where((d) => d.statusName.toLowerCase() == 'pending').length;
  }
}
