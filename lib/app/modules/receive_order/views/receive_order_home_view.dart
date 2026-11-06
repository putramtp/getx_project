import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/accent.dart';
import '../../../global/widget/app_header.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/order_menu_widgets.dart';
import '../../../routes/app_pages.dart';
import '../controllers/receive_order_home_controller.dart';

class ReceiveOrderHomeView extends GetView<ReceiveOrderHomeController> {
  const ReceiveOrderHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appHeader('Receive', accent: AppAccent.navy, icon: Icons.move_to_inbox_rounded),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(size * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              orderMenuHero(
                size: size,
                title: "Receive Orders",
                subtitle: "View all receiving history",
                icon: Icons.move_to_inbox_rounded,
                gradientColors: const [navyDark, navyMid],
                onTap: () => controller.open(AppPages.receiveOrderListPage),
              ),
              // Shown only while some receive order still holds unscanned labels.
              Obx(() {
                final summary = controller.serialSummary.value;
                if (summary == null || !summary.hasPending) return const SizedBox.shrink();
                final orders = summary.pendingOrders == 1 ? '1 order' : '${summary.pendingOrders} orders';
                final labels = summary.pendingLabels == 1 ? '1 label' : '${summary.pendingLabels} labels';
                return Padding(
                  padding: EdgeInsets.only(top: size * 2),
                  child: KeyedSubtree(
                    key: const Key('receiveHomeSerialQueueCard'),
                    child: orderMenuInfoCard(
                      size: size,
                      title: "Serials to Confirm",
                      subtitle: "$orders · $labels not scanned",
                      icon: Icons.qr_code_scanner_rounded,
                      accent: AppAccent.navy,
                      onTap: controller.openSerialQueue,
                    ),
                  ),
                );
              }),
              SizedBox(height: size * 3),
              orderMenuSectionHeader(
                  size, "Create Receiving", Icons.add_circle_outline_rounded, navyDark),
              SizedBox(height: size * 2),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: orderMenuTile(
                        size: size,
                        title: "By Purchase-order",
                        subtitle: "Receive against a PO",
                        icon: Icons.request_page_rounded,
                        color: skyBlue,
                        onTap: () => controller.open(AppPages.receiveOrderByPoPage),
                      ),
                    ),
                    SizedBox(width: size * 1.6),
                    Expanded(
                      child: orderMenuTile(
                        size: size,
                        title: "By Supplier",
                        subtitle: "Receive from a supplier",
                        icon: Icons.groups_rounded,
                        color: sageTeal,
                        onTap: () => controller.open(AppPages.receiveOrderBySupplierPage),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
