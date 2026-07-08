import 'api_providers.dart';
import '../models/purchase_order_line_item_by_supplier_model.dart';
import '../models/purchase_order_line_item_model.dart';
import '../models/purchase_order_supplier_model.dart';
import '../models/receive_confirm_serial_model.dart';
import '../models/receive_order_detail_model.dart';

class ReceiveOrderProvider extends ApiProvider {
  Future<Map<String, dynamic>> getReceiveOrders({String? cursor, Map<String, String>? params}) {
    return getMap('/receive-order/pagination', query: {
      if (params != null) ...params,
      if (cursor != null) 'cursor': cursor,
    });
  }

  Future<ReceiveOrderDetailModel> getReceiveOrderDetail(int roId) async {
    final response = await get('/receive-order/$roId');
    checkResponse(response);
    return ReceiveOrderDetailModel.fromJson(response.body['data'] as Map<String, dynamic>);
  }

  Future<List<ReceiveConfirmSerialModel>> getReceiveOrderSerials(int roId) {
    return getList('/receive-order/$roId/serial-number', ReceiveConfirmSerialModel.fromJson);
  }

  Future<Map<String, dynamic>> confirmReceiveSerial(int roId, List<String> codes) {
    return postMap('/receive-order/$roId/confirm-serials', {'codes': codes});
  }

  Future<Map<String, dynamic>> getPurchaseOrders({String? cursor, Map<String, String>? params}) {
    return getMap('/purchase-order/pagination', query: {
      if (params != null) ...params,
      if (cursor != null) 'cursor': cursor,
    });
  }

  Future<List<PurchaseOrderLineItemModel>> getPurchaseOrderLineItem(int poId) {
    return getList('/purchase-order/$poId/summary', PurchaseOrderLineItemModel.fromJson);
  }

  Future<Map<String, dynamic>> postPoLineToReceivedData(Map<String, dynamic> payload) {
    return postMap('/purchase-order/receiveData', payload);
  }

  Future<List<PoSupplierModel>> getSuppliers() {
    return getList('/purchase-order/supplier-summary', PoSupplierModel.fromJson);
  }

  Future<List<PurchaseOrderLineItemBySupplierModel>> getPurchaseOrderItemBySupplier(int supplierId) {
    return getList('/purchase-order/$supplierId/supplier-summary', PurchaseOrderLineItemBySupplierModel.fromJson);
  }
}
