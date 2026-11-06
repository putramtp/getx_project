import 'package:getx_project/app/global/functions.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'outflow_order_by_customer_detail_controller.dart';
import '../../../global/accent.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/outflow_request_customer_model.dart';
import '../../../data/providers/outflow_order_provider.dart';
import '../../../routes/app_pages.dart';

/// The By Customer list — and, through [OutflowOrderByWorkOrderController],
/// the By Work Order one: both list targets with reserved / outflowed totals
/// (`OrCustomerModel` rows) and open one target's Item Summary.
class OutflowOrderByCustomerController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  var isLoading = false.obs;
  var hasError = false.obs;
  var orders = <OrCustomerModel>[].obs;
  var filteredCustomers = <OrCustomerModel>[].obs;
  var isAscending = true.obs;
  var isSearchFocused = false.obs;

  // 🗓️ Date filter fields
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();

  // What this list shows; By Work Order overrides these.
  String get title => 'Customers';
  String get searchHint => 'Search Customer...';
  String get emptyMessage => 'No Customer data.';
  AppAccent get accent => AppAccent.amber;
  IconData get icon => Icons.groups_rounded;
  IconData get cardIcon => Icons.store_rounded;
  String get detailRoute => AppPages.outflowOrderByCustomerDetailPage;
  Future<List<OrCustomerModel>> fetchTargets() => provider.getCustomers();

  @override
  void onInit() {
    super.onInit();
    searchFocus.addListener(() {
      isSearchFocused.value = searchFocus.hasFocus;
    });
    loadCustomers();
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

  /// [filteredCustomers] = [orders] matching the search, in the order Sort
  /// set. Run after every load too: a reload (back from a submit, pull to
  /// refresh) must not show every target under a search box that still names
  /// one, nor drop the order the Sort button shows.
  void _applyView() {
    final rows = orders
        .where((o) => _query.isEmpty || o.name.toLowerCase().contains(_query) || o.customerCode.toLowerCase().contains(_query))
        .toList();
    if (_sortedByUser) sortRowsBy(rows, (o) => o.name, ascending: isAscending.value);
    filteredCustomers.assignAll(rows);
  }

  Future<void> loadCustomers() async {
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      hasError: hasError,
      task: fetchTargets,
    );
    // If network failed or exception handled, data is null
    if (data == null) return;
    orders.assignAll(data);
    _applyView();
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void openDetail(OrCustomerModel customer) {
    openFresh<OutflowOrderByCustomerDetailController>(detailRoute, arguments: customer);
  }

}
