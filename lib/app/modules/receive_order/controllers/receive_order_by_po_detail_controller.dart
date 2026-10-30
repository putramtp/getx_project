import 'package:get/get.dart';

import '../controllers/receive_order_by_po_controller.dart';
import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/purchase_order_model.dart';
import '../../../data/providers/receive_order_provider.dart';
import '../../../services/draft_service.dart';
import '../../../routes/app_pages.dart';
import '../../../global/functions.dart';

class ReceiveOrderByPoDetailController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();

  /// Durable store for in-progress fills — they live only in memory until the
  /// final submit, so persist them to survive an app close / crash / offline.
  final DraftService _drafts = Get.find<DraftService>();
  Worker? _fillCacheWorker;
  String get _draftScope => 'receive_po_${currentOrder.id}';

  var items = <Map<String, dynamic>>[].obs;
  var selectedIndex = 0.obs;
  var selectedItem = Rxn<Map<String, dynamic>>();
  var filledResults = <String>[].obs;
  var isLoading = false.obs;
  var isLoadingReceiving = false.obs;
  late final PurchaseOrderModel currentOrder;
  final receiveNumber = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is PurchaseOrderModel) {
      currentOrder = args;
      // Auto-persist fills on every change so nothing is lost before submit.
      _fillCacheWorker = ever(items, (_) => _persistDraft());
      loadPurchaseOrderItems();
    } else {
      errorAlert("⚠️ Invalid or missing arguments in currentOrder: $args");
    }
  }

  @override
  void onClose() {
    _fillCacheWorker?.dispose();
    super.onClose();
  }

  /// 🔹 Fetch items for this order
  Future<void> loadPurchaseOrderItems() async {
    final orderId = currentOrder.id;
    final data = await ApiExecutor.run(
        isLoading: isLoading,
        task: () => provider.getPurchaseOrderLineItem(orderId));
    if (data == null) return;

    final cached = await readLineDraft(_drafts, _draftScope);
    final normalizedData = data.map((item) {
      final serverFilled = (item.filled != null && item.filled!.isNotEmpty)
          ? item.filled!
          : <String>[];
      // Restore any locally cached in-progress fills for this line — unless the
      // backend now refuses it, so a stale fill can't ride along to the submit.
      final filled = item.blockedReason != null
          ? <String>[]
          : cached[item.lineId.toString()] ?? serverFilled;
      return {
        "line_id": item.lineId,
        "name": item.name,
        "serialNumberType": item.serialNumberType,
        "manageExpired": item.manageExpired,
        "manage_sn": item.manageSn,
        "expected": item.expected,
        "received": item.received,
        "filled": filled,
        "blocked_reason": item.blockedReason,
      };
    }).toList();

    items.assignAll(normalizedData);
  }

  /// Persist current fills (only non-empty lines); clears the draft when empty.
  void _persistDraft() {
    final map = buildLineDraftMap(items, "filled");
    if (map.isEmpty) {
      _drafts.remove(_draftScope);
    } else {
      _drafts.saveJson(_draftScope, map);
    }
  }

  /// 🔹 Add new filled barcode (Unified format for UNIQUE + BATCH)
  void addFilledQty({
    num? batchQty,
    String? expiredDate,
  }) {
    final index = selectedIndex.value;
    if (index >= items.length) return;

    final item = items[index];
    final String itemName = item['name'] ?? '(unknown item)';
    final serialType = item['serialNumberType'] ?? 'OTHER';
    final expectedQty = safeToNum(item['expected']);
    final receivedQty = safeToNum(item['received']);

    final List<Map<String, dynamic>> filled =
        List<Map<String, dynamic>>.from(item["filled"] ?? []);

    // 🔹 Calculate current total filled qty
    final totalFilledQty = sumQty(filled);

    // 🔹 Determine new qty
    final qtyToAdd = batchQty ?? 1;

    if (serialType != 'BATCH' && filled.isNotEmpty) {
      warningAlertBottom(
          title: "Not Allowed", "Only one fill is allowed for $itemName.");
      return;
    }

    // 🔹 Over-fill protection
    if (roundQty(totalFilledQty + qtyToAdd + receivedQty) > expectedQty) {
      errorAlertBottom(
          title: "Exceeded Quantity",
          "Filling this item would exceed the expected qty (${formatQty(expectedQty)}) for $itemName.");
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

  /// 🔹 Add a scanned batch serial for a serial-managed BATCH item.
  /// One receive line can be split across several batch serials — e.g. a batch
  /// of 5 entered as 2 + 3 — so each call adds one `{serial, qty, expired_date}`
  /// entry carrying its own batch [qty]. Only used for `manage_sn` + BATCH.
  void addFilledSerial({required String serial, num qty = 1, String? expiredDate}) {
    final index = selectedIndex.value;
    if (index >= items.length) return;

    final item = items[index];
    final String itemName = item['name'] ?? '(unknown item)';
    final expectedQty = safeToNum(item['expected']);
    final receivedQty = safeToNum(item['received']);

    final filled = List<Map<String, dynamic>>.from(item['filled'] ?? []);

    // Reject duplicate batch serials.
    if (filled.any((e) => (e['serial']?.toString() ?? '') == serial)) {
      warningAlertBottom(
          title: "Duplicate Serial",
          "Serial \"$serial\" is already added for $itemName.");
      return;
    }

    final totalFilledQty = sumQty(filled);

    if (roundQty(totalFilledQty + qty + receivedQty) > expectedQty) {
      errorAlertBottom(
          title: "Exceeded Quantity",
          "Adding this serial would exceed the expected qty (${formatQty(expectedQty)}) for $itemName.");
      return;
    }

    filled.add({"serial": serial, "qty": qty, "expired_date": expiredDate});
    item['filled'] = filled;
    items[index] = item;
    items.refresh();
  }

  /// 🔹 Update a single filled entry (qty / expiry / batch serial) at [index]
  /// for the currently selected item, with the same over-fill protection.
  void updateFilledAt(int index,
      {required num qty, String? expiredDate, String? serial}) {
    final itemIndex = selectedIndex.value;
    if (itemIndex >= items.length) return;

    final item = items[itemIndex];
    final String itemName = item['name'] ?? '(unknown item)';
    final expectedQty = safeToNum(item['expected']);
    final receivedQty = safeToNum(item['received']);

    final filled = List<Map<String, dynamic>>.from(item['filled'] ?? []);
    if (index < 0 || index >= filled.length) return;

    // Sum every other entry so the edited value is validated against the rest.
    final othersTotal = sumQty([
      for (var i = 0; i < filled.length; i++)
        if (i != index) filled[i],
    ]);

    if (roundQty(othersTotal + qty + receivedQty) > expectedQty) {
      errorAlertBottom(
          title: "Exceeded Quantity",
          "Updating this would exceed the expected qty (${formatQty(expectedQty)}) for $itemName.");
      return;
    }

    final entry = <String, dynamic>{"qty": qty, "expired_date": expiredDate};
    // Preserve/replace the batch serial when editing a serial-managed entry.
    final existingSerial = filled[index]['serial'];
    if (serial != null) {
      entry["serial"] = serial;
    } else if (existingSerial != null) {
      entry["serial"] = existingSerial;
    }
    filled[index] = entry;
    item['filled'] = filled;
    items[itemIndex] = item;
    items.refresh();
  }

  /// 🔹 Remove a single filled entry at [index] for the current item.
  void removeFilledAt(int index) {
    final itemIndex = selectedIndex.value;
    if (itemIndex >= items.length) return;

    final item = items[itemIndex];
    final filled = List<Map<String, dynamic>>.from(item['filled'] ?? []);
    if (index < 0 || index >= filled.length) return;

    filled.removeAt(index);
    item['filled'] = filled;
    items[itemIndex] = item;
    items.refresh();
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
      // log('Edited code $oldCode → $newCode');
    }
  }

  void removeFilledCode(String code) {
    final index = selectedIndex.value;
    final item = items[index];
    item['filled']
        ?.removeWhere((e) => e['code']?.toString() == code.toString());
    items.refresh();
    // log('Removed code $code');
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
      infoAlertBottom(
          title: "Cleared", "Removed $clearedCount filled qty from $name");
    }
  }

  /// ✅ Go to the next item if available, else show success message
  void goToNextItem() {
    // Lines the backend would refuse are read-only — skip them.
    final nextIndex = nextOpenLine(items, selectedIndex.value);

    if (nextIndex != null) {
      selectedIndex.value = nextIndex;
    } else {
      closeRoute(true); // close fill page
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

  num get totalFilled => sumQty(getAllFilledUnified().values.expand((list) => list));

  void startReceivingItem() async {
    final po = currentOrder;
    final poNumber = po.poNumber;
    final Map<String, dynamic> payload = {
      "receive_number": receiveNumber.value,
      "po_id": po.id,
      "items": linesToSubmit(items, "filled"), // unfilled lines would be saved as qty 0
    };
    final data = await ApiExecutor.run(
      isLoading: isLoadingReceiving,
      task: () => provider.postPoLineToReceivedData(payload),
    );
    if (data == null) return;

    // Submitted to the server — drop the local in-progress draft. (On failure
    // the draft is intentionally kept so the worker can retry when back online.)
    await _drafts.remove(_draftScope);

    if (Get.isDialogOpen == true) closeRoute();
    successAlertBottom("Receiving process for $poNumber started successfully.");

    // The POST returns the created receive order; route straight into the
    // serial-confirmation pass so each unit can be scanned one-by-one.
    final ro = data['data'] as Map<String, dynamic>?;
    final roId = ro?['id'];
    final roCode = (ro?['code'] ?? '-').toString();

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (roId is int) {
        await Get.offAndToNamed(
          AppPages.receiveOrderConfirmPage,
          arguments: {'ro_id': roId, 'ro_code': roCode},
        );
      } else {
        // Defensive fallback: behave as before if the id is missing.
        if (Get.isRegistered<ReceiveOrderByPoController>()) {
          Get.delete<ReceiveOrderByPoController>(force: true);
        }
        await Get.offAndToNamed(AppPages.receiveOrderByPoPage);
      }
    });
  }

  void setReceiveNumber(String value) => receiveNumber.value = value;
}
