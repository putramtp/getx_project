import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_menu_widgets.dart';
import '../../../routes/app_pages.dart';

class OutflowOrderHomeView extends GetView {
  const OutflowOrderHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder(
        "Outflow Order Menu", size,
        icon: Icons.grid_view_outlined,
        routeBackName: AppPages.homePage,
        hex1: "#6B5FB5", hex2: "#7C73C0",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(size * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              orderMenuHero(
                size: size,
                title: "Outflow Orders",
                subtitle: "View all outflow history",
                icon: Icons.outbox_rounded,
                gradientColors: const [mutedPurple, softPurple, lightPurple],
                onTap: () => Get.toNamed(AppPages.outflowOrderListPage),
              ),
              SizedBox(height: size * 3),
              orderMenuSectionHeader(
                  size, "Create Outflow", Icons.add_circle_outline_rounded, softPurple),
              SizedBox(height: size * 2),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: orderMenuTile(
                        size: size,
                        title: "By Request",
                        subtitle: "Outflow from a request",
                        icon: Icons.assignment_rounded,
                        color: mutedPurple,
                        onTap: () =>
                            Get.toNamed(AppPages.outflowOrderByRequestPage),
                      ),
                    ),
                    SizedBox(width: size * 1.6),
                    Expanded(
                      child: orderMenuTile(
                        size: size,
                        title: "By Customer",
                        subtitle: "Outflow to a customer",
                        icon: Icons.groups_rounded,
                        color: amber,
                        onTap: () =>
                            Get.toNamed(AppPages.outflowOrderByCustomerPage),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size * 3),
              orderMenuSectionHeader(
                  size, "Logistics", Icons.local_shipping_outlined, steelBlue),
              SizedBox(height: size * 2),
              orderMenuHero(
                size: size,
                title: "Deliveries",
                subtitle: "Track & dispatch deliveries",
                icon: Icons.local_shipping_rounded,
                gradientColors: const [steelBlue, lightSteelBlue],
                onTap: () => Get.toNamed(AppPages.deliveryListPage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
