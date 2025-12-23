import 'package:getx_project/app/data/models/product_unit_model.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getx_project/app/data/providers/product_provider.dart';
import 'package:getx_project/app/helpers/api_excecutor.dart';

class ProductUnitController extends GetxController {
  final ProductProvider provider = Get.find<ProductProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  // Data
  var orders = <ProductUnitModel>[].obs;
  var filteredOrders = <ProductUnitModel>[].obs;

  // State
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs; // ⭐ add no-more-data indicator
  var isAscending = true.obs;
  var isSearchFocused = false.obs;

  // Cursors
  final RxnString cursorNext = RxnString();
  final RxnString cursorPrev = RxnString();


  // Scroll listener
  final ScrollController scrollController = ScrollController(debugLabel:'ProductUnitController' );

  @override
  void onInit() {
    super.onInit();
    searchFocus.addListener(() {
      isSearchFocused.value = searchFocus.hasFocus;
    });
    scrollController.addListener(_scrollListener);
    loadCategories();
  }

  // Auto loading
  void _scrollListener() {
    if(!scrollController.hasClients) return;
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 250) loadMore();
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    searchController.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  void toggleSort() {
    isAscending.value = !isAscending.value;
    filteredOrders.sort((a, b) => isAscending.value
        ? a.name.compareTo(b.name)
        : b.name.compareTo(a.name));
    filteredOrders.refresh();
  }

  void clearSearch() {
    searchController.clear();
    searchFocus.unfocus();
  }

  void onSearchChanged(String value) {
    filterList(value);
  }

  // FIRST LOAD
  Future<void> loadCategories() async {
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getProductCategories(cursor: null),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

    // Reset hasMore
    hasMore.value = true;

    if (res['data'] == null) {
      orders.clear();
      filteredOrders.clear();
      cursorNext.value = null;
      cursorPrev.value = null;
      hasMore.value = false;
      return;
    }

    final List rawList = res['data'] ?? [];

    // Assign cursors ⭐
    cursorNext.value = res['next_cursor'];
    cursorPrev.value = res['prev_cursor'];

    // If backend says no more pages
    hasMore.value = cursorNext.value != null;

    final mapped = rawList.map((e) => ProductUnitModel.fromJson(e)).toList();

    orders.assignAll(mapped);
    filteredOrders.assignAll(mapped);
  }

  // LOAD NEXT PAGE
  Future<void> loadMore() async {
    if (!hasMore.value) return; // ⭐ stop if no more data
    if (cursorNext.value == null) return; // no cursor → stop
    if (isLoadingMore.value) return; // avoid double loads

    final res = await ApiExecutor.run(
      isLoading: isLoadingMore,
      task: () => provider.getProductCategories(cursor: cursorNext.value),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

    final List rawList = res['data'] ?? [];
    final newOrders = rawList.map((e) => ProductUnitModel.fromJson(e)).toList();

    // ⭐ Update next cursor
    cursorNext.value = res['next_cursor'];
    cursorPrev.value = res['prev_cursor'];

    // If response returns null cursor → no more data
    if (cursorNext.value == null) {
      hasMore.value = false;
    }

    orders.addAll(newOrders);
    filteredOrders.assignAll(orders);
  }

  String formatYmd(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date).toString();
  }

  /// 🔍 Filter list by PO number
  void filterList(String query) {
    if (query.isEmpty) {
      filteredOrders.assignAll(orders);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredOrders.assignAll(
        orders.where((order) {
          return order.name.toLowerCase().contains(lowerQuery) ||
              order.description.toLowerCase().contains(lowerQuery);
        }).toList(),
      );
    }
  }

  void openDetail(ProductUnitModel unit) {
    Get.defaultDialog(
      title: unit.name,
      titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400,color: Colors.blueGrey),
      content: Text(unit.description),
      titlePadding: const EdgeInsets.all(12.0),
      contentPadding:   const EdgeInsets.fromLTRB(16, 0, 16, 20),
    );
  }

}
