import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/global/widget/top_filter_popup.dart';
import 'package:intl/intl.dart';

import 'product_detail.controller.dart';
import 'product_transaction_list_controller.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/product_summary_model.dart';
import '../../../routes/app_pages.dart';
import '../../../data/providers/product_provider.dart';

class ProductController extends GetxController  implements TopFilterController{
  Timer? _debounce;
  final provider = Get.find<ProductProvider>();

  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  // data
  var productSummaries = <ProductSummaryModel>[].obs;

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
  final RxString searchQuery = ''.obs;

  // Cursors
  final RxnString cursorNext = RxnString();

  // 🗓️ Date filter fields
  @override
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  @override
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  @override
  RxInt limit = 20.obs;
  @override
  RxDouble minPrice = 0.0.obs;
  @override
  RxDouble maxPrice = 100000000.0.obs;
  @override
  final enablePriceRange = false.obs;
  final qtyRemainingLessThan = RxnInt();


  @override
  void onInit() {
    searchFocus.addListener(() {
      isSearchFocused.value = searchFocus.hasFocus;
    });
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
    cursorNext.value = null;
    hasMore.value = true;

    final res = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getProductSummaries(cursor: null,params: buildParams()),
    );
   
    if (res == null || res['data'] == null) {
      productSummaries.clear();
      return;
    }

    final List rawList = res['data'] ?? [];
    totalProducts.value = res['total'] ?? 0;
    stockInHand.value = safeToInt(res['stock_in_hand']);

      // Assign cursors ⭐
    cursorNext.value = res['next_cursor'];

    // If backend says no more pages
    hasMore.value = cursorNext.value != null;

    productSummaries.assignAll(rawList.map((e) => ProductSummaryModel.fromJson(e)).toList());
  }

    // LOAD NEXT PAGE
  Future<void> loadMore() async {
    if (!hasMore.value || cursorNext.value == null || isLoadingMore.value) return;

    final res = await ApiExecutor.run(
      isLoading: isLoadingMore,
      task: () => provider.getProductSummaries(cursor: cursorNext.value,params: buildParams()),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

    final List rawList = res['data'] ?? [];
    final newProducts = rawList.map((e) => ProductSummaryModel.fromJson(e)).toList();

    // ⭐ Update next cursor
    cursorNext.value = res['next_cursor'];

    // If response returns null cursor → no more data
    hasMore.value = cursorNext.value != null;

    productSummaries.addAll(newProducts);
  }


  void toggleSort() {
    isAscending.value = !isAscending.value;
    productSummaries.sort((a, b) => isAscending.value
        ? a.itemName.compareTo(b.itemName)
        : b.itemName.compareTo(a.itemName));
    productSummaries.refresh();
  }



  void filterList(String value) {
    searchQuery.value = value.trim();
    isStillSearch.value = value.isNotEmpty;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final latestQuery = searchController.text.trim(); // latest
      searchQuery.value = latestQuery;
      loadProducts();
    });
  }

  // 📅 Pick start date
  @override
  Future<void> pickStartDate(BuildContext context) async {
    final picked = await pickDate(context, initialDate: startDate.value);
    if (picked != null) startDate.value = picked;
  }
  @override
  Future<void> pickEndDate(BuildContext context) async {
    final picked = await pickDate(context, initialDate: endDate.value);
    if (picked != null) endDate.value = picked;
  }

  Map<String, String> buildParams() {
    return {
      'limit': limit.value.toString(),
      if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
      if (qtyRemainingLessThan.value != null) 'qty_less_than': qtyRemainingLessThan.value.toString(),
      if (enablePriceRange.value) ...{
        'min_price': minPrice.value.toString(),
        'max_price': maxPrice.value.toString(),
      },
    };
  }

  @override
  void applyFilter() {
    loadProducts();
  }

  /// ♻️ Clear date filter
  @override
  void clearFilter () {
    limit.value = 20;
    startDate.value = null;
    endDate.value = null;
    qtyRemainingLessThan.value = null;
    searchQuery.value = '';
    searchController.clear();
    loadProducts();
    infoAlertBottom(title: 'Filter deleted', 'Filter has been reset.');
  }

  @override
  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
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
