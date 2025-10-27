import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';
import 'package:getx_project/app/modules/outflow_order/controllers/outflow_order_detail_controller.dart';
import 'package:getx_project/app/modules/outflow_order/views/outflow_scan_page.dart';

class OutflowOrderDetailView extends GetView<OutflowOrderDetailController> {
  const OutflowOrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: appBarPO("Item Summary"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text("Loading items...",
                          style: TextStyle(fontSize: 16, color: Colors.black54))
                    ],
                  ),
                );
              }

              if (controller.items.isEmpty) {
                return const Center(
                    child: Text("No items found.",
                        style: TextStyle(fontSize: 16, color: Colors.black54)));
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
                  final received = item['received'] ?? 0;
                  final bool isFinished = received >= expected;
                  final receivedAndScanned = received + scannedCount;

                  // log("${item['name']} - ${item['serialNumberType']}");

                  IconData icon;
                  Color bgColor;

                  if (expected > 0 && receivedAndScanned >= expected) {
                    icon = Icons.check_circle_rounded;
                    bgColor = Colors.green;
                  } else if (receivedAndScanned > 0 &&
                      receivedAndScanned < expected) {
                    icon = Icons.timelapse_rounded;
                    bgColor = Colors.orange;
                  } else {
                    icon = Icons.cancel_rounded;
                    bgColor = Colors.red;
                  }

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(item['name'] ?? "Unnamed",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          "Expected: $expected | Received: $received | receiving: $scannedCount",
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[700])),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: bgColor.withOpacity(0.15),
                        child: Icon(icon, color: bgColor, size: 26),
                      ),
                      trailing: !isFinished
                          ? ElevatedButton.icon(
                              onPressed: () {
                                controller.selectedIndex.value = index;
                                controller.selectedItem.value = item;
                                Get.to(() => const ScanPage());
                              },
                              icon: const Icon(Icons.qr_code_scanner_rounded),
                              label: const Text("Scan"),
                            )
                          : null,
                    ),
                  );
                },
              );
            })),
            const SizedBox(height: 16),
            _buildContinueButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        final allScannedUnified = controller.getAllScannedUnified();
        final totalScanned = allScannedUnified.values.fold<int>(0, (sum, list) {
          return sum +
              list.fold<int>(
                0,
                (innerSum, e) =>
                    innerSum +
                    (e['qty'] is int
                        ? e['qty'] as int
                        : int.tryParse('${e['qty']}') ?? 0),
              );
        });

        return FilledButton.icon(
          icon: const Icon(Icons.receipt_long_rounded),
          label: Text("Continue to receiving items ($totalScanned scanned)"),
          onPressed: () async {
            if (controller.items.isEmpty) return;

            // Use the unified scanned data
            final allScannedUnified = controller.getAllScannedUnified();

            // Calculate totalScanned for display (sum all qty)
            final totalScanned =
                allScannedUnified.values.fold<int>(0, (sum, list) {
              return sum +
                  list.fold<int>(
                    0,
                    (innerSum, e) =>
                        innerSum +
                        (e['qty'] is int
                            ? e['qty'] as int
                            : int.tryParse('${e['qty']}') ?? 0),
                  );
            });

            final confirm = await Get.dialog<bool>(
              _buildConfirmDialog(allScannedUnified, totalScanned),
            );
            if (confirm == true) {
              // Log per item in unified format
              allScannedUnified.forEach((id, scannedList) {
                log('Item $id: $scannedList', name: 'OutflowOrder');
              });
              controller.startReceivingItem();
            }
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Continue to Receiving Items?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Total receiving quantity: $totalScanned',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // 🔹 Loop through each item and show scanned codes + total qty
              ...controller.items.map((item) {
                final id = item['id'];
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
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            'Total: $itemQty',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
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
                              final displayText = (qty == 1) ? code : "$code (qty: $qty)";
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.qr_code_2,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        code != null
                                            ? displayText
                                            : "filled: $qty",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(left: 4, top: 4),
                          child: Text(
                            "No scanned codes yet.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                              fontStyle: FontStyle.italic,
                            ),
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
                      onPressed: () => Get.back(result: true),
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

  Widget _buildHeader() {
    final po = controller.currentOrder;
    final poNumber = po.poNumber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF528FF3), Color(0xFF2163F0), Color(0xFF1B3B94)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Purchase Order",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text("#$poNumber",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }
}
