import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../global/alert.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/outflow_request_customer_model.dart';
import '../../../modules/outflow_order/controllers/outflow_order_by_customer_controller.dart';
import '../../../data/providers/outflow_order_provider.dart';
import '../../../routes/app_pages.dart';

class OutflowOrderByCustomerDetailController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();

  /// Local cache of in-progress scans — they live only in memory until the
  /// final submit, so persist them to survive an app close / accidental exit.
  final GetStorage _box = GetStorage();
  Worker? _scanCacheWorker;
  String get _cacheKey => 'or_cust_scanned_${currentOrCustomer.id}';

  var items = <Map<String, dynamic>>[].obs;
  var selectedIndex = 0.obs;
  var selectedItem = Rxn<Map<String, dynamic>>();
  var scannedResults = <String>[].obs;
  var isLoading = false.obs;
  var isLoadingOutflowing = false.obs;

  late final OrCustomerModel currentOrCustomer;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is OrCustomerModel) {
      currentOrCustomer = args;
      // Auto-persist scans on every change so nothing is lost before submit.
      _scanCacheWorker = ever(items, (_) => _persistScanned());
      loadOrByCustomerItems();
    } else {
      errorAlert("⚠️ Invalid or missing arguments in currentOrder: $args");
    }
  }

  @override
  void onClose() {
    _scanCacheWorker?.dispose();
    super.onClose();
  }

  Future<void> loadOrByCustomerItems() async {
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      task: () =>
          provider.getOutflowRequestLineItemByCustomer(currentOrCustomer.id),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;

    final cached = _readCachedScanned();
    final normalized = data.map((item) {
      final serverScanned = (item.scanned != null && item.scanned!.isNotEmpty)
          ? item.scanned!
          : <String>[];
      // Restore any locally cached in-progress scans for this line.
      final scanned = cached[item.lineId.toString()] ?? serverScanned;

      return {
        "line_id": item.lineId,
        "name": item.name,
        "serialNumberType": item.serialNumberType,
        "manageExpired": item.manageExpired,
        "manage_sn": item.manageSn,
        "expected": item.expected,
        "received": item.received,
        "scanned": scanned,
      };
    }).toList();

    items.assignAll(normalized);
  }

  /// Read previously cached scans, keyed by line id (as string).
  Map<String, List<Map<String, dynamic>>> _readCachedScanned() {
    final raw = _box.read(_cacheKey);
    if (raw is! Map) return {};
    final result = <String, List<Map<String, dynamic>>>{};
    raw.forEach((key, value) {
      if (value is List) {
        result[key.toString()] = value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    });
    return result;
  }

  /// Persist current scans (only non-empty lines); clears the key when empty.
  void _persistScanned() {
    final map = <String, dynamic>{};
    for (final item in items) {
      final list = List<Map<String, dynamic>>.from(item['scanned'] ?? []);
      if (list.isNotEmpty) map[item['line_id'].toString()] = list;
    }
    if (map.isEmpty) {
      _box.remove(_cacheKey);
    } else {
      _box.write(_cacheKey, map);
    }
  }

  void addScannedCode(String code,
      {int? batchQty, Map<String, dynamic>? extraData}) {
    final index = selectedIndex.value;

    final item = items[index];
    final serialType = item["serialNumberType"];
    final expectedQty = item["expected"];
    final received = item["received"] ?? 0;

    final scanned = List<Map<String, dynamic>>.from(item["scanned"] ?? []);
    final existingIndex = scanned.indexWhere((e) => e['code'] == code);

    final totalScanned =
        scanned.fold(0, (sum, e) => sum + (e['qty'] ?? 1) as int);

    final qty = batchQty ?? 1;

    if (serialType == "OTHER" && scanned.isNotEmpty) {
      warningAlertBottom("Only one scan is allowed.");
      return;
    }

    // Cap at the remaining qty: received + scanned must not exceed expected.
    if (received + totalScanned + qty > expectedQty) {
      errorAlertBottom("Exceeds remaining qty (${expectedQty - received}).");
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

  /// Non serial-tracked (manage_sn == false) items don't scan — they hold a
  /// single quantity entry with no code. Set/replace it (used for add + edit).
  void setScannedQty(int qty) {
    final index = selectedIndex.value;
    if (index >= items.length) return;

    final item = items[index];
    final expectedQty = item["expected"] ?? 0;
    final received = item["received"] ?? 0;

    // Cap at the remaining qty: received + this entry must not exceed expected.
    if (received + qty > expectedQty) {
      errorAlertBottom("Exceeds remaining qty (${expectedQty - received}).");
      return;
    }

    item["scanned"] = [
      {"qty": qty}
    ];
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
      return sum + list.fold<int>(0, (inner, e) => inner + safeToInt(e['qty']));
    });
  }

  void startOutflowingItem() async {
    final customer = currentOrCustomer;

    final payload = {
      "customer_id": customer.id,
      "items": items.toList(),
    };
    final data = await ApiExecutor.run(
      isLoading: isLoadingOutflowing,
      task: () => provider.postOrLineToOutflowedData(payload),
    );
    if (data == null) return;

    // Submitted to the server — drop the local in-progress cache.
    _box.remove(_cacheKey);
    successAlertBottom("Outflow for ${customer.name} completed!");
    await Future.delayed(const Duration(milliseconds: 300));
    if (Get.isRegistered<OutflowOrderByCustomerController>()) {
      Get.delete<OutflowOrderByCustomerController>(force: true);
    }
    Get.offAndToNamed(AppPages.outflowOrderByCustomerPage);
  }
}
