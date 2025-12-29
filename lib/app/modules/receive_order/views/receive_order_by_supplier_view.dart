import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/receive_order_by_supplier_controller.dart';
import '../../../global/size_config.dart';
import '../../../global/widget/search_bar.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../data/models/purchase_order_supplier_model.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderBySupplierView extends GetView<ReceiveOrderBySupplierController> {
  const ReceiveOrderBySupplierView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Supplier List",size,icon: Icons.group_rounded, routeBackName: AppPages.receiveHomePage,hex1:"75a340",hex2:"B1C29E"),
      body: RefreshIndicator(
        onRefresh: controller.loadSuppliers,
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
                    hintText: 'Search Supplier', // custom hint
                )),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return textLoading(size);
                    }
      
                    final orders = controller.filteredSuppliers;
                    if (orders.isEmpty) {
                      return textNoData(size,message: "No supplier data.");
                    }
      
                    return ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _buildOrderCard(order,size);
                      },
                    );
                  }),
                ),
                // buildSyncButton(name: 'Supplier Synchronization',size: size,onPressed:controller.loadSuppliers,color: const Color.fromARGB(255, 122, 150, 89)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(PoSupplierModel supplier,double size) {
    final status = supplier.status;
    final statusColor = status.toLowerCase().contains('processing')
        ? Colors.cyan
        : status.toLowerCase().contains('waiting')
            ? Colors.orange
            : Colors.green;
    return GestureDetector(
      onTap: () => controller.openDetail(supplier),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: size * 2.5,
                backgroundColor: statusColor.withOpacity(0.15),
                child: Icon(
                  Icons.store_rounded,
                  color: statusColor,
                  size: size * 2.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(supplier.name,style: TextStyle(fontSize: size * 1.6, fontWeight: FontWeight.bold)),
                    Text(supplier.code,style: TextStyle(fontSize: size * 1.2, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(supplier.items, style: TextStyle(fontSize: size * 1)),
                    Text(
                      status.toString().isNotEmpty
                          ? '${status[0].toUpperCase()}${status.substring(1)}'
                          : '-',
                      style: TextStyle(
                          fontSize: size * 1.4,
                          color: statusColor,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
