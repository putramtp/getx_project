import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/order_list_widgets.dart';
import '../../../global/widget/search_bar.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../routes/app_pages.dart';
import '../controllers/delivery_list_controller.dart';

class DeliveryListView extends GetView<DeliveryListController> {
  const DeliveryListView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appBarOrder("Deliveries", size,
          icon: Icons.local_shipping_rounded,
          routeBackName: AppPages.outflowHomePage,
          color1: steelBlue, color2: lightSteelBlue),
      body: RefreshIndicator(
        onRefresh: controller.loadDeliveries,
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
                      hintText: 'Search code / customer...',
                    )),
                SizedBox(height: size * 1.2),
                _statusChips(size),
                SizedBox(height: size * 1.2),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return skeletonOrderList(size, accent: steelBlue);
                    }
                    final deliveries = controller.deliveries;
                    if (controller.hasError.value && deliveries.isEmpty) {
                      return errorRetry(size, onRetry: controller.loadDeliveries, accent: steelBlue);
                    }
                    if (deliveries.isEmpty) {
                      return textNoData(size, message: "No deliveries found.");
                    }
                    return ListView.builder(
                      itemCount: deliveries.length,
                      itemBuilder: (context, index) {
                        final d = deliveries[index];
                        return orderListCard(
                          size: size,
                          leadingIcon: Icons.local_shipping_rounded,
                          accentColor: steelBlue,
                          title: d.code,
                          subtitle: d.customer,
                          subtitleIcon: Icons.person_outline_rounded,
                          dateText: controller.formatEstimate(d),
                          trailingBottom: d.statusName,
                          trailingBottomColor: controller.colorForStatus(d.statusId),
                          onTap: () => controller.openDetail(d),
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

  /// Horizontal "All / <status>" filter chips, colored per status.
  Widget _statusChips(double size) {
    return Obx(() {
      final options = controller.statusOptions;
      if (options.isEmpty) return const SizedBox.shrink();
      final selected = controller.statusFilter.value;
      return SizedBox(
        height: size * 4,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _chip(size, "All", selected == null, steelBlue,
                () => controller.setStatusFilter(null)),
            ...options.map((s) {
              final color = controller.colorForStatus(s.id);
              return _chip(size, s.name, selected == s.id, color,
                  () => controller.setStatusFilter(s.id));
            }),
          ],
        ),
      );
    });
  }

  Widget _chip(double size, String label, bool active, Color color,
      VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(right: size * 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size * 2),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: size * 1.6, vertical: size * 0.8),
            decoration: BoxDecoration(
              color: active ? color : Colors.white,
              borderRadius: BorderRadius.circular(size * 2),
              border: Border.all(color: color.withOpacity(active ? 1 : 0.4)),
            ),
            child: Center(
              child: Text(label,
                  style: AppTextStyle.small(size,
                          color: active ? Colors.white : color)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: size * 1.3)),
            ),
          ),
        ),
      ),
    );
  }
}
