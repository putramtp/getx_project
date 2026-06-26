import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/widget/top_filter_popup.dart';

import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/search_bar.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../routes/app_pages.dart';
import '../controllers/receive_order_by_po_controller.dart';
import '../../../global/widget/functions_widget.dart';

class ReceiveOrderByPoView extends GetView<ReceiveOrderByPoController> {
  const ReceiveOrderByPoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Purchase Order List", size,
          icon: Icons.list_alt_sharp,
          routeBackName: AppPages.receiveHomePage,
          hex1: "#4A90D9", hex2: "#6FA8E0"),
      body: RefreshIndicator(
        onRefresh: controller.loadPurchaseOrders,
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
                      hintText: 'Search Purchase Orders...',
                    )),
                SizedBox(height: size * 1.2),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return textLoading(size);
                    }
                    final orders = controller.orders;
                    if (orders.isEmpty) {
                      return textNoData(size, message: "No purchase order data.");
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
                            final status = order.status;
                            final statusColor =
                                status.toLowerCase().contains('processing')
                                    ? skyBlue
                                    : status.toLowerCase().contains('waiting')
                                        ? amber
                                        : sageTeal;
                            return orderListCard(
                              size: size,
                              leadingIcon: Icons.request_page_rounded,
                              accentColor: skyBlue,
                              title: order.poNumber,
                              subtitle: order.supplier,
                              subtitleIcon: Icons.store_outlined,
                              dateText: controller.formatDate(order.date),
                              trailingTop: order.items,
                              trailingBottom: status.isNotEmpty
                                  ? '${status[0].toUpperCase()}${status.substring(1)}'
                                  : '-',
                              trailingBottomColor: statusColor,
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
