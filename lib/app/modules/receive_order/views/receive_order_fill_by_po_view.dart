import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';

import '../controllers/receive_order_by_po_detail_controller.dart';
import '../../../global/alert.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_fill_widgets.dart';
import '../../../global/widget/skeleton_widgets.dart';

class ReceiveOrderFillByPoView extends GetView<ReceiveOrderByPoDetailController> {
  const ReceiveOrderFillByPoView({super.key});

  static const Color _accent = skyBlue;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Fill Item", size,
          icon: Icons.edit_rounded, color1: skyBlue, color2: skyBlueLight),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size * 1.6),
          child: Obx(() {
            final index = controller.selectedIndex.value;
            if (controller.items.isEmpty || index >= controller.items.length) {
              return skeletonSummaryList(size, accent: _accent);
            }

            final item = controller.items[index];
            // Serial-managed BATCH items capture batch serials at fill; one
            // line can be split across serials (e.g. 5 = 2 + 3).
            final bool batchSerial = item['manage_sn'] == true &&
                item['serialNumberType'] == 'BATCH';
            final int expected = (item["expected"] ?? 0) as int;
            final int received = (item["received"] ?? 0) as int;
            final List<Map<String, dynamic>> filled =
                List<Map<String, dynamic>>.from(item["filled"] ?? []);

            final int filledQty = filled.fold<int>(0, (sum, e) {
              final qtyValue = e['qty'];
              final parsedQty =
                  qtyValue is int ? qtyValue : int.tryParse('$qtyValue') ?? 0;
              return sum + parsedQty;
            });

            final int remaining = expected - (received + filledQty);

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
                      size: size, name: item["name"].toString(), accent: _accent),
                  SizedBox(height: size * 1.4),
                  orderFillStatsCard(size: size, stats: [
                    FillStat("Expected", "$expected", Colors.grey.shade700),
                    FillStat("Received", "$received", skyBlue),
                    FillStat("Filled", "$filledQty", sageTeal),
                    FillStat("Remaining", "$remaining",
                        remaining <= 0 ? Colors.grey : Colors.red),
                  ]),
                  SizedBox(height: size * 2),
                  Text(batchSerial ? "Serials" : "Filled Results",
                      style: AppTextStyle.h5(size)),
                  SizedBox(height: size * 0.8),
                  Expanded(child: _buildFilledList(size, filled, batchSerial)),
                ],
              ),
            );
          }),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(() {
        final index = controller.selectedIndex.value;
        final batchSerial = index < controller.items.length &&
            controller.items[index]['manage_sn'] == true &&
            controller.items[index]['serialNumberType'] == 'BATCH';
        return orderScanFab(
          size: size,
          color: _accent,
          icon: batchSerial
              ? Icons.keyboard_rounded
              : Icons.edit_note_rounded,
          onPressed: _onFillTap,
        );
      }),
      bottomNavigationBar: _buildBottomBar(size),
    );
  }

  /// FAB handler. Serial-managed BATCH items scan a batch serial then enter its
  /// qty (a line can be split across serials, e.g. 5 = 2 + 3). Every other item
  /// is quantity-only — the backend generates those serials and the confirm
  /// pass verifies them.
  Future<void> _onFillTap() async {
    final index = controller.selectedIndex.value;
    if (index >= controller.items.length) return;
    final item = controller.items[index];
    final serialType = item['serialNumberType'];
    final manageExpired = item['manageExpired'] == true;
    final bool batchSerial = item['manage_sn'] == true && serialType == 'BATCH';

    if (batchSerial) {
      // Receive uses manual serial entry (no scanner — scanner is reserved for
      // confirm-serial and outflow).
      final barcode = await showManualSerialDialog(accent: _accent);
      if (barcode == null) return;
      final result = await _showItemQtyDialog(
          type: serialType, manageExpired: manageExpired);
      if (result != null && result['qty'] != null && result['qty'] > 0) {
        controller.addFilledSerial(
          serial: barcode,
          qty: result['qty'],
          expiredDate: result['expired_date'],
        );
      }
    } else {
      final result = await _showItemQtyDialog(
          type: serialType, manageExpired: manageExpired);
      if (result != null && result['qty'] != null && result['qty'] > 0) {
        controller.addFilledQty(
          batchQty: result['qty'],
          expiredDate: result['expired_date'],
        );
      }
    }
  }

  Future<String?> _pickExpiry() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _accent,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
  }

  Future<Map<String, dynamic>?> _showItemQtyDialog({
    String? type,
    bool? manageExpired,
    int? initialQty,
    String? initialExpired,
  }) async {
    final TextEditingController qtyController =
        TextEditingController(text: initialQty?.toString() ?? '');
    final TextEditingController expController =
        TextEditingController(text: initialExpired ?? '');

    final result = await Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          type == 'BATCH' ? 'Batch Quantity' : 'Enter item quantity',
          style: AppTextStyle.plain(weight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
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
              const SizedBox(height: 16),
              if (manageExpired == true) ...[
                GestureDetector(
                  onTap: () async {
                    FocusScope.of(Get.context!).unfocus();
                    final picked = await _pickExpiry();
                    if (picked != null) expController.text = picked;
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: expController,
                      decoration: const InputDecoration(
                        labelText: 'Expiration Date',
                        prefixIcon: Icon(Icons.date_range),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () {
              final qty = int.tryParse(qtyController.text);
              if (qty == null || qty <= 0) {
                errorAlertBottom(
                    title: "Invalid Input",
                    "Please enter a valid quantity greater than 0.");
                return;
              }
              if (manageExpired == true && expController.text.isEmpty) {
                errorAlertBottom(
                    title: "Missing Expiration Date",
                    "Please select an expiration date.");
                return;
              }
              Get.back(result: {
                'qty': qty,
                'expired_date': expController.text,
              });
            },
            child: Text('Save', style: AppTextStyle.plain(color: Colors.white)),
          ),
        ],
      ),
    );
    qtyController.dispose();
    expController.dispose();
    return result;
  }

  Widget _buildBottomBar(double size) {
    return Obx(() {
      final items = controller.items;
      final hasItems = items.isNotEmpty;
      final selectedIndex = controller.selectedIndex.value;

      final currentItem = hasItems && selectedIndex < items.length
          ? items[selectedIndex]
          : null;

      final List<Map<String, dynamic>> filled = currentItem != null
          ? List<Map<String, dynamic>>.from(currentItem["filled"] ?? [])
          : [];

      final bool hasFilledCurrent = filled.isNotEmpty;
      final bool hasAnyFilled = controller.totalFilled > 0;

      return orderFillBottomBar(
        size: size,
        clearEnabled: hasItems && hasFilledCurrent,
        onClear: controller.clearFilledCodes,
        continueEnabled: hasAnyFilled,
        onContinue: controller.goToNextItem,
        accent: _accent,
      );
    });
  }

  Widget _buildFilledList(
    double size,
    List<Map<String, dynamic>> filled,
    bool batchSerial,
  ) {
    if (filled.isEmpty) {
      return orderFillEmptyState(
        size: size,
        icon: batchSerial ? Icons.keyboard_rounded : Icons.inventory_outlined,
        message: batchSerial
            ? "No serials entered yet"
            : "No items have been filled yet",
      );
    }

    return orderFillResultsContainer(
      size: size,
      child: ListView.separated(
        padding: EdgeInsets.all(size * 1.2),
        itemCount: filled.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final serial = filled[i]['serial'];
          final qty = filled[i]['qty'] ?? 1;
          final expiredDate = filled[i]['expired_date'] ?? '';
          final bool isSerial = serial != null;
          final String titleText =
              isSerial ? "$serial  (qty: $qty)" : "$qty";

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _accent.withOpacity(0.12),
              child: Icon(
                  isSerial
                      ? Icons.qr_code_rounded
                      : Icons.assignment_turned_in_outlined,
                  color: _accent),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(titleText,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.bodyBold(size)
                          .copyWith(fontSize: size * 1.4)),
                ),
                if (expiredDate.isNotEmpty)
                  Text("Exp : $expiredDate",
                      style: AppTextStyle.small(size, color: Colors.red.shade400)),
              ],
            ),
            onTap: () => _showRowActions(i, isSerial, qty, expiredDate),
          );
        },
      ),
    );
  }

  Future<void> _showRowActions(
      int i, bool isSerial, dynamic qty, String expiredDate) async {
    await Get.bottomSheet(
      SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blueAccent),
              title: Text(isSerial ? "Edit Serial" : "Edit Quantity"),
              onTap: () async {
                Get.back();
                if (isSerial) {
                  final barcode = await showManualSerialDialog(accent: _accent);
                  if (barcode == null) return;
                  final result = await _showItemQtyDialog(
                    type: 'BATCH',
                    manageExpired:
                        controller.items[controller.selectedIndex.value]
                                ['manageExpired'] ==
                            true,
                    initialQty: qty is int ? qty : int.tryParse('$qty'),
                    initialExpired: expiredDate.isNotEmpty ? expiredDate : null,
                  );
                  if (result != null &&
                      result['qty'] != null &&
                      result['qty'] > 0) {
                    controller.updateFilledAt(
                      i,
                      qty: result['qty'],
                      expiredDate: result['expired_date'],
                      serial: barcode,
                    );
                  }
                  return;
                }
                final cur = controller.items[controller.selectedIndex.value];
                final result = await _showItemQtyDialog(
                  type: cur['serialNumberType'],
                  manageExpired: cur['manageExpired'],
                  initialQty: qty is int ? qty : int.tryParse('$qty'),
                  initialExpired: expiredDate.isNotEmpty ? expiredDate : null,
                );
                if (result != null &&
                    result['qty'] != null &&
                    result['qty'] > 0) {
                  controller.updateFilledAt(
                    i,
                    qty: result['qty'],
                    expiredDate: result['expired_date'],
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text("Remove"),
              onTap: () {
                Get.back();
                controller.removeFilledAt(i);
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
