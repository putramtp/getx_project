import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/data/models/stock_transaction_model.dart';
import 'package:getx_project/app/global/widget/top_filter_popup.dart';
import 'package:getx_project/app/modules/transaction/controllers/stock_transaction_controller.dart';
import '../../../global/size_config.dart';
import '../../../global/widget/search_bar.dart';
import '../../../routes/app_pages.dart';
import '../../../global/widget/functions_widget.dart';

class StockTransactionView extends GetView<StockTransactionController> {
  const StockTransactionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Stock Transactions",size,icon: Icons.currency_exchange, routeBackName: AppPages.homePage,hex1: '#124076',hex2: '#7F9F80'),
      body: RefreshIndicator(
        onRefresh:  controller.loadstockTransactions,
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
      
                    final trans = controller.trans;
                    if (trans.isEmpty) {
                      return textNoData(size,message: "No stock transaction data.");
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
                        itemCount: trans.length + 1,
                        itemBuilder: (context, index) {
                          if (index < trans.length) {
                            return _buildOrderCard(trans[index], size);
                          }
                          
                          if (controller.cursorNext.value != null  &&  controller.limit.value >= 8 ) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(strokeWidth: 3),
                                ),
                              ),
                            );
                          }
                          
                          if (controller.cursorNext.value == null && trans.isNotEmpty) {
                            return Padding(
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
                // buildSyncButton(name: 'Sync',size: size,onPressed: controller.loadstockTransactions,color: const Color.fromARGB(255, 25, 105, 116))
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

  Widget _buildOrderCard(StockTransactionModel st, double size) {
    final isIn = st.flowType == "IN";
    final color = isIn ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: size * 4,
              height: size * 4,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIn ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: size * 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Product Name
                        Text(
                          st.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:  TextStyle(
                            // color: Color.fromARGB(255, 64, 114, 202),
                            fontWeight: FontWeight.w400,
                            fontSize: size * 1.4
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          st.order!.code,
                          style: TextStyle(
                            fontSize: size * 1.1,
                            fontWeight: FontWeight.w400,
                            color: isIn ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ), 
                  ),

                  /// Qty & Type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${isIn ? '+' : '-'}${st.qty}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        st.time,
                        style: TextStyle(
                          fontSize: size * 1.2,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
