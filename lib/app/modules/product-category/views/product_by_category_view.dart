import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ============ INTERNAL IMPORTS ============
import 'package:getx_project/app/global/widget/product_by_filter_view.dart';
import '../../../routes/app_pages.dart';
import '../controllers/product_by_category_controller.dart';

class ProductByCategoryView extends GetView<ProductByCategoryController> {
  const ProductByCategoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProductByFilterView(
      backRoute: AppPages.productCategory,
      headerIcon: Icons.category_outlined,
      headerLabel: "Product Category",
      entityName: controller.currentCategory.name,
      entityCode: controller.currentCategory.initialCode,
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
