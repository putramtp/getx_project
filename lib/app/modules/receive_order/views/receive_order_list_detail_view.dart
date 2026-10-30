import 'package:getx_project/app/global/functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/receive_order_list_detail_controller.dart';
import '../../../global/accent.dart';
import '../../../global/widget/app_header.dart';
import '../../../global/widget/accent_header_card.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderListDetailView extends GetView<ReceiveOrderListDetailController> {
  const ReceiveOrderListDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appHeader('Receive Order', accent: AppAccent.navy, icon: Icons.assignment_turned_in_rounded),
      floatingActionButton: Obx(() {
        // Offer a re-open entry into the serial-confirm pass only when this RO
        // actually carries serial numbers.
        final detail = controller.receiveOrderDetail.value;
        final hasSerials = detail?.receiveOrderLines
                .any((l) => l.serialNumbers.isNotEmpty) ??
            false;
        if (!hasSerials) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          backgroundColor: navyDark,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: Text("Confirm Serials",
              style: AppTextStyle.bodyBold(size, color: Colors.white)),
          onPressed: () => Get.toNamed(
            AppPages.receiveOrderConfirmPage,
            arguments: {
              'ro_id': controller.currentReceiveOrder.id,
              'ro_code': controller.currentReceiveOrder.code,
              'back_route': AppPages.receiveOrderListPage,
            },
          ),
        );
      }),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size * 1.6),
          child: Column(
            children: [
              Obx(() {
                final detail = controller.receiveOrderDetail.value;
                final lines = detail?.receiveOrderLines ?? const [];
                final serials = [for (final l in lines) ...l.serialNumbers];
                final confirmed = serials.where((s) => s.isScanned).length;
                final type = detail?.type ?? controller.currentReceiveOrder.type;
                return skeletonize(
                  loading: controller.isLoading.value,
                  child: orderRecordHeader(
                    size: size,
                    accent: AppAccent.navy,
                    icon: Icons.assignment_turned_in_rounded,
                    label: 'Receive order',
                    code: controller.currentReceiveOrder.code,
                    type: type,
                    typeAccent: type.toUpperCase().contains('PO') ? AppAccent.sky : AppAccent.sage,
                    isIn: true,
                    lines: lines.length,
                    totalQty: roundQty(lines.fold<num>(0, (sum, l) => sum + l.qty)),
                    date: detail?.date ?? controller.currentReceiveOrder.date,
                    footer: headerFooterText([detail?.supplierName, detail?.receiveNumber]),
                    footerIcon: Icons.storefront_rounded,
                    progress: serials.isEmpty
                        ? null
                        : AccentProgress(
                            [ProgressSegment(confirmed / serials.length, stockInColor)],
                            caption: '$confirmed of ${serials.length} serials confirmed',
                          ),
                  ),
                );
              }),
              SizedBox(height: size * 2),
              Expanded(child: Obx(() {
                if (controller.isLoading.value) {
                  return skeletonLineList(size, accent: navyDark);
                }
                if (controller.receiveOrderDetail.value == null) {
                  return textNoData(size, message: "No items found.");
                }
                final lines =
                    controller.receiveOrderDetail.value?.receiveOrderLines ?? [];
                return ListView.separated(
                  itemCount: lines.length,
                  separatorBuilder: (_, _) => SizedBox(height: size * 1.2),
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    return orderSerialLineCard(
                      size: size,
                      itemName: line.itemName,
                      qty: line.qty,
                      accent: navyDark,
                      serials: line.serialNumbers,
                      showConfirmation: true,
                    );
                  },
                );
              })),
            ],
          ),
        ),
      ),
    );
  }
}
