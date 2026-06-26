import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_list_widgets.dart';
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
          hex1: "#6B5FB5", hex2: "#7C73C0"),
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
                  return textLoading(size, message: "loading items..");
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
            ],
          ),
        ),
      ),
    );
  }
}
