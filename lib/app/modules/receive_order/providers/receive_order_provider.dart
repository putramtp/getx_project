import 'dart:developer';

import 'package:get/get.dart';
import 'package:getx_project/app/api_providers.dart';
import 'package:getx_project/app/models/purchase_order_line_item_by_supplier_model.dart';
import 'package:getx_project/app/models/purchase_order_line_item_model.dart';
import 'package:getx_project/app/models/purchase_order_model.dart';
import 'package:getx_project/app/models/purchase_order_supplier_model.dart';

class ReceiveOrderProvider extends ApiProvider {
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

  Future<List<PurchaseOrderLineItem>> getPurchaseOrderLineItem(int poId) async {
    final response = await get('/purchase-order/$poId');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => PurchaseOrderLineItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load getReceiveOrderItems: ${response.statusText}');
    }
  }

  Future<Response> postPoLineToReceivedData(Map<String, dynamic> payload) async {
    try {
      final response = await post('/purchase-order/receiveData', payload);
      return response;
    } catch (e, st) {
      log('❌ postReceivedData error: $e\n$st', name: 'ReceiveOrderProvider');
      rethrow;
    }
  }

    Future<List<PoSupplier>> getSuppliers() async {
    final response = await get('/purchase-order/supplier');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => PoSupplier.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load getPurchaseOrders: ${response.statusText}');
    }
  }

   Future<List<PurchaseOrderLineItemBySupplier>> getPurchaseOrderItemBySupplier(int supplierId) async {
    final response = await get('/purchase-order/$supplierId/supplier');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => PurchaseOrderLineItemBySupplier.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load getReceiveOrderItems: ${response.statusText}');
    }
  }

}
