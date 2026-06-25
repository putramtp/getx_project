import 'api_providers.dart';
import '../models/purchase_order_line_item_by_supplier_model.dart';
import '../models/purchase_order_line_item_model.dart';
import '../models/purchase_order_supplier_model.dart';
import '../models/receive_order_detail_model.dart';

class ReceiveOrderProvider extends ApiProvider {
  Future<Map<String, dynamic>> getReceiveOrders({String? cursor, Map<String, String>? params}) async {
    final response = await get(
      '/receive-order/pagination',
      query: {
        if (params != null) ...params,
        if (cursor != null) 'cursor': cursor,
      },
    );
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  Future<ReceiveOrderDetailModel> getReceiveOrderDetail(int roId) async {
    final response = await get('/receive-order/$roId');
    checkResponse(response);
    return ReceiveOrderDetailModel.fromJson(response.body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getPurchaseOrders({String? cursor, Map<String, String>? params}) async {
    final response = await get(
      '/purchase-order/pagination',
      query: {
        if (params != null) ...params,
        if (cursor != null) 'cursor': cursor,
      },
    );
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  Future<List<PurchaseOrderLineItemModel>> getPurchaseOrderLineItem(int poId) async {
    final response = await get('/purchase-order/$poId/summary');
    checkResponse(response);
    final List data = response.body['data'];
    return data.map((e) => PurchaseOrderLineItemModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> postPoLineToReceivedData(Map<String, dynamic> payload) async {
    final response = await post('/purchase-order/receiveData', payload);
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  Future<List<PoSupplierModel>> getSuppliers() async {
    final response = await get('/purchase-order/supplier-summary');
    checkResponse(response);
    final List data = response.body['data'];
    return data.map((e) => PoSupplierModel.fromJson(e)).toList();
  }

  Future<List<PurchaseOrderLineItemBySupplierModel>> getPurchaseOrderItemBySupplier(int supplierId) async {
    final response = await get('/purchase-order/$supplierId/supplier-summary');
    checkResponse(response);
    final List data = response.body['data'];
    return data.map((e) => PurchaseOrderLineItemBySupplierModel.fromJson(e)).toList();
  }
}
