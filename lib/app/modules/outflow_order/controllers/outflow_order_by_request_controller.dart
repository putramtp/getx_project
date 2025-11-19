import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/helpers/api_excecutor.dart';
import 'package:getx_project/app/models/outlfow_request_model.dart';
import 'package:getx_project/app/modules/outflow_order/controllers/outflow_order_by_request_detail_controller.dart';
import 'package:getx_project/app/modules/outflow_order/providers/outflow_order_provider.dart';
import 'package:getx_project/app/routes/app_pages.dart';
import 'package:intl/intl.dart';

class OutflowOrderByRequestController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  var isLoading = false.obs;
  var orders = <OutflowRequest>[].obs;
  var filteredOrders = <OutflowRequest>[].obs;
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
    loadRequestOrders();
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
    // Optionally refresh list here
  }

  void onSearchChanged(String value) {
    filterList(value);
  }

  Future<void> loadRequestOrders() async {
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getOutflowRequests(),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;
    orders.assignAll(data);
    filteredOrders.assignAll(data);
    successAlertBottom('Outflow request loaded successfully (${data.length} records)');
  }

  /// 🔍 Filter list by PO number
  void filterList(String query) {
    if (query.isEmpty) {
      filteredOrders.assignAll(orders);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredOrders.assignAll(
        orders.where((order) =>
            order.code.toLowerCase().contains(lowerQuery) ||
            order.customer.toLowerCase().contains(lowerQuery)),
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

  // 📆 Apply date range filter
  void applyDateFilter() {
    if (startDate.value == null || endDate.value == null) {
      infoAlertBottom(
          title: 'Filter Tanggal',
          'Silakan pilih kedua tanggal terlebih dahulu');
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
    infoAlertBottom(title: 'Filter Dihapus', 'Filter tanggal telah direset');
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void openDetail(OutflowRequest order) {
    if (Get.isRegistered<OutflowOrderByRequestDetailController>()) {
      Get.delete<OutflowOrderByRequestDetailController>(force: true);
    }
    Get.toNamed(AppPages.outflowOrderByRequestDetailPage, arguments: order);
  }

  /// 🔄 Manual Sync
  void syncData() async {
    await loadRequestOrders();
    infoAlertBottom(title: 'Sinkronisasi', 'Data terbaru disinkronisasi');
  }
}
