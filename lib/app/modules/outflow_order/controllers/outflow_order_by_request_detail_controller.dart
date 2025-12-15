import 'package:get/get.dart';

import '../../../global/alert.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/outlfow_request_model.dart';
import '../../../modules/outflow_order/controllers/outflow_order_by_request_controller.dart';
import '../../../data/providers/outflow_order_provider.dart';
import '../../../routes/app_pages.dart';

class OutflowOrderByRequestDetailController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();

  var items = <Map<String, dynamic>>[].obs;
  var selectedIndex = 0.obs;
  var selectedItem = Rxn<Map<String, dynamic>>();
  var scannedResults = <String>[].obs;
  var isLoading = false.obs;
  var isLoadingOutflowing = false.obs;

  late final OutflowRequestModel currentOr;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;

    if (args != null && args is OutflowRequestModel) {
      currentOr = args;
      loadOrItems();
    } else {
      errorAlert("⚠️ Invalid or missing arguments in currentOrder: $args");
    }
  }

  Future<void> loadOrItems() async {
    final orderId = currentOr.id;
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getOutflowRequestLineItem(orderId),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;

    final normalizedData = data.map((item) {
      final scanned = (item.scanned != null && item.scanned!.isNotEmpty)
          ? item.scanned!
          : <String>[];

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

    items.assignAll(normalizedData);
  }

  void addScannedCode(String code,
      {int? batchQty, Map<String, dynamic>? extraData}) {
    final index = selectedIndex.value;
    if (index >= items.length) return;

    final item = items[index];
    final String itemName = item['name'] ?? '(unknown item)';
    final serialType = item['serialNumberType'] ?? 'OTHER';
    final expectedQty = item['expected'] ?? 0;

    final List<Map<String, dynamic>> scanned =
        List<Map<String, dynamic>>.from(item["scanned"] ?? []);

    final existingIndex = scanned.indexWhere((e) => e['code'] == code);

    final totalScannedQty =
        scanned.fold(0, (sum, e) => sum + (e['qty'] ?? 1) as int);

    final qtyToAdd = batchQty ?? 1;

    if (serialType == "OTHER" && scanned.isNotEmpty) {
      warningAlertBottom(
        title: "Not Allowed",
        "Only one scan is allowed for $itemName.",
      );
      return;
    }

    if (totalScannedQty + qtyToAdd > expectedQty) {
      errorAlertBottom(
        "Scanning this code would exceed the expected qty ($expectedQty) for $itemName.",
        title: "Exceeded Quantity",
      );
      return;
    }

    if (existingIndex != -1 && serialType != "BATCH") {
      warningAlertBottom(
        "Duplicate Code",
        title: 'Code "$code" already scanned for $itemName.',
      );
      return;
    }

    final newData = {"code": code, "qty": qtyToAdd};

    if (existingIndex != -1 && serialType == "BATCH") {
      scanned[existingIndex]['qty'] =
          (scanned[existingIndex]['qty'] ?? 0) + qtyToAdd;
    } else {
      scanned.add(newData);
    }

    item["scanned"] = scanned;
    items[index] = item;
    items.refresh();
  }

  void editScannedCode({required String oldCode, required String newCode}) {
    final index = selectedIndex.value;
    final item = items[index];

    final scanned = List<Map<String, dynamic>>.from(item['scanned'] ?? []);

    final foundIndex = scanned.indexWhere((e) => e['code'] == oldCode);
    if (foundIndex != -1) {
      scanned[foundIndex]['code'] = newCode;
      item['scanned'] = scanned;
      items.refresh();
    }
  }

  void removeScannedCode(String code) {
    final index = selectedIndex.value;
    final item = items[index];

    item['scanned']?.removeWhere((e) => e['code'] == code);
    items.refresh();
  }

  void clearScannedCodes() {
    final index = selectedIndex.value;
    if (index < items.length) {
      final item = items[index];
      final name = item["name"] ?? "Unknown";

      final cleared = (item["scanned"] as List?)?.length ?? 0;

      item["scanned"] = [];
      items[index] = Map<String, dynamic>.from(item);
      items.refresh();

      errorAlertBottom(
        title: "Cleared",
        "Removed $cleared scanned qty from $name",
      );
    }
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
    final Map<dynamic, List<Map<String, dynamic>>> result = {};

    for (final item in items) {
      result[item["line_id"]] =
          List<Map<String, dynamic>>.from(item["scanned"] ?? []);
    }

    return result;
  }

  int get totalScanned {
    final all = getAllScannedUnified();
    return all.values.fold<int>(0, (sum, list) {
      return sum + list.fold<int>(0, (inner, e) => inner + safeToInt(e['qty']));
    });
  }

  void startOutflowingItem() async {
    final or = currentOr;
    final payload = {
      "or_id": or.id,
      "items": items.toList(),
    };
    final response = await ApiExecutor.run(
      isLoading: isLoadingOutflowing,
      task: () => provider.postOrLineToOutflowedData(payload),
    );
    // If network failed or exception handled, data is null
    if (response == null) return;

    if (response.isOk && response.body?['success'] == true) {
      successAlertBottom("Outflowing process for ${or.code} completed!");
      
      await Future.delayed(const Duration(milliseconds: 400));
      if (Get.isRegistered<OutflowOrderByRequestController>()) {
        Get.delete<OutflowOrderByRequestController>(force: true);
      }

      Get.offAndToNamed(AppPages.outflowOrderByRequestPage);
    } else {
      errorAlertBottom("Failed to start outflowing for ${or.code}.");
    }
    
  }
}
