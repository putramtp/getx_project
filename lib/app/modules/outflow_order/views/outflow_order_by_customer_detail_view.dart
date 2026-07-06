import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../modules/outflow_order/controllers/outflow_order_by_customer_detail_controller.dart';
import '../../../modules/outflow_order/views/scan_page_by_customer.dart';
import '../../../routes/app_pages.dart';

class OutflowOrderByCustomerDetailView extends GetView<OutflowOrderByCustomerDetailController> {
  const OutflowOrderByCustomerDetailView({super.key});

  // By-Customer flow accent (matches the header gradient + scan action).
  static const Color _accent = amber;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      appBar: appBarOrder("Item Summary", size,
          routeBackName: AppPages.outflowOrderByCustomerPage,
          color1: amber, color2: amberLight),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(size),
            const SizedBox(height: 16),
            Expanded(child: Obx(() {
              if (controller.isLoading.value) {
                return skeletonSummaryList(size, accent: amber);
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
                  // Unified scanned format: [{code, qty}]
                  final List<Map<String, dynamic>> scannedList =
                      List<Map<String, dynamic>>.from(item['scanned'] ?? []);

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
                  final bool isFinished = outflowed >= expected;
                  final outflowedAndScanned = outflowed + scannedCount;

                  // log("${item['name']} - ${item['serialNumberType']}");

                  IconData icon;
                  Color bgColor;

                  if (expected > 0 && outflowedAndScanned >= expected) {
                    icon = Icons.check_circle_rounded;
                    bgColor = Colors.green;
                  } else if (outflowedAndScanned > 0 &&
                      outflowedAndScanned < expected) {
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
                        "Expected: $expected | Outflowed: $outflowed | Outflowing: $scannedCount",
                    statusIcon: icon,
                    statusColor: bgColor,
                    showAction: !isFinished,
                    actionLabel: "Scan",
                    actionIcon: Icons.qr_code_scanner_rounded,
                    actionColor: amber,
                    onAction: () {
                      controller.selectedIndex.value = index;
                      controller.selectedItem.value = item;
                      Get.to(() => const ScanPageByCustomer());
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
        final totalScanned = controller.totalScanned;
        final isLoading = controller.isLoadingOutflowing.value;
        return FilledButton.icon(
          icon: const Icon(Icons.receipt_long_rounded),
          label: Text(isLoading
              ? "Processing..."
              : "Continue to outflowing items ($totalScanned scanned)"),
          onPressed: isLoading
              ? null
              : () async {
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
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }),
    );
  }

  Widget _buildConfirmDialog(
    Map<dynamic, List<Map<String, dynamic>>> allScanned,
    int totalScanned,
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
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: _accent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Continue to Outflowing Items?',
                style: AppTextStyle.custom(SizeConfig.defaultSize,
                    px: 20, weight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Total Outflowing quantity: $totalScanned',
                style: AppTextStyle.custom(SizeConfig.defaultSize,
                    px: 16, weight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // 🔹 Loop through each item and show scanned codes + total qty
              ...controller.items.map((item) {
                final id = item['line_id'];
                final name = item['name'] ?? 'Unnamed';
                final scannedList = allScanned[id] ?? [];

                // Calculate total qty for this item
                final itemQty = scannedList.fold<int>(
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
                          Text(
                            'Total: $itemQty',
                            style: AppTextStyle.plain(
                                weight: FontWeight.w500,
                                color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (scannedList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: scannedList.map((entry) {
                              final code = entry['code'];
                              final qty = entry['qty'];
                              final displayText =
                                  (qty == 1) ? code : "$code (qty: $qty)";
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.qr_code_2,size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        code != null
                                            ? displayText
                                            : "scanned: $qty",
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
                            "No scanned codes yet.",
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accent,
                        side: const BorderSide(color: _accent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Continue'),
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

  Widget _buildHeader(double size) {
    return orderDetailHeader(
      size: size,
      label: "Customer",
      code: controller.currentOrCustomer.name,
      icon: Icons.groups_rounded,
      gradientColors: [amber, Color.lerp(amber, Colors.white, 0.35)!],
    );
  }
}
