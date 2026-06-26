import 'package:get/get.dart';

import '../controllers/receive_order_by_supplier_controller.dart';
import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/purchase_order_supplier_model.dart';
import '../../../data/providers/receive_order_provider.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderBySupplierDetailController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();

  var items = <Map<String, dynamic>>[].obs;
  var selectedIndex = 0.obs;
  var selectedItem = Rxn<Map<String, dynamic>>();
  var filledResults = <String>[].obs;
  var isLoading = false.obs;
  var isLoadingReceiving = false.obs;
  late final PoSupplierModel currentSupplier;
  final receiveNumber = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is PoSupplierModel) {
      currentSupplier = args;
      loadPurchaseOrderItemBySupplier();
    } else {
      errorAlert("⚠️ Invalid or missing arguments in currentSupplier: $args");
    }
  }

  /// 🔹 Fetch items for this order
  Future<void> loadPurchaseOrderItemBySupplier() async {
    final orderId = currentSupplier.id;
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getPurchaseOrderItemBySupplier(orderId),
    );
    if (data == null) return;

    final normalizedData = data.map((item) {
      final filled = (item.filled != null && item.filled!.isNotEmpty)
          ? item.filled!
          : <String>[];
      return {
        "line_id": item.lineId,
        "name": item.name,
        "serialNumberType": item.serialNumberType,
        "manageExpired": item.manageExpired,
        "manage_sn": item.manageSn,
        "expected": item.expected,
        "received": item.received,
        "filled": filled,
      };
    }).toList();

    items.assignAll(normalizedData);
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
      warningAlertBottom(
          title: "Not Allowed", "Only one fill is allowed for $itemName.");
      return;
    }

    // 🔹 Over-fill protection
    if ((totalFilledQty + qtyToAdd + receivedQty) > expectedQty) {
      errorAlertBottom(
          title: "Exceeded Quantity",
          "Filling this item would exceed the expected qty ($expectedQty) for $itemName.");
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
  void addFilledSerial({required String serial, int qty = 1, String? expiredDate}) {
    final index = selectedIndex.value;
    if (index >= items.length) return;

    final item = items[index];
    final String itemName = item['name'] ?? '(unknown item)';
    final expectedQty = item['expected'] ?? 0;
    final receivedQty = item['received'] ?? 0;

    final filled = List<Map<String, dynamic>>.from(item['filled'] ?? []);

    // Reject duplicate batch serials.
    if (filled.any((e) => (e['serial']?.toString() ?? '') == serial)) {
      warningAlertBottom(
          title: "Duplicate Serial",
          "Serial \"$serial\" is already added for $itemName.");
      return;
    }

    final totalFilledQty = filled.fold<int>(0, (sum, e) {
      final q = e['qty'];
      return sum + (q is int ? q : int.tryParse('$q') ?? 0);
    });

    if (totalFilledQty + qty + receivedQty > expectedQty) {
      errorAlertBottom(
          title: "Exceeded Quantity",
          "Adding this serial would exceed the expected qty ($expectedQty) for $itemName.");
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
      {required int qty, String? expiredDate, String? serial}) {
    final itemIndex = selectedIndex.value;
    if (itemIndex >= items.length) return;

    final item = items[itemIndex];
    final String itemName = item['name'] ?? '(unknown item)';
    final expectedQty = item['expected'] ?? 0;
    final receivedQty = item['received'] ?? 0;

    final filled = List<Map<String, dynamic>>.from(item['filled'] ?? []);
    if (index < 0 || index >= filled.length) return;

    // Sum every other entry so the edited value is validated against the rest.
    final othersTotal = filled.asMap().entries
        .where((e) => e.key != index)
        .fold<int>(0, (sum, e) {
      final q = e.value['qty'];
      return sum + (q is int ? q : int.tryParse('$q') ?? 0);
    });

    if (othersTotal + qty + receivedQty > expectedQty) {
      errorAlertBottom(
          title: "Exceeded Quantity",
          "Updating this would exceed the expected qty ($expectedQty) for $itemName.");
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
      errorAlertBottom(
          title: "Cleared", "Removed $clearedCount filled qty from $name");
    }
  }

  /// ✅ Go to the next item if available, else show success message
  void goToNextItem() {
    final nextIndex = selectedIndex.value + 1;

    if (nextIndex < items.length) {
      selectedIndex.value = nextIndex;
      // final nextName = items[nextIndex]["name"] ?? "Next Item";
      // log("➡️ Moved to next item: $nextName");
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
    final supplier = currentSupplier;
    final supplierName = supplier.name;

    final Map<String, dynamic> payload = {
      "receive_number": receiveNumber.value,
      "supplier_id": supplier.id,
      "items": items.map((e) => e).toList(), // ensure list of maps
    };
    final data = await ApiExecutor.run(
      isLoading: isLoadingReceiving,
      task: () => provider.postPoLineToReceivedData(payload),
    );
    if (data == null) return;

    if (Get.isDialogOpen == true) Get.back();
    successAlertBottom("Receiving process for $supplierName started successfully.");

    // Route into the serial-confirmation pass for the created receive order.
    final ro = data['data'] as Map<String, dynamic>?;
    final roId = ro?['id'];
    final roCode = (ro?['code'] ?? '-').toString();

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (roId is int) {
        await Get.offAndToNamed(
          AppPages.receiveOrderConfirmPage,
          arguments: {
            'ro_id': roId,
            'ro_code': roCode,
            'back_route': AppPages.receiveOrderBySupplierPage,
          },
        );
      } else {
        if (Get.isRegistered<ReceiveOrderBySupplierController>()) {
          Get.delete<ReceiveOrderBySupplierController>(force: true);
        }
        await Get.offAndToNamed(AppPages.receiveOrderBySupplierPage);
      }
    });
  }

  void setReceiveNumber(String value) => receiveNumber.value = value;
}
