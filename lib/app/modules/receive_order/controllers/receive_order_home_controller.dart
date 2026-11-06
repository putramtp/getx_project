import 'package:get/get.dart';

import '../../../data/models/serial_confirm_summary_model.dart';
import '../../../global/functions.dart';
import '../../../data/providers/receive_order_provider.dart';
import '../../../routes/app_pages.dart';
import 'receive_order_list_controller.dart';

/// The Receive menu. Its only state is the "Serials to confirm" card: receive
/// orders that still hold unscanned labels, loaded on open and again whenever
/// the user comes back to the menu from any of its pages (a receive or a
/// confirm pass in between may have changed the count).
class ReceiveOrderHomeController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();

  /// Null until loaded (or when the call fails): the card stays hidden.
  final serialSummary = Rxn<SerialConfirmSummary>();
  bool _summaryLoading = false;

  @override
  void onInit() {
    super.onInit();
    loadSerialSummary();
  }

  /// Loaded silently, not through `ApiExecutor.run`: the card is an extra the
  /// user never asked for, so offline or an older backend without the endpoint
  /// just keeps it hidden instead of showing an error snackbar on every visit.
  Future<void> loadSerialSummary() async {
    if (_summaryLoading) return;
    _summaryLoading = true;
    try {
      serialSummary.value = await provider.getSerialConfirmSummary();
    } catch (_) {
      // Keep the last known value; the next return to the menu retries.
    } finally {
      _summaryLoading = false;
    }
  }

  /// Push a page from the menu and refresh the card once the user is back.
  Future<void> open(String route, {dynamic arguments}) async {
    if (route == AppPages.receiveOrderListPage) {
      // History and the pending queue are one route under one controller type:
      // opened right after leaving the other, the binding would reuse its
      // controller (the queue's filter in the history), then lose it when the
      // old route is disposed. openFresh waits for it to go.
      await openFresh<ReceiveOrderListController>(route, arguments: arguments);
    } else {
      await Get.toNamed(route, arguments: arguments);
    }
    await loadSerialSummary();
  }

  /// Open the receive orders waiting for serial confirmation.
  Future<void> openSerialQueue() =>
      open(AppPages.receiveOrderListPage, arguments: {'serial_status': 'pending'});
}
