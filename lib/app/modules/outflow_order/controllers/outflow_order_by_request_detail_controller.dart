import 'package:get/get.dart';

import '../../../global/alert.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/outlfow_request_model.dart';
import '../../../modules/outflow_order/controllers/outflow_order_by_request_controller.dart';
import '../../../modules/delivery/delivery_actions.dart';
import '../../../data/providers/outflow_order_provider.dart';
import '../../../global/scan_feedback.dart';
import '../../../services/draft_service.dart';
import '../../../routes/app_pages.dart';

class OutflowOrderByRequestDetailController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();

  /// Durable store for in-progress scans — they live only in memory until the
  /// final submit, so persist them to survive an app close / accidental exit.
  final DraftService _drafts = Get.find<DraftService>();
  Worker? _scanCacheWorker;
  String get _draftScope => 'outflow_or_${currentOr.id}';

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
      // Auto-persist scans on every change so nothing is lost before submit.
      _scanCacheWorker = ever(items, (_) => _persistScanned());
      loadOrItems();
    } else {
      errorAlert("⚠️ Invalid or missing arguments in currentOrder: $args");
    }
  }

  @override
  void onClose() {
    _scanCacheWorker?.dispose();
    super.onClose();
  }

  Future<void> loadOrItems() async {
    final orderId = currentOr.id;
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getOutflowRequestLineItem(orderId),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;

    final cached = await readLineDraft(_drafts, _draftScope);
    final normalizedData = data.map((item) {
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

    items.assignAll(normalizedData);
  }

  /// Persist current scans (only non-empty lines); clears the draft when empty.
  void _persistScanned() {
    final map = buildLineDraftMap(items, "scanned");
    if (map.isEmpty) {
      _drafts.remove(_draftScope);
    } else {
      _drafts.saveJson(_draftScope, map);
    }
  }

  void addScannedCode(String code,
      {int? batchQty, Map<String, dynamic>? extraData}) {
    final index = selectedIndex.value;
    if (index >= items.length) return;

    final item = items[index];
    final String itemName = item['name'] ?? '(unknown item)';
    final serialType = item['serialNumberType'] ?? 'OTHER';
    final expectedQty = item['expected'] ?? 0;
    final received = item['received'] ?? 0;

    final List<Map<String, dynamic>> scanned =
        List<Map<String, dynamic>>.from(item["scanned"] ?? []);

    final existingIndex = scanned.indexWhere((e) => e['serial_number'] == code);

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

    // Cap at the remaining qty: received + scanned must not exceed expected.
    if (received + totalScannedQty + qtyToAdd > expectedQty) {
      errorAlertBottom(
        "This would exceed the remaining qty (${expectedQty - received}) for $itemName.",
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

    final newData = {"serial_number": code, "qty": qtyToAdd};

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

  /// Continuous batch-scan add for a UNIQUE serial-tracked item (one scan = one
  /// unit). Returns [ScanFeedback] for the scanner overlay instead of showing a
  /// snackbar; the camera stays open so the worker scans unit after unit.
  ScanFeedback scanUnique(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) return ScanFeedback.error("Empty code.");

    final index = selectedIndex.value;
    if (index >= items.length) return ScanFeedback.error("No item selected.");

    final item = items[index];
    final String itemName = item['name'] ?? 'item';
    final expectedQty = item['expected'] ?? 0;
    final received = item['received'] ?? 0;

    final scanned = List<Map<String, dynamic>>.from(item['scanned'] ?? []);
    if (scanned.any((e) => e['serial_number'] == code)) {
      return ScanFeedback.duplicate("\"$code\" already scanned.");
    }

    final total = scanned.fold<int>(0, (sum, e) => sum + safeToInt(e['qty']));
    if (received + total + 1 > expectedQty) {
      return ScanFeedback.error(
          "Reached expected qty ($expectedQty) for $itemName.");
    }

    scanned.add({"serial_number": code, "qty": 1});
    item['scanned'] = scanned;
    items[index] = item;
    items.refresh();
    return ScanFeedback.ok("Scanned ${received + total + 1}/$expectedQty");
  }

  /// Non serial-tracked (manage_sn == false) items don't scan — they hold a
  /// single quantity entry with no code. Set/replace it (used for add + edit).
  void setScannedQty(int qty) {
    final index = selectedIndex.value;
    if (index >= items.length) return;

    final item = items[index];
    final String itemName = item['name'] ?? '(unknown item)';
    final expectedQty = item['expected'] ?? 0;
    final received = item['received'] ?? 0;

    // Cap at the remaining qty: received + this entry must not exceed expected.
    if (received + qty > expectedQty) {
      errorAlertBottom(
        "Quantity would exceed the remaining qty (${expectedQty - received}) for $itemName.",
        title: "Exceeded Quantity",
      );
      return;
    }

    item['scanned'] = [
      {"qty": qty}
    ];
    items[index] = item;
    items.refresh();
  }

  void editScannedCode({required String oldCode, required String newCode}) {
    final index = selectedIndex.value;
    final item = items[index];

    final scanned = List<Map<String, dynamic>>.from(item['scanned'] ?? []);

    final foundIndex = scanned.indexWhere((e) => e['serial_number'] == oldCode);
    if (foundIndex != -1) {
      scanned[foundIndex]['serial_number'] = newCode;
      item['scanned'] = scanned;
      items.refresh();
    }
  }

  void removeScannedCode(String code) {
    final index = selectedIndex.value;
    final item = items[index];

    item['scanned']?.removeWhere((e) => e['serial_number'] == code);
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
    final data = await ApiExecutor.run(
      isLoading: isLoadingOutflowing,
      task: () => provider.postOrLineToOutflowedData(payload),
    );
    if (data == null) return;

    // Submitted to the server — drop the local in-progress draft.
    await _drafts.remove(_draftScope);
    successAlertBottom("Outflowing process for ${or.code} completed!");

    // Offer to create a delivery for the newly created outflow order.
    final createdId = _createdOutflowId(data);
    final wantsDelivery = createdId != null && await confirmCreateDelivery();

    await Future.delayed(const Duration(milliseconds: 400));
    if (Get.isRegistered<OutflowOrderByRequestController>()) {
      Get.delete<OutflowOrderByRequestController>(force: true);
    }

    if (wantsDelivery) {
      await createDeliveryForOutflow(createdId);
    } else {
      Get.offAndToNamed(AppPages.outflowOrderByRequestPage);
    }
  }

  /// The created outflow order id from the submit response (`data.data.id`).
  int? _createdOutflowId(Map<String, dynamic> data) {
    final inner = data['data'];
    final id = (inner is Map) ? inner['id'] : null;
    return (id is int) ? id : int.tryParse(id?.toString() ?? '');
  }
}
