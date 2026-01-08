import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:getx_project/app/global/widget/top_filter_popup.dart';
import '../controllers/receive_order_list_detail_controller.dart';
import '../../../global/alert.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/receive_order_model.dart';
import '../../../data/providers/receive_order_provider.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderListController extends GetxController  implements TopFilterController  {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  // Data
  var orders = <ReceiveOrderModel>[].obs;
  var filteredOrders = <ReceiveOrderModel>[].obs;


  // State
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs; // ⭐ add no-more-data indicator
  var isAscending = true.obs;
  var isSearchFocused = false.obs;
  final RxnString filterStatus = RxnString();

  // Cursors
  final RxnString cursorNext = RxnString();
  final RxnString cursorPrev = RxnString();

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
    loadReceiveOrders();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  void toggleSort() {
    isAscending.value = !isAscending.value;
    filteredOrders.sort((a, b) => isAscending.value
        ? a.code.compareTo(b.code)
        : b.code.compareTo(a.code));
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
  Future<void> loadReceiveOrders() async {
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getReceiveOrders(cursor: null,params: buildParams()),
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

    final mapped = rawList.map((e) => ReceiveOrderModel.fromJson(e)).toList();

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
      task: () => provider.getReceiveOrders(cursor: cursorNext.value, params:buildParams()),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

    final List rawList = res['data'] ?? [];
    final newOrders = rawList.map((e) => ReceiveOrderModel.fromJson(e)).toList();

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
          return order.code.toLowerCase().contains(lowerQuery) ||
              order.supplier.toLowerCase().contains(lowerQuery);
        }).toList(),
      );
    }
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
      if (startDate.value != null)
        'start_date': getDateString(startDate.value!),
      if (endDate.value != null)
        'end_date': getDateString(endDate.value!), 
      // if (enablePriceRange.value) ...{
      //   'min_price': minPrice.value.toString(),
      //   'max_price': maxPrice.value.toString(),
      // },
    };
  }

  @override
  void applyFilter() {
    loadReceiveOrders();
  }

  /// ♻️ Clear date filter
  @override
  void clearFilter () {
    limit.value = 20;
    startDate.value = null;
    endDate.value = null;
    loadReceiveOrders();
    infoAlertBottom(title: 'Filter deleted', 'Filter has been reset.');
  }

  @override
  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void openDetail(ReceiveOrderModel order) {
    if (Get.isRegistered<ReceiveOrderListDetailController>()) {
      Get.delete<ReceiveOrderListDetailController>(force: true);
    }
    Get.toNamed(AppPages.receiveOrderListDetailPage, arguments: order);
  }

}
