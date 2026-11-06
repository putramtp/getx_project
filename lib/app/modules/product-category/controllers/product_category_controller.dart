import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/helpers/list_reload_guard.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/modules/product-category/controllers/product_by_category_controller.dart';
import 'package:getx_project/app/routes/app_pages.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getx_project/app/data/models/product_category_model.dart';
import 'package:getx_project/app/data/providers/product_provider.dart';
import 'package:getx_project/app/helpers/api_excecutor.dart';

class ProductCategoryController extends GetxController with ListReloadGuard {
  final ProductProvider provider = Get.find<ProductProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  // Data
  var orders = <ProductCategoryModel>[].obs;

  // State
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasError = false.obs;
  var hasMore = true.obs; // ⭐ add no-more-data indicator
  var isAscending = true.obs;
  var isSearchFocused = false.obs;
  RxInt limit = 20.obs;
  final RxString searchQuery = ''.obs;

  // Cursors
  final RxnString cursorNext = RxnString();

  @override
  void onInit() {
    super.onInit();
    searchFocus.addListener(() {
      isSearchFocused.value = searchFocus.hasFocus;
    });
    loadCategories();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  /// Set once Sort is tapped: from then on the order is kept on every reload
  /// and next page ([_keepSort]); until then the server's order stands.
  bool _sortedByUser = false;

  void toggleSort() {
    isAscending.value = !isAscending.value;
    _sortedByUser = true;
    _keepSort();
  }

  /// Re-sorts the loaded rows the way Sort set them (see [sortRowsBy]).
  void _keepSort() {
    if (!_sortedByUser) return;
    sortRowsBy(orders, (o) => o.name, ascending: isAscending.value);
    orders.refresh();
  }

  void clearSearch() {
    searchController.clear();
    searchFocus.unfocus();
  }

  void clearFilter() {
    limit.value = 20;
    searchQuery.value = '';
    searchController.clear();
    loadCategories();
    infoAlertBottom(title: 'Filter deleted', 'Filter has been reset.');
  }

  void onSearchChanged(String value) {
    searchQuery.value = value.trim();
    loadCategories();
  }

  Map<String, String> buildParams() {
    return {
      'limit': limit.value.toString(),
      if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
    };
  }

  void applyFilter() {
    loadCategories();
  }

  // FIRST LOAD
  Future<void> loadCategories() => guardReload(isLoading, _loadCategories);

  Future<void> _loadCategories() async {
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      hasError: hasError,
      task: () =>
          provider.getProductCategories(cursor: null, params: buildParams()),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

    // Reset hasMore
    hasMore.value = true;

    if (res['data'] == null) {
      orders.clear();
      cursorNext.value = null;
      hasMore.value = false;
      return;
    }

    final List rawList = res['data'] ?? [];

    // Assign cursors ⭐
    cursorNext.value = res['next_cursor'];

    // If backend says no more pages
    hasMore.value = cursorNext.value != null;

    final mapped =
        rawList.map((e) => ProductCategoryModel.fromJson(e)).toList();

    orders.assignAll(mapped);
    _keepSort();
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
      task: () => provider.getProductCategories(cursor: cursorNext.value, params: buildParams()),
    );
    // If network failed or exception handled, data is null
    // A reload started meanwhile: this page belongs to the old query.
    if (res == null) return noteLoadMoreFailed();
    if (!isCurrentPage(generation)) return;

    final List rawList = res['data'] ?? [];
    final newOrders =
        rawList.map((e) => ProductCategoryModel.fromJson(e)).toList();

    // ⭐ Update next cursor
    cursorNext.value = res['next_cursor'];

    // If response returns null cursor → no more data
    if (cursorNext.value == null) {
      hasMore.value = false;
    }

    orders.addAll(newOrders);
    _keepSort();
  }

  String formatYmd(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date).toString();
  }

  void openDetail(ProductCategoryModel category) {
    openFresh<ProductByCategoryController>(AppPages.productByCategory, arguments: category);
  }
}
