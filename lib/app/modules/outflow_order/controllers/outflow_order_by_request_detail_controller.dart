import 'package:get/get.dart';
import '../../../global/submit_key.dart';

import '../../../global/alert.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/outlfow_request_model.dart';
import '../../../modules/outflow_order/controllers/outflow_order_by_request_controller.dart';
import '../../../modules/delivery/delivery_actions.dart';
import '../outflow_submit.dart';
import '../outflow_batch_check.dart';
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
  /// The last load failed: the view offers Retry instead of reading it as empty.
  final hasError = false.obs;
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
    _batchStock.clear(); // a reload reads the stock afresh
    final orderId = currentOr.id;
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      hasError: hasError,
      task: () => provider.getOutflowRequestLineItem(orderId),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;

    final cached = await readLineDraft(_drafts, _draftScope);

    final cleared = <String>[];
    final normalizedData = data.map((item) {
      final serverScanned = (item.scanned != null && item.scanned!.isNotEmpty)
          ? item.scanned!
          : <String>[];
      // Restore any locally cached in-progress scans for this line — unless the
      // backend now refuses it, so a stale scan can't ride along to the submit.
      // A draft larger than what is still open is dropped (draftThatFits).
      final draft = cached[item.lineId.toString()];
      final fits = draftThatFits(draft, item.reserved - (item.received ?? 0));
      if (draft != null && fits == null && item.blockedReason == null) cleared.add(item.name);
      final scanned = item.blockedReason != null
          ? <String>[]
          : fits ?? serverScanned;

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

    items.assignAll(normalizedData);
    showClearedDrafts(cleared);
    // The pending submit key stays: if the earlier submit was booked (its answer
    // lost), the next tap gets `submit_already_saved` and drops the draft —
    // clearing it here would let the lines that still fit be booked twice.
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

  /// Busy flag of the BATCH label check ([batchLeft]).
  final isCheckingBatch = false.obs;

  /// Label stock per item, read once per load of this screen (see batchLeftToScan).
  final _batchStock = <int, Map<String, num>>{};

  /// What can still be drawn from BATCH label [code] on the selected line, or
  /// null when it can't (reason shown) — checked at the scan, before the qty.
  Future<num?> batchLeft(String code) {
    final index = selectedIndex.value;
    if (index >= items.length) return Future.value(null);
    return batchLeftToScan(provider, items[index], code, isLoading: isCheckingBatch, lines: items, stockCache: _batchStock);
  }

  void addScannedCode(String code,
      {num? batchQty, Map<String, dynamic>? extraData}) {
    final index = selectedIndex.value;
    if (index >= items.length) return;

    final item = items[index];
    final String itemName = item['name'] ?? '(unknown item)';
    final serialType = item['serialNumberType'] ?? 'OTHER';
    final reservedQty = safeToNum(item['reserved']);
    final received = safeToNum(item['received']);

    final List<Map<String, dynamic>> scanned =
        List<Map<String, dynamic>>.from(item["scanned"] ?? []);

    final existingIndex = scanned.indexWhere((e) => sameCode(e['serial_number'], code));

    final totalScannedQty = sumQty(scanned);

    final qtyToAdd = batchQty ?? 1;

    if (serialType == "OTHER" && scanned.isNotEmpty) {
      warningAlertBottom(
        title: "Not Allowed",
        "Only one scan is allowed for $itemName.",
      );
      return;
    }

    // Cap at the remaining qty: received + scanned must not exceed expected.
    if (roundQty(received + totalScannedQty + qtyToAdd) > reservedQty) {
      errorAlertBottom(
        "This would exceed the remaining qty (${formatQty(reservedQty - received)}) for $itemName.",
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
          roundQty(safeToNum(scanned[existingIndex]['qty']) + qtyToAdd);
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
    final reservedQty = safeToNum(item['reserved']);
    final received = safeToNum(item['received']);

    final scanned = List<Map<String, dynamic>>.from(item['scanned'] ?? []);
    if (scanned.any((e) => sameCode(e['serial_number'], code)) || scannedOnOtherLine(items, item, code)) {
      return ScanFeedback.duplicate("\"$code\" already scanned.");
    }

    final total = sumQty(scanned);
    if (roundQty(received + total + 1) > reservedQty) {
      return ScanFeedback.error(
          "Reached reserved qty (${formatQty(reservedQty)}) for $itemName.");
    }

    scanned.add({"serial_number": code, "qty": 1});
    item['scanned'] = scanned;
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
    final String itemName = item['name'] ?? '(unknown item)';
    final reservedQty = safeToNum(item['reserved']);
    final received = safeToNum(item['received']);

    // Cap at the remaining qty: received + this entry must not exceed expected.
    if (roundQty(received + qty) > reservedQty) {
      errorAlertBottom(
        "Quantity would exceed the remaining qty (${formatQty(reservedQty - received)}) for $itemName.",
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

  /// "Edit Code" on a scanned row — refused (reason shown) when the new code is
  /// a duplicate or, on a BATCH line, not in stock / too small for the row's qty.
  Future<void> editScannedCode({required String oldCode, required String newCode}) async {
    final index = selectedIndex.value;
    if (index >= items.length) return;
    newCode = newCode.trim();
    if (!await canRenameScan(provider, items[index], oldCode, newCode, isLoading: isCheckingBatch, lines: items, stockCache: _batchStock)) {
      return;
    }

    // Re-read the line: Clear or Remove may have replaced it during the lookup.
    if (index >= items.length) return;
    final item = items[index];
    final scanned = List<Map<String, dynamic>>.from(item['scanned'] ?? []);
    final foundIndex = scanned.indexWhere((e) => e['serial_number'] == oldCode);
    if (foundIndex == -1) {
      warningAlertBottom('"$oldCode" was removed while its new code was checked.', title: 'Not Renamed');
      return;
    }
    scanned[foundIndex]['serial_number'] = newCode;
    item['scanned'] = scanned;
    items[index] = item;
    items.refresh();
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

      final message = clearedEntriesMessage(item["scanned"] as List?, name);

      item["scanned"] = [];
      items[index] = Map<String, dynamic>.from(item);
      items.refresh();

      errorAlertBottom(
        title: "Cleared",
        message,
      );
    }
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
    final Map<dynamic, List<Map<String, dynamic>>> result = {};

    for (final item in items) {
      result[item["line_id"]] =
          List<Map<String, dynamic>>.from(item["scanned"] ?? []);
    }

    return result;
  }

  num get totalScanned => sumQty(getAllScannedUnified().values.expand((list) => list));

  void startOutflowingItem() async {
    final page = topRoute(); // see submitPageStillOpen
    final or = currentOr;
    final payload = {
      "or_id": or.id,
      "items": submitLines(items, "scanned"), // unscanned lines would be saved as qty 0
    };
    final data = await submitOutflowData(provider.postOrLineToOutflowedData, payload,
        isLoading: isLoadingOutflowing, submitKey: SubmitKey(_drafts, _draftScope, onAlreadySaved: () {
          dropAllEntries(items, 'scanned');
          loadOrItems();
        }));
    if (data == null) return;

    // Submitted to the server — drop the local in-progress draft.
    await _drafts.remove(_draftScope);
    // The entries on screen are booked now: kept, a second Continue (after a
    // failed delivery create, or from a page left open) would book them again.
    dropAllEntries(items, 'scanned');
    successAlertBottom("Outflowing process for ${or.code} completed!");

    // The worker left the page while it was sending: the document is saved
    // (snackbar above); don't navigate from whatever screen is on top now.
    if (!submitPageStillOpen(page)) return;

    // Offer to create a delivery for the newly created outflow order.
    final createdId = _createdOutflowId(data);
    final wantsDelivery = createdId != null && await confirmCreateDelivery();

    await Future.delayed(const Duration(milliseconds: 400));
    if (wantsDelivery) {
      // On success it unwinds to the Outflow menu, list included — its
      // controller goes with it; a failed create leaves the list alive.
      await createDeliveryForOutflow(createdId, replace: true, beforeLeaving: () {
        if (Get.isRegistered<OutflowOrderByRequestController>()) Get.delete<OutflowOrderByRequestController>(force: true);
      });
    } else {
      returnToListAfterSubmit(AppPages.outflowOrderByRequestPage, menuRoute: AppPages.outflowHomePage,
          refresh: () => Get.find<OutflowOrderByRequestController>().loadRequestOrders());
    }
  }

  /// The created outflow order id from the submit response (`data.data.id`).
  int? _createdOutflowId(Map<String, dynamic> data) {
    final inner = data['data'];
    final id = (inner is Map) ? inner['id'] : null;
    return (id is int) ? id : int.tryParse(id?.toString() ?? '');
  }
}
