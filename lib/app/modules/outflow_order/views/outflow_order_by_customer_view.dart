import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/widget/app_header.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/search_bar.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../modules/outflow_order/controllers/outflow_order_by_customer_controller.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/skeleton_widgets.dart';

class OutflowOrderByCustomerView extends GetView<OutflowOrderByCustomerController> {
  const OutflowOrderByCustomerView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appHeader(controller.title, accent: controller.accent, icon: controller.icon),
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
                      hintText: controller.searchHint,
                    )),
                SizedBox(height: size * 1.2),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return skeletonOrderList(size, accent: controller.accent.base);
                    }
                    final orders = controller.filteredCustomers;
                    if (controller.hasError.value && orders.isEmpty) {
                      return errorRetry(size, onRetry: controller.loadCustomers, accent: controller.accent.base);
                    }
                    if (orders.isEmpty) {
                      return textNoData(size, message: controller.emptyMessage);
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
                          leadingIcon: controller.cardIcon,
                          accentColor: controller.accent.base,
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
