import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/models/outlfow_request_model.dart';
import 'package:getx_project/app/routes/app_pages.dart';
import '../controllers/outflow_order_by_request_controller.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';

class OutflowOrderByRequestView
    extends GetView<OutflowOrderByRequestController> {
  const OutflowOrderByRequestView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: appBarOrder("Outflow Request List",
            icon: Icons.list_alt_sharp,
            routeBackName: AppPages.outflowHomePage),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 12),

              /// 🔍 Animated Search, Sort & Filter Row
              Obx(() {
                final bool isFocused = controller.isSearchFocused.value;
                final searchController = controller.searchController;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// 🔍 Animated Search Bar (takes all available space)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: 50,
                        child: Focus(
                          focusNode: controller.searchFocus,
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Search...',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: isFocused
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        searchController.clear();
                                        FocusScope.of(context).unfocus();
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: controller.onSearchChanged,
                          ),
                        ),
                      ),
                    ),

                    /// ✨ Animated Sort & Filter Buttons
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SizeTransition(
                          sizeFactor: anim,
                          axis: Axis.horizontal,
                          child: child,
                        ),
                      ),
                      child: !isFocused
                          ? Row(
                              key: const ValueKey('buttons'),
                              children: [
                                const SizedBox(width: 6),
                                // Sort button
                                Obx(() => IconButton.filledTonal(
                                      tooltip: controller.isAscending.value
                                          ? "Sort Z–A"
                                          : "Sort A–Z",
                                      icon: Icon(
                                        controller.isAscending.value
                                            ? Icons.sort_by_alpha_rounded
                                            : Icons.arrow_upward_rounded,
                                        color: Colors.blueAccent,
                                      ),
                                      onPressed: controller.toggleSort,
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.all(12),
                                      ),
                                    )),
                                const SizedBox(width: 6),
                                // Filter button
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.filter_alt_rounded),
                                  tooltip: 'Filter',
                                  onPressed: () => _openTopFilterSheet(context),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                  ],
                );
              }),

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
                    shrinkWrap: true, // 👈 **fix #1**
                    physics:const BouncingScrollPhysics(), // 👈 allow only this to scroll
                    itemBuilder: (context, index) {
                      if (index < orders.length) {
                        return _buildOrderCard(orders[index]);
                      }

                      return Obx(() {
                        if (controller.cursorNext != null) {
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

                        if (controller.cursorNext == null &&
                            orders.isNotEmpty) {
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
                      });
                    },
                  );
                }),
              ),

              /// 🔄 Sync Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: controller.syncData,
                    icon: const Icon(Icons.sync, color: Colors.white),
                    label: const Text(
                      'Synchronization',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
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

  Widget _buildOrderCard(OutflowRequestModel order) {
    final status = order.status;
    final statusColor = status.toLowerCase().contains('processing')
        ? Colors.cyan
        : status.toLowerCase().contains('waiting')
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(Icons.check_circle, color: statusColor),
        ),
        title: Text(order.code,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          order.customer,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(order.items, style: const TextStyle(fontSize: 10)),
            Text(
              status.toString().isNotEmpty
                  ? '${status[0].toUpperCase()}${status.substring(1)}'
                  : '-',
              style: TextStyle(
                  fontSize: 14,
                  color: statusColor,
                  fontWeight: FontWeight.w800),
            ),
          ],
        ),
        onTap: () => controller.openDetail(order),
      ),
    );
  }
}
