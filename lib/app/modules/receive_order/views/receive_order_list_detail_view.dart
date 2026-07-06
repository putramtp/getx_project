import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/receive_order_list_detail_controller.dart';
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
      appBar: appBarOrder("Receive Order Detail", size,
          routeBackName: AppPages.receiveOrderListPage,
          color1: navyDark, color2: navyMid),
      floatingActionButton: Obx(() {
        // Offer a re-open entry into the serial-confirm pass only when this RO
        // actually carries serial numbers.
        final detail = controller.receiveOrderDetail.value;
        final hasSerials = detail?.receiveOrderLines
                .any((l) => l.serialNumbers.isNotEmpty) ??
            false;
        if (!hasSerials) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          backgroundColor: skyBlue,
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
              orderDetailHeader(
                size: size,
                label: "Receive Order",
                code: controller.currentReceiveOrder.code,
                icon: Icons.inventory_rounded,
                gradientColors: const [navyDark, navyMid, navyLight],
              ),
              SizedBox(height: size * 2),
              Expanded(child: Obx(() {
                if (controller.isLoading.value) {
                  return skeletonLineList(size, accent: skyBlue);
                }
                if (controller.receiveOrderDetail.value == null) {
                  return textNoData(size, message: "No items found.");
                }
                final lines =
                    controller.receiveOrderDetail.value?.receiveOrderLines ?? [];
                return ListView.separated(
                  itemCount: lines.length,
                  separatorBuilder: (_, __) => SizedBox(height: size * 1.2),
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    return orderSerialLineCard(
                      size: size,
                      itemName: line.itemName,
                      qty: line.qty,
                      accent: skyBlue,
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
