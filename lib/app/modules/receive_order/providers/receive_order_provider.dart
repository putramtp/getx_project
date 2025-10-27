import 'dart:developer';

import 'package:get/get.dart';
import 'package:getx_project/app/api_providers.dart';
import 'package:getx_project/app/models/purchase_order_line_item_model.dart';
import 'package:getx_project/app/models/purchase_order_model.dart';

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

  Future<List<PurchaseOrderLineItem>> getReceiveOrderItems(int orderId) async {
    final response = await get('/purchase-order/$orderId');
    if (response.statusCode == 200 && response.body != null) {
      final data = response.body['data'] as List<dynamic>;
      return data.map((e) => PurchaseOrderLineItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load getReceiveOrderItems: ${response.statusText}');
    }
  }

  Future<Response> postReceivedData(Map<String, dynamic> payload) async {
    try {
      final response = await post('/purchase-order/receive', payload);
      return response;
    } catch (e, st) {
      log('❌ postReceivedData error: $e\n$st', name: 'ReceiveOrderProvider');
      rethrow;
    }
  }
}
