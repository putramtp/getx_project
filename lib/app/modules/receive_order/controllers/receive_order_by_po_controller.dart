import 'package:getx_project/app/helpers/list_reload_guard.dart';
import 'package:getx_project/app/global/widget/top_filter_popup.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/receive_order_by_po_detail_controller.dart';
import '../../../global/alert.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/purchase_order_model.dart';
import '../../../data/providers/receive_order_provider.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderByPoController extends GetxController with ListReloadGuard implements TopFilterController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  var orders = <PurchaseOrderModel>[].obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs; 
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
    loadPurchaseOrders();
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
    sortRowsBy(orders, (o) => o.poNumber, ascending: isAscending.value);
    orders.refresh();
  }

  void clearSearch() {
    searchController.clear();
    searchFocus.unfocus();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value.trim();
    loadPurchaseOrders();
  }

  // FIRST LOAD
  Future<void> loadPurchaseOrders() => guardReload(isLoading, _loadPurchaseOrders);

  Future<void> _loadPurchaseOrders() async {
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      hasError: hasError,
      task: () => provider.getPurchaseOrders(cursor: null,params: buildParams()),
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

    final mapped = rawList.map((e) => PurchaseOrderModel.fromJson(e)).toList();
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
      task: () => provider.getPurchaseOrders(cursor: cursorNext.value,params: buildParams()),
    );
    // If network failed or exception handled, data is null
    // A reload started meanwhile: this page belongs to the old query.
    if (res == null) return noteLoadMoreFailed();
    if (!isCurrentPage(generation)) return;

    final List rawList = res['data'] ?? [];
    final newOrders = rawList.map((e) => PurchaseOrderModel.fromJson(e)).toList();

    // ⭐ Update next cursor
    cursorNext.value = res['next_cursor'];

    // If response returns null cursor → no more data
    if (cursorNext.value == null) {
      hasMore.value = false;
    }

    orders.addAll(newOrders);
    _keepSort();
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
      if (startDate.value != null)'start_date': getDateString(startDate.value!),
      if (endDate.value != null)'end_date': getDateString(endDate.value!), 
    };
  }

  @override
  void applyFilter() {
    loadPurchaseOrders();
  }

  /// ♻️ Clear date filter
  @override
  void clearFilter () {
    limit.value = 20;
    startDate.value = null;
    endDate.value = null;
    searchQuery.value = '';
    searchController.clear();
    loadPurchaseOrders();
    infoAlertBottom(title: 'Filter deleted', 'Filter has been reset.');
  }

  @override
  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void openDetail(PurchaseOrderModel order) {
    openFresh<ReceiveOrderByPoDetailController>(AppPages.receiveOrderByPoDetailPage, arguments: order);
  }
}
