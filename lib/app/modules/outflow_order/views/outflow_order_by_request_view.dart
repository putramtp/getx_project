import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/outflow_order_by_request_controller.dart';
import '../../../global/size_config.dart';
import '../../../global/widget/search_bar.dart';
import '../../../data/models/outlfow_request_model.dart';
import '../../../routes/app_pages.dart';
import '../../../global/widget/functions_widget.dart';

class OutflowOrderByRequestView extends GetView<OutflowOrderByRequestController> {
  const OutflowOrderByRequestView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Outflow Request List",icon: Icons.list_alt_sharp,routeBackName: AppPages.outflowHomePage,hex1:'5170FD',hex2:"60ABFB"),
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orders = controller.filteredOrders;
                  if (orders.isEmpty) {
                    return const Center(child: Text('No order data.'));
                  }

                  return ListView.builder(
                    controller: controller.scrollController,
                    itemCount: orders.length + 1,
                    itemBuilder: (context, index) {
                      if (index < orders.length) {
                        return _buildOrderCard(orders[index],size);
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

                      if (controller.cursorNext.value == null && orders.isNotEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: Text(
                              "No more data",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  );
                }),
              ),
              buildSyncButton(
                  name: 'Synchronization',
                  size: size,
                  onPressed: controller.loadRequestOrders,
                  color: const Color(0xff5170FD))
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
                      const Text(
                        "Filter Options",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                              icon: const Icon(Icons.check),
                              label: const Text("Apply"),
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
            Text(value, style: const TextStyle(fontSize: 15)),
            const Icon(Icons.date_range, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OutflowRequestModel order,double size) {
    final status = order.status;
    final statusColor = status.toLowerCase().contains('processing')
        ? Colors.cyan
        : status.toLowerCase().contains('waiting')
            ? Colors.orange
            : Colors.green;

   return GestureDetector(
      onTap: () => controller.openDetail(order),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0), // ✅ flexible padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ Leading Icon
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.15),
                radius: size * 2,
                child: Icon(Icons.check_circle,color: statusColor,size: size * 2.6),
              ),
    
              const SizedBox(width: 12),
    
              // ✅ Title & Subtitle (Flexible)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: size * 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.customer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: size * 1.3,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
    
              const SizedBox(width: 12),
    
              // ✅ Trailing Info (Now flexible)
              Column(
                mainAxisSize: MainAxisSize.min, // ✅ prevents overflow
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order.items,
                    style: TextStyle(fontSize: size * 1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status.isNotEmpty
                        ? '${status[0].toUpperCase()}${status.substring(1)}'
                        : '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: size * 1.3,
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
