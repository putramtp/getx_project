import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';

import '../controllers/receive_order_confirm_controller.dart';
import '../../../data/models/receive_confirm_serial_model.dart';
import '../../../global/alert.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderConfirmView extends GetView<ReceiveOrderConfirmController> {
  const ReceiveOrderConfirmView({super.key});

  /// Match the accent of the flow that opened this screen: By-Supplier =
  /// sageTeal, By-PO (default) = skyBlue.
  bool get _isSupplier =>
      controller.backRoute == AppPages.receiveOrderBySupplierPage;
  Color get _accent => _isSupplier ? sageTeal : skyBlue;
  Color get _color1 => _isSupplier ? sageTeal : skyBlue;
  Color get _color2 => _isSupplier ? sageTealLight : skyBlueLight;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;

    // Block leaving the screen while a scan is still being saved, so a serial
    // can't be lost by navigating away mid-request.
    return Obx(() {
      final saving = controller.isConfirming.value;
      return WillPopScope(
        onWillPop: () async {
          if (saving) {
            warningAlertBottom(
                title: "Saving…",
                "Please wait — the last scan is still being confirmed.");
            return false;
          }
          return true;
        },
        child: _buildScaffold(size),
      );
    });
  }

  Widget _buildScaffold(double size) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder(
        "Confirm Serials", size,
        icon: Icons.qr_code_scanner_rounded,
        routeBackName: controller.backRoute,
        color1: _color1, color2: _color2,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            if (controller.isLoading.value) {
              return skeletonLineList(size, accent: _accent);
            }

            // No UNIQUE items => nothing to scan-confirm.
            if (controller.groups.isEmpty) {
              return _buildNothingToConfirm(size);
            }

            final index = controller.selectedIndex.value;
            if (index >= controller.groups.length) {
              return skeletonLineList(size, accent: _accent);
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
        // While a scan is saving, disable the button and show a spinner so a
        // second scan can't fire before the previous one is persisted.
        final saving = controller.isConfirming.value;
        return SizedBox(
          width: size * 6,
          height: size * 6,
          child: FloatingActionButton(
            backgroundColor: saving ? Colors.grey.shade400 : _accent,
            foregroundColor: Colors.white,
            elevation: 5,
            shape: const CircleBorder(),
            onPressed: saving
                ? null
                : () async {
                    final barcode = await FlutterBarcodeScanner.scanBarcode(
                      "#ff6666",
                      "Cancel",
                      true,
                      ScanMode.BARCODE,
                    );
                    if (barcode == "-1") return;
                    await controller.confirmScan(barcode);
                  },
            child: saving
                ? SizedBox(
                    width: size * 3,
                    height: size * 3,
                    child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.6),
                  )
                : Icon(Icons.qr_code_scanner, size: size * 4),
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
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: controller.finish,
            icon: const Icon(Icons.check_rounded),
            label: Text("Done", style: AppTextStyle.custom(size, scale: 1.6)),
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
      // Lock navigation while a scan is being saved.
      final saving = controller.isConfirming.value;

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
          children: [
            SizedBox(width: size * 1.6),
            // Counter — constrained so it ellipsizes instead of sliding under
            // the centre-docked scanner FAB.
            Expanded(
              child: Row(
                children: [
                  Icon(
                    allDone ? Icons.verified_rounded : Icons.fact_check_outlined,
                    color: allDone ? Colors.green : Colors.grey.shade600,
                    size: size * 2.4,
                  ),
                  SizedBox(width: size * 0.8),
                  Flexible(
                    child: Text(
                      "${controller.totalConfirmed} / ${controller.totalSerials} confirmed",
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.custom(size,
                          scale: 1.5,
                          weight: FontWeight.bold,
                          color: allDone ? Colors.green : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            // Clearance for the centre-docked FAB.
            SizedBox(width: size * 7),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: saving ? null : controller.goToNextItem,
                  icon: Icon(
                    isLast
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                    color: saving
                        ? Colors.grey
                        : (isLast ? Colors.green : _accent),
                    size: size * 2.6,
                  ),
                  label: Text(
                    isLast ? "Finish" : "Next Item",
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.custom(size,
                        scale: 1.6,
                        color: saving
                            ? Colors.grey
                            : (isLast ? Colors.green : _accent),
                        weight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            SizedBox(width: size * 0.6),
          ],
        ),
      );
    });
  }

  Widget _buildHeaderCard(double size, Map<String, dynamic> group) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 2),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_accent, _accent.withOpacity(0.78)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Soft decorative circle, like the other detail headers.
            Positioned(
              top: -size * 3,
              right: -size * 3,
              child: Container(
                width: size * 12,
                height: size * 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size * 1.8),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(size * 1.2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.qr_code_scanner_rounded,
                        color: Colors.white, size: size * 2.8),
                  ),
                  SizedBox(width: size * 1.6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                color: Colors.white70, size: size * 1.6),
                            SizedBox(width: size * 0.5),
                            Text("RO #${controller.roCode}",
                                style: AppTextStyle.body(size,
                                    color: Colors.white70)),
                          ],
                        ),
                        SizedBox(height: size * 0.4),
                        Text(group['item_name'].toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.h4(size, color: Colors.white)),
                      ],
                    ),
                  ),
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
            style: AppTextStyle.custom(size,
                scale: 1.6, weight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyle.custom(size,
                scale: 1.3, color: Colors.grey.shade600)),
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
              style: AppTextStyle.plain(
                weight: FontWeight.w600,
                color: scanned ? Colors.black87 : Colors.black54,
              ).copyWith(fontFamily: 'monospace'),
            ),
            subtitle: (scanned && s.scannedByName != null)
                ? Text("by ${s.scannedByName}",
                    style: AppTextStyle.custom(size,
                        scale: 1.2, color: Colors.grey.shade600))
                : null,
            trailing: Text(
              scanned ? "Confirmed" : "Pending",
              style: AppTextStyle.custom(size,
                  scale: 1.3,
                  weight: FontWeight.w600,
                  color: scanned ? Colors.green : Colors.orange),
            ),
          );
        },
      ),
    );
  }
}
