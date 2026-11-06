import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/data/models/stock_transaction_model.dart';
import '../../../global/functions.dart';
import '../../../global/accent.dart';
import '../../../global/widget/app_header.dart';
import '../../../global/widget/stock_direction_icon.dart';
import 'package:getx_project/app/global/widget/top_filter_popup.dart';
import 'package:getx_project/app/modules/transaction/controllers/stock_transaction_controller.dart';
import '../../../global/size_config.dart';
import '../../../global/widget/search_bar.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../global/variables.dart';
import '../../../global/styles/app_text_style.dart';

class StockTransactionView extends GetView<StockTransactionController> {
  const StockTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appHeader('Stock Transactions', accent: AppAccent.slate, icon: Icons.swap_vert_rounded, subtitle: 'Inventory'),
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
                      return skeletonGenericList(size);
                    }
      
                    final trans = controller.trans;
                    // Read here, not in itemBuilder, so the footer follows the cursor.
                    final cursor = controller.cursorNext.value;
                    if (controller.hasError.value && trans.isEmpty) {
                      return _pullable(errorRetry(size, onRetry: controller.loadstockTransactions, accent: navyDark));
                    }
                    if (trans.isEmpty) {
                      return _pullable(textNoData(size, message: "No stock transaction data."));
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
                        physics: const AlwaysScrollableScrollPhysics(), // pull-to-refresh on a short list
                        itemCount: trans.length + 1,
                        itemBuilder: (context, index) {
                          if (index < trans.length) {
                            return _buildOrderCard(trans[index], size);
                          }
                          
                          if (cursor != null && controller.limit.value >= 8) {
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
                          
                          if (cursor == null) {
                            return NoMoreDataFooter(size: size);
                          }
                          
                          return const SizedBox.shrink();
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

  /// 🧾 Modern Top Filter Sheet
  void _openTopFilterSheet(BuildContext context) {
    showTopFilterPopup(context, TopDateFilterPopup(controller: controller));
  }

  /// The empty / error state inside a scrollable, so pull-to-refresh still
  /// works when there is no list to pull.
  Widget _pullable(Widget child) => LayoutBuilder(
        builder: (context, box) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: box.maxHeight, child: child)],
        ),
      );

  Widget _buildOrderCard(StockTransactionModel st, double size) {
    final isIn = st.flowType == "IN";
    final color = isIn ? stockInColor : stockOutColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            stockDirectionIcon(size, isIn: isIn),
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
                          style: AppTextStyle.custom(size,
                              scale: 1.4, weight: FontWeight.w400),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          st.order?.code ?? '-', // no order once it was deleted
                          style: AppTextStyle.custom(size,
                              scale: 1.1,
                              weight: FontWeight.w400,
                              color: isIn ? Colors.green : Colors.orange),
                        ),
                      ],
                    ), 
                  ),

                  /// Qty & Type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${isIn ? '+' : '-'}${formatQty(st.qty)}",
                        style: AppTextStyle.plain(
                            weight: FontWeight.bold, color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        st.time,
                        style: AppTextStyle.body(size, color: Colors.grey.shade600),
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
