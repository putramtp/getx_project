import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/accent.dart';
import '../../../global/alert.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/outflow_request_customer_model.dart';
import '../../../data/models/outflow_request_line_item_model.dart';
import '../../../modules/outflow_order/controllers/outflow_order_by_customer_controller.dart';
import '../../../modules/delivery/delivery_actions.dart';
import '../outflow_submit.dart';
import '../../../data/providers/outflow_order_provider.dart';
import '../../../global/scan_feedback.dart';
import '../../../services/draft_service.dart';
import '../../../routes/app_pages.dart';

/// Item Summary + scan for one customer's reservations (a delivery order) —
/// and, through [OutflowOrderByWorkOrderDetailController], for one work
/// order's (material issued to production). The views read the target from
/// the hooks below.
class OutflowOrderByCustomerDetailController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();

  /// Durable store for in-progress scans — they live only in memory until the
  /// final submit, so persist them to survive an app close / accidental exit.
  final DraftService drafts = Get.find<DraftService>();
  Worker? _scanCacheWorker;

  // What this screen issues to; By Work Order overrides these.
  String get draftScope => 'outflow_cust_${currentOrCustomer.id}';
  String get targetLabel => 'Customer';
  IconData get targetIcon => Icons.groups_rounded;
  AppAccent get accent => AppAccent.amber;
  Future<List<OutflowRequestLineItemModel>> fetchLines() =>
      provider.getOutflowRequestLineItemByCustomer(currentOrCustomer.id);

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
      task: fetchLines,
    );
    // If network failed or exception handled, data is null
    if (data == null) return;

    final cached = await readLineDraft(drafts, draftScope);
    final normalized = data.map((item) {
      final serverScanned = (item.scanned != null && item.scanned!.isNotEmpty)
          ? item.scanned!
          : <String>[];
      // Restore any locally cached in-progress scans for this line — unless the
      // backend now refuses it, so a stale scan can't ride along to the submit.
      final scanned = item.blockedReason != null
          ? <String>[]
          : cached[item.lineId.toString()] ?? serverScanned;

      return {
        "line_id": item.lineId,
        "item_id": item.itemId,
        "name": item.name,
        "serialNumberType": item.serialNumberType,
        "manageExpired": item.manageExpired,
        "manage_sn": item.manageSn,
        "expected": item.expected,
        "reserved": item.reserved,
        "received": item.received,
        "scanned": scanned,
        "blocked_reason": item.blockedReason,
      };
    }).toList();

    items.assignAll(normalized);
  }

  /// Persist current scans (only non-empty lines); clears the draft when empty.
  void _persistScanned() {
    final map = buildLineDraftMap(items, "scanned");
    if (map.isEmpty) {
      drafts.remove(draftScope);
    } else {
      drafts.saveJson(draftScope, map);
    }
  }

  void addScannedCode(String code,
      {num? batchQty, Map<String, dynamic>? extraData}) {
    final index = selectedIndex.value;

    final item = items[index];
    final serialType = item["serialNumberType"];
    final reservedQty = safeToNum(item["reserved"]);
    final received = safeToNum(item["received"]);

    final scanned = List<Map<String, dynamic>>.from(item["scanned"] ?? []);
    final existingIndex = scanned.indexWhere((e) => e['serial_number'] == code);

    final totalScanned = sumQty(scanned);

    final qty = batchQty ?? 1;

    if (serialType == "OTHER" && scanned.isNotEmpty) {
      warningAlertBottom("Only one scan is allowed.");
      return;
    }

    // Cap at the remaining qty: received + scanned must not exceed expected.
    if (roundQty(received + totalScanned + qty) > reservedQty) {
      errorAlertBottom("Exceeds remaining qty (${formatQty(reservedQty - received)}).");
      return;
    }

    if (existingIndex != -1 && serialType != "BATCH") {
      warningAlertBottom("Duplicate code.");
      return;
    }

    final newData = {"serial_number": code, "qty": qty};

    if (existingIndex != -1 && serialType == "BATCH") {
      scanned[existingIndex]['qty'] = roundQty(safeToNum(scanned[existingIndex]['qty']) + qty);
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
    final reservedQty = safeToNum(item["reserved"]);
    final received = safeToNum(item["received"]);

    final scanned = List<Map<String, dynamic>>.from(item["scanned"] ?? []);
    if (scanned.any((e) => e['serial_number'] == code)) {
      return ScanFeedback.duplicate("\"$code\" already scanned.");
    }

    final total = sumQty(scanned);
    if (roundQty(received + total + 1) > reservedQty) {
      return ScanFeedback.error(
          "Reached reserved qty (${formatQty(reservedQty)}) for $itemName.");
    }

    scanned.add({"serial_number": code, "qty": 1});
    item["scanned"] = scanned;
    items[index] = item;
    items.refresh();
    return ScanFeedback.ok("Scanned ${formatQty(received + total + 1)}/${formatQty(reservedQty)}");
  }

  /// Non serial-tracked (manage_sn == false) items don't scan — they hold a
  /// single quantity entry with no code. Set/replace it (used for add + edit).
  void setScannedQty(num qty) {
    final index = selectedIndex.value;
    if (index >= items.length) return;

    final item = items[index];
    final reservedQty = safeToNum(item["reserved"]);
    final received = safeToNum(item["received"]);

    // Cap at the remaining qty: received + this entry must not exceed expected.
    if (roundQty(received + qty) > reservedQty) {
      errorAlertBottom("Exceeds remaining qty (${formatQty(reservedQty - received)}).");
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
    final idx = scanned.indexWhere((e) => e["serial_number"] == oldCode);

    if (idx != -1) {
      scanned[idx]["serial_number"] = newCode;
      item["scanned"] = scanned;
      items.refresh();
    }
  }

  void removeScannedCode(String code) {
    final item = items[selectedIndex.value];

    item["scanned"]?.removeWhere((e) => e["serial_number"] == code);
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
    // Lines the backend would refuse are read-only — skip them.
    final next = nextOpenLine(items, selectedIndex.value);

    if (next != null) {
      selectedIndex.value = next;
    } else {
      closeRoute(true);
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

  num get totalScanned => sumQty(getAllScannedUnified().values.expand((list) => list));

  Future<void> startOutflowingItem() async {
    final customer = currentOrCustomer;

    final payload = {
      "customer_id": customer.id,
      "items": linesToSubmit(items, "scanned"), // unscanned lines would be saved as qty 0
    };
    final data = await submitOutflowData(provider.postOrLineToOutflowedData, payload, isLoading: isLoadingOutflowing);
    if (data == null) return;

    // Submitted to the server — drop the local in-progress draft.
    await drafts.remove(draftScope);
    successAlertBottom("Outflow for ${customer.name} completed!");

    // Offer to create a delivery for the newly created outflow order.
    final createdId = _createdOutflowId(data);
    final wantsDelivery = createdId != null && await confirmCreateDelivery();

    await Future.delayed(const Duration(milliseconds: 300));
    if (Get.isRegistered<OutflowOrderByCustomerController>()) {
      Get.delete<OutflowOrderByCustomerController>(force: true);
    }

    if (wantsDelivery) {
      await createDeliveryForOutflow(createdId, replace: true);
    } else {
      Get.offAndToNamed(AppPages.outflowOrderByCustomerPage);
    }
  }

  /// The created outflow order id from the submit response (`data.data.id`).
  int? _createdOutflowId(Map<String, dynamic> data) {
    final inner = data['data'];
    final id = (inner is Map) ? inner['id'] : null;
    return (id is int) ? id : int.tryParse(id?.toString() ?? '');
  }
}
