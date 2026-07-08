import 'api_providers.dart';
import '../models/outflow_order_detail_model.dart';
import '../models/outflow_request_customer_model.dart';
import '../models/outflow_request_line_item_model.dart';

class OutflowOrderProvider extends ApiProvider {
  Future<Map<String, dynamic>> getOutflowOrders({String? cursor, Map<String, String>? params}) {
    return getMap('/outflow-order/pagination', query: {
      if (params != null) ...params,
      if (cursor != null) 'cursor': cursor,
    });
  }

  Future<OutflowOrderDetailModel> getOutflowOrderDetail(int ooId) async {
    final response = await get('/outflow-order/$ooId');
    checkResponse(response);
    return OutflowOrderDetailModel.fromJson(response.body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getOutflowRequests({String? cursor, Map<String, String>? params}) {
    return getMap('/outflow-request/pagination', query: {
      if (params != null) ...params,
      if (cursor != null) 'cursor': cursor,
    });
  }

  Future<List<OutflowRequestLineItemModel>> getOutflowRequestLineItem(int orderId) {
    return getList('/outflow-request/$orderId/summary', OutflowRequestLineItemModel.fromJson);
  }

  Future<List<OutflowRequestLineItemModel>> getOutflowRequestLineItemByCustomer(int customerId) {
    return getList('/outflow-request/$customerId/customer-summary', OutflowRequestLineItemModel.fromJson);
  }

  Future<Map<String, dynamic>> postOrLineToOutflowedData(Map<String, dynamic> payload) {
    return postMap('/outflow-request/outflowData', payload);
  }

  Future<List<OrCustomerModel>> getCustomers() {
    return getList('/outflow-request/customer-summary', OrCustomerModel.fromJson);
  }
}
