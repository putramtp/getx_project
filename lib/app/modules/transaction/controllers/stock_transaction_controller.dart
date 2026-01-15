import 'dart:async';
import 'package:getx_project/app/data/providers/stock_transaction_provider.dart';
import 'package:getx_project/app/global/widget/top_filter_popup.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:getx_project/app/data/models/stock_transaction_model.dart';
import '../../../global/alert.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';

class StockTransactionController extends GetxController implements TopFilterController {
  final StockTransactionProvider provider = Get.find<StockTransactionProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  // Data
  var trans = <StockTransactionModel>[].obs;

  // State
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs; // ⭐ add no-more-data indicator
  var isAscending = true.obs;
  var isSearchFocused = false.obs;
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
  RxDouble maxPrice = 1000000.0.obs;
  @override
  final enablePriceRange = false.obs;

  @override
  void onInit() {
    super.onInit();
    searchFocus.addListener(() {
      isSearchFocused.value = searchFocus.hasFocus;
    });
    loadstockTransactions();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  void toggleSort() {
    isAscending.value = !isAscending.value;
    trans.sort((a, b) => isAscending.value
        ? a.productName.compareTo(b.productName)
        : b.productName.compareTo(a.productName));
    trans.refresh();
  }

  void clearSearch() {
    searchController.clear();
    searchFocus.unfocus();
  }


  // FIRST LOAD
  Future<void> loadstockTransactions() async {
    cursorNext.value = null;
    hasMore.value = true;
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getStockTransactions(cursor: null,params: buildParams()),
    );

     if (res == null || res['data'] == null) {
      trans.clear();
      return;
    }

    final List rawList = res['data'] ?? [];

    // Assign cursors ⭐
    cursorNext.value = res['next_cursor'];

    // If backend says no more pages
    hasMore.value = cursorNext.value != null;
    
    trans.assignAll(rawList.map((e) => StockTransactionModel.fromJson(e)).toList());
  }

  // LOAD NEXT PAGE
  Future<void> loadMore() async {
    if (!hasMore.value || cursorNext.value == null || isLoadingMore.value) return;

    final res = await ApiExecutor.run(
      isLoading: isLoadingMore,
      task: () => provider.getStockTransactions(cursor: cursorNext.value,params: buildParams()),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

    final List rawList = res['data'] ?? [];
    final newOrders = rawList.map((e) => StockTransactionModel.fromJson(e)).toList();

    // ⭐ Update next cursor
    cursorNext.value = res['next_cursor'];

    // If response returns null cursor → no more data
    hasMore.value = cursorNext.value != null;

    trans.addAll(newOrders);
  }

  String formatYmd(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date).toString();
  }

   void onSearchChanged(String value) {
    searchQuery.value = value.trim();
    loadstockTransactions();
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
      if (startDate.value != null)  'start_date': getDateString(startDate.value!),
      if (endDate.value != null)    'end_date': getDateString(endDate.value!), 
    };
  }

  @override
  void applyFilter() {
    loadstockTransactions();
  }

  /// ♻️ Clear date filter
  @override
  void clearFilter () {
    limit.value = 20;
    startDate.value = null;
    endDate.value = null;
    searchQuery.value = '';
    searchController.clear();
    loadstockTransactions();
    infoAlertBottom(title: 'Filter deleted', 'Filter has been reset.');
  }

  @override
  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void openDetail(StockTransactionModel order) {
    // if (Get.isRegistered<ReceiveOrderListDetailController>()) {
    //   Get.delete<ReceiveOrderListDetailController>(force: true);
    // }
    // Get.toNamed(AppPages.receiveOrderListDetailPage, arguments: order);
  }
}
