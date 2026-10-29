import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/receive_order_by_po_detail_controller.dart';
import '../views/receive_order_fill_by_po_view.dart';
import '../../../global/accent.dart';
import '../../../global/widget/app_header.dart';
import '../../../global/widget/accent_header_card.dart';
import '../../../global/widget/app_buttons.dart';
import '../../../global/widget/accent_pill.dart';
import '../../../global/alert.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../global/widget/qty_input_dialogs.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../global/functions.dart';

class ReceiveOrderByPoDetailView
    extends GetView<ReceiveOrderByPoDetailController> {
  const ReceiveOrderByPoDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: appHeader(
        'Item Summary',
        accent: AppAccent.sky,
        icon: Icons.list_alt_rounded,
        subtitle: 'By PO · ${controller.currentOrder.poNumber}',
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
                    return skeletonSummaryList(size, accent: skyBlue);
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
                      // Unified filled format: [{code, qty}]
                      final List<Map<String, dynamic>> filledList =
                          List<Map<String, dynamic>>.from(item['filled'] ?? []);

                      // Sum up total filled qty
                      final filledCount = filledList.fold<int>(
                        0,
                        (sum, e) =>
                            sum +
                            ((e['qty'] is int)
                                ? e['qty'] as int
                                : int.tryParse('${e['qty']}') ?? 0),
                      );
                      final received = item['received'] ?? 0;
                      final bool isFinished = received >= expected;
                      final receivedAndFilled = received + filledCount;

                      // log("${item['name']} - ${item['serialNumberType']}");

                      IconData icon;
                      Color bgColor;

                      if (expected > 0 && receivedAndFilled >= expected) {
                        icon = Icons.check_circle_rounded;
                        bgColor = Colors.green;
                      } else if (receivedAndFilled > 0 &&
                          receivedAndFilled < expected) {
                        icon = Icons.timelapse_rounded;
                        bgColor = Colors.orange;
                      } else {
                        icon = Icons.cancel_rounded;
                        bgColor = Colors.red;
                      }

                      return orderItemSummaryTile(
                        size: size,
                        name: item['name'] ?? "Unnamed",
                        subtitle:
                            "Expected: $expected | Received: $received | receiving: $filledCount",
                        statusIcon: icon,
                        statusColor: bgColor,
                        showAction: !isFinished,
                        actionLabel: "Fill",
                        actionIcon: Icons.edit_rounded,
                        actionColor: AppAccent.sky.text,
                        onAction: () {
                          controller.selectedIndex.value = index;
                          controller.selectedItem.value = item;
                          Get.to(() => const ReceiveOrderFillByPoView());
                        },
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              _buildContinueButton(size),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(double size) {
    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        final totalFilled = controller.totalFilled;
        final isLoading = controller.isLoadingReceiving.value;
        return navyButton(
          SizeConfig.defaultSize,
          isLoading
              ? "Processing..."
              : "Continue to receiving items ($totalFilled filled)",
          icon: Icons.receipt_long_rounded,
          loading: isLoading,
          onPressed: () async {
            if (controller.items.isEmpty) return;
            // Use the unified filled data
            final allFilledUnified = controller.getAllFilledUnified();
            final totalFilled = controller.totalFilled;

            if (totalFilled == 0) {
              warningAlertBottom(
                title: "No Items Filled",
                "Please fill at least one item before continuing.",
              );
              return;
            }

            // ✅ Make sure only one dialog opens at a time
            String? receiveNumber = controller.receiveNumber.value;
            if (receiveNumber.isEmpty) {
              receiveNumber = await showReceiveNumberDialog();
              if (receiveNumber == null || receiveNumber.trim().isEmpty) {
                return; // user cancelled or input empty
              }
              controller.receiveNumber.value = receiveNumber.trim();
            }

            // ✅ Ensure previous dialog is fully closed before showing next
            await Future.delayed(const Duration(milliseconds: 200));

            final confirm = await Get.dialog<bool>(
              _buildConfirmDialog(allFilledUnified, totalFilled),
            );
            if (confirm == true) {
              controller.startReceivingItem();
            }
          },
        );
      }),
    );
  }

  Widget _buildConfirmDialog(
    Map<dynamic, List<Map<String, dynamic>>> allFilled,
    int totalFilled,
  ) {
    final size = SizeConfig.defaultSize;
    return orderSubmitConfirmDialog(
      size: size,
      accent: AppAccent.sky,
      // Tap the title to change the receive number before confirming.
      title: TextButton(
        onPressed: () async {
          final newNumber = await showReceiveNumberDialog(
            initialValue: controller.receiveNumber.value,
          );
          if (newNumber != null && newNumber.trim().isNotEmpty) {
            controller.receiveNumber.value = newNumber.trim();
          }
        },
        child: Column(
          children: [
            Text(
              'Continue to Receiving ',
              style: AppTextStyle.custom(
                size,
                px: 20,
                weight: FontWeight.bold,
                color: navyDark,
              ),
              textAlign: TextAlign.center,
            ),
            Obx(
              () => Text(
                '#${controller.receiveNumber.value}?',
                style: AppTextStyle.custom(
                  size,
                  px: 20,
                  weight: FontWeight.bold,
                  color: AppAccent.sky.text,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      summary: 'Total receiving quantity: $totalFilled',
      lines: [
        for (final item in controller.items)
          if (allFilled[item['line_id']]?.isNotEmpty ?? false)
            SubmitConfirmLine(
              name: item['name'] ?? 'Unnamed',
              total: item['serialNumberType'] == 'BATCH'
                  ? allFilled[item['line_id']]!.fold<int>(
                      0,
                      (sum, e) => sum + safeToInt(e['qty']),
                    )
                  : null,
              entries: [
                for (final e in allFilled[item['line_id']]!)
                  'Filled: ${e['qty']}',
              ],
            ),
      ],
    );
  }

  Widget _buildHeader(double size) {
    final po = controller.currentOrder;
    return Obx(
      () => skeletonize(
        loading: controller.isLoading.value,
        child: orderSummaryHeader(
          size: size,
          accent: AppAccent.sky,
          icon: Icons.request_page_rounded,
          label: 'Purchase order',
          title: '#${po.poNumber}',
          badge: accentPill(size, po.status, accent: AppAccent.sky),
          footer: headerFooterText([po.supplier, getDateString(po.date)]),
          footerIcon: Icons.storefront_rounded,
          totals: lineTotals(
            controller.items,
            expectedKey: 'expected',
            pendingKey: 'filled',
          ),
          labels: ('Expected', 'Received', 'Receiving now'),
          doneVerb: 'complete',
        ),
      ),
    );
  }
}
