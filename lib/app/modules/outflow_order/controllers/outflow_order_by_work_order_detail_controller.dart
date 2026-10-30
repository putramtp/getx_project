import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/outflow_request_line_item_model.dart';
import '../../../global/accent.dart';
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
    final workOrder = currentOrCustomer;
    final data = await submitOutflowData(
      provider.issueByWorkOrder,
      workOrderIssuePayload(workOrder.id, items),
      isLoading: isLoadingOutflowing,
    );
    if (data == null) return;

    // Submitted to the server — drop the local in-progress draft.
    await drafts.remove(draftScope);
    successAlertBottom("Material issued to ${workOrder.customerCode}.");

    await Future.delayed(const Duration(milliseconds: 300));
    if (Get.isRegistered<OutflowOrderByCustomerController>()) {
      Get.delete<OutflowOrderByCustomerController>(force: true);
    }
    Get.offAndToNamed(AppPages.outflowOrderByWorkOrderPage);
  }
}
