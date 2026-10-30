import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../global/accent.dart';
import '../../../global/widget/app_header.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';

import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_fill_widgets.dart';
import '../../../global/widget/qty_input_dialogs.dart';
import '../../../global/widget/scanner_page.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../controllers/outflow_order_by_customer_detail_controller.dart';
import '../../../global/functions.dart';

class ScanPageByCustomer
    extends GetView<OutflowOrderByCustomerDetailController> {
  const ScanPageByCustomer({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appHeader('Scan Item', accent: AppAccent.amber, icon: Icons.qr_code_scanner_rounded),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size * 1.6),
          child: Obx(() {
            final index = controller.selectedIndex.value;
            if (controller.items.isEmpty || index >= controller.items.length) {
              return skeletonSummaryList(size, accent: amber);
            }

            final item = controller.items[index];
            final reserved = safeToNum(item["reserved"]);
            final received = safeToNum(item["received"]);
            final List<Map<String, dynamic>> scanned =
                List<Map<String, dynamic>>.from(item["scanned"] ?? []);
            final scannedQty = sumQty(scanned);

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
                  orderFillItemHeader(
                    size,
                    accent: AppAccent.amber,
                    name: item["name"].toString(),
                    targetLabel: "Reserved",
                    target: reserved,
                    received: received,
                    doneLabel: "Scanned",
                    done: scannedQty,
                  ),
                  SizedBox(height: size * 2),
                  orderFillResultsTitle(size, "Scanned Results", count: scanned.length, accent: AppAccent.amber),
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
          color: amber,
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
      final result = await showOtherItemDialog();
      if (result != null && result['qty'] != null && result['qty'] > 0) {
        controller.setScannedQty(result['qty']);
      }
      return;
    }

    // UNIQUE: continuous batch scanning — one scan = one unit, camera stays open.
    if (serialType == 'UNIQUE') {
      await Get.to(() => ScannerPage(
            title: item['name']?.toString() ?? 'Scan Serial',
            accent: amber,
            onCode: (code) async => controller.scanUnique(code),
            onManualEntry: () => showManualSerialDialog(accent: amber),
          ));
      return;
    }

    // BATCH / OTHER: a single scan (or manual entry) then a quantity dialog.
    final barcode = await captureSerialInput(accent: amber);
    if (barcode == null) return;

    if (serialType == 'BATCH') {
      final qty = await showBatchQtyDialog();
      if (qty != null && qty > 0) {
        controller.addScannedCode(barcode, batchQty: qty);
      }
    } else if (serialType == 'OTHER') {
      final result = await showOtherItemDialog();
      if (result != null) {
        controller.addScannedCode(barcode, batchQty: result['qty']);
      }
    } else {
      controller.addScannedCode(barcode);
    }
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
        accent: amber,
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
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final code = scanned[i]['serial_number'];
          final qty = safeToNum(scanned[i]['qty'] ?? 1);
          final serialType = controller.items[controller.selectedIndex.value]
                  ['serialNumberType'] ??
              'OTHER';
          // Codeless entries are non serial-tracked (quantity-only) items.
          final bool isQtyOnly = code == null;
          final String title = isQtyOnly
              ? "Qty: ${formatQty(qty)}"
              : (serialType == 'UNIQUE' ? code : "$code (qty: ${formatQty(qty)})");

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: amber.withValues(alpha: 0.12),
              child: Icon(isQtyOnly ? Icons.tag_rounded : Icons.qr_code,
                  color: amber),
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
      String? code, num qty) async {
    await Get.bottomSheet(
      SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blueAccent),
              title: Text(isQtyOnly ? "Edit Quantity" : "Edit Code"),
              onTap: () async {
                closeRoute();
                if (isQtyOnly) {
                  final result = await showOtherItemDialog(
                      initialQty: qty);
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
                closeRoute();
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
