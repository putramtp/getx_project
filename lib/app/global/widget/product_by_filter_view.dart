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

import '../accent.dart';
import 'accent_header_card.dart';
import 'app_header.dart';
/// Shared "products filtered by a master entity" list screen — used by both the
/// by-Category and by-Brand views, which are otherwise identical. Callers pass
/// the gradient-header identity (icon/label/name/code), the reactive state, and
/// the row callbacks.
class ProductByFilterView extends StatelessWidget {

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
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final double size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appHeader('Products', accent: AppAccent.slate, icon: headerIcon, subtitle: '${headerLabel.replaceFirst('Product ', '')} · $entityName'),
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
                          return NoMoreDataFooter(size: size);
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
    return accentHeaderCard(
      size: size,
      accent: AppAccent.slate,
      icon: headerIcon,
      label: headerLabel,
      title: entityName,
      code: entityCode,
    );
  }
}
