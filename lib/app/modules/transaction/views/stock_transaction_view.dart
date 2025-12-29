import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/data/models/stock_transaction_model.dart';
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
                      onOpenFilter: () => _openTopFilterSheet(context ,size),
                    )),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return textLoading(size);
                    }
      
                    final trans = controller.filteredTrans;
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
                          
                          if (controller.cursorNext.value != null) {
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
  void _openTopFilterSheet(BuildContext context ,double size) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Filter",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        final maxHeight = MediaQuery.of(context).size.height * 0.75;
        return LayoutBuilder(
            builder: (context, constraints) {
            final bool isSmall = constraints.maxWidth < 300;
            return Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxHeight: maxHeight),
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
                      return SingleChildScrollView(
                        child: Column(
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
                            const Text(
                              "Filter Options",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (isSmall) 
                             Column(
                              children: [
                                _buildFilterDateField(
                                  context,
                                  label: "Start Date",
                                  value: controller.startDate.value != null
                                      ? controller.formatDate(controller.startDate.value!)
                                      : 'Start date',
                                  onTap: () => controller.pickStartDate(context),
                                ),
                                const SizedBox(height: 12),
                                _buildFilterDateField(
                                  context,
                                  label: "End Date",
                                  value: controller.endDate.value != null
                                      ? controller.formatDate(controller.endDate.value!)
                                      : "End date",
                                  onTap: () => controller.pickEndDate(context),
                                ),
                              ],
                            ),
                            if (!isSmall) 
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFilterDateField(
                                    context,
                                    label: "Start Date",
                                    value: controller.startDate.value != null
                                        ? controller.formatDate(
                                            controller.startDate.value!)
                                        : 'Start date',
                                    onTap: () =>
                                        controller.pickStartDate(context),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFilterDateField(
                                    context,
                                    label: "End Date",
                                    value: controller.endDate.value != null
                                        ? controller.formatDate(
                                            controller.endDate.value!)
                                        : "End date",
                                    onTap: () =>
                                        controller.pickEndDate(context),
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
                                    icon:  Icon(Icons.clear,size: size * 1.4,),
                                    label:  Text("Clear",overflow: TextOverflow.ellipsis, maxLines: 2, style: TextStyle(fontSize: size * 1.4),),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                    onPressed: () {
                                      controller.applyDateFilter();
                                      Navigator.pop(context);
                                    },
                                    icon:  Icon(Icons.check,color: Colors.white,size: size * 1.4,),
                                    label:  Text(
                                      "Apply",
                                      style: TextStyle(color: Colors.white,fontSize: size * 1.4,),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            );
          }
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          ),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }


  Widget _buildFilterDateField(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
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
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(width: 8),
            const Icon(Icons.date_range, color: Colors.grey),
          ],
        ),
      ),
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
