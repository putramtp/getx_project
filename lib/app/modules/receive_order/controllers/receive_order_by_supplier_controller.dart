import 'package:getx_project/app/global/functions.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../controllers/receive_order_by_supplier_detail_controller.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/purchase_order_supplier_model.dart';
import '../../../data/providers/receive_order_provider.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderBySupplierController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  var isLoading = false.obs;
  var hasError = false.obs;
  var orders = <PoSupplierModel>[].obs;
  var filteredSuppliers = <PoSupplierModel>[].obs;
  var isAscending = true.obs;
  var isSearchFocused = false.obs;

  @override
  void onInit() {
    super.onInit();
    searchFocus.addListener(() {
      isSearchFocused.value = searchFocus.hasFocus;
    });
    loadSuppliers();
  }

 @override
  void onClose() {
    searchController.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  /// The search typed and submitted, lower-cased; kept for every reload.
  String _query = '';

  /// Set once Sort is tapped; until then the server's order stands.
  bool _sortedByUser = false;

  void toggleSort() {
    isAscending.value = !isAscending.value;
    _sortedByUser = true;
    _applyView();
  }

  void clearSearch() {
    searchController.clear();
    searchFocus.unfocus();
  }

  void onSearchChanged(String query) {
    _query = query.trim().toLowerCase();
    _applyView();
  }

  /// [filteredSuppliers] = [orders] matching the search, in the order Sort
  /// set. Run after every load too: a reload (back from a receive, pull to
  /// refresh) must not show every supplier under a search box that still
  /// names one, nor drop the order the Sort button shows.
  void _applyView() {
    final rows = orders
        .where((o) => _query.isEmpty || o.name.toLowerCase().contains(_query) || o.code.toLowerCase().contains(_query))
        .toList();
    if (_sortedByUser) sortRowsBy(rows, (o) => o.name, ascending: isAscending.value);
    filteredSuppliers.assignAll(rows);
  }

  Future<void> loadSuppliers() async {
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      hasError: hasError,
      task: () => provider.getSuppliers(),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;
    orders.assignAll(data);
    _applyView();
  }

  void openDetail(PoSupplierModel supplier) {
    openFresh<ReceiveOrderBySupplierDetailController>(AppPages.receiveOrderBySupplierDetailPage, arguments: supplier);
  }
}
