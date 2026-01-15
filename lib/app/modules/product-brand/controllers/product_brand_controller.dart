import 'package:flutter/material.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
//=========== INTERNAL IMPORTS ============
import 'package:getx_project/app/data/models/product_brand_model.dart';
import 'package:getx_project/app/data/providers/product_provider.dart';
import 'package:getx_project/app/helpers/api_excecutor.dart';
import 'package:getx_project/app/modules/product-brand/controllers/product_by_brand_controller.dart';
import 'package:getx_project/app/routes/app_pages.dart';

class ProductBrandController extends GetxController {
  final ProductProvider provider = Get.find<ProductProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  // Data
  var orders = <ProductBrandModel>[].obs;

  // State
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
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
    loadBrands();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  void toggleSort() {
    isAscending.value = !isAscending.value;
    orders.sort((a, b) => isAscending.value
        ? a.name.compareTo(b.name)
        : b.name.compareTo(a.name));
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
    loadBrands();
    infoAlertBottom(title: 'Filter deleted', 'Filter has been reset.');
  }

  void onSearchChanged(String value) {
    searchQuery.value = value.trim();
    loadBrands();
  }

  Map<String, String> buildParams() {
    return {
      'limit': limit.value.toString(),
      if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
    };
  }

  void applyFilter() {
    loadBrands();
  }

  // FIRST LOAD
  Future<void> loadBrands() async {
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getProductBrands(cursor: null,params: buildParams()),
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

    final mapped = rawList.map((e) => ProductBrandModel.fromJson(e)).toList();

    orders.assignAll(mapped);
  }

  // LOAD NEXT PAGE
  Future<void> loadMore() async {
    if (!hasMore.value) return; // ⭐ stop if no more data
    if (cursorNext.value == null) return; // no cursor → stop
    if (isLoadingMore.value) return; // avoid double loads

    final res = await ApiExecutor.run(
      isLoading: isLoadingMore,
      task: () => provider.getProductBrands(cursor: cursorNext.value),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

    final List rawList = res['data'] ?? [];
    final newOrders = rawList.map((e) => ProductBrandModel.fromJson(e)).toList();

    // ⭐ Update next cursor
    cursorNext.value = res['next_cursor'];

    // If response returns null cursor → no more data
    if (cursorNext.value == null) {
      hasMore.value = false;
    }

    orders.addAll(newOrders);
  }

  String formatYmd(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date).toString();
  }


  void openDetail(ProductBrandModel brand) {
    if (Get.isRegistered<ProductByBrandController>()) {
      Get.delete<ProductByBrandController>(force: true);
    }
    Get.toNamed(AppPages.productByBrand, arguments: brand);
  }
}
