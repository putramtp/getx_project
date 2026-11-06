import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/accent.dart';
import '../../../global/widget/accent_header_card.dart';
import '../../../global/widget/accent_pill.dart';
import '../../../global/widget/app_header.dart';

import 'package:getx_project/app/global/styles/app_text_style.dart';

import '../controllers/receive_order_confirm_controller.dart';
import '../../../data/models/receive_confirm_serial_model.dart';
import '../../../global/alert.dart';
import '../../../global/functions.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_fill_widgets.dart';
import '../../../global/widget/scanner_page.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderConfirmView extends GetView<ReceiveOrderConfirmController> {
  const ReceiveOrderConfirmView({super.key});

  /// Match the accent of the flow that opened this screen: By-Supplier =
  /// sageTeal, By-PO (default) = skyBlue.
  bool get _isSupplier =>
      controller.backRoute == AppPages.receiveOrderBySupplierPage;
  AppAccent get _appAccent => _isSupplier ? AppAccent.sage : AppAccent.sky;
  Color get _accent => _appAccent.base;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;

    // Block leaving the screen while a scan is still being saved, so a serial
    // can't be lost by navigating away mid-request.
    return Obx(() {
      final saving = controller.isConfirming.value;
      return PopScope(
        canPop: !saving,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          warningAlertBottom(
            title: "Saving…",
            "Please wait — the last scan is still being confirmed.",
          );
        },
        child: _buildScaffold(size),
      );
    });
  }

  Widget _buildScaffold(double size) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appHeader(
        'Confirm Serials',
        accent: _appAccent,
        icon: Icons.fact_check_rounded,
        subtitle:
            '${controller.roCode} · ${controller.totalConfirmed} of ${controller.totalSerials} confirmed',
        onBack: controller.leave,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            if (controller.isLoading.value) {
              return skeletonLineList(size, accent: _accent);
            }
            // A failed reload keeps what is already on screen; Retry only replaces nothing.
            if (controller.hasError.value && controller.groups.isEmpty) {
              return errorRetry(size, onRetry: controller.loadSerials, accent: _accent);
            }

            // No manage_sn items => nothing to scan-confirm.
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
                  _buildHeaderCard(size, group, total, confirmed, remaining),
                  SizedBox(height: size * 2),
                  _buildSerialListTitle(size, remaining),
                  SizedBox(height: size),
                  // Flexible, not Expanded: a short list's white box hugs its
                  // rows instead of stretching empty down to the bottom bar.
                  Flexible(child: _buildSerialList(size, serials)),
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
            key: const Key('receiveConfirmScanFab'),
            backgroundColor: saving ? Colors.grey.shade300 : Colors.white,
            foregroundColor: _accent,
            elevation: 5,
            shape: const CircleBorder(
              side: BorderSide(color: navyDark, width: 3),
            ),
            onPressed: saving
                ? null
                : () {
                    // Continuous batch scanning: the camera stays open and each
                    // label is auto-matched + confirmed across all items.
                    Get.to(
                      () => ScannerPage(
                        title: "Confirm Serials",
                        accent: _accent,
                        onCode: controller.confirmAnyScan,
                        onManualEntry: () =>
                            showManualSerialDialog(accent: _accent),
                      ),
                    );
                  },
            child: saving
                ? SizedBox(
                    width: size * 3,
                    height: size * 3,
                    child: const CircularProgressIndicator(
                      color: navyDark,
                      strokeWidth: 2.6,
                    ),
                  )
                : Icon(Icons.qr_code_scanner, size: size * 4, color: _accent),
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
          Text("Nothing to confirm", style: AppTextStyle.h5(size)),
          const SizedBox(height: 6),
          Text(
            "This receive order has no serial-tracked items.",
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

      final isLast =
          controller.selectedIndex.value >= controller.groups.length - 1;
      final allDone = controller.allConfirmed;
      // Lock navigation while a scan is being saved.
      final saving = controller.isConfirming.value;

      // SafeArea: lift the bar above Android's 3-button navigation bar (edge-to-edge).
      return SafeArea(
        top: false,
        child: Container(
          height: size * 4,
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          decoration: BoxDecoration(
            gradient: navyGradient,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: navyDark.withValues(alpha: 0.25),
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
                      allDone
                          ? Icons.verified_rounded
                          : Icons.fact_check_outlined,
                      color: Colors.white.withValues(alpha: allDone ? 1 : 0.78),
                      size: size * 2.4,
                    ),
                    SizedBox(width: size * 0.8),
                    Flexible(
                      child: Text(
                        "${controller.totalConfirmed} / ${controller.totalSerials} confirmed",
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.custom(
                          size,
                          scale: 1.5,
                          weight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                    key: const Key('receiveConfirmNextButton'),
                    onPressed: saving ? null : () => _onNextOrFinish(size),
                    icon: Icon(
                      isLast
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white.withValues(alpha: saving ? 0.4 : 1),
                      size: size * 2.6,
                    ),
                    label: Text(
                      isLast ? "Finish" : "Next Item",
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.custom(
                        size,
                        scale: 1.6,
                        color: Colors.white.withValues(alpha: saving ? 0.4 : 1),
                        weight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: size * 0.6),
            ],
          ),
        ),
      );
    });
  }

  /// Next Item, or — on the last item — Finish. Finishing with labels still
  /// pending asks first: the scans made so far stay saved, and the pass can be
  /// resumed from the Receive Order detail.
  Future<void> _onNextOrFinish(double size) async {
    final isLast =
        controller.selectedIndex.value >= controller.groups.length - 1;
    final pending = controller.totalPending;
    if (isLast && pending > 0) {
      final ok = await _confirmFinishWithPending(size, pending);
      if (ok != true) return;
    }
    controller.goToNextItem();
  }

  Future<bool?> _confirmFinishWithPending(double size, int pending) {
    final labels = pending == 1 ? 'label is' : 'labels are';
    return Get.dialog<bool>(
      AlertDialog(
        key: const Key('receiveConfirmPendingDialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.pending_actions_rounded, color: amberDark, size: size * 4),
        title: Text("Finish with pending labels?", style: AppTextStyle.h5(size)),
        content: Text(
          "$pending $labels not confirmed yet. Confirmed scans are saved — "
          "you can finish the rest later from the Receive Order detail.",
          textAlign: TextAlign.center,
          style: AppTextStyle.body(size, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => closeRoute(false),
            child: Text("Keep Scanning",
                style: AppTextStyle.bodyBold(size, color: navyDark)),
          ),
          TextButton(
            onPressed: () => closeRoute(true),
            child: Text("Finish Anyway",
                style: AppTextStyle.bodyBold(size, color: stockOutColor)),
          ),
        ],
      ),
    );
  }

  static bool _isBatch(String? type) => type?.toUpperCase() == 'BATCH';

  /// More rows than this already reach the bottom bar on a phone.
  static const int _hugRowLimit = 20;

  /// "Batch" / "Unique" pill on the item card, so the worker knows whether
  /// one label covers a whole batch entry or a single unit.
  Widget _serialTypePill(double size, String? type) {
    final batch = _isBatch(type);
    return KeyedSubtree(
      key: const Key('receiveConfirmSerialType'),
      child: accentPill(
        size,
        batch ? 'Batch' : 'Unique',
        accent: _appAccent,
        icon: batch ? Icons.inventory_2_rounded : Icons.qr_code_2_rounded,
      ),
    );
  }

  Widget _buildHeaderCard(
    double size,
    Map<String, dynamic> group,
    int total,
    int confirmed,
    int remaining,
  ) {
    return accentHeaderCard(
      size: size,
      accent: _appAccent,
      icon: Icons.qr_code_scanner_rounded,
      label: 'RO #${controller.roCode}',
      badge: _serialTypePill(size, group['serial_number_type']?.toString()),
      title: group['item_name'].toString(),
      stats: [
        HeaderStat('Total', '$total'),
        HeaderStat('Confirmed', '$confirmed', color: stockInColor),
        HeaderStat(
          'Remaining',
          '$remaining',
          color: remaining <= 0 ? Colors.grey : stockOutColor,
        ),
      ],
      progress: AccentProgress([
        ProgressSegment(total > 0 ? confirmed / total : 0, stockInColor),
      ], caption: '$confirmed of $total labels confirmed'),
    );
  }

  /// "Serial Labels" heading with how many labels of this item still wait.
  Widget _buildSerialListTitle(double size, int remaining) {
    return Row(
      children: [
        Expanded(
          child: Text("Serial Labels", style: AppTextStyle.h5(size, weight: FontWeight.w700)),
        ),
        remaining == 0
            ? statusPill(size, "All confirmed", Colors.green, icon: Icons.verified_rounded)
            : accentPill(size, "$remaining pending", accent: _appAccent),
      ],
    );
  }

  Widget _buildSerialList(
    double size,
    List<ReceiveConfirmSerialModel> serials,
  ) {
    if (serials.isEmpty) {
      return Center(
        child: Text(
          "No serials for this item",
          style: AppTextStyle.body(size, color: Colors.grey),
        ),
      );
    }

    return orderFillResultsContainer(
      size: size,
      child: ListView.separated(
        // Only a short list hugs its rows (shrinkWrap lays out every row on
        // each scan); a long one fills the space anyway, so it stays lazy.
        shrinkWrap: serials.length <= _hugRowLimit,
        padding: EdgeInsets.symmetric(vertical: size * 0.6),
        itemCount: serials.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          indent: size * 1.6,
          endIndent: size * 1.6,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (_, i) {
          final s = serials[i];
          final scanned = s.isScanned;
          final tileColor = scanned ? Colors.green : _accent;
          return ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: size * 1.6, vertical: size * 0.2),
            leading: Container(
              width: size * 4,
              height: size * 4,
              decoration: BoxDecoration(
                color: tileColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(size * 1.2),
              ),
              child: Icon(
                scanned ? Icons.check_rounded : Icons.qr_code_2_rounded,
                color: tileColor,
                size: size * 2.2,
              ),
            ),
            title: Text(
              s.internalCode.isNotEmpty ? s.internalCode : s.serialNumber,
              style: AppTextStyle.custom(
                size,
                scale: 1.2,
                weight: FontWeight.w700,
                color: scanned ? navyDark : Colors.black87,
              ),
            ),
            // The label's serial type (a BATCH label stands for its whole
            // batch entry, so it shows how many units it covers), then who
            // confirmed it.
            subtitle: Padding(
              padding: EdgeInsets.only(top: size * 0.3),
              child: Text(
                [
                  _isBatch(s.serialNumberType)
                      ? "Batch · qty ${s.qty}"
                      : "Unique · 1 unit",
                  if (scanned && s.scannedByName != null) "by ${s.scannedByName}",
                ].join(' · '),
                key: const Key('receiveConfirmLabelType'),
                style: AppTextStyle.small(size, color: Colors.grey.shade600),
              ),
            ),
            trailing: scanned
                ? statusPill(size, "Confirmed", Colors.green, icon: Icons.check_circle_rounded)
                : statusPill(size, "Pending", Colors.orange, icon: Icons.schedule_rounded),
          );
        },
      ),
    );
  }
}
