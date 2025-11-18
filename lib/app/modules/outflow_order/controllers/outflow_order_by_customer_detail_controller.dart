import 'dart:developer';

import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/models/outflow_request_customer_model.dart';
import 'package:getx_project/app/models/outflow_request_line_item_model.dart';
import 'package:getx_project/app/modules/outflow_order/controllers/outflow_order_by_customer_controller.dart';
import 'package:getx_project/app/modules/outflow_order/providers/outflow_order_provider.dart';
import 'package:getx_project/app/routes/app_pages.dart';


class OutflowOrderByCustomerDetailController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();

  var items = <Map<String, dynamic>>[].obs;
  var selectedIndex = 0.obs;
  var selectedItem = Rxn<Map<String, dynamic>>();
  var scannedResults = <String>[].obs;
  var isLoading = false.obs;
  var isLoadingOutflowing = false.obs;

  late final OrCustomer currentOrCustomer;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;

    if (args != null && args is OrCustomer) {
      currentOrCustomer = args;
      loadOrByCustomerItems();
    } else {
      log("⚠️ Invalid or missing arguments in currentOrder: $args");
    }
  }

  Future<void> loadOrByCustomerItems() async {
    try {
      isLoading.value = true;

      final List<OutflowRequestLineItem> data = await provider.getOutflowRequestLineItemByCustomer(currentOrCustomer.id);

      final normalized = data.map((item) {
        final scanned =
            (item.scanned != null && item.scanned!.isNotEmpty) ? item.scanned! : <String>[];

        return {
          "line_id": item.lineId,
          "name": item.name,
          "serialNumberType": item.serialNumberType,
          "manageExpired": item.manageExpired,
          "expected": item.expected,
          "received": item.received,
          "scanned": scanned,
        };
      }).toList();

      items.assignAll(normalized);
    } catch (e) {
      errorAlertBottom("Unable to load items.\nError: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void addScannedCode(String code, {int? batchQty, Map<String, dynamic>? extraData}) {
    final index = selectedIndex.value;

    final item = items[index];
    final serialType = item["serialNumberType"];
    final expectedQty = item["expected"];

    final scanned = List<Map<String, dynamic>>.from(item["scanned"] ?? []);
    final existingIndex = scanned.indexWhere((e) => e['code'] == code);

    final totalScanned =
        scanned.fold(0, (sum, e) => sum + (e['qty'] ?? 1) as int);

    final qty = batchQty ?? 1;

    if (serialType == "OTHER" && scanned.isNotEmpty) {
      warningAlertBottom("Only one scan is allowed.");
      return;
    }

    if (totalScanned + qty > expectedQty) {
      errorAlertBottom("Exceeds expected qty.");
      return;
    }

    if (existingIndex != -1 && serialType != "BATCH") {
      warningAlertBottom("Duplicate code.");
      return;
    }

    final newData = {"code": code, "qty": qty};

    if (existingIndex != -1 && serialType == "BATCH") {
      scanned[existingIndex]['qty'] += qty;
    } else {
      scanned.add(newData);
    }

    item["scanned"] = scanned;
    items[index] = item;
    items.refresh();
  }

  void editScannedCode({required String oldCode, required String newCode}) {
    final item = items[selectedIndex.value];

    final scanned = List<Map<String, dynamic>>.from(item["scanned"] ?? []);
    final idx = scanned.indexWhere((e) => e["code"] == oldCode);

    if (idx != -1) {
      scanned[idx]["code"] = newCode;
      item["scanned"] = scanned;
      items.refresh();
    }
  }

  void removeScannedCode(String code) {
    final item = items[selectedIndex.value];

    item["scanned"]?.removeWhere((e) => e["code"] == code);
    items.refresh();
  }

  void clearScannedCodes() {
    final index = selectedIndex.value;

    final item = items[index];
    item["scanned"] = [];

    items[index] = Map<String, dynamic>.from(item);
    items.refresh();
  }

  void goToNextItem() {
    final next = selectedIndex.value + 1;

    if (next < items.length) {
      selectedIndex.value = next;
    } else {
      Get.back(result: true);
    }
  }

  Map<dynamic, List<Map<String, dynamic>>> getAllScannedUnified() {
    final result = <dynamic, List<Map<String, dynamic>>>{};

    for (final item in items) {
      result[item["line_id"]] =
          List<Map<String, dynamic>>.from(item["scanned"] ?? []);
    }

    return result;
  }

  int get totalScanned {
    final all = getAllScannedUnified();
    return all.values.fold<int>(0, (sum, list) {
      return sum +
          list.fold<int>(0, (inner, e) => inner + safeToInt(e['qty']));
    });
  }


  void startOutflowingItem() async {
    if (isLoadingOutflowing.value) return;

    isLoadingOutflowing.value = true;

    try {
      final customer = currentOrCustomer;

      final payload = {
        "customer_id": customer.id,
        "items": items.toList(),
      };

      final response = await provider.postOrLineToOutflowedData(payload);

      if (response.isOk && response.body?["success"] == true) {
        successAlertBottom("Outflow for ${customer.name} completed!");

        await Future.delayed(const Duration(milliseconds: 300));

        if (Get.isRegistered<OutflowOrderByCustomerController>()) {
          Get.delete<OutflowOrderByCustomerController>(force: true);
        }

        Get.offAndToNamed(AppPages.outflowOrderByCustomerPage);
      } else {
        errorAlertBottom("Failed to process outflow.");
      }
    } catch (e) {
      errorAlertBottom("Unexpected error: $e");
    } finally {
      isLoadingOutflowing.value = false;
    }
  }
}
