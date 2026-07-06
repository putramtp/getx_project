import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/widget/top_filter_popup.dart';

import '../controllers/outflow_order_list_controller.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/search_bar.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../routes/app_pages.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/skeleton_widgets.dart';

class OutflowOrderListView extends GetView<OutflowOrderListController> {
  const OutflowOrderListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Outflow Order List", size,
          icon: Icons.list_alt_sharp,
          routeBackName: AppPages.outflowHomePage,
          color1: mutedPurple, color2: softPurple),
      body: RefreshIndicator(
        onRefresh: controller.loadOutflowOrders,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 1.6),
            child: Column(
              children: [
                SizedBox(height: size * 1.2),
                Obx(() => SearchBarWidget(
                      isFocused: controller.isSearchFocused.value,
                      isAscending: controller.isAscending.value,
                      searchController: controller.searchController,
                      focusNode: controller.searchFocus,
                      onSearchChanged: controller.onSearchChanged,
                      onToggleSort: controller.toggleSort,
                      onOpenFilter: () => _openTopFilterSheet(context),
                    )),
                SizedBox(height: size * 1.2),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return skeletonOrderList(size, accent: softPurple);
                    }
                    final orders = controller.orders;
                    if (controller.hasError.value && orders.isEmpty) {
                      return errorRetry(size, onRetry: controller.loadOutflowOrders, accent: mutedPurple);
                    }
                    if (orders.isEmpty) {
                      return textNoData(size);
                    }
                    return NotificationListener(
                      onNotification: (ScrollNotification notification) {
                        if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 250) {
                          controller.loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        itemCount: orders.length + 1,
                        itemBuilder: (context, index) {
                          if (index < orders.length) {
                            final order = orders[index];
                            return orderListCard(
                              size: size,
                              leadingIcon: Icons.receipt_long_rounded,
                              accentColor: softPurple,
                              title: order.code,
                              subtitle: order.customer,
                              subtitleIcon: Icons.person_outline_rounded,
                              dateText: controller.formatYmd(order.date),
                              trailingBottom: order.type,
                              trailingBottomColor: softPurple,
                              onTap: () => controller.openDetail(order),
                            );
                          }
                          return orderListFooter(
                            size,
                            showLoader: controller.cursorNext.value != null &&
                                controller.limit.value >= 8,
                            showEnd: controller.cursorNext.value == null &&
                                orders.isNotEmpty,
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTopFilterSheet(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Filter",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => TopDateFilterPopup(controller: controller),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }
}
