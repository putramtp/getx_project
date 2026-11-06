import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../global/alert.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/product_summary_model.dart';
import '../../../data/models/stock_transaction_model.dart';
import '../../../data/providers/product_provider.dart';

/// Stock transactions of one product (`GET /stock-transaction/product/{itemId}`,
/// cursor-paginated). Search, the date range and the sort are applied on the
/// loaded rows by [_applyFilters], so a newly loaded page keeps them.
class ProductTransactionListController extends GetxController {
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

  // Date filter — applied only once "Apply" is tapped.
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();
  DateTimeRange? _appliedRange;
  String _query = '';

  @override
  void onInit() {
    super.onInit();
    currentProduct = Get.arguments;
    searchFocus.addListener(() {
      isSearchFocused.value = searchFocus.hasFocus;
    });
    loadProductTrans();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  void toggleSort() {
    isAscending.value = !isAscending.value;
    _applyFilters();
  }

  void clearSearch() {
    searchController.clear();
    searchFocus.unfocus();
    filterList('');
  }

  void onSearchChanged(String value) => filterList(value);

  // FIRST LOAD
  Future<void> loadProductTrans() async {
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      hasError: hasError,
      task: () => provider.getStockTransactionByProduct(productId: currentProduct.itemId),
    );
    if (res == null) return;

    final List rawList = res['data'] ?? [];
    cursorNext.value = res['next_cursor'];
    cursorPrev.value = res['prev_cursor'];
    hasMore.value = cursorNext.value != null;

    transactions.assignAll(rawList.map((e) => StockTransactionModel.fromJson(e)));
    _applyFilters();
  }

  // LOAD NEXT PAGE
  Future<void> loadMore() async {
    final cursor = cursorNext.value;
    if (!hasMore.value || cursor == null || isLoadingMore.value || isLoading.value) return;

    final res = await ApiExecutor.run(
      isLoading: isLoadingMore,
      task: () => provider.getStockTransactionByProduct(productId: currentProduct.itemId, cursor: cursor),
    );
    // A reload replaced the list meanwhile: this page belongs to the old one.
    if (res == null || cursorNext.value != cursor) return;

    final List rawList = res['data'] ?? [];
    cursorNext.value = res['next_cursor'];
    cursorPrev.value = res['prev_cursor'];
    hasMore.value = cursorNext.value != null;

    transactions.addAll(rawList.map((e) => StockTransactionModel.fromJson(e)));
    _applyFilters();
  }

  String formatYmd(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Filter the loaded rows by document code (case-insensitive).
  void filterList(String query) {
    _query = query.trim().toLowerCase();
    _applyFilters();
  }

  /// Search + applied date range + sort over every loaded row.
  void _applyFilters() {
    final range = _appliedRange;
    final rows = transactions.where((trans) {
      if (_query.isNotEmpty && !(trans.order?.code ?? '').toLowerCase().contains(_query)) return false;
      if (range != null) {
        final date = trans.order?.date;
        if (date == null || date.isBefore(range.start) || date.isAfter(range.end)) return false;
      }
      return true;
    }).toList();

    rows.sort((a, b) {
      final codeA = a.order?.code ?? '';
      final codeB = b.order?.code ?? '';
      return isAscending.value ? codeA.compareTo(codeB) : codeB.compareTo(codeA);
    });
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

    // Whole days: from 00:00 of the start to 23:59:59 of the end.
    _appliedRange = DateTimeRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
    _applyFilters();
  }

  /// Clear the date filter (the search stays).
  void clearDateFilter() {
    startDate.value = null;
    endDate.value = null;
    _appliedRange = null;
    _applyFilters();
    infoAlertBottom(title: 'Filter Cleared', 'The date filter has been reset.');
  }

  String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);
}
