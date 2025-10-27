import 'package:getx_project/app/api_providers.dart';
import 'package:getx_project/app/models/purchase_order_item_model_copy.dart';
import 'package:getx_project/app/models/purchase_order_model.dart';

class OutflowOrderProvider extends ApiProvider {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = '';
  // }

  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final response = await get('/purchase-order');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => PurchaseOrder.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load getPurchaseOrders: ${response.statusText}');
    }
  }

  Future<List<PurchaseOrderItemCopy>> getOutflowOrderItems(int orderId) async {
    final response = await get('/purchase-order/$orderId');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => PurchaseOrderItemCopy.fromJson(e)).toList();
    } else {
      throw Exception(
          'Failed to load getOutflowOrderItems: ${response.statusText}');
    }
  }

  Future postOutflowdData(Map<String, dynamic> payload) async {
    final response = await post('/outflow-order', payload);
    return response;
  }
}
