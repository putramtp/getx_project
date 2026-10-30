import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'scan_page_by_request.dart';
import '../controllers/outflow_order_by_request_detail_controller.dart';
import '../../../global/accent.dart';
import '../../../global/widget/app_header.dart';
import '../../../global/widget/accent_header_card.dart';
import '../../../global/widget/app_buttons.dart';
import '../../../global/widget/accent_pill.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../global/functions.dart';

class OutflowOrderByRequestDetailView
    extends GetView<OutflowOrderByRequestDetailController> {
  const OutflowOrderByRequestDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: appHeader(
        'Item Summary',
        accent: AppAccent.purple,
        icon: Icons.list_alt_rounded,
        subtitle: 'By Request · ${controller.currentOr.code}',
      ),
      body: SafeArea(
        // Keep "Continue" above Android's 3-button navigation bar (edge-to-edge).
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(size),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return skeletonSummaryList(size, accent: mutedPurple);
                  }

                  if (controller.items.isEmpty) {
                    return textNoData(size, message: "No items found.");
                  }

                  final issuable = controller.currentOr.hasCustomer;
                  return ListView.separated(
                    itemCount: controller.items.length + (issuable ? 0 : 1),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      // A work-order reservation is read-only here: say why first.
                      if (!issuable) {
                        if (index == 0) return _workOrderNotice(size);
                        index -= 1;
                      }
                      final item = controller.items[index];
                      final expected = safeToNum(item['expected']);
                      // Outflow is capped at the reserved qty, not the requested one.
                      final reserved = safeToNum(item['reserved']);
                      // Unified scanned format: [{code, qty}]
                      final List<Map<String, dynamic>> scannedList =
                          List<Map<String, dynamic>>.from(
                            item['scanned'] ?? [],
                          );

                      // Sum up total scanned qty
                      final scannedCount = sumQty(scannedList);
                      final outflowed = safeToNum(item['received']);
                      final bool isFinished = outflowed >= reserved;
                      final outflowedAndScanned = roundQty(outflowed + scannedCount);

                      // log("${item['name']} - ${item['serialNumberType']}");

                      // A line the backend would refuse stays read-only with its
                      // reason (a finished line needs no explanation).
                      final String? blockedReason =
                          isFinished ? null : item['blocked_reason'] as String?;

                      IconData icon;
                      Color bgColor;

                      if (blockedReason != null) {
                        icon = Icons.lock_rounded;
                        bgColor = Colors.grey;
                      } else if (reserved > 0 && outflowedAndScanned >= reserved) {
                        icon = Icons.check_circle_rounded;
                        bgColor = Colors.green;
                      } else if (outflowedAndScanned > 0 &&
                          outflowedAndScanned < reserved) {
                        icon = Icons.timelapse_rounded;
                        bgColor = Colors.orange;
                      } else {
                        icon = Icons.cancel_rounded;
                        bgColor = Colors.red;
                      }

                      // Serial-tracked (manage_sn) items scan a printed label;
                      // quantity-only items just fill a qty, so mirror receive's
                      // "Fill" action instead of showing a scanner.
                      final bool manageSn = item['manage_sn'] == true;

                      return orderItemSummaryTile(
                        size: size,
                        name: item['name'] ?? "Unnamed",
                        subtitle:
                            "Reserved: ${formatQty(reserved)}/${formatQty(expected)} | Outflowed: ${formatQty(outflowed)} | Outflowing: ${formatQty(scannedCount)}",
                        statusIcon: icon,
                        statusColor: bgColor,
                        blockedReason: blockedReason,
                        showAction: issuable && !isFinished,
                        actionLabel: manageSn ? "Scan" : "Fill",
                        actionIcon: manageSn
                            ? Icons.qr_code_scanner_rounded
                            : Icons.edit_rounded,
                        actionColor: AppAccent.purple.text,
                        onAction: () {
                          controller.selectedIndex.value = index;
                          controller.selectedItem.value = item;
                          Get.to(() => const ScanPageByRequest());
                        },
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        final totalScanned = controller.totalScanned;
        final isLoading = controller.isLoadingOutflowing.value;
        return navyButton(
          SizeConfig.defaultSize,
          isLoading
              ? "Processing..."
              : "Continue to outflowing items (${formatQty(totalScanned)} scanned)",
          icon: Icons.receipt_long_rounded,
          loading: isLoading,
          onPressed: !controller.currentOr.hasCustomer ? null : () async {
            if (controller.items.isEmpty) return;
            // Use the unified scanned data
            final allScannedUnified = controller.getAllScannedUnified();
            final totalScanned = controller.totalScanned;

            final confirm = await Get.dialog<bool>(
              _buildConfirmDialog(allScannedUnified, totalScanned),
            );
            if (confirm == true) {
              controller.startOutflowingItem();
            }
          },
        );
      }),
    );
  }

  Widget _buildConfirmDialog(
    Map<dynamic, List<Map<String, dynamic>>> allScanned,
    num totalScanned,
  ) {
    final size = SizeConfig.defaultSize;
    return orderSubmitConfirmDialog(
      size: size,
      accent: AppAccent.purple,
      title: Text(
        'Continue to Outflowing Items?',
        style: AppTextStyle.custom(size, px: 20, weight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      summary: 'Total Outflowing quantity: ${formatQty(totalScanned)}',
      entryIcon: Icons.qr_code_2,
      lines: [
        for (final item in controller.items)
          if (allScanned[item['line_id']]?.isNotEmpty ?? false)
            SubmitConfirmLine(
              name: item['name'] ?? 'Unnamed',
              total: sumQty(allScanned[item['line_id']]!),
              entries: [
                for (final e in allScanned[item['line_id']]!)
                  scannedEntryLabel(e),
              ],
            ),
      ],
    );
  }

  /// Shown above the lines of a reservation with no customer (work order /
  /// material requisition): the backend won't put it on a delivery order.
  Widget _workOrderNotice(double size) {
    return Container(
      key: const Key('outflowWorkOrderNotice'),
      padding: EdgeInsets.all(size * 1.4),
      decoration: BoxDecoration(
        color: AppAccent.purple.tint(0.08),
        borderRadius: BorderRadius.circular(size * 1.6),
        border: Border.all(color: AppAccent.purple.tint(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.engineering_rounded, color: AppAccent.purple.text, size: size * 2.4),
          SizedBox(width: size * 1.2),
          Expanded(
            child: Text(
              "This is a work order reservation, so it can't go on a delivery order. "
              "Issue it on the web with Issue by Work Order.",
              style: AppTextStyle.small(size, color: AppAccent.purple.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double size) {
    final request = controller.currentOr;
    return Obx(
      () => skeletonize(
        loading: controller.isLoading.value,
        child: orderSummaryHeader(
          size: size,
          accent: AppAccent.purple,
          icon: Icons.assignment_rounded,
          label: 'Outflow request',
          title: '#${request.code}',
          badge: accentPill(size, request.status, accent: AppAccent.purple),
          footer: headerFooterText([
            request.customer,
            getDateString(request.date),
          ]),
          footerIcon: Icons.groups_rounded,
          totals: lineTotals(
            controller.items,
            expectedKey: 'reserved',
            pendingKey: 'scanned',
          ),
          labels: ('Reserved', 'Outflowed', 'Outflowing'),
          doneVerb: 'outflowed',
        ),
      ),
    );
  }
}
