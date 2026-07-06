// ============ PACKAGE IMPORTS ============
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ============ INTERNAL IMPORTS ============
import 'package:getx_project/app/data/models/product_category_model.dart';
import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/global/widget/master_list_view.dart';
import 'package:getx_project/app/modules/product-category/controllers/product_category_controller.dart';
import 'package:getx_project/app/routes/app_pages.dart';

class ProductCategoryView extends GetView<ProductCategoryController> {
  const ProductCategoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MasterListView<ProductCategoryModel>(
      title: "Category",
      icon: Icons.category_outlined,
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
      onRefresh: controller.loadCategories,
      onSearchChanged: controller.onSearchChanged,
      onToggleSort: controller.toggleSort,
      onLoadMore: controller.loadMore,
      onApplyLimit: (value) {
        controller.limit.value = value;
        controller.applyFilter();
      },
      onClearFilter: controller.clearFilter,
      emptyMessage: "No category data.",
      itemBuilder: (context, category) {
        final size = SizeConfig.defaultSize;
        final code = category.initialCode.trim().isNotEmpty
            ? category.initialCode.trim().toUpperCase()
            : masterMonogram(category.name);
        final hasSlug = category.slug.trim().isNotEmpty;
        return masterListCard(
          size: size,
          accent: getAccentColor2(category.name),
          avatarText: code,
          title: category.name,
          subtitle: hasSlug ? category.slug : 'Tap to view products',
          onTap: () => controller.openDetail(category),
        );
      },
    );
  }
}
