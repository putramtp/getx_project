import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_menu_widgets.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderHomeView extends GetView {
  const ReceiveOrderHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder(
        "Receive Order Menu", size,
        icon: Icons.grid_view_outlined,
        routeBackName: AppPages.homePage,
        color1: navyDark, color2: navyMid,
      ),
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
                gradientColors: const [navyDark, navyMid, navyLight],
                onTap: () => Get.toNamed(AppPages.receiveOrderListPage),
              ),
              SizedBox(height: size * 3),
              orderMenuSectionHeader(
                  size, "Create Receiving", Icons.add_circle_outline_rounded, steelBlue),
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
                        onTap: () => Get.toNamed(AppPages.receiveOrderByPoPage),
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
                        onTap: () =>
                            Get.toNamed(AppPages.receiveOrderBySupplierPage),
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
