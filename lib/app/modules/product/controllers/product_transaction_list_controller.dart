import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../global/alert.dart';
import '../../../global/functions.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/product_summary_model.dart';
import '../../../data/models/stock_transaction_model.dart';
import '../../../data/providers/product_provider.dart';
import 'package:intl/intl.dart';

class ProductTransactionListController extends GetxController {
  final ProductProvider provider = Get.find<ProductProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  // Data
  var transactions = <StockTransactionModel>[].obs;
  var filteredTransactions = <StockTransactionModel>[].obs;

  // State
  var isLoading = false.obs;  
  var isLoadingMore = false.obs;
  var hasMore = true.obs; // ⭐ add no-more-data indicator
  var isAscending = true.obs;
  var isSearchFocused = false.obs;

  late ProductSummaryModel currentProduct;
  // Cursors
  final RxnString cursorNext = RxnString();
  final RxnString cursorPrev = RxnString();

  // 🗓️ Date filter fields
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();

  // Scroll listener
  final ScrollController scrollController = ScrollController(debugLabel:'StockTransactionByProductController' );

  @override
  void onInit() {
    super.onInit();
    currentProduct = Get.arguments;
    searchFocus.addListener(() {
      isSearchFocused.value = searchFocus.hasFocus;
    });
    scrollController.addListener(_scrollListener);
    loadProductTrans();
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
  filteredTransactions.sort((a, b) {
    final codeA = a.order?.code ?? ''; 
    final codeB = b.order?.code ?? '';
    return isAscending.value
        ? codeA.compareTo(codeB)
        : codeB.compareTo(codeA);
  });

  filteredTransactions.refresh();
}
  void clearSearch() {
    searchController.clear();
    searchFocus.unfocus();
  }

  void onSearchChanged(String value) {
    filterList(value);
  }

  // FIRST LOAD
  Future<void> loadProductTrans() async {
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getStockTransactionByProduct(productId: 1 ,cursor: null),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

    // Reset hasMore
    hasMore.value = true;

    if (res['data'] == null) {
      transactions.clear();
      filteredTransactions.clear();
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

    final mapped = rawList.map((e) => StockTransactionModel.fromJson(e)).toList();

    transactions.assignAll(mapped);
    filteredTransactions.assignAll(mapped);
  }

  // LOAD NEXT PAGE
  Future<void> loadMore() async {
    if (!hasMore.value) return; // ⭐ stop if no more data
    if (cursorNext.value == null) return; // no cursor → stop
    if (isLoadingMore.value) return; // avoid double loads

    final res = await ApiExecutor.run(
      isLoading: isLoadingMore,
      task: () => provider.getStockTransactionByProduct(productId: 1 ,cursor: null),
    );
    // If network failed or exception handled, data is null
    if (res == null) return;

    final List rawList = res['data'] ?? [];
    final newOrders = rawList.map((e) => StockTransactionModel.fromJson(e)).toList();

    // ⭐ Update next cursor
    cursorNext.value = res['next_cursor'];
    cursorPrev.value = res['prev_cursor'];

    // If response returns null cursor → no more data
    if (cursorNext.value == null) {
      hasMore.value = false;
    }

    transactions.addAll(newOrders);
    filteredTransactions.assignAll(transactions);
  }

  String formatYmd(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date).toString();
  }

  /// 🔍 Filter list by PO number
  void filterList(String query) {
    if (query.isEmpty) {
      filteredTransactions.assignAll(transactions);
    } else {
      final lowerQuery = query.toLowerCase();

      filteredTransactions.assignAll(
        transactions.where((trans) {
          final codeTrans = trans.order?.code ?? ''; 
          return codeTrans.contains(lowerQuery) ;
        }).toList(),
      );
    }
  }

  // 📅 Pick start date
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
      infoAlertBottom(
        title: 'Filter Tanggal',
        'Please select both dates first.',
      );
      return;
    }

    // Normalized to midnight (00:00) and end of day (23:59)
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    filteredTransactions.assignAll(
      transactions.where((trans) {
        final orderDate = trans.order?.date;
        if (orderDate == null) return false; // skip if null

        return orderDate.isAtSameMomentAs(startOfDay) ||
           orderDate.isAtSameMomentAs(endOfDay) ||
           (orderDate.isAfter(startOfDay) && orderDate.isBefore(endOfDay));
        }).toList(),
    );

  }

  /// ♻️ Clear date filter
  void clearDateFilter() {
    startDate.value = null;
    endDate.value = null;
    filteredTransactions.assignAll(transactions);
    infoAlertBottom(title: 'Filter Dihapus', 'Filter tanggal telah direset');
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

}
