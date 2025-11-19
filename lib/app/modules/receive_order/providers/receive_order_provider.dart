import 'package:get/get.dart';
import 'package:getx_project/app/api_providers.dart';
import 'package:getx_project/app/models/purchase_order_line_item_by_supplier_model.dart';
import 'package:getx_project/app/models/purchase_order_line_item_model.dart';
import 'package:getx_project/app/models/purchase_order_model.dart';
import 'package:getx_project/app/models/purchase_order_supplier_model.dart';
import 'package:getx_project/app/models/receive_order_detail_model.dart';
import 'package:getx_project/app/models/receive_order_model.dart';

class ReceiveOrderProvider extends ApiProvider {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = '';
  // }

  Future<List<ReceiveOrder>> getReceiveOrders() async {
    final response = await get('/receive-order');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      // log("getReceiveOrders : $data");
      return data.map((e) => ReceiveOrder.fromJson(e)).toList();
    } else {
      throw Exception(
          'Failed to load getPurchaseOrders: ${response.statusText}');
    }
  }

  Future<ReceiveOrderDetail> getReceiveOrderDetail(int roId) async {
    final response = await get('/receive-order/$roId');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'];
      if (data is Map<String, dynamic>) {
        return ReceiveOrderDetail.fromJson(data);
      } else {
        throw Exception('Unexpected response format: data is not a Map');
      }
    } else {
      throw Exception('Failed to load getReceiveOrderDetail: ${response.statusText}');
    }
  }

  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final response = await get('/purchase-order/summary');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => PurchaseOrder.fromJson(e)).toList();
    } else {
      throw Exception(
          'Failed to load getPurchaseOrders: ${response.statusText}');
    }
  }

  Future<List<PurchaseOrderLineItem>> getPurchaseOrderLineItem(int poId) async {
    final response = await get('/purchase-order/$poId/summary');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => PurchaseOrderLineItem.fromJson(e)).toList();
    } else {
      throw Exception( 'Failed to load getPurchaseOrderLineItem: ${response.statusText}');
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

  Future<List<PoSupplier>> getSuppliers() async {
    final response = await get('/purchase-order/supplier-summary');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => PoSupplier.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load getSuppliers: ${response.statusText}');
    }
  }

  Future<List<PurchaseOrderLineItemBySupplier>> getPurchaseOrderItemBySupplier(
      int supplierId) async {
    final response = await get('/purchase-order/$supplierId/supplier-summary');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data
          .map((e) => PurchaseOrderLineItemBySupplier.fromJson(e))
          .toList();
    } else {
      throw Exception(
          'Failed to load getPurchaseOrderItemBySupplier: ${response.statusText}');
    }
  }

}
