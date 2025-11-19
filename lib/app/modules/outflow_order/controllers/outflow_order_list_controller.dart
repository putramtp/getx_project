import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/helpers/api_excecutor.dart';
import 'package:getx_project/app/models/outflow_order_model.dart';
import 'package:getx_project/app/modules/outflow_order/controllers/outflow_order_list_detail_controller.dart';
import 'package:getx_project/app/modules/outflow_order/providers/outflow_order_provider.dart';
import 'package:getx_project/app/routes/app_pages.dart';
import 'package:intl/intl.dart';

class OutflowOrderListController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  // Data
  var orders = <OutflowOrder>[].obs;
  var filteredOrders = <OutflowOrder>[].obs;

  // State
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs; // ⭐ add no-more-data indicator
  var isAscending = true.obs;
  var isSearchFocused = false.obs;

  // Cursors
  String? cursorNext;
  String? cursorPrev;

  // Date filter
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();

  // Scroll listener
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();

    searchFocus.addListener(() {
      isSearchFocused.value = searchFocus.hasFocus;
    });

    scrollController.addListener(_scrollListener);

    loadOutflowOrders();
  }

  // Auto loading
  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 250) {
      loadMore();
    }
  }

  // FIRST LOAD
  Future<void> loadOutflowOrders() async {
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getOutflowOrders(cursor: null),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

    // Reset hasMore
    hasMore.value = true;

    if (res['data'] == null) {
      orders.clear();
      filteredOrders.clear();
      cursorNext = null;
      cursorPrev = null;
      hasMore.value = false;
      return;
    }

    final List rawList = res['data'] ?? [];

    // Assign cursors ⭐
    cursorNext = res['next_cursor'];
    cursorPrev = res['prev_cursor'];

    // If backend says no more pages
    hasMore.value = cursorNext != null;

    final mapped = rawList.map((e) => OutflowOrder.fromJson(e)).toList();

    orders.assignAll(mapped);
    filteredOrders.assignAll(mapped);
  }

  // LOAD NEXT PAGE
  Future<void> loadMore() async {
    if (!hasMore.value) return; // ⭐ stop if no more data
    if (cursorNext == null) return; // no cursor → stop
    if (isLoadingMore.value) return; // avoid double loads

    final res = await ApiExecutor.run(
      isLoading: isLoadingMore,
      task: () => provider.getOutflowOrders(cursor: cursorNext),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

    final List rawList = res['data'] ?? [];
    final newOrders = rawList.map((e) => OutflowOrder.fromJson(e)).toList();

    // ⭐ Update next cursor
    cursorNext = res['next_cursor'];
    cursorPrev = res['prev_cursor'];

    // If response returns null cursor → no more data
    if (cursorNext == null) {
      hasMore.value = false;
    }

    orders.addAll(newOrders);
    filteredOrders.assignAll(orders);
  }

  // SEARCH
  void onSearchChanged(String query) {
    if (query.isEmpty) {
      filteredOrders.assignAll(orders);
      return;
    }

    final lower = query.toLowerCase();
    filteredOrders.assignAll(
      orders.where((o) =>
          o.code.toLowerCase().contains(lower) ||
          o.customer.toLowerCase().contains(lower)),
    );
  }

  // SORT
  void toggleSort() {
    isAscending.value = !isAscending.value;
    filteredOrders.sort((a, b) => isAscending.value
        ? a.code.compareTo(b.code)
        : b.code.compareTo(a.code));
    filteredOrders.refresh();
  }

  // DATE FILTERS
  Future<void> pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) startDate.value = picked;
  }

  Future<void> pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) endDate.value = picked;
  }

  void applyDateFilter() {
    if (startDate.value == null || endDate.value == null) {
      infoAlertBottom(title: "Filter", "Please select both dates.");
      return;
    }

    filteredOrders.assignAll(
      orders.where((order) {
        return order.date
                .isAfter(startDate.value!.subtract(const Duration(days: 1))) &&
            order.date.isBefore(endDate.value!.add(const Duration(days: 1)));
      }),
    );
  }

  void clearDateFilter() {
    startDate.value = null;
    endDate.value = null;
    filteredOrders.assignAll(orders);
  }

  String formatYmd(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  void openDetail(OutflowOrder order) {
    if (Get.isRegistered<OutflowOrderListDetailController>()) {
      Get.delete<OutflowOrderListDetailController>(force: true);
    }
    Get.toNamed(AppPages.outflowOrderListDetailPage, arguments: order);
  }

  // MANUAL REFRESH
  Future<void> syncData() async {
    await loadOutflowOrders();
    infoAlertBottom(title: 'Sync', 'Data updated');
  }
}
