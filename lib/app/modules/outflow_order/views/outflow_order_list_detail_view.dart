import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../controllers/outflow_order_list_detail_controller.dart';
import '../../../routes/app_pages.dart';

class OutflowOrderDetailView extends GetView<OutflowOrderListDetailController> {
  const OutflowOrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Outflow Order Detail", size,
          routeBackName: AppPages.outflowOrderListPage,
          color1: mutedPurple, color2: softPurple),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size * 1.6),
          child: Column(
            children: [
              orderDetailHeader(
                size: size,
                label: "Outflow Order",
                code: controller.curretOutflowOrder.code,
                icon: Icons.inventory_rounded,
                gradientColors: const [mutedPurple, softPurple, lightPurple],
              ),
              SizedBox(height: size * 2),
              Expanded(child: Obx(() {
                if (controller.isLoading.value) {
                  return skeletonLineList(size, accent: softPurple);
                }
                if (controller.outflowOrderDetail.value == null) {
                  return textNoData(size, message: "No items found.");
                }
                final lines =
                    controller.outflowOrderDetail.value?.outflowOrderLines ?? [];
                return ListView.separated(
                  itemCount: lines.length,
                  separatorBuilder: (_, __) => SizedBox(height: size * 1.2),
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    return orderSerialLineCard(
                      size: size,
                      itemName: line.itemName,
                      qty: line.qty,
                      accent: softPurple,
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
