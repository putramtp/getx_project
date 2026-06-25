import 'api_providers.dart';
import '../models/outflow_order_detail_model.dart';
import '../models/outflow_request_customer_model.dart';
import '../models/outflow_request_line_item_model.dart';

class OutflowOrderProvider extends ApiProvider {
  Future<Map<String, dynamic>> getOutflowOrders({String? cursor, Map<String, String>? params}) async {
    final response = await get(
      '/outflow-order/pagination',
      query: {
        if (params != null) ...params,
        if (cursor != null) 'cursor': cursor,
      },
    );
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  Future<OutflowOrderDetailModel> getOutflowOrderDetail(int ooId) async {
    final response = await get('/outflow-order/$ooId');
    checkResponse(response);
    return OutflowOrderDetailModel.fromJson(response.body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getOutflowRequests({String? cursor, Map<String, String>? params}) async {
    final response = await get(
      '/outflow-request/pagination',
      query: {
        if (params != null) ...params,
        if (cursor != null) 'cursor': cursor,
      },
    );
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  Future<List<OutflowRequestLineItemModel>> getOutflowRequestLineItem(int orderId) async {
    final response = await get('/outflow-request/$orderId/summary');
    checkResponse(response);
    final List data = response.body['data'];
    return data.map((e) => OutflowRequestLineItemModel.fromJson(e)).toList();
  }

  Future<List<OutflowRequestLineItemModel>> getOutflowRequestLineItemByCustomer(int customerId) async {
    final response = await get('/outflow-request/$customerId/customer-summary');
    checkResponse(response);
    final List data = response.body['data'];
    return data.map((e) => OutflowRequestLineItemModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> postOrLineToOutflowedData(Map<String, dynamic> payload) async {
    final response = await post('/outflow-request/outflowData', payload);
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  Future<List<OrCustomerModel>> getCustomers() async {
    final response = await get('/outflow-request/customer-summary');
    checkResponse(response);
    final List data = response.body['data'];
    return data.map((e) => OrCustomerModel.fromJson(e)).toList();
  }
}
