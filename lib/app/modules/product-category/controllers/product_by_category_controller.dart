import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/helpers/list_reload_guard.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ============ INTERNAL IMPORTS ============
import 'package:getx_project/app/data/models/product_category_model.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/modules/product/controllers/product_detail.controller.dart';
import 'package:getx_project/app/helpers/api_excecutor.dart';
import 'package:getx_project/app/data/models/product_summary_model.dart';
import 'package:getx_project/app/modules/product/controllers/product_transaction_list_controller.dart';
import 'package:getx_project/app/routes/app_pages.dart';
import 'package:getx_project/app/data/providers/product_provider.dart';

class ProductByCategoryController extends GetxController with ListReloadGuard {
  Timer? _debounce;
  final provider = Get.find<ProductProvider>();

  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  // data
  var productSummaries = <ProductSummaryModel>[].obs;
  var filteredProductSummaries = <ProductSummaryModel>[].obs;
  late final ProductCategoryModel currentCategory;

  // State
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasError = false.obs;
  var hasMore = true.obs; // ⭐ add no-more-data indicator
  var isAscending = true.obs;
  var isSearchFocused = false.obs;
  var isSearching = false.obs;
  var isStillSearch = false.obs;

  // Cursors
  final RxnString cursorNext = RxnString();
  final RxnString cursorPrev = RxnString();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is ProductCategoryModel){
        currentCategory = args;
        loadProducts();
    }else {
      errorAlert("⚠️ Invalid or missing arguments in ProductByCategoryController: $args");
    }
  }

  @override
  void onClose() {
    _debounce?.cancel(); // a search typed just before Back must not fire
    searchController.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  void startSearch() {
    isSearching.value = true;
  }

  void stopSearch() {
    isSearching.value = false;
    searchController.clear();
    Get.focusScope?.unfocus();
    filterList("");
  }

  void clearSearched() {
    isStillSearch.value = false;
    searchController.clear();
    filterList("");
  }

  Future<void> loadProducts() => guardReload(isLoading, _loadProducts);

  Future<void> _loadProducts() async {
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      hasError: hasError,
      task: () => provider.getProductSummariesByCategory(catId: currentCategory.id),
    );
    if (res == null) return;

    if (res['data'] == null) {
      productSummaries.clear();
      _applyView();
      return;
    }

    final List rawList = res['data'] ?? [];


      // Assign cursors ⭐
    cursorNext.value = res['next_cursor'];
    cursorPrev.value = res['prev_cursor'];

    // If backend says no more pages
    hasMore.value = cursorNext.value != null;

    final mapped = rawList.map((e) => ProductSummaryModel.fromJson(e)).toList();

    productSummaries.assignAll(mapped);
    _applyView();
  }

    // LOAD NEXT PAGE
  Future<void> loadMore() async {
    if (isLoading.value || !mayLoadMore) return; // a reload owns the list; or a page just failed
    final generation = listGeneration;
    if (!hasMore.value) return; // ⭐ stop if no more data
    if (cursorNext.value == null) return; // no cursor → stop
    if (isLoadingMore.value) return; // avoid double loads

    final res = await ApiExecutor.run(
      isLoading: isLoadingMore,
      task: () => provider.getProductSummariesByCategory(catId: currentCategory.id,cursor: cursorNext.value),
    );
    // If network failed or exception handled, data is null
    // A reload started meanwhile: this page belongs to the old query.
    if (res == null) return noteLoadMoreFailed();
    if (!isCurrentPage(generation)) return;

    final List rawList = res['data'] ?? [];
    final newOrders = rawList.map((e) => ProductSummaryModel.fromJson(e)).toList();

    // ⭐ Update next cursor
    cursorNext.value = res['next_cursor'];
    cursorPrev.value = res['prev_cursor'];

    // If response returns null cursor → no more data
    if (cursorNext.value == null) {
      hasMore.value = false;
    }

    productSummaries.addAll(newOrders);
    _applyView(); // a next page must not undo the search or the sort
  }


  /// The search typed, lower-cased; applied to every page loaded.
  String _query = '';

  /// Set once Sort is tapped; until then the server's order stands.
  bool _sortedByUser = false;

  void toggleSort() {
    isAscending.value = !isAscending.value;
    _sortedByUser = true;
    _applyView();
  }

  void onSearchChanged(String value) {
    isStillSearch.value = value.isEmpty ? false :true;
    filterList(value);
  }

  void filterList(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _query = value.trim().toLowerCase();
      _applyView();
    });
  }

  /// [filteredProductSummaries] = the loaded [productSummaries] matching the
  /// search, in the order Sort set — after a search, a sort, a reload or a
  /// next page alike.
  void _applyView() {
    final rows = productSummaries
        .where((item) =>
            _query.isEmpty ||
            item.itemName.trim().toLowerCase().contains(_query) ||
            item.itemCode.trim().toLowerCase().contains(_query))
        .toList();
    if (_sortedByUser) sortRowsBy(rows, (o) => o.itemName, ascending: isAscending.value);
    filteredProductSummaries.assignAll(rows);
  }

  void openDetail(ProductSummaryModel product) {
    openFresh<ProductDetailController>(AppPages.productDetailPage, arguments: product);
  }

  void openTransaction(ProductSummaryModel product) {
    openFresh<ProductTransactionListController>(AppPages.productTransactionListPage, arguments: product);
  }


}
