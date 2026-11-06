import 'dart:async';

import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../global/alert.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../helpers/list_reload_guard.dart';
import '../../../data/models/product_summary_model.dart';
import '../../../data/models/stock_transaction_model.dart';
import '../../../data/providers/product_provider.dart';

/// Stock transactions of one product (`GET /stock-transaction/product/{itemId}`,
/// cursor-paginated). Search and the date range go to the backend
/// ([buildParams]) and reload the list, so a match on a page not loaded yet is
/// still found; only the code sort runs on the loaded rows.
class ProductTransactionListController extends GetxController with ListReloadGuard {
  final ProductProvider provider = Get.find<ProductProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  // Data
  var transactions = <StockTransactionModel>[].obs;
  var filteredTransactions = <StockTransactionModel>[].obs;

  // State
  var isLoading = false.obs;
  var hasError = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  var isAscending = true.obs;
  var isSearchFocused = false.obs;

  late ProductSummaryModel currentProduct;
  // Cursors
  final RxnString cursorNext = RxnString();
  final RxnString cursorPrev = RxnString();

  // Date filter — sent only once "Apply" is tapped.
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();
  DateTime? _appliedStart;
  DateTime? _appliedEnd;
  String _query = '';
  Timer? _debounce;

  /// The query the rows on screen were loaded with ([buildParams], as text).
  String? _loadedQuery;

  /// False until Sort is tapped: the server's order (newest first) is kept, so
  /// a next page appends below instead of being sorted in among the rows above.
  bool _sortedByCode = false;

  @override
  void onInit() {
    super.onInit();
    searchFocus.addListener(() {
      isSearchFocused.value = searchFocus.hasFocus;
    });
    final args = Get.arguments;
    if (args is ProductSummaryModel) {
      currentProduct = args;
      loadProductTrans();
    } else {
      errorAlert("⚠️ Invalid or missing arguments in ProductTransactionListController: $args");
    }
  }

  @override
  void onClose() {
    _debounce?.cancel(); // a search typed just before Back must not fire
    searchController.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  /// First tap: A→Z by code (leaving the server's order); later taps flip it.
  void toggleSort() {
    if (_sortedByCode) {
      isAscending.value = !isAscending.value;
    } else {
      _sortedByCode = true;
      isAscending.value = true;
    }
    _applySort();
  }

  void clearSearch() {
    searchController.clear();
    searchFocus.unfocus();
    filterList('');
  }

  void onSearchChanged(String value) => filterList(value);

  /// Query sent with every page: the document-code search and the applied range.
  Map<String, String> buildParams() => {
        if (_query.isNotEmpty) 'search': _query,
        if (_appliedStart != null) 'start_date': formatYmd(_appliedStart!),
        if (_appliedEnd != null) 'end_date': formatYmd(_appliedEnd!),
      };

  // FIRST LOAD
  Future<void> loadProductTrans() => guardReload(isLoading, _loadProductTrans);

  Future<void> _loadProductTrans() async {
    final params = buildParams();
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      hasError: hasError,
      task: () => provider.getStockTransactionByProduct(productId: currentProduct.itemId, params: params),
    );
    if (res == null) {
      // A new search / date range failed: the rows and cursor on screen belong
      // to the old one. Clear them so Retry shows and a scroll can't append the
      // new query's pages to them. A failed refresh of the same query keeps them.
      if (params.toString() != _loadedQuery) {
        transactions.clear();
        filteredTransactions.clear();
        cursorNext.value = null;
        hasMore.value = false;
        _loadedQuery = null;
      }
      return;
    }
    _loadedQuery = params.toString();

    final List rawList = res['data'] ?? [];
    cursorNext.value = res['next_cursor'];
    cursorPrev.value = res['prev_cursor'];
    hasMore.value = cursorNext.value != null;

    transactions.assignAll(rawList.map((e) => StockTransactionModel.fromJson(e)));
    _applySort();
  }

  // LOAD NEXT PAGE
  Future<void> loadMore() async {
    final cursor = cursorNext.value;
    if (!hasMore.value || cursor == null || isLoadingMore.value || isLoading.value || !mayLoadMore) return;
    final generation = listGeneration;

    final res = await ApiExecutor.run(
      isLoading: isLoadingMore,
      task: () => provider.getStockTransactionByProduct(
        productId: currentProduct.itemId,
        cursor: cursor,
        params: buildParams(),
      ),
    );
    // A reload started meanwhile: this page belongs to the old query.
    if (res == null) return noteLoadMoreFailed();
    if (!isCurrentPage(generation)) return;

    final List rawList = res['data'] ?? [];
    cursorNext.value = res['next_cursor'];
    cursorPrev.value = res['prev_cursor'];
    hasMore.value = cursorNext.value != null;

    transactions.addAll(rawList.map((e) => StockTransactionModel.fromJson(e)));
    _applySort();
  }

  String formatYmd(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Search by document code on the backend, 400 ms after the last keystroke.
  void filterList(String query) {
    _query = query.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), loadProductTrans);
  }

  /// The loaded rows, sorted by code once Sort was tapped.
  void _applySort() {
    final rows = transactions.toList();
    if (_sortedByCode) {
      rows.sort((a, b) {
        final codeA = a.order?.code ?? '';
        final codeB = b.order?.code ?? '';
        return isAscending.value ? codeA.compareTo(codeB) : codeB.compareTo(codeA);
      });
    }
    filteredTransactions.assignAll(rows);
  }

  // Pick start date
  Future<void> pickStartDate(BuildContext context) async {
    final picked = await pickDate(context, initialDate: startDate.value);
    if (picked != null) startDate.value = picked;
  }

  Future<void> pickEndDate(BuildContext context) async {
    final picked = await pickDate(context, initialDate: endDate.value);
    if (picked != null) endDate.value = picked;
  }

  void applyDateFilter() {
    final start = startDate.value;
    final end = endDate.value;

    if (start == null || end == null) {
      infoAlertBottom(title: 'Date Filter', 'Please select both dates first.');
      return;
    }
    if (end.isBefore(start)) {
      infoAlertBottom(title: 'Date Filter', 'The end date is before the start date.');
      return;
    }

    _appliedStart = start;
    _appliedEnd = end;
    loadProductTrans();
  }

  /// Clear the date filter (the search stays).
  void clearDateFilter() {
    startDate.value = null;
    endDate.value = null;
    _appliedStart = null;
    _appliedEnd = null;
    loadProductTrans();
    infoAlertBottom(title: 'Filter Cleared', 'The date filter has been reset.');
  }

  String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);
}
