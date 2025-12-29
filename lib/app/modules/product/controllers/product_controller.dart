import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'product_detail.controller.dart';
import 'product_transaction_list_controller.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/product_summary_model.dart';
import '../../../routes/app_pages.dart';
import '../../../data/providers/product_provider.dart';

class ProductController extends GetxController {
  Timer? _debounce;
  final provider = Get.find<ProductProvider>();

  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  // data
  var productSummaries = <ProductSummaryModel>[].obs;
  var filteredProductSummaries = <ProductSummaryModel>[].obs;

  // State
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs; // ⭐ add no-more-data indicator
  var isAscending = true.obs;
  var isSearchFocused = false.obs;
  var totalProducts = 0.obs;
  var stockInHand = 0.obs;
  var isSearching = false.obs;
  var isStillSearch = false.obs;

  // Cursors
  final RxnString cursorNext = RxnString();
  final RxnString cursorPrev = RxnString();

  @override
  void onInit() {
    loadProducts();
    super.onInit();
  }

  @override
  void onClose() {
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

  Future<void> loadProducts() async {
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getProductSummaries(),
    );
    if (res == null) return;

    if (res['data'] == null) {
      productSummaries.clear();
      return;
    }

    final List rawList = res['data'] ?? [];
    totalProducts.value = res['total'] ?? 0;
    stockInHand.value = safeToInt(res['stock_in_hand']);

      // Assign cursors ⭐
    cursorNext.value = res['next_cursor'];
    cursorPrev.value = res['prev_cursor'];

    // If backend says no more pages
    hasMore.value = cursorNext.value != null;

    final mapped = rawList.map((e) => ProductSummaryModel.fromJson(e)).toList();

    productSummaries.assignAll(mapped);
    filteredProductSummaries.assignAll(mapped);
  }

    // LOAD NEXT PAGE
  Future<void> loadMore() async {
    if (!hasMore.value) return; // ⭐ stop if no more data
    if (cursorNext.value == null) return; // no cursor → stop
    if (isLoadingMore.value) return; // avoid double loads

    final res = await ApiExecutor.run(
      isLoading: isLoadingMore,
      task: () => provider.getProductSummaries(cursor: cursorNext.value),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

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
    filteredProductSummaries.assignAll(productSummaries);
  }


  void toggleSort() {
    isAscending.value = !isAscending.value;
    filteredProductSummaries.sort((a, b) => isAscending.value
        ? a.itemName.compareTo(b.itemName)
        : b.itemName.compareTo(a.itemName));
    filteredProductSummaries.refresh();
  }

  void onSearchChanged(String value) {
    isStillSearch.value = value.isEmpty ? false :true;
    filterList(value);
  }

  void filterList(String value) {
    final query = value.trim().toLowerCase();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        filteredProductSummaries.assignAll(productSummaries);
      } else {
        filteredProductSummaries.assignAll(
          productSummaries.where((item) {
            final name = item.itemName.trim().toLowerCase();
            final code = item.itemCode.trim().toLowerCase();
            return name.contains(query) || code.contains(query);
          }).toList(),
        );
      }
    });
  }

  void openDetail(ProductSummaryModel product) {
    if (Get.isRegistered<ProductDetailController>()) {
      Get.delete<ProductDetailController>(force: true);
    }
    Get.toNamed(AppPages.productDetailPage, arguments: product);
  }

  void openTransaction(ProductSummaryModel product) {
    if (Get.isRegistered<ProductTransactionListController>()) {
      Get.delete<ProductTransactionListController>(force: true);
    }
    Get.toNamed(AppPages.productTransactionListPage, arguments: product);
  }

  // @override
  // void onReady() {
  //   super.onReady();
  // }

  // @override
  // void onClose() {
  //   super.onClose();
  // }
}
