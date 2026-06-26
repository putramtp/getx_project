import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';

import '../controllers/outflow_order_by_request_detail_controller.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_fill_widgets.dart';

class ScanPageByRequest extends GetView<OutflowOrderByRequestDetailController> {
  const ScanPageByRequest({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Scan Item", size,
          showIcon: false, hex1: "#6B5FB5", hex2: "#9B8FD5"),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size * 1.6),
          child: Obx(() {
            final index = controller.selectedIndex.value;
            if (controller.items.isEmpty || index >= controller.items.length) {
              return textLoading(size);
            }

            final item = controller.items[index];
            final int expected = (item["expected"] ?? 0) as int;
            final int received = (item["received"] ?? 0) as int;
            final List<Map<String, dynamic>> scanned =
                List<Map<String, dynamic>>.from(item["scanned"] ?? []);

            final int scannedQty = scanned.fold<int>(0, (sum, e) {
              final qtyValue = e['qty'];
              final parsedQty =
                  qtyValue is int ? qtyValue : int.tryParse('$qtyValue') ?? 0;
              return sum + parsedQty;
            });

            final int remaining = expected - (received + scannedQty);

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
              child: Column(
                key: ValueKey(item['id']),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  orderFillHeaderCard(
                      size: size, name: item["name"].toString(), accent: mutedPurple),
                  SizedBox(height: size * 1.4),
                  orderFillStatsCard(size: size, stats: [
                    FillStat("Expected", "$expected", Colors.grey.shade700),
                    FillStat("Received", "$received", skyBlue),
                    FillStat("Scanned", "$scannedQty", sageTeal),
                    FillStat("Remaining", "$remaining",
                        remaining <= 0 ? Colors.grey : Colors.red),
                  ]),
                  SizedBox(height: size * 2),
                  Text("Scanned Results", style: AppTextStyle.h5(size)),
                  SizedBox(height: size * 0.8),
                  Expanded(child: _buildScannedList(size, scanned, context)),
                ],
              ),
            );
          }),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(() {
        final index = controller.selectedIndex.value;
        final manageSn = index < controller.items.length &&
            controller.items[index]['manage_sn'] == true;
        return orderScanFab(
          size: size,
          color: mutedPurple,
          icon: manageSn ? Icons.qr_code_scanner : Icons.edit_note_rounded,
          onPressed: _onScanTap,
        );
      }),
      bottomNavigationBar: _buildBottomBar(size),
    );
  }

  /// Serial-tracked (manage_sn) items scan the serial leaving stock; everything
  /// else is quantity-only (the backend deducts by qty, no serial needed).
  Future<void> _onScanTap() async {
    final index = controller.selectedIndex.value;
    if (index >= controller.items.length) return;
    final item = controller.items[index];
    final manageSn = item['manage_sn'] == true;
    final serialType = item['serialNumberType'];

    if (!manageSn) {
      final result = await _showOtherItemDialog();
      if (result != null && result['qty'] != null && result['qty'] > 0) {
        controller.setScannedQty(result['qty']);
      }
      return;
    }

    final barcode = await captureSerialInput(accent: mutedPurple);
    if (barcode == null) return;

    if (serialType == 'BATCH') {
      final qty = await _showBatchQtyDialog();
      if (qty != null && qty > 0) {
        controller.addScannedCode(barcode, batchQty: qty);
      }
    } else if (serialType == 'OTHER') {
      final result = await _showOtherItemDialog();
      if (result != null) {
        controller.addScannedCode(barcode, batchQty: result['qty']);
      }
    } else {
      controller.addScannedCode(barcode);
    }
  }

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

  Future<Map<String, dynamic>?> _showOtherItemDialog({int? initialQty}) async {
    final TextEditingController qtyController =
        TextEditingController(text: initialQty?.toString() ?? '');
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

  Widget _buildBottomBar(double size) {
    return Obx(() {
      final items = controller.items;
      final hasItems = items.isNotEmpty;
      final selectedIndex = controller.selectedIndex.value;

      final currentItem = hasItems && selectedIndex < items.length
          ? items[selectedIndex]
          : null;

      final List<Map<String, dynamic>> scanned = currentItem != null
          ? List<Map<String, dynamic>>.from(currentItem["scanned"] ?? [])
          : [];

      final bool hasScannedCurrent = scanned.isNotEmpty;
      final bool hasAnyScanned = controller.totalScanned > 0;

      return orderFillBottomBar(
        size: size,
        clearEnabled: hasItems && hasScannedCurrent,
        onClear: controller.clearScannedCodes,
        continueEnabled: hasAnyScanned,
        onContinue: controller.goToNextItem,
        accent: mutedPurple,
      );
    });
  }

  Widget _buildScannedList(
    double size,
    List<Map<String, dynamic>> scanned,
    BuildContext context,
  ) {
    if (scanned.isEmpty) {
      return orderFillEmptyState(
        size: size,
        icon: Icons.qr_code_2_rounded,
        message: "No codes scanned yet",
      );
    }

    return orderFillResultsContainer(
      size: size,
      child: ListView.separated(
        padding: EdgeInsets.all(size * 1.2),
        itemCount: scanned.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final code = scanned[i]['code'];
          final qty = scanned[i]['qty'] ?? 1;
          final serialType = controller.items[controller.selectedIndex.value]
                  ['serialNumberType'] ??
              'OTHER';
          // Codeless entries are non serial-tracked (quantity-only) items.
          final bool isQtyOnly = code == null;
          final String title = isQtyOnly
              ? "Qty: $qty"
              : (serialType == 'UNIQUE' ? code : "$code (qty: $qty)");

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: mutedPurple.withOpacity(0.12),
              child: Icon(isQtyOnly ? Icons.tag_rounded : Icons.qr_code,
                  color: mutedPurple),
            ),
            title: Text(
              title,
              style: AppTextStyle.bodyBold(size).copyWith(fontSize: size * 1.4),
            ),
            onTap: () => _showRowActions(context, i, isQtyOnly, code, qty),
          );
        },
      ),
    );
  }

  Future<void> _showRowActions(BuildContext context, int i, bool isQtyOnly,
      String? code, dynamic qty) async {
    await Get.bottomSheet(
      SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blueAccent),
              title: Text(isQtyOnly ? "Edit Quantity" : "Edit Code"),
              onTap: () async {
                Get.back();
                if (isQtyOnly) {
                  final result = await _showOtherItemDialog(
                      initialQty: qty is int ? qty : int.tryParse('$qty'));
                  if (result != null &&
                      result['qty'] != null &&
                      result['qty'] > 0) {
                    controller.setScannedQty(result['qty']);
                  }
                } else {
                  final c = code!;
                  showEditCodeDialog(
                    context,
                    c,
                    onSave: (newCode) {
                      controller.editScannedCode(oldCode: c, newCode: newCode);
                    },
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text("Remove"),
              onTap: () {
                Get.back();
                if (isQtyOnly) {
                  controller.clearScannedCodes();
                } else {
                  final c = code!;
                  showRemoveDialog(
                      context, c, () => controller.removeScannedCode(c));
                }
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}
