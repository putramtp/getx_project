import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/accent.dart';
import '../../../global/widget/app_header.dart';
import '../../../global/widget/accent_header_card.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../controllers/outflow_order_list_detail_controller.dart';

class OutflowOrderDetailView extends GetView<OutflowOrderListDetailController> {
  const OutflowOrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appHeader('Outflow Order', accent: AppAccent.purple, icon: Icons.receipt_long_rounded),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size * 1.6),
          child: Column(
            children: [
              Obx(() {
                final detail = controller.outflowOrderDetail.value;
                final lines = detail?.outflowOrderLines ?? const [];
                return skeletonize(
                  loading: controller.isLoading.value,
                  child: orderRecordHeader(
                    size: size,
                    accent: AppAccent.purple,
                    icon: Icons.receipt_long_rounded,
                    label: 'Outflow order',
                    code: controller.curretOutflowOrder.code,
                    type: detail?.type ?? controller.curretOutflowOrder.type,
                    typeAccent: AppAccent.steel,
                    isIn: false,
                    lines: lines.length,
                    totalQty: lines.fold<int>(0, (sum, l) => sum + l.qty),
                    date: detail?.date,
                    footer: headerFooterText([detail?.customerName, detail?.billNumber]),
                    footerIcon: Icons.groups_rounded,
                  ),
                );
              }),
              SizedBox(height: size * 2),
              Expanded(child: Obx(() {
                if (controller.isLoading.value) {
                  return skeletonLineList(size, accent: mutedPurple);
                }
                if (controller.outflowOrderDetail.value == null) {
                  return textNoData(size, message: "No items found.");
                }
                final lines =
                    controller.outflowOrderDetail.value?.outflowOrderLines ?? [];
                return ListView.separated(
                  itemCount: lines.length,
                  separatorBuilder: (_, _) => SizedBox(height: size * 1.2),
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    return orderSerialLineCard(
                      size: size,
                      itemName: line.itemName,
                      qty: line.qty,
                      accent: mutedPurple,
                      serials: line.serialNumbers,
                    );
                  },
                );
              })),
              SizedBox(height: size * 1.2),
              _deliveryCta(size),
            ],
          ),
        ),
      ),
    );
  }

  /// "Create Delivery" when the order has none yet, else "View Deliveries".
  Widget _deliveryCta(double size) {
    return Obx(() {
      if (controller.outflowOrderDetail.value == null) {
        return const SizedBox.shrink();
      }
      // Only DO (Delivery Order) type orders can be delivered.
      if (!controller.isDeliverable) {
        return const SizedBox.shrink();
      }
      final hasDelivery = controller.hasDelivery;
      return SizedBox(
        width: double.infinity,
        height: size * 4.6,
        child: ElevatedButton.icon(
          onPressed: controller.isCreatingDelivery.value
              ? null
              : (hasDelivery
                  ? controller.viewDeliveries
                  : controller.createDelivery),
          icon: controller.isCreatingDelivery.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white))
              : Icon(
                  hasDelivery
                      ? Icons.local_shipping_rounded
                      : Icons.add_road_rounded,
                  size: size * 2,
                  color: Colors.white),
          label: Text(hasDelivery ? "View Deliveries" : "Create Delivery",
              style: AppTextStyle.bodyBold(size, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: steelBlue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size * 1.2)),
          ),
        ),
      );
    });
  }
}
