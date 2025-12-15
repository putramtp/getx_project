import 'package:getx_project/app/data/providers/api_providers.dart';
import 'package:getx_project/app/data/models/outflow_order_detail_model.dart';
import 'package:getx_project/app/data/models/outflow_request_customer_model.dart';
import 'package:getx_project/app/data/models/outflow_request_line_item_model.dart';

class OutflowOrderProvider extends ApiProvider {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = '';
  // }

  Future<Map<String, dynamic>> getOutflowOrders({String? cursor}) async {
    final response = await get(
      '/outflow-order/pagination',
      query: cursor != null ? {'cursor': cursor} : {},
    );

    if (response.statusCode == 200 && response.body != null) {
      return response.body; // return full data including cursor
    } else {
      throw Exception(
          'Failed to load getOutflowOrders: ${response.statusText}');
    }
  }

  Future<OutflowOrderDetailModel> getOutflowOrderDetail(int ooId) async {
    final response = await get('/outflow-order/$ooId');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'];
      if (data is Map<String, dynamic>) {
        return OutflowOrderDetailModel.fromJson(data);
      } else {
        throw Exception('Unexpected response format: data is not a Map');
      }
    } else {
      throw Exception(
          'Failed to load getOutflowOrderDetail: ${response.statusText}');
    }
  }
  
  Future<Map<String, dynamic>> getOutflowRequests({String? cursor}) async {
    final response = await get(
      '/outflow-request/pagination',
      query: cursor != null ? {'cursor': cursor} : {},
    );

    if (response.statusCode == 200 && response.body != null) {
      return response.body; // return full data including cursor
    } else {
      throw Exception( 'Failed to load getOutflowRequests: ${response.statusText}');
    }
  }

  Future<List<OutflowRequestLineItemModel>> getOutflowRequestLineItem(
      int orderId) async {
    final response = await get('/outflow-request/$orderId/summary');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => OutflowRequestLineItemModel.fromJson(e)).toList();
    } else {
      throw Exception(
          'Failed to load getOutflowRequestLineItem: ${response.statusText}');
    }
  }

  Future<List<OutflowRequestLineItemModel>> getOutflowRequestLineItemByCustomer(
      int customerId) async {
    final response = await get('/outflow-request/$customerId/customer-summary');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => OutflowRequestLineItemModel.fromJson(e)).toList();
    } else {
      throw Exception(
          'Failed to load getOutflowRequestLineItemByCustomer: ${response.statusText}');
    }
  }

  Future postOrLineToOutflowedData(Map<String, dynamic> payload) async {
    try {
      final response = await post('/outflow-request/outflowData', payload);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<OrCustomerModel>> getCustomers() async {
    final response = await get('/outflow-request/customer-summary');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => OrCustomerModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load getCustomers: ${response.statusText}');
    }
  }
}
