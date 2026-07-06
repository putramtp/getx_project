import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/product_transaction_list_controller.dart';
import '../../../global/size_config.dart';
import '../../../global/widget/search_bar.dart';
import '../../../data/models/stock_transaction_model.dart';
import '../../../routes/app_pages.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../global/variables.dart';
import '../../../global/styles/app_text_style.dart';

class ProductTransactionListView extends GetView<ProductTransactionListController> {
  const ProductTransactionListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Transaction",size,icon: Icons.list_alt_sharp,routeBackName: AppPages.productPage,color1: navyDark,color2: sageGreen),
      body: SafeArea(
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

                  final transactions = controller.filteredTransactions;
                  if (controller.hasError.value && transactions.isEmpty) {
                    return errorRetry(size, onRetry: controller.loadProductTrans, accent: navyDark);
                  }
                  if (transactions.isEmpty) {
                    return const Center(child: Text('No  transaction data.'));
                  }

                  return NotificationListener(
                    onNotification: (ScrollNotification notification) {
                      if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 250) {
                        controller.loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      itemCount: transactions.length + 1,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        if (index < transactions.length) {
                          return _buildOrderCard(transactions[index],size);
                        }
                  
                        if (controller.cursorNext.value != null) {
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
                  
                        if (controller.cursorNext.value == null &&  transactions.isNotEmpty) {
                          return  Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                "No more data",
                                style: AppTextStyle.bodyBold(size,
                                    color: Colors.grey, weight: FontWeight.w500),
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
            ],
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
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Obx(() {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Filter Options",
                        style: AppTextStyle.custom(SizeConfig.defaultSize,
                            px: 18, weight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterDateField(
                              context,
                              label: "Start Date",
                              value: controller.startDate.value != null
                                  ? controller
                                      .formatDate(controller.startDate.value!)
                                  : 'Start date',
                              onTap: () => controller.pickStartDate(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFilterDateField(
                              context,
                              label: "End Date",
                              value: controller.endDate.value != null
                                  ? controller
                                      .formatDate(controller.endDate.value!)
                                  : "End date",
                              onTap: () => controller.pickEndDate(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                controller.clearDateFilter();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text("Clear"),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                controller.applyDateFilter();
                                Navigator.pop(context);
                              },
                              icon:
                                  const Icon(Icons.check, color: Colors.white),
                              label: Text(
                                "Apply",
                                style: AppTextStyle.plain(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
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

  Widget _buildFilterDateField(BuildContext context,
      {required String label,
      required String value,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: AppTextStyle.custom(SizeConfig.defaultSize, px: 15)),
            const Icon(Icons.date_range, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(StockTransactionModel transaction, double size) {
    final String orderCode = transaction.order?.code ?? "";
    final isIn = transaction.flowType == "IN";
    final color = isIn ? Colors.green : Colors.red;

    return Row(
      children: [
        /// Status Icon
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
            size: size *2,
          ),
        ),

        const SizedBox(width: 12),

        /// Product Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.plain(weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.time,
                style: AppTextStyle.info(size, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        /// Qty & Status
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${isIn ? '+' : '-'}${transaction.qty % 1 == 0 ? transaction.qty.toInt() : transaction.qty}",
              style: AppTextStyle.bodyBold(size, color: color, weight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isIn
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                transaction.type,
                style: AppTextStyle.body(size,
                    color: isIn ? Colors.blue : Colors.orange),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
