import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';

import '../controllers/receive_order_confirm_controller.dart';
import '../../../data/models/receive_confirm_serial_model.dart';
import '../../../global/size_config.dart';
import '../../../global/widget/functions_widget.dart';

class ReceiveOrderConfirmView extends GetView<ReceiveOrderConfirmController> {
  const ReceiveOrderConfirmView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder(
        "Confirm Serials", size,
        icon: Icons.qr_code_scanner_rounded,
        routeBackName: controller.backRoute,
        hex1: "75a340", hex2: "B1C29E",
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            if (controller.isLoading.value) {
              return textLoading(size, message: "Loading serials...");
            }

            // No UNIQUE items => nothing to scan-confirm.
            if (controller.groups.isEmpty) {
              return _buildNothingToConfirm(size);
            }

            final index = controller.selectedIndex.value;
            if (index >= controller.groups.length) {
              return textLoading(size);
            }

            final group = controller.groups[index];
            final serials = controller.serialsOf(group);
            final confirmed = controller.confirmedIn(group);
            final total = serials.length;
            final remaining = total - confirmed;

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
                key: ValueKey(group['item_id']),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(size, group),
                  const SizedBox(height: 12),
                  _buildQtyCard(total, confirmed, remaining, size),
                  const SizedBox(height: 20),
                  Text("Serial Labels", style: AppTextStyle.h5(size)),
                  const SizedBox(height: 8),
                  Expanded(child: _buildSerialList(size, serials)),
                ],
              ),
            );
          }),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(() {
        // Hide the scanner when there is nothing left to confirm anywhere.
        if (controller.groups.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          width: size * 6,
          height: size * 6,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF658C58),
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
              await controller.confirmScan(barcode);
            },
          ),
        );
      }),
      bottomNavigationBar: _buildBottomBar(size),
    );
  }

  Widget _buildNothingToConfirm(double size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_rounded, size: 72, color: Colors.green.shade400),
          const SizedBox(height: 16),
          Text(
            "Nothing to confirm",
            style: AppTextStyle.h5(size),
          ),
          const SizedBox(height: 6),
          Text(
            "This receive order has no serial-tracked (UNIQUE) items.",
            textAlign: TextAlign.center,
            style: AppTextStyle.body(size, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF658C58),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: controller.finish,
            icon: const Icon(Icons.check_rounded),
            label: Text("Done", style: TextStyle(fontSize: size * 1.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double size) {
    return Obx(() {
      if (controller.groups.isEmpty) return const SizedBox.shrink();

      final isLast = controller.selectedIndex.value >= controller.groups.length - 1;
      final allDone = controller.allConfirmed;

      return Container(
        height: size * 4,
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 20),
            Row(
              children: [
                Icon(
                  allDone ? Icons.verified_rounded : Icons.fact_check_outlined,
                  color: allDone ? Colors.green : Colors.grey.shade600,
                  size: size * 2.4,
                ),
                const SizedBox(width: 8),
                Text(
                  "${controller.totalConfirmed} / ${controller.totalSerials} confirmed",
                  style: TextStyle(
                    fontSize: size * 1.5,
                    fontWeight: FontWeight.bold,
                    color: allDone ? Colors.green : Colors.black87,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: controller.goToNextItem,
              icon: Icon(
                isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                color: isLast ? Colors.green : Colors.blue,
                size: size * 2.6,
              ),
              label: Text(
                isLast ? "Finish" : "Next Item",
                style: TextStyle(
                  fontSize: size * 1.6,
                  color: isLast ? Colors.green : Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      );
    });
  }

  Widget _buildHeaderCard(double size, Map<String, dynamic> group) {
    return Card(
      color: Colors.green[50],
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_rounded,
                color: Colors.blueGrey, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("RO #${controller.roCode}",
                      style: AppTextStyle.body(size, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(group['item_name'].toString(),
                      style: AppTextStyle.h5(size)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyCard(int total, int confirmed, int remaining, double size) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQtyInfo("Total", total.toString(), Colors.grey.shade700, size),
            _buildQtyInfo("Confirmed", confirmed.toString(), Colors.green, size),
            _buildQtyInfo("Remaining", remaining.toString(),
                remaining <= 0 ? Colors.grey : Colors.red, size),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyInfo(String label, String value, Color color, double size) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: size * 1.6)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: size * 1.3, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildSerialList(double size, List<ReceiveConfirmSerialModel> serials) {
    if (serials.isEmpty) {
      return Center(
        child: Text("No serials for this item",
            style: AppTextStyle.body(size, color: Colors.grey)),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: serials.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final s = serials[i];
          final scanned = s.isScanned;
          return ListTile(
            leading: Icon(
              scanned
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: scanned ? Colors.green : Colors.grey.shade400,
              size: size * 3,
            ),
            title: Text(
              s.internalCode.isNotEmpty ? s.internalCode : s.serialNumber,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: scanned ? Colors.black87 : Colors.black54,
              ),
            ),
            subtitle: (scanned && s.scannedByName != null)
                ? Text("by ${s.scannedByName}",
                    style: TextStyle(
                        fontSize: size * 1.2, color: Colors.grey.shade600))
                : null,
            trailing: Text(
              scanned ? "Confirmed" : "Pending",
              style: TextStyle(
                fontSize: size * 1.3,
                fontWeight: FontWeight.w600,
                color: scanned ? Colors.green : Colors.orange,
              ),
            ),
          );
        },
      ),
    );
  }
}
