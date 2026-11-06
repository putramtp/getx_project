import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../global/submit_key.dart';

import '../../../data/models/outflow_request_line_item_model.dart';
import '../../../global/accent.dart';
import '../../../global/functions.dart';
import '../../../global/alert.dart';
import '../../../routes/app_pages.dart';
import '../outflow_submit.dart';
import 'outflow_order_by_customer_controller.dart';
import 'outflow_order_by_customer_detail_controller.dart';

/// By Work Order Item Summary: one work order's reserved material, issued to
/// production through `issue-by-work-order` (a JC outflow order — no delivery).
/// `currentOrCustomer` holds the work order (same row shape as a customer).
class OutflowOrderByWorkOrderDetailController extends OutflowOrderByCustomerDetailController {
  @override
  String get draftScope => 'outflow_wo_${currentOrCustomer.id}';
  @override
  String get targetLabel => 'Work Order';
  @override
  IconData get targetIcon => Icons.precision_manufacturing_rounded;
  @override
  AppAccent get accent => AppAccent.sage;
  @override
  Future<List<OutflowRequestLineItemModel>> fetchLines() =>
      provider.getOutflowRequestLineItemByWorkOrder(currentOrCustomer.id);

  @override
  Future<void> startOutflowingItem() async {
    final page = topRoute(); // see submitPageStillOpen
    final workOrder = currentOrCustomer;
    final data = await submitOutflowData(
      provider.issueByWorkOrder,
      workOrderIssuePayload(workOrder.id, items),
      isLoading: isLoadingOutflowing,
      submitKey: SubmitKey(drafts, draftScope, onAlreadySaved: () {
          dropAllEntries(items, 'scanned');
          loadOrByCustomerItems();
        }),
    );
    if (data == null) return;

    // Submitted to the server — drop the local in-progress draft.
    await drafts.remove(draftScope);
    // The entries on screen are booked now: kept, a second Continue (after a
    // failed delivery create, or from a page left open) would book them again.
    dropAllEntries(items, 'scanned');
    successAlertBottom("Material issued to ${workOrder.customerCode}.");

    await Future.delayed(const Duration(milliseconds: 300));
    // The worker left the page while it was sending: the document is saved
    // (snackbar above); don't navigate from whatever screen is on top now.
    if (!submitPageStillOpen(page)) return;
    // The work-order list runs under the By Customer controller type.
    returnToListAfterSubmit(AppPages.outflowOrderByWorkOrderPage, menuRoute: AppPages.outflowHomePage,
        refresh: () => Get.find<OutflowOrderByCustomerController>().loadCustomers());
  }
}
