import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/receive_order_by_supplier_detail_controller.dart';
import '../views/receive_order_fill_by_supplier_view.dart';
import '../../../global/alert.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderBySupplierDetailView extends GetView<ReceiveOrderBySupplierDetailController> {
  const ReceiveOrderBySupplierDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: appBarOrder("Item Summary",size,routeBackName:AppPages.receiveOrderBySupplierPage,color1:sageTeal,color2:sageTealLight),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderGradient(size),
            const SizedBox(height: 16),
            Expanded(child: Obx(() {
              if (controller.isLoading.value) {
                return skeletonSummaryList(size, accent: sageTeal);
              }

              if (controller.items.isEmpty) {
                return textNoData(size,message: "No items found.");
              }

              return ListView.separated(
                itemCount: controller.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                    actionColor: sageTeal,
                    onAction: () {
                      controller.selectedIndex.value = index;
                      controller.selectedItem.value = item;
                      Get.to(() => const ReceiveOrderFillBySupplierView());
                    },
                  );
                },
              );
            })),
            const SizedBox(height: 16),
            _buildContinueButton(),
          ],
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
        return FilledButton.icon(
          icon: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.receipt_long_rounded),
          label: Text(isLoading
              ? "Processing..."
              : "Continue to receiving items ($totalFilled filled)"),
          onPressed: isLoading ? null  :() async {
            if (controller.items.isEmpty) return;
            // Use the unified filled data
            final allFilledUnified = controller.getAllFilledUnified();
            final totalFilled = controller.totalFilled;

            if (totalFilled == 0) {
              warningAlertBottom(
                title:"No Items Filled",
                "Please fill at least one item before continuing.",
              );
              return;
            }

            // ✅ Make sure only one dialog opens at a time
            String? receiveNumber = controller.receiveNumber.value;
            if (receiveNumber.isEmpty) {
              receiveNumber = await _showReceiveNumberDialog();
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
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFF31694E)
          ),
        );
      }),
    );
  }

  Widget _buildConfirmDialog(
    Map<dynamic, List<Map<String, dynamic>>> allFilled,
    int totalFilled,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.teal,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () async {
                  final newNumber = await _showReceiveNumberDialog(
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
                      style: AppTextStyle.custom(SizeConfig.defaultSize,
                          px: 20, weight: FontWeight.bold, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    Obx(() => Text(
                          '#${controller.receiveNumber.value}?',
                          style: AppTextStyle.custom(SizeConfig.defaultSize,
                              px: 20,
                              weight: FontWeight.bold,
                              color: Colors.blue),
                          textAlign: TextAlign.center,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Total receiving quantity: $totalFilled',
                style: AppTextStyle.custom(SizeConfig.defaultSize,
                    px: 16, weight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // 🔹 Loop through each item and show filled  + total qty
              ...controller.items.map((item) {
                final lineId = item['line_id'];
                final name = item['name'] ?? 'Unnamed';
                final serialNumberType = item['serialNumberType'] ?? 'other';
                final filledList = allFilled[lineId] ?? [];

                // Calculate total qty for this item
                final itemQty = filledList.fold<int>(
                  0,
                  (sum, entry) =>
                      sum +
                      (entry['qty'] is int
                          ? entry['qty'] as int
                          : int.tryParse('${entry['qty']}') ?? 0),
                );

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_rounded,
                              size: 20, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: AppTextStyle.custom(SizeConfig.defaultSize,
                                  px: 15,
                                  weight: FontWeight.w600,
                                  color: Colors.black87),
                            ),
                          ),
                          serialNumberType == 'BATCH'
                              ? Text(
                                  'Total: $itemQty',
                                  style: AppTextStyle.plain(
                                      weight: FontWeight.w500,
                                      color: Colors.black54),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (filledList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: filledList.map((entry) {
                              final qty = entry['qty'];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.list_rounded,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "Filled: $qty",
                                        style: AppTextStyle.custom(
                                            SizeConfig.defaultSize,
                                            px: 13,
                                            color: Colors.black54),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Text(
                            "No filled quantities yet.",
                            style: AppTextStyle.custom(SizeConfig.defaultSize,
                                    px: 13, color: Colors.black45)
                                .copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      onPressed: () => Get.back(result: true),
                      child: Text(
                        'Continue',
                        style: AppTextStyle.plain(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showReceiveNumberDialog({String? initialValue}) async {
    final TextEditingController textController =
        TextEditingController(text: initialValue ?? '');

    final result = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Receive Number'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Enter receive number',
            prefixIcon: Icon(Icons.confirmation_number),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = textController.text.trim();
              Get.back(result: val);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    textController.dispose();
    return result;
  }

  Widget _buildHeaderGradient(double size) {
    return orderDetailHeader(
      size: size,
      label: "Supplier / Vendor",
      code: controller.currentSupplier.name,
      icon: Icons.store_rounded,
      gradientColors: const [sageTeal, sageGreen],
    );
  }
}
