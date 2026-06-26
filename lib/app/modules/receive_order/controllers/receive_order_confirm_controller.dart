import 'package:get/get.dart';

import '../controllers/receive_order_by_po_controller.dart';
import '../controllers/receive_order_by_supplier_controller.dart';
import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/receive_confirm_serial_model.dart';
import '../../../data/providers/receive_order_provider.dart';
import '../../../routes/app_pages.dart';

/// Drives the "scan to confirm" pass that runs immediately after a receive
/// order is created. Only UNIQUE items carry per-unit serial labels, so only
/// those are grouped into the scan loop; BATCH/OTHER lines need no confirmation.
class ReceiveOrderConfirmController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();

  late final int roId;
  late final String roCode;

  /// Where to return when the confirm pass is finished. Defaults to the
  /// by-PO list; the by-supplier flow passes its own route in.
  String backRoute = AppPages.receiveOrderByPoPage;

  /// One entry per UNIQUE item: {item_id, item_name, serials: List<...>}.
  final groups = <Map<String, dynamic>>[].obs;
  final selectedIndex = 0.obs;
  final isLoading = false.obs;
  final isConfirming = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['ro_id'] != null) {
      roId = args['ro_id'] as int;
      roCode = (args['ro_code'] ?? '-').toString();
      backRoute = (args['back_route'] ?? AppPages.receiveOrderByPoPage).toString();
      loadSerials();
    } else {
      errorAlert("⚠️ Invalid or missing arguments for confirm screen: $args");
    }
  }

  Future<void> loadSerials() async {
    final data = await ApiExecutor.run<List<ReceiveConfirmSerialModel>>(
      isLoading: isLoading,
      task: () => provider.getReceiveOrderSerials(roId),
    );
    if (data == null) return;

    // Keep only UNIQUE serials and group them by item, preserving order.
    final Map<int, Map<String, dynamic>> byItem = {};
    for (final serial in data.where((s) => s.serialNumberType == 'UNIQUE')) {
      final group = byItem.putIfAbsent(
        serial.itemId,
        () => {
          'item_id': serial.itemId,
          'item_name': serial.itemName,
          'serials': <ReceiveConfirmSerialModel>[],
        },
      );
      (group['serials'] as List<ReceiveConfirmSerialModel>).add(serial);
    }

    groups.assignAll(byItem.values.toList());
    selectedIndex.value = 0;
  }

  List<ReceiveConfirmSerialModel> serialsOf(Map<String, dynamic> group) =>
      List<ReceiveConfirmSerialModel>.from(group['serials'] ?? []);

  int confirmedIn(Map<String, dynamic> group) =>
      serialsOf(group).where((s) => s.isScanned).length;

  /// Total serials across every UNIQUE item.
  int get totalSerials =>
      groups.fold<int>(0, (sum, g) => sum + serialsOf(g).length);

  /// Total confirmed across every UNIQUE item.
  int get totalConfirmed =>
      groups.fold<int>(0, (sum, g) => sum + confirmedIn(g));

  bool get allConfirmed =>
      groups.isNotEmpty && totalConfirmed >= totalSerials;

  /// Handle a scanned barcode against the currently selected item.
  Future<void> confirmScan(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || groups.isEmpty) return;

    final index = selectedIndex.value;
    if (index >= groups.length) return;
    final group = groups[index];
    final serials = serialsOf(group);

    final match = serials.firstWhereOrNull(
      (s) => s.internalCode == code || s.serialNumber == code,
    );

    if (match == null) {
      // Help the worker if the label actually belongs to another item.
      final otherGroup = groups.firstWhereOrNull((g) => g != group &&
          serialsOf(g).any(
              (s) => s.internalCode == code || s.serialNumber == code));
      if (otherGroup != null) {
        warningAlertBottom(
          title: "Wrong Item",
          "This label belongs to ${otherGroup['item_name']}. Switch to that item first.",
        );
      } else {
        warningAlertBottom(
          title: "Unknown Label",
          "Code \"$code\" is not part of this receive order.",
        );
      }
      return;
    }

    if (match.isScanned) {
      infoAlertBottom(title: "Already Confirmed", "\"$code\" is already confirmed.");
      return;
    }

    final res = await ApiExecutor.run<Map<String, dynamic>>(
      isLoading: isConfirming,
      task: () => provider.confirmReceiveSerial(roId, [code]),
    );
    if (res == null) return;

    final confirmed =
        List<String>.from(res['data']?['confirmed'] ?? const []);
    final already =
        List<String>.from(res['data']?['already_scanned'] ?? const []);

    if (confirmed.contains(code) || already.contains(code)) {
      match.isScanned = true;
      groups.refresh();
      if (confirmedIn(group) >= serials.length) {
        successAlertBottom("${group['item_name']} fully confirmed.");
      }
    } else {
      warningAlertBottom(
        title: "Not Confirmed",
        "Server did not accept \"$code\".",
      );
    }
  }

  /// Advance to the next UNIQUE item, or finish when on the last one.
  void goToNextItem() {
    final next = selectedIndex.value + 1;
    if (next < groups.length) {
      selectedIndex.value = next;
    } else {
      finish();
    }
  }

  /// Leave the confirm flow and return to whichever list opened it, with a
  /// fresh controller so the just-received order reflects its new state.
  void finish() {
    if (Get.isRegistered<ReceiveOrderByPoController>()) {
      Get.delete<ReceiveOrderByPoController>(force: true);
    }
    if (Get.isRegistered<ReceiveOrderBySupplierController>()) {
      Get.delete<ReceiveOrderBySupplierController>(force: true);
    }
    Get.offAndToNamed(backRoute);
  }
}
