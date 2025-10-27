import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/models/purchase_order_item_model_copy.dart';
import 'package:getx_project/app/models/purchase_order_model.dart';
import 'package:getx_project/app/modules/outflow_order/providers/outflow_order_provider.dart';

class OutflowOrderDetailController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();

  var items = <Map<String, dynamic>>[].obs;
  var selectedIndex = 0.obs;
  var selectedItem = Rxn<Map<String, dynamic>>();
  var scannedResults = <String>[].obs;
  var isLoading = false.obs;
  late final PurchaseOrder currentOrder;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;

    if (args != null && args is PurchaseOrder) {
      currentOrder = args;
      loadOutflowOrderItems();
    } else {
      log("⚠️ Invalid or missing arguments in OutflowOrderDetailController: $args");
    }
  }

  /// 🔹 Fetch items for this order
  Future<void> loadOutflowOrderItems() async {
    try {
      isLoading.value = true;
      final orderId = currentOrder.id;

      final List<PurchaseOrderItemCopy> data = await provider.getOutflowOrderItems(orderId);
      log("loadOutflowOrderItems success : $data");
      // Normalize each item: ensure scanned list & outflowd count are consistent
      final normalizedData = data.map((item) {
        final scanned = (item.scanned != null && item.scanned!.isNotEmpty)
            ? item.scanned!
            : <String>[];
        return {
          "id": item.id,
          "name": item.name,
          "serialNumberType": item.serialNumberType,
          "expected": item.expected,
          "received": item.received,
          "scanned": scanned,
        };
      }).toList();

      items.assignAll(normalizedData);
    } catch (e) {
      log("loadOutflowOrderItems error: $e");
      Get.snackbar(
        'Failed',
        'Unable to load outflow order items.\nError: $e',
        backgroundColor: const Color(0xFFF44336),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 Add new scanned barcode (Unified format for UNIQUE + BATCH)
  void addScannedCode(
    String code, {
    int? batchQty,
    Map<String, dynamic>? extraData,
  }) {
    final index = selectedIndex.value;
    if (index >= items.length) return;

    final item = items[index];
    final String itemName = item['name'] ?? '(unknown item)';
    final serialType = item['serialNumberType'] ?? 'OTHER';
    final expectedQty = item['expected'] ?? 0;

    final List<Map<String, dynamic>> scanned =
        List<Map<String, dynamic>>.from(item["scanned"] ?? []);

    final existingIndex = scanned.indexWhere((e) => e['code'] == code);

    // 🔹 Calculate current total scanned qty
    final totalScannedQty = scanned.fold<int>(
      0,
      (sum, e) => sum + (e['qty'] ?? 1) as int,
    );

    // 🔹 Determine new qty
    final qtyToAdd = batchQty ?? 1;

    // 🔹 Special rule for serialType == "OTHER"
    if (serialType == 'OTHER' && scanned.isNotEmpty) {
      Get.snackbar(
        "Not Allowed",
        "Only one scan is allowed for $itemName.",
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade800,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.block_rounded, color: Colors.orange),
      );
      return;
    }

    // 🔹 Over-scan protection
    if (totalScannedQty + qtyToAdd > expectedQty) {
      Get.snackbar(
        "Exceeded Quantity",
        "Scanning this code would exceed the expected qty ($expectedQty) for $itemName.",
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
      );
      return;
    }

    // 🔹 Duplicate handling
    if (existingIndex != -1 && serialType != 'BATCH') {
      Get.snackbar(
        "Duplicate Code",
        "Code \"$code\" already scanned for $itemName.",
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade800,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error_outline, color: Colors.orange),
      );
      return;
    }

    // 🔹 Build unified scan data
    final newData = {
      "code": code,
      "qty": qtyToAdd,
    };

    // 🔹 Handle BATCH logic (update qty if exists)
    if (existingIndex != -1 && serialType == 'BATCH') {
      scanned[existingIndex]['qty'] =
          (scanned[existingIndex]['qty'] ?? 0) + qtyToAdd;
    } else {
      scanned.add(newData);
    }

    // 🔹 Save and refresh
    item["scanned"] = scanned;
    items[index] = item;
    items.refresh();

    log(
      "✅ [${DateTime.now().toIso8601String()}] Added/Updated scan for $itemName → $newData (Total now: ${totalScannedQty + qtyToAdd}/$expectedQty)",
    );
  }

  /// Edit code (only applies to unique or batch)
  void editScannedCode({required String oldCode, required String newCode}) {
    final index = selectedIndex.value;
    final item = items[index];
    final scanned = List<Map<String, dynamic>>.from(item['scanned'] ?? []);

    final foundIndex = scanned.indexWhere((e) => e['code'] == oldCode);
    if (foundIndex != -1) {
      scanned[foundIndex]['code'] = newCode;
      item['scanned'] = scanned;
      items.refresh();
      log('Edited code $oldCode → $newCode');
    }
  }

  void removeScannedCode(String code) {
    final index = selectedIndex.value;
    final item = items[index];
    item['scanned']
        ?.removeWhere((e) => e['code']?.toString() == code.toString());
    items.refresh();
    log('Removed code $code');
  }

  /// ✅ Clear all scanned codes for the currently selected item
  void clearScannedCodes() {
    final index = selectedIndex.value;
    if (index < items.length) {
      final item = items[index];
      final name = item["name"] ?? "Unknown";

      final clearedCount = (item["scanned"] as List?)?.length ?? 0;
      item["scanned"] = [];
      items[index] = Map<String, dynamic>.from(item); // trigger update
      items.refresh();

      log("✅ Cleared $clearedCount scanned codes for $name");
      Get.snackbar(
        "Cleared",
        "Removed $clearedCount scanned code(s) from $name",
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
      Get.back(result: true); // close scan page
    }
  }

  /// 🔹 Get all scanned codes per item (Unified format)
  Map<dynamic, List<Map<String, dynamic>>> getAllScannedUnified() {
    final Map<dynamic, List<Map<String, dynamic>>> result = {};
    for (final item in items) {
      final id = item["id"];
      final scanned = List<Map<String, dynamic>>.from(item["scanned"] ?? []);
      result[id] = scanned;
    }
    return result;
  }

  /// 🔹 Start scan session (just a message for now)
  // void startReceivingItem() {
  //   final po = currentOrder.poNumber;
  //   log(items.toString(), name: 'startReceivingItem');
  //   Get.snackbar("Receiving", "Continue receiving items for $po");
  // }

  void startReceivingItem() async {
    try {
      final PurchaseOrder po = currentOrder;
      final poNumber = po.poNumber;

      // ✅ Build clean combined payload (no dateNow)
      final Map<String, dynamic> payload = {
        ...po.toJson(),
        "items": items.toList(),
      };

      // ✅ Log the full combined result
      log("📦 Final concatenated payload to send:\n$payload",name: 'startReceivingItem');

      // ✅ POST using your provider
      final response = await provider.postOutflowdData(payload);

      if (response.isOk) {
        Get.snackbar(
          "Success",
          "Receiving process for $poNumber started successfully.",
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
      } else {
        Get.snackbar(
          "Failed",
          "Unable to start receiving for $poNumber. Please try again.",
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.error_outline, color: Colors.red),
        );
      }
    } catch (e, st) {
      log('❌ Error in startReceivingItem: $e\n$st');
      Get.snackbar(
        "Error",
        "An unexpected error occurred while starting the receiving process.",
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }
}
