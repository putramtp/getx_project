import 'package:get/get.dart';

import '../controllers/receive_order_by_po_controller.dart';
import '../controllers/receive_order_by_supplier_controller.dart';
import '../controllers/receive_order_list_detail_controller.dart';
import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/receive_confirm_serial_model.dart';
import '../../../data/providers/receive_order_provider.dart';
import '../../../global/scan_feedback.dart';
import '../../../global/functions.dart';
import '../../../services/draft_service.dart';
import '../../../routes/app_pages.dart';

/// Drives the "scan to confirm" pass that runs immediately after a receive
/// order is created. Only `manage_sn` items carry printed SKU labels (one per
/// unit for UNIQUE, one per batch entry for BATCH), so only those are grouped
/// into the scan loop; quantity-only lines need no confirmation.
class ReceiveOrderConfirmController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();

  /// Local cache of confirmed serial codes, keyed per receive order. Protects
  /// in-progress confirmations from being lost if the app is closed or offline
  /// before the server state is re-fetched.
  final DraftService _drafts = Get.find<DraftService>();
  String get _draftScope => 'receive_confirm_$roId';

  late final int roId;
  late final String roCode;

  /// Where to return when the confirm pass is finished. Defaults to the
  /// by-PO list; the by-supplier flow passes its own route in.
  String backRoute = AppPages.receiveOrderByPoPage;

  /// One entry per manage_sn item: {item_id, item_name, serials: List<...>}.
  final groups = <Map<String, dynamic>>[].obs;
  final selectedIndex = 0.obs;
  final isLoading = false.obs;
  /// The last load failed: the view offers Retry instead of reading it as empty.
  final hasError = false.obs;
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
      hasError: hasError,
      task: () => provider.getReceiveOrderSerials(roId),
    );
    if (data == null) return;

    // Keep only labels of manage_sn items (UNIQUE: one per unit, BATCH: one per
    // batch entry) and group them by item, preserving order.
    final Map<int, Map<String, dynamic>> byItem = {};
    for (final serial in data.where((s) => s.manageSn)) {
      final group = byItem.putIfAbsent(
        serial.itemId,
        () => {
          'item_id': serial.itemId,
          'item_name': serial.itemName,
          'serial_number_type': serial.serialNumberType,
          'serials': <ReceiveConfirmSerialModel>[],
        },
      );
      (group['serials'] as List<ReceiveConfirmSerialModel>).add(serial);
    }

    groups.assignAll(byItem.values.toList());

    // Re-apply locally cached confirmations on top of the server state, so a
    // scan that was saved before an app close/offline gap still shows as done.
    final cached = await _cachedCodes();
    if (cached.isNotEmpty) {
      for (final group in groups) {
        for (final s in serialsOf(group)) {
          if (!s.isScanned &&
              (cached.contains(s.internalCode) ||
                  cached.contains(s.serialNumber))) {
            s.isScanned = true;
          }
        }
      }
      groups.refresh();
    }

    selectedIndex.value = 0;
  }

  /// Codes confirmed on this device for the current RO (local safety cache).
  Future<Set<String>> _cachedCodes() async {
    final raw = await _drafts.readJson(_draftScope);
    if (raw is! List) return <String>{};
    return raw.map((e) => e.toString()).toSet();
  }

  /// Persist a confirmed code locally (idempotent).
  Future<void> _cacheCode(String code) async {
    final codes = await _cachedCodes()
      ..add(code);
    await _drafts.saveJson(_draftScope, codes.toList());
  }

  List<ReceiveConfirmSerialModel> serialsOf(Map<String, dynamic> group) =>
      List<ReceiveConfirmSerialModel>.from(group['serials'] ?? []);

  int confirmedIn(Map<String, dynamic> group) =>
      serialsOf(group).where((s) => s.isScanned).length;

  /// Total labels across every manage_sn item.
  int get totalSerials =>
      groups.fold<int>(0, (sum, g) => sum + serialsOf(g).length);

  /// Total confirmed across every manage_sn item.
  int get totalConfirmed =>
      groups.fold<int>(0, (sum, g) => sum + confirmedIn(g));

  bool get allConfirmed =>
      groups.isNotEmpty && totalConfirmed >= totalSerials;

  /// Labels still waiting for a scan, across every manage_sn item.
  int get totalPending => totalSerials - totalConfirmed;

  /// True when this pass was reopened from the Receive Order detail (history)
  /// rather than entered straight after a receive submit.
  bool get openedFromDetail => backRoute == AppPages.receiveOrderListPage;

  /// Reload the Receive Order detail underneath, so its confirm progress and
  /// "Confirm Serials" button reflect the scans just made.
  void _reloadDetail() {
    if (Get.isRegistered<ReceiveOrderListDetailController>()) {
      Get.find<ReceiveOrderListDetailController>().loadReceiveOrderDetail();
    }
  }

  /// Confirm a scanned label in continuous batch mode: match [rawCode] against
  /// ANY label of this RO across every item (batch scanning isn't scoped to the
  /// selected tab), POST it, and return [ScanFeedback] for the scanner overlay
  /// instead of showing a snackbar. Persisted + idempotent server-side.
  Future<ScanFeedback> confirmAnyScan(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) return ScanFeedback.error("Empty code.");
    if (groups.isEmpty) return ScanFeedback.error("Nothing to confirm.");

    ReceiveConfirmSerialModel? match;
    for (final group in groups) {
      match = serialsOf(group).firstWhereOrNull(
        // The backend matches codes without case: a label typed in lower case is the same label.
        (s) => s.internalCode.toLowerCase() == code.toLowerCase() || s.serialNumber.toLowerCase() == code.toLowerCase(),
      );
      if (match != null) break;
    }

    if (match == null) {
      return ScanFeedback.unknown("\"$code\" is not part of this order.");
    }
    if (match.isScanned) {
      return ScanFeedback.duplicate("\"$code\" already confirmed.");
    }

    final res = await ApiExecutor.run<Map<String, dynamic>>(
      isLoading: isConfirming,
      task: () => provider.confirmReceiveSerial(roId, [code]),
    );
    // The reason (offline, refused, server error) is in ApiExecutor's message.
    if (res == null) return ScanFeedback.error("Not saved — see the message above, then scan it again.");

    final confirmed = List<String>.from(res['data']?['confirmed'] ?? const []);
    final already = List<String>.from(res['data']?['already_scanned'] ?? const []);

    final sent = match.internalCode.isNotEmpty ? match.internalCode : match.serialNumber;
    if ([...confirmed, ...already].any((c) => c.toLowerCase() == code.toLowerCase() || c == sent)) {
      match.isScanned = true;
      await _cacheCode(sent); // local safety copy — the label's own code, so a restore matches it
      groups.refresh();
      return ScanFeedback.ok("Confirmed $totalConfirmed/$totalSerials");
    }
    return ScanFeedback.error("Server did not accept \"$code\".");
  }

  /// Advance to the next manage_sn item, or finish when on the last one.
  void goToNextItem() {
    // Don't navigate while a scan is still being confirmed — wait for the save.
    if (isConfirming.value) return;
    final next = selectedIndex.value + 1;
    if (next < groups.length) {
      selectedIndex.value = next;
    } else {
      finish();
    }
  }

  /// AppBar back: pop to whatever opened this screen (the PO/Supplier list
  /// after a receive, or the Receive Order detail) and reload the lists, so the
  /// just-received order doesn't show stale progress. Blocked while a scan is
  /// still being saved, like the system back.
  void leave() {
    if (isConfirming.value) {
      warningAlertBottom(title: "Saving…", "Please wait — the last scan is still being confirmed.");
      return;
    }
    closeRoute();
    _reloadDetail();
    if (Get.isRegistered<ReceiveOrderByPoController>()) {
      Get.find<ReceiveOrderByPoController>().loadPurchaseOrders();
    }
    if (Get.isRegistered<ReceiveOrderBySupplierController>()) {
      Get.find<ReceiveOrderBySupplierController>().loadSuppliers();
    }
  }

  /// Leave the confirm flow. Reopened from the Receive Order detail, it pops
  /// back to that detail (pushing the list again would stack a second list on
  /// top of list → detail). After a receive submit it pops back to the list
  /// that opened it and reloads it, so the just-received order shows its new
  /// state (see returnToListAfterSubmit).
  void finish() {
    // Fully confirmed and persisted server-side — drop the local safety cache.
    if (allConfirmed) _drafts.remove(_draftScope);
    if (openedFromDetail) {
      closeRoute();
      _reloadDetail();
      return;
    }
    returnToListAfterSubmit(backRoute, menuRoute: AppPages.receiveHomePage, refresh: () {
      if (backRoute == AppPages.receiveOrderBySupplierPage) {
        Get.find<ReceiveOrderBySupplierController>().loadSuppliers();
      } else {
        Get.find<ReceiveOrderByPoController>().loadPurchaseOrders();
      }
    });
  }
}
