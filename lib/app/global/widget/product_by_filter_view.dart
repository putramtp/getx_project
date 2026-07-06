// ============ PACKAGE IMPORTS ============
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ============ INTERNAL IMPORTS ============
import 'package:getx_project/app/data/models/product_summary_model.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';
import 'package:getx_project/app/global/variables.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';
import 'package:getx_project/app/global/widget/product_tile.dart';
import 'package:getx_project/app/global/widget/search_bar.dart';
import 'package:getx_project/app/global/widget/skeleton_widgets.dart';

/// Shared "products filtered by a master entity" list screen — used by both the
/// by-Category and by-Brand views, which are otherwise identical. Callers pass
/// the gradient-header identity (icon/label/name/code), the reactive state, and
/// the row callbacks.
class ProductByFilterView extends StatelessWidget {
  final String backRoute;

  // Header identity
  final IconData headerIcon;
  final String headerLabel; // e.g. "Product Category"
  final String entityName;
  final String entityCode;

  // Reactive state (owned by the caller's controller)
  final RxBool isLoading;
  final RxBool isSearchFocused;
  final RxBool isAscending;
  final RxnString cursorNext;
  final RxList<ProductSummaryModel> items;

  /// Optional load-failure flag. When true and [items] is empty, an error+retry
  /// state is shown instead of the empty state.
  final RxBool? hasError;

  /// Called when the user taps Retry on the error state.
  final Future<void> Function() onRetry;

  // Text input
  final TextEditingController searchController;
  final FocusNode searchFocus;

  // Callbacks
  final void Function(String value) onSearchChanged;
  final VoidCallback onToggleSort;
  final VoidCallback onLoadMore;
  final void Function(ProductSummaryModel product) onViewDetail;
  final void Function(ProductSummaryModel product) onViewTransaction;

  const ProductByFilterView({
    Key? key,
    required this.backRoute,
    required this.headerIcon,
    required this.headerLabel,
    required this.entityName,
    required this.entityCode,
    required this.isLoading,
    required this.isSearchFocused,
    required this.isAscending,
    required this.cursorNext,
    required this.items,
    this.hasError,
    required this.onRetry,
    required this.searchController,
    required this.searchFocus,
    required this.onSearchChanged,
    required this.onToggleSort,
    required this.onLoadMore,
    required this.onViewDetail,
    required this.onViewTransaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBarOrder("Product", size,
          icon: Icons.shopping_bag_outlined,
          routeBackName: backRoute,
          color1: navyDark,
          color2: sageGreen),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            children: [
              _buildHeaderGradient(size),
              const SizedBox(height: 6),
              Obx(() => SearchBarWidget(
                    isFocused: isSearchFocused.value,
                    isAscending: isAscending.value,
                    searchController: searchController,
                    focusNode: searchFocus,
                    onSearchChanged: onSearchChanged,
                    onToggleSort: onToggleSort,
                    hintText: 'Search products...',
                  )),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  if (isLoading.value) {
                    return skeletonGenericList(size);
                  }
                  final products = items;
                  if ((hasError?.value ?? false) && products.isEmpty) {
                    return errorRetry(size, onRetry: onRetry, accent: navyMid);
                  }
                  if (products.isEmpty) {
                    return Center(
                      child: Text(
                        "No products available.",
                        style: AppTextStyle.custom(size,
                            scale: 1.4, weight: FontWeight.w400),
                      ),
                    );
                  }
                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 250) {
                        onLoadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      itemCount: products.length + 1,
                      itemBuilder: (context, index) {
                        if (index < products.length) {
                          final productSummary = products[index];
                          return ProductTile(
                            product: productSummary,
                            size: size,
                            onViewDetail: () => onViewDetail(productSummary),
                            onViewTransaction: () =>
                                onViewTransaction(productSummary),
                          );
                        }
                        if (cursorNext.value != null) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: size * 3),
                            child: const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child:
                                    CircularProgressIndicator(strokeWidth: 3),
                              ),
                            ),
                          );
                        }
                        if (cursorNext.value == null && products.isNotEmpty) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: size * 3),
                            child: Center(
                              child: Text(
                                "No more data.",
                                style: AppTextStyle.custom(size,
                                    scale: 1.4,
                                    color: Colors.grey,
                                    weight: FontWeight.w500),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderGradient(double size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navyMid, skyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(headerIcon, color: Colors.white, size: size * 3),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headerLabel,
                    style: AppTextStyle.custom(size,
                        scale: 1.5, color: Colors.white70)),
                Text(
                  "$entityName ",
                  style: AppTextStyle.h4(size,
                      color: Colors.white, weight: FontWeight.bold),
                ),
                Text(
                  "#$entityCode ",
                  style: AppTextStyle.h4(size,
                      color: Colors.white, weight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
