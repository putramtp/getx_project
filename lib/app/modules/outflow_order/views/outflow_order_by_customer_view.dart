import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/widget/search_bar.dart';
import '../../../data/models/outflow_request_customer_model.dart';
import '../../../modules/outflow_order/controllers/outflow_order_by_customer_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../global/widget/functions_widget.dart';

class OutflowOrderByCustomerView extends GetView<OutflowOrderByCustomerController> {
  const OutflowOrderByCustomerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: appBarOrder("Customer List",size,icon: Icons.group_rounded, routeBackName: AppPages.outflowHomePage,hex1:"778873",hex2:'A1BC98'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadCustomers,
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
                  hintText: 'Search Customer...',
                )),
                const SizedBox(height: 12),
      
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return textLoading(size);
                    }
      
                    final orders = controller.filteredCustomers;
                    if (orders.isEmpty) {
                      return textNoData(size,message: 'No Costumer data.');
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
      
                // buildSyncButton(name: 'Customer Synchronization',size: size,onPressed:controller.loadCustomers,color: const Color(0xff778873))
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrCustomerModel customer,double size ) {
    final status = customer.status;
    final statusColor = status.toLowerCase().contains('processing')
        ? Colors.cyan
        : status.toLowerCase().contains('waiting')
            ? Colors.orange
            : Colors.green;

     return GestureDetector(
      onTap: () => controller.openDetail(customer),
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
                child: Icon(Icons.store_rounded,color: statusColor,size: size * 2.6),
              ),
    
              const SizedBox(width: 12),
    
              // ✅ Title & Subtitle (Flexible)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: size * 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.customerCode,
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
                    customer.items,
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
