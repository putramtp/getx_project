import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/widget/top_filter_popup.dart';

import '../controllers/receive_order_list_controller.dart';
import '../../../global/size_config.dart';
import '../../../global/widget/search_bar.dart';
import '../../../data/models/receive_order_model.dart';
import '../../../routes/app_pages.dart';
import '../../../global/widget/functions_widget.dart';

class ReceiveOrderListView extends GetView<ReceiveOrderListController> {
  const ReceiveOrderListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Receive Order List",size,
          icon: Icons.list_alt_sharp,
          routeBackName: AppPages.receiveHomePage),
      body: RefreshIndicator(
        onRefresh: controller.loadReceiveOrders,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Obx(() => SearchBarWidget(
                    isFocused: controller.isSearchFocused.value,
                    isAscending: controller.isAscending.value,
                    searchController: controller.searchController,
                    focusNode: controller.searchFocus,
                    onSearchChanged: controller.onSearchChanged,
                    onToggleSort: controller.toggleSort,
                    onOpenFilter: () => _openTopFilterSheet(context),
                )),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return textLoading(size);
                    }
      
                    final orders = controller.orders;
                    if (orders.isEmpty) {
                      return textNoData(size,message: "No receive order data.");
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
                            return _buildOrderCard(orders[index],size);
                          }
                    
                          if (controller.cursorNext.value != null &&controller.limit.value >= 8) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 3),
                                ),
                              ),
                            );
                          }
                    
                          if (controller.cursorNext.value == null &&  orders.isNotEmpty) {
                            return  Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: Text(
                                  "No more data",
                                  style: TextStyle(
                                    fontSize: size * 1.2,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }
                    
                          return const SizedBox.shrink();
                        },
                      ),
                    );
                  }),
                ),
                // buildSyncButton(name: 'Sync',size: size,onPressed:controller.loadReceiveOrders,color: const Color(0xff4A70A9))
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🧾 Modern Top Filter Sheet
  void _openTopFilterSheet(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Filter",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return TopDateFilterPopup(controller: controller);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1), // 👈 slide from top
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(ReceiveOrderModel order, double size) {
    return GestureDetector(
      onTap: () => controller.openDetail(order),
      child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: size * 1.6,
                      backgroundColor: Colors.cyan.withOpacity(0.15),
                      child:Icon(Icons.file_present_rounded, color: Colors.cyan,size: size * 2),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.code,style: const TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(Icons.star_border,
                                size: size * 1.2, color: Colors.black54),
                            const SizedBox(width: 2),
                            Text(
                              order.supplier,
                              style:
                                  TextStyle(fontSize: size * 1.2, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(order.type,style: TextStyle(fontSize: size , fontWeight: FontWeight.w600)),
                    Text(
                      controller.formatYmd(order.date),
                      style: TextStyle(
                          fontSize: size,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          )),
    );
  }
}
