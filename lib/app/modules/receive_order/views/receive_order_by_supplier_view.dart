import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/receive_order_by_supplier_controller.dart';
import '../../../global/size_config.dart';
import '../../../global/variables.dart';
import '../../../global/widget/search_bar.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderBySupplierView extends GetView<ReceiveOrderBySupplierController> {
  const ReceiveOrderBySupplierView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Supplier List", size,
          icon: Icons.group_rounded,
          routeBackName: AppPages.receiveHomePage,
          color1: sageTeal, color2: sageTealLight),
      body: RefreshIndicator(
        onRefresh: controller.loadSuppliers,
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
                      hintText: 'Search Supplier',
                    )),
                SizedBox(height: size * 1.2),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return skeletonOrderList(size, accent: sageTeal);
                    }
                    final orders = controller.filteredSuppliers;
                    if (controller.hasError.value && orders.isEmpty) {
                      return errorRetry(size, onRetry: controller.loadSuppliers, accent: sageTeal);
                    }
                    if (orders.isEmpty) {
                      return textNoData(size, message: "No supplier data.");
                    }
                    return ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final supplier = orders[index];
                        final status = supplier.status;
                        final statusColor =
                            status.toLowerCase().contains('processing')
                                ? skyBlue
                                : status.toLowerCase().contains('waiting')
                                    ? amber
                                    : sageTeal;
                        return orderListCard(
                          size: size,
                          leadingIcon: Icons.store_rounded,
                          accentColor: sageTeal,
                          title: supplier.name,
                          subtitle: supplier.code,
                          subtitleIcon: Icons.qr_code_rounded,
                          trailingTop: supplier.items,
                          trailingBottom: status.isNotEmpty
                              ? '${status[0].toUpperCase()}${status.substring(1)}'
                              : '-',
                          trailingBottomColor: statusColor,
                          onTap: () => controller.openDetail(supplier),
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
