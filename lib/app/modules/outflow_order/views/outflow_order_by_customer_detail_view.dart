import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/accent.dart';
import '../../../global/widget/app_header.dart';
import '../../../global/widget/app_buttons.dart';
import '../../../global/widget/accent_pill.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../modules/outflow_order/controllers/outflow_order_by_customer_detail_controller.dart';
import '../../../modules/outflow_order/views/scan_page_by_customer.dart';
import '../../../global/functions.dart';

class OutflowOrderByCustomerDetailView
    extends GetView<OutflowOrderByCustomerDetailController> {
  const OutflowOrderByCustomerDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: appHeader(
        'Item Summary',
        accent: AppAccent.amber,
        icon: Icons.list_alt_rounded,
        subtitle: 'By Customer · ${controller.currentOrCustomer.name}',
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
                    return skeletonSummaryList(size, accent: amber);
                  }

                  if (controller.items.isEmpty) {
                    return textNoData(size, message: "No items found.");
                  }

                  return ListView.separated(
                    itemCount: controller.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = controller.items[index];
                      final expected = item['expected'] ?? 0;
                      // Outflow is capped at the reserved qty, not the requested one.
                      final reserved = item['reserved'] ?? 0;
                      // Unified scanned format: [{code, qty}]
                      final List<Map<String, dynamic>> scannedList =
                          List<Map<String, dynamic>>.from(
                            item['scanned'] ?? [],
                          );

                      // Sum up total scanned qty
                      final scannedCount = scannedList.fold<int>(
                        0,
                        (sum, e) =>
                            sum +
                            ((e['qty'] is int)
                                ? e['qty'] as int
                                : int.tryParse('${e['qty']}') ?? 0),
                      );
                      final outflowed = item['received'] ?? 0;
                      final bool isFinished = outflowed >= reserved;
                      final outflowedAndScanned = outflowed + scannedCount;

                      // log("${item['name']} - ${item['serialNumberType']}");

                      IconData icon;
                      Color bgColor;

                      if (reserved > 0 && outflowedAndScanned >= reserved) {
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
                            "Reserved: $reserved/$expected | Outflowed: $outflowed | Outflowing: $scannedCount",
                        statusIcon: icon,
                        statusColor: bgColor,
                        showAction: !isFinished,
                        actionLabel: manageSn ? "Scan" : "Fill",
                        actionIcon: manageSn
                            ? Icons.qr_code_scanner_rounded
                            : Icons.edit_rounded,
                        actionColor: AppAccent.amber.text,
                        onAction: () {
                          controller.selectedIndex.value = index;
                          controller.selectedItem.value = item;
                          Get.to(() => const ScanPageByCustomer());
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
              : "Continue to outflowing items ($totalScanned scanned)",
          icon: Icons.receipt_long_rounded,
          loading: isLoading,
          onPressed: () async {
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
    int totalScanned,
  ) {
    final size = SizeConfig.defaultSize;
    return orderSubmitConfirmDialog(
      size: size,
      accent: AppAccent.amber,
      title: Text(
        'Continue to Outflowing Items?',
        style: AppTextStyle.custom(size, px: 20, weight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      summary: 'Total Outflowing quantity: $totalScanned',
      entryIcon: Icons.qr_code_2,
      lines: [
        for (final item in controller.items)
          if (allScanned[item['line_id']]?.isNotEmpty ?? false)
            SubmitConfirmLine(
              name: item['name'] ?? 'Unnamed',
              total: allScanned[item['line_id']]!.fold<int>(
                0,
                (sum, e) => sum + safeToInt(e['qty']),
              ),
              entries: [
                for (final e in allScanned[item['line_id']]!)
                  scannedEntryLabel(e),
              ],
            ),
      ],
    );
  }

  Widget _buildHeader(double size) {
    final customer = controller.currentOrCustomer;
    return Obx(
      () => skeletonize(
        loading: controller.isLoading.value,
        child: orderSummaryHeader(
          size: size,
          accent: AppAccent.amber,
          icon: Icons.groups_rounded,
          label: 'Customer',
          title: customer.name,
          code: customer.customerCode,
          badge: accentPill(size, customer.status, accent: AppAccent.amber),
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
