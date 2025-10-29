import 'dart:developer';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/models/purchase_order_line_item_model.dart';
import 'package:getx_project/app/models/purchase_order_model.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_by_po_controller.dart';
import 'package:getx_project/app/modules/receive_order/providers/receive_order_provider.dart';
import 'package:getx_project/app/routes/app_pages.dart';

class ReceiveOrderByPoDetailController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();

  var items = <Map<String, dynamic>>[].obs;
  var selectedIndex = 0.obs;
  var selectedItem = Rxn<Map<String, dynamic>>();
  var filledResults = <String>[].obs;
  var isLoading = false.obs;
  var isLoadingReceiving = false.obs;
  late final PurchaseOrder currentOrder;
  final receiveNumber = ''.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;

    if (args != null && args is PurchaseOrder) {
      currentOrder = args;
      loadPurchaseOrderItems();
    } else {
      log("⚠️ Invalid or missing arguments in currentOrder: $args");
    }
  }

  /// 🔹 Fetch items for this order
  Future<void> loadPurchaseOrderItems() async {
    try {
      isLoading.value = true;
      final orderId = currentOrder.id;

      final List<PurchaseOrderLineItem> data =
          await provider.getPurchaseOrderLineItem(orderId);
      log("loadReceiveOrderItems success : ${jsonEncode(data.map((e) => e.toJson()).toList())}");
      // Normalize each item: ensure filled list & received count are consistent
      final normalizedData = data.map((item) {
        final filled = (item.filled != null && item.filled!.isNotEmpty)
            ? item.filled!
            : <String>[];
        return {
          "line_id": item.lineId,
          "name": item.name,
          "serialNumberType": item.serialNumberType,
          "manageExpired": item.manageExpired,
          "expected": item.expected,
          "received": item.received,
          "filled": filled,
        };
      }).toList();

      items.assignAll(normalizedData);
    } catch (e) {
      log("loadReceiveOrderItems error: $e");
      Get.snackbar(
        'Failed',
        'Unable to load receive order items.\nError: $e',
        backgroundColor: const Color(0xFFF44336),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 Add new filled barcode (Unified format for UNIQUE + BATCH)
  void addFilledQty({
    int? batchQty,
    String? expiredDate,
  }) {
    final index = selectedIndex.value;
    if (index >= items.length) return;

    final item = items[index];
    final String itemName = item['name'] ?? '(unknown item)';
    final serialType = item['serialNumberType'] ?? 'OTHER';
    final expectedQty = item['expected'] ?? 0;
    final receivedQty = item['received'] ?? 0;

    final List<Map<String, dynamic>> filled =
        List<Map<String, dynamic>>.from(item["filled"] ?? []);

    // 🔹 Calculate current total filled qty
    final totalFilledQty = filled.fold<int>(
      0,
      (sum, e) => sum + (e['qty'] ?? 1) as int,
    );

    // 🔹 Determine new qty
    final qtyToAdd = batchQty ?? 1;

    if (serialType != 'BATCH' && filled.isNotEmpty) {
      Get.snackbar(
        "Not Allowed",
        "Only one fill is allowed for $itemName.",
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade800,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.block_rounded, color: Colors.orange),
      );
      return;
    }

    // 🔹 Over-fill protection
    if ((totalFilledQty + qtyToAdd + receivedQty) > expectedQty) {
      Get.snackbar(
        "Exceeded Quantity",
        "Filling this item would exceed the expected qty ($expectedQty) for $itemName.",
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
      );
      return;
    }

    // 🔹 Build unified fill data
    final newData = {
      "qty": qtyToAdd,
      "expired_date": expiredDate,
    };

    filled.add(newData);

    // 🔹 Save and refresh
    item["filled"] = filled;
    items[index] = item;
    items.refresh();

    // log(
    //   "✅ [${DateTime.now().toIso8601String()}] Added/Updated fill for $itemName → $newData (Total now: ${totalFilledQty + qtyToAdd}/$expectedQty)",
    // );
  }

  /// Edit code (only applies to unique or batch)
  void editFilledCode({required String oldCode, required String newCode}) {
    final index = selectedIndex.value;
    final item = items[index];
    final filled = List<Map<String, dynamic>>.from(item['filled'] ?? []);

    final foundIndex = filled.indexWhere((e) => e['code'] == oldCode);
    if (foundIndex != -1) {
      filled[foundIndex]['code'] = newCode;
      item['filled'] = filled;
      items.refresh();
      log('Edited code $oldCode → $newCode');
    }
  }

  void removeFilledCode(String code) {
    final index = selectedIndex.value;
    final item = items[index];
    item['filled']
        ?.removeWhere((e) => e['code']?.toString() == code.toString());
    items.refresh();
    log('Removed code $code');
  }

  /// ✅ Clear all filled qty for the currently selected item
  void clearFilledCodes() {
    final index = selectedIndex.value;
    if (index < items.length) {
      final item = items[index];
      final name = item["name"] ?? "Unknown";

      final clearedCount = (item["filled"] as List?)?.length ?? 0;
      item["filled"] = [];
      items[index] = Map<String, dynamic>.from(item); // trigger update
      items.refresh();

      Get.snackbar(
        "Cleared",
        "Removed $clearedCount filled qty from $name",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFE5E5),
        colorText: const Color(0xFFB71C1C),
      );
    }
  }

  /// ✅ Go to the next item if available, else show success message
  void goToNextItem() {
    final nextIndex = selectedIndex.value + 1;

    if (nextIndex < items.length) {
      selectedIndex.value = nextIndex;
      final nextName = items[nextIndex]["name"] ?? "Next Item";
      log("➡️ Moved to next item: $nextName");
    } else {
      Get.back(result: true); // close fill page
    }
  }

  /// 🔹 Get all filled qty per item (Unified format)
  Map<dynamic, List<Map<String, dynamic>>> getAllFilledUnified() {
    final Map<dynamic, List<Map<String, dynamic>>> result = {};
    for (final item in items) {
      final lineId = item["line_id"];
      final filled = List<Map<String, dynamic>>.from(item["filled"] ?? []);
      result[lineId] = filled;
    }
    return result;
  }

  int get totalFilled {
    final allFilledUnified = getAllFilledUnified();
    return allFilledUnified.values.fold<int>(0, (sum, list) {
      return sum +
          list.fold<int>(
            0,
            (innerSum, e) =>
                innerSum +
                (e['qty'] is int
                    ? e['qty'] as int
                    : int.tryParse('${e['qty']}') ?? 0),
          );
    });
  }

  void startReceivingItem() async {
    if (isLoadingReceiving.value) return; // ✅ Prevent double submit
    isLoadingReceiving.value = true;
    try {
      final po = currentOrder;
      final poNumber = po.poNumber;

      final Map<String, dynamic> payload = {
        "receive_number": receiveNumber.value,
        "po_id": po.id,
        "items": items.map((e) => e).toList(), // ensure list of maps
      };

      // log("📦 Payload:\n${jsonEncode(payload)}", name: 'startReceivingItem');
      final response = await provider.postPoLineToReceivedData(payload);

      if (response.isOk && (response.body?['success'] == true)) {
        // log("Receiving process for $poNumber completed successfully.", name: 'startReceivingItem');

        if (Get.isDialogOpen == true) {
          Get.back(); // closes confirmation dialog
        }

        Get.snackbar(
          "Success",
          "Receiving process for $poNumber started successfully.",
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );

        // ✅ Navigate to the target page after a short delay
        Future.delayed(const Duration(milliseconds: 500), () async {
          // Ensure this controller is deleted before navigating
          if (Get.isRegistered<ReceiveOrderByPoController>()) {
            Get.delete<ReceiveOrderByPoController>(force: true);
          }
          // Navigate and recreate a fresh controller on that page
          await Get.offAndToNamed(AppPages.receiveOrderByPoPage);
        });

      } else {
        Get.snackbar(
          "Failed",
          "Unable to start receiving for $poNumber. Please try again.",
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.error_outline, color: Colors.red),
        );
        // log(
        //   '''
        //   ❌ Response Error:
        //   • Status Code : ${response.statusCode}
        //   • Status Text : ${response.statusText}
        //   • Body        : ${response.bodyString ?? response.body}
        //   • Headers     : ${response.headers}
        //   ''',
        //   name: 'startReceivingItem',
        // );
      }
    } catch (e, st) {
      log('❌ Exception in startReceivingItem: $e\n$st',name: 'startReceivingItem');
      Get.snackbar(
        "Error",
        "An unexpected error occurred while starting the receiving process.",
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      isLoadingReceiving.value = false;
    }
  }

  void setReceiveNumber(String value) => receiveNumber.value = value;
}
