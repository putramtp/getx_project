import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';
import 'package:getx_project/app/modules/outflow_order/controllers/outflow_order_by_customer_detail_controller.dart';

class ScanPageByCustomer extends GetView<OutflowOrderByCustomerDetailController> {
  const ScanPageByCustomer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;

    return Scaffold(
      appBar: appBarOrder("Scan Item",showIcon: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final index = controller.selectedIndex.value;
            if (controller.items.isEmpty || index >= controller.items.length) {
              return const Center(child: CircularProgressIndicator());
            }

            final item = controller.items[index];
            final int expected = (item["expected"] ?? 0) as int;
            final int received = (item["received"] ?? 0) as int;
            final List<Map<String, dynamic>> scanned = List<Map<String, dynamic>>.from(item["scanned"] ?? []);

            final int scannedQty = scanned.fold<int>(
              0,
              (sum, e) {
                final qtyValue = e['qty'];
                final parsedQty =
                    qtyValue is int ? qtyValue : int.tryParse('$qtyValue') ?? 0;
                return sum + parsedQty;
              },
            );

            final int remaining = expected - (received + scannedQty);

            // AnimatedSwitcher keyed by item id -> animates when selectedIndex changes
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final inAnim = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: inAnim,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              // key must change when item changes
              child: Column(
                key: ValueKey(item['id']),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(theme, item),
                  const SizedBox(height: 12),
                  _buildQtyCard(theme, expected, received, scannedQty, remaining),
                  const SizedBox(height: 20),
                  Text("Scanned Results",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(child: _buildScannedList(theme, scanned, context)),
                ],
              ),
            );
          }),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: size * 8,
        height: size * 8,
        child: FloatingActionButton(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 5,
          shape: const CircleBorder(),
          child: Icon(Icons.qr_code_scanner, size: size * 4),
          onPressed: () async {
            final barcode = await FlutterBarcodeScanner.scanBarcode(
              "#ff6666",
              "Cancel",
              true,
              ScanMode.BARCODE,
            );
            if (barcode == "-1") return;

            final index = controller.selectedIndex.value;
            final item = controller.items[index];
            final serialType = item['serialNumberType'];
            log('serialType : $serialType');

            if (serialType == 'BATCH') {
              final qty = await _showBatchQtyDialog();
              if (qty != null && qty > 0) {
                controller.addScannedCode(barcode, batchQty: qty);
              }
            } else if (serialType == 'OTHER') {
              final result = await _showOtherItemDialog();
              if (result != null) {
                controller.addScannedCode(
                  barcode,
                  batchQty: result['qty'],
                );
                log('🔹 Added OTHER item: $barcode | ${result['qty']} ');
              }
            } else {
              controller.addScannedCode(barcode);
            }
          },
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme,controller),
    );
  }

  /// 🧮 Batch item qty input
  Future<int?> _showBatchQtyDialog() async {
    final TextEditingController qtyController = TextEditingController();

    return Get.dialog<int>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Batch Quantity'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter quantity for this batch',
            prefixIcon: Icon(Icons.numbers),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(qtyController.text);
              Get.back(result: val);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 🧩 Dialog for OTHER type item
  Future<Map<String, dynamic>?> _showOtherItemDialog() async {
    final TextEditingController qtyController = TextEditingController();

    return Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enter item quantity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text) ?? 1;
              Get.back(result: {'qty': qty});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ===== UI helpers =====

  Widget _buildBottomBar(ThemeData theme,controller) {
    return Obx(() {
      final items = controller.items;
      final hasItems = items.isNotEmpty;
      final selectedIndex = controller.selectedIndex.value;

      final currentItem = hasItems && selectedIndex < items.length
          ? items[selectedIndex]
          : null;

      // ✅ unified scanned format
      final List<Map<String, dynamic>> scanned = currentItem != null
          ? List<Map<String, dynamic>>.from(currentItem["scanned"] ?? [])
          : [];

      final bool hasScannedCurrent = scanned.isNotEmpty;

      // ✅ count all scanned qty from unified data
      final totalScanned = controller.totalScanned;
      final bool hasAnyScanned = totalScanned > 0;

      return Container(
        height: 60,
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            /// 🗑 Clear scanned codes for current item
            TextButton.icon(
              onPressed: hasItems && hasScannedCurrent
                  ? controller.clearScannedCodes
                  : null,
              icon: Icon(
                Icons.delete_forever,
                color: hasItems && hasScannedCurrent ? Colors.red : Colors.grey,
              ),
              label: Text(
                "Clear",
                style: TextStyle(
                  color:
                      hasItems && hasScannedCurrent ? Colors.red : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 56),

            TextButton.icon(
              onPressed: hasAnyScanned ? controller.goToNextItem : null,
              icon: Icon(
                Icons.save_rounded,
                color: hasAnyScanned ? Colors.blue : Colors.grey,
              ),
              label: Text(
                "Continue",
                style: TextStyle(
                  color: hasAnyScanned ? Colors.blueAccent : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHeaderCard(ThemeData theme, Map<String, dynamic> item) {
    return Card(
      color: Colors.brown[50],
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.inventory_2_rounded,
                color: theme.colorScheme.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item["name"].toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyCard(
    ThemeData theme,
    int expected,
    int received,
    int scannedQty,
    int remaining,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQtyInfo(
                "Expected", expected.toString(), Colors.grey.shade700),
            _buildQtyInfo("Received", received.toString(), Colors.blue),
            _buildQtyInfo("Scanned", scannedQty.toString(), Colors.green),
            _buildQtyInfo(
              "Remaining",
              remaining.toString(),
              remaining <= 0 ? Colors.grey : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  /// ✅ Modern scanned list
  Widget _buildScannedList(
    ThemeData theme,
    List<Map<String, dynamic>> scanned,
    BuildContext context,
  ) {
    if (scanned.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text("No codes scanned yet",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: scanned.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final code = scanned[i]['code'] ?? 'N/A';
                final qty = scanned[i]['qty'] ?? 1;
                final serialType =
                    controller.items[controller.selectedIndex.value]
                            ['serialNumberType'] ??
                        'OTHER';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child:
                        Icon(Icons.qr_code, color: theme.colorScheme.primary),
                  ),
                  // show qty only for batch items
                  title: Text(
                    serialType == 'UNIQUE' ? code : "$code (qty: $qty)",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    await Get.bottomSheet(
                      SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit,
                                  color: Colors.blueAccent),
                              title: const Text("Edit Code"),
                              onTap: () {
                                Get.back();
                                showEditCodeDialog(
                                  context,
                                  code,
                                  onSave: (newCode) {
                                    controller.editScannedCode(
                                      oldCode: code,
                                      newCode: newCode,
                                    );
                                  },
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              title: const Text("Remove Code"),
                              onTap: () {
                                Get.back();
                                showRemoveDialog(
                                  context,
                                  code,
                                  () => controller.removeScannedCode(code),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
