import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ============ INTERNAL IMPORTS ============
import 'package:getx_project/app/global/widget/product_by_filter_view.dart';
import 'package:getx_project/app/modules/product-brand/controllers/product_by_brand_controller.dart';
import '../../../routes/app_pages.dart';

class ProductByBrandView extends GetView<ProductByBrandController> {
  const ProductByBrandView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProductByFilterView(
      backRoute: AppPages.productBrand,
      headerIcon: Icons.label_outline,
      headerLabel: "Product Brand",
      entityName: controller.currentBrand.name,
      entityCode: controller.currentBrand.initialCode,
      isLoading: controller.isLoading,
      isSearchFocused: controller.isSearchFocused,
      isAscending: controller.isAscending,
      cursorNext: controller.cursorNext,
      items: controller.filteredProductSummaries,
      hasError: controller.hasError,
      onRetry: controller.loadProducts,
      searchController: controller.searchController,
      searchFocus: controller.searchFocus,
      onSearchChanged: controller.onSearchChanged,
      onToggleSort: controller.toggleSort,
      onLoadMore: controller.loadMore,
      onViewDetail: controller.openDetail,
      onViewTransaction: controller.openTransaction,
    );
  }
}
