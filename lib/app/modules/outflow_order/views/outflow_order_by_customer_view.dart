import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/search_bar.dart';
import '../../../global/widget/order_list_widgets.dart';
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
      appBar: appBarOrder("Customer List", size,
          icon: Icons.group_rounded,
          routeBackName: AppPages.outflowHomePage,
          hex1: "#C4882A", hex2: "#D6A24E"),
      body: RefreshIndicator(
        onRefresh: controller.loadCustomers,
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
                      hintText: 'Search Customer...',
                    )),
                SizedBox(height: size * 1.2),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return textLoading(size);
                    }
                    final orders = controller.filteredCustomers;
                    if (orders.isEmpty) {
                      return textNoData(size, message: 'No Customer data.');
                    }
                    return ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final customer = orders[index];
                        final status = customer.status;
                        final statusColor =
                            status.toLowerCase().contains('processing')
                                ? skyBlue
                                : status.toLowerCase().contains('waiting')
                                    ? amber
                                    : sageTeal;
                        return orderListCard(
                          size: size,
                          leadingIcon: Icons.store_rounded,
                          accentColor: amber,
                          title: customer.name,
                          subtitle: customer.customerCode,
                          subtitleIcon: Icons.qr_code_rounded,
                          trailingTop: customer.items,
                          trailingBottom: status.isNotEmpty
                              ? '${status[0].toUpperCase()}${status.substring(1)}'
                              : '-',
                          trailingBottomColor: statusColor,
                          onTap: () => controller.openDetail(customer),
                        );
                      },
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
}
