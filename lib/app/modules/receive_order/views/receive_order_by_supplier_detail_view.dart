import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/receive_order_by_supplier_detail_controller.dart';
import '../views/receive_order_fill_by_supplier_view.dart';
import '../../../global/accent.dart';
import '../../../global/widget/app_header.dart';
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

class ReceiveOrderBySupplierDetailView
    extends GetView<ReceiveOrderBySupplierDetailController> {
  const ReceiveOrderBySupplierDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: appHeader(
        'Item Summary',
        accent: AppAccent.sage,
        icon: Icons.list_alt_rounded,
        subtitle: 'By Supplier · ${controller.currentSupplier.name}',
      ),
      body: SafeArea(
        // Keep "Continue" above Android's 3-button navigation bar (edge-to-edge).
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeaderGradient(size),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return skeletonSummaryList(size, accent: sageTeal);
                  }

                  if (controller.items.isEmpty) {
                    return textNoData(size, message: "No items found.");
                  }

                  return ListView.separated(
                    itemCount: controller.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = controller.items[index];
                      final expected = safeToNum(item['expected']);
                      // Unified filled format: [{code, qty}]
                      final List<Map<String, dynamic>> filledList =
                          List<Map<String, dynamic>>.from(item['filled'] ?? []);

                      // Sum up total filled qty
                      final filledCount = sumQty(filledList);
                      final received = safeToNum(item['received']);
                      final bool isFinished = received >= expected;
                      final receivedAndFilled = roundQty(received + filledCount);

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
                      } else if (expected > 0 && receivedAndFilled >= expected) {
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
                            "Expected: ${formatQty(expected)} | Received: ${formatQty(received)} | receiving: ${formatQty(filledCount)}",
                        statusIcon: icon,
                        statusColor: bgColor,
                        blockedReason: blockedReason,
                        showAction: !isFinished,
                        actionLabel: "Fill",
                        actionIcon: Icons.edit_rounded,
                        actionColor: AppAccent.sage.text,
                        onAction: () {
                          controller.selectedIndex.value = index;
                          controller.selectedItem.value = item;
                          Get.to(() => const ReceiveOrderFillBySupplierView());
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
        final totalFilled = controller.totalFilled;
        final isLoading = controller.isLoadingReceiving.value;
        return navyButton(
          SizeConfig.defaultSize,
          isLoading
              ? "Processing..."
              : "Continue to receiving items (${formatQty(totalFilled)} filled)",
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
    num totalFilled,
  ) {
    final size = SizeConfig.defaultSize;
    return orderSubmitConfirmDialog(
      size: size,
      accent: AppAccent.sage,
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
                  color: AppAccent.sage.text,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      summary: 'Total receiving quantity: ${formatQty(totalFilled)}',
      lines: [
        for (final item in controller.items)
          if (allFilled[item['line_id']]?.isNotEmpty ?? false)
            SubmitConfirmLine(
              name: item['name'] ?? 'Unnamed',
              total: item['serialNumberType'] == 'BATCH'
                  ? sumQty(allFilled[item['line_id']]!)
                  : null,
              entries: [
                for (final e in allFilled[item['line_id']]!)
                  'Filled: ${formatQty(safeToNum(e['qty']))}',
              ],
            ),
      ],
    );
  }

  Widget _buildHeaderGradient(double size) {
    final supplier = controller.currentSupplier;
    return Obx(
      () => skeletonize(
        loading: controller.isLoading.value,
        child: orderSummaryHeader(
          size: size,
          accent: AppAccent.sage,
          icon: Icons.storefront_rounded,
          label: 'Supplier',
          title: supplier.name,
          code: supplier.code,
          badge: accentPill(size, supplier.status, accent: AppAccent.sage),
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
