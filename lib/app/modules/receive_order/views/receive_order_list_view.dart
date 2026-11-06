import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../global/accent.dart';
import '../../../global/widget/app_header.dart';
import 'package:getx_project/app/global/widget/top_filter_popup.dart';

import '../controllers/receive_order_list_controller.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/search_bar.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/skeleton_widgets.dart';

class ReceiveOrderListView extends GetView<ReceiveOrderListController> {
  const ReceiveOrderListView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: controller.pendingSerialOnly
          ? appHeader('Serials to Confirm', accent: AppAccent.navy, icon: Icons.qr_code_scanner_rounded,
              subtitle: 'Labels not scanned yet')
          : appHeader('Receive Orders', accent: AppAccent.navy, icon: Icons.history_rounded, subtitle: 'Receiving history'),
      body: RefreshIndicator(
        onRefresh: controller.loadReceiveOrders,
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
                      return skeletonOrderList(size, accent: navyDark);
                    }
                    final orders = controller.orders;
                    if (controller.hasError.value && orders.isEmpty) {
                      return errorRetry(size, onRetry: controller.loadReceiveOrders, accent: navyDark);
                    }
                    if (orders.isEmpty) {
                      return textNoData(size,
                          message: controller.pendingSerialOnly
                              ? "Every recent receive order is confirmed."
                              : "No receive order data.");
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
                              accentColor: navyDark,
                              title: order.code,
                              subtitle: order.supplier,
                              subtitleIcon: Icons.store_outlined,
                              dateText: controller.formatYmd(order.date),
                              trailingBottom: controller.pendingSerialOnly
                                  ? '${order.pendingSerialCount} to scan'
                                  : order.type,
                              trailingBottomColor: navyDark,
                              onTap: () => controller.pendingSerialOnly
                                  ? controller.openSerialConfirm(order)
                                  : controller.openDetail(order),
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
    showTopFilterPopup(context, TopDateFilterPopup(controller: controller));
  }
}
