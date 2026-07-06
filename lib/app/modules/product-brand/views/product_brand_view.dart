// ============ PACKAGE IMPORTS ============
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ============ INTERNAL IMPORTS ============
import 'package:getx_project/app/data/models/product_brand_model.dart';
import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/global/widget/master_list_view.dart';
import 'package:getx_project/app/modules/product-brand/controllers/product_brand_controller.dart';
import 'package:getx_project/app/routes/app_pages.dart';

class ProductBrandView extends GetView<ProductBrandController> {
  const ProductBrandView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MasterListView<ProductBrandModel>(
      title: "Brand",
      icon: Icons.label_outline,
      routeBackName: AppPages.homePage,
      isLoading: controller.isLoading,
      isSearchFocused: controller.isSearchFocused,
      isAscending: controller.isAscending,
      cursorNext: controller.cursorNext,
      limit: controller.limit,
      items: controller.orders,
      hasError: controller.hasError,
      searchController: controller.searchController,
      searchFocus: controller.searchFocus,
      onRefresh: controller.loadBrands,
      onSearchChanged: controller.onSearchChanged,
      onToggleSort: controller.toggleSort,
      onLoadMore: controller.loadMore,
      onApplyLimit: (value) {
        controller.limit.value = value;
        controller.applyFilter();
      },
      onClearFilter: controller.clearFilter,
      emptyMessage: "No brand data.",
      itemBuilder: (context, brand) {
        final size = SizeConfig.defaultSize;
        final code = brand.initialCode.trim().isNotEmpty
            ? brand.initialCode.trim().toUpperCase()
            : masterMonogram(brand.name);
        final hasSlug = brand.slug.trim().isNotEmpty;
        return masterListCard(
          size: size,
          accent: getAccentColor2(brand.name),
          avatarText: code,
          title: brand.name,
          subtitle: hasSlug ? brand.slug : 'Tap to view products',
          onTap: () => controller.openDetail(brand),
        );
      },
    );
  }
}
