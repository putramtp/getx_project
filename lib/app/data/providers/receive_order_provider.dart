import 'package:get/get.dart';

import 'api_providers.dart';
import '../models/purchase_order_line_item_by_supplier_model.dart';
import '../models/purchase_order_line_item_model.dart';
import '../models/purchase_order_supplier_model.dart';
import '../models/receive_order_detail_model.dart';

class ReceiveOrderProvider extends ApiProvider {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = '';
  // }

  Future<Map<String, dynamic>> getReceiveOrders({String? cursor}) async {
    final response = await get(
      '/receive-order/pagination',
      query: cursor != null ? {'cursor': cursor} : {},
    );

    if (response.statusCode == 200 && response.body != null) {
      return response.body; // return full data including cursor
    } else {
      throw Exception( 'Failed to load getReceiveOrders: ${response.statusText}');
    }
  }

  Future<ReceiveOrderDetailModel> getReceiveOrderDetail(int roId) async {
    final response = await get('/receive-order/$roId');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'];
      if (data is Map<String, dynamic>) {
        return ReceiveOrderDetailModel.fromJson(data);
      } else {
        throw Exception('Unexpected response format: data is not a Map');
      }
    } else {
      throw Exception(
          'Failed to load getReceiveOrderDetail: ${response.statusText}');
    }
  }

  Future<Map<String, dynamic>> getPurchaseOrders({String? cursor}) async {
    final response = await get(
      '/purchase-order/pagination',
      query: cursor != null ? {'cursor': cursor} : {},
    );

    if (response.statusCode == 200 && response.body != null) {
    return response.body; // return full data including cursor
    } else {
      throw Exception( 'Failed to load getPurchaseOrders: ${response.statusText}');
    }
  }

  Future<List<PurchaseOrderLineItemModel>> getPurchaseOrderLineItem(int poId) async {
    final response = await get('/purchase-order/$poId/summary');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => PurchaseOrderLineItemModel.fromJson(e)).toList();
    } else {
      throw Exception(
          'Failed to load getPurchaseOrderLineItem: ${response.statusText}');
    }
  }

  Future<Response> postPoLineToReceivedData(
      Map<String, dynamic> payload) async {
    try {
      final response = await post('/purchase-order/receiveData', payload);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PoSupplierModel>> getSuppliers() async {
    final response = await get('/purchase-order/supplier-summary');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => PoSupplierModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load getSuppliers: ${response.statusText}');
    }
  }

  Future<List<PurchaseOrderLineItemBySupplierModel>> getPurchaseOrderItemBySupplier(
      int supplierId) async {
    final response = await get('/purchase-order/$supplierId/supplier-summary');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data
          .map((e) => PurchaseOrderLineItemBySupplierModel.fromJson(e))
          .toList();
    } else {
      throw Exception(
          'Failed to load getPurchaseOrderItemBySupplier: ${response.statusText}');
    }
  }
}
