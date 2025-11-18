
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/models/outflow_order_model.dart';
import 'package:getx_project/app/modules/outflow_order/controllers/outflow_order_list_detail_controller.dart';
import 'package:getx_project/app/modules/outflow_order/providers/outflow_order_provider.dart';
import 'package:getx_project/app/routes/app_pages.dart';
import 'package:intl/intl.dart';

class OutflowOrderListController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  var isLoading = false.obs;
  var orders = <OutflowOrder>[].obs;
  var filteredOrders = <OutflowOrder>[].obs;
  var isAscending = true.obs;
  var isSearchFocused = false.obs;

  // 🗓️ Date filter fields
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    searchFocus.addListener(() {
      isSearchFocused.value = searchFocus.hasFocus;
    });
    loadOutflowOrders();
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

  Future<void> loadOutflowOrders() async {
    try {
      isLoading.value = true;
      final data = await provider.getOutflowOrders();
      orders.assignAll(data);
      filteredOrders.assignAll(data);
      successAlertBottom('Outflow requests loaded successfully (${data.length} records)');
    } catch (e) {
      errorAlertBottom('Unable to load outflow orders.\nError: $e');
    } finally {
      isLoading.value = false;
    }
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
        orders.where((order) =>
            order.code.toLowerCase().contains(lowerQuery) 
            || order.customer.toLowerCase().contains(lowerQuery) 
            ),
      );
    }
  }

  // 📅 Pick start date
  Future<void> pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) startDate.value = picked;
  }

  // 📅 Pick end date
  Future<void> pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) endDate.value = picked;
  }

  // 📆 Apply date range filter
  void applyDateFilter() {
    if (startDate.value == null || endDate.value == null) {
      infoAlertBottom(title:'Filter Tanggal', 'Silakan pilih kedua tanggal terlebih dahulu');
      return;
    }

    filteredOrders.assignAll(orders.where((order) {
      final date = order.date;
      return date.isAfter(startDate.value!.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.value!.add(const Duration(days: 1)));
    }).toList());
  }

  /// ♻️ Clear date filter
  void clearDateFilter() {
    startDate.value = null;
    endDate.value = null;
    filteredOrders.assignAll(orders);
    infoAlertBottom(title:'Filter Dihapus', 'Filter tanggal telah direset');
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void openDetail(OutflowOrder order) {
     if (Get.isRegistered<OutflowOrderListDetailController>()) {
      Get.delete<OutflowOrderListDetailController>(force: true);
    }
    Get.toNamed(AppPages.outflowOrderListDetailPage, arguments: order);
  }

  void syncData() async {
    await loadOutflowOrders();
    infoAlertBottom(title:'Sinkronisasi', 'Data terbaru disinkronisasi');
  }
}
