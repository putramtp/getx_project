import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/outflow_order_model.dart';
import '../../../modules/outflow_order/controllers/outflow_order_list_detail_controller.dart';
import '../../../data/providers/outflow_order_provider.dart';
import '../../../routes/app_pages.dart';

class OutflowOrderListController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  // Data
  var orders = <OutflowOrderModel>[].obs;
  var filteredOrders = <OutflowOrderModel>[].obs;

  // State
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs; // ⭐ add no-more-data indicator
  var isAscending = true.obs;
  var isSearchFocused = false.obs;

  // Cursors
  final RxnString cursorNext = RxnString();
  final RxnString cursorPrev = RxnString();

  // Date filter
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();

  // Scroll listener
  final ScrollController scrollController = ScrollController(debugLabel:'OutflowOrderListController');
 
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

    final mapped = rawList.map((e) => OutflowOrderModel.fromJson(e)).toList();

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
      task: () => provider.getOutflowOrders(cursor: cursorNext.value),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

    final List rawList = res['data'] ?? [];
    final newOrders = rawList.map((e) => OutflowOrderModel.fromJson(e)).toList();

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

  void openDetail(OutflowOrderModel order) {
    if (Get.isRegistered<OutflowOrderListDetailController>()) {
      Get.delete<OutflowOrderListDetailController>(force: true);
    }
    Get.toNamed(AppPages.outflowOrderListDetailPage, arguments: order);
  }

}
