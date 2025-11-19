import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/helpers/api_excecutor.dart';
import 'package:getx_project/app/models/purchase_order_model.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_by_po_detail_controller.dart';
import 'package:getx_project/app/modules/receive_order/providers/receive_order_provider.dart';
import 'package:getx_project/app/routes/app_pages.dart';
import 'package:intl/intl.dart';

class ReceiveOrderByPoController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  var isLoading = false.obs;
  var orders = <PurchaseOrder>[].obs;
  var filteredOrders = <PurchaseOrder>[].obs;
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
    loadPurchaseOrders();
  }

  void toggleSort() {
    isAscending.value = !isAscending.value;
    filteredOrders.sort((a, b) => isAscending.value
        ? a.poNumber.compareTo(b.poNumber)
        : b.poNumber.compareTo(a.poNumber));
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

  Future<void> loadPurchaseOrders() async {
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getPurchaseOrders(),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;
    filteredOrders.assignAll(data);
    successAlertBottom(
        'Purchase orders loaded successfully (${data.length} records)');
  }

  /// 🔍 Filter list by PO number
  void filterList(String query) {
    if (query.isEmpty) {
      filteredOrders.assignAll(orders);
    } else {
      filteredOrders.assignAll(
        orders.where((order) =>
            order.poNumber.toLowerCase().contains(query.toLowerCase())),
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
          title: "Filter Tanggal",
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

  void openDetail(PurchaseOrder order) {
    if (Get.isRegistered<ReceiveOrderByPoDetailController>()) {
      Get.delete<ReceiveOrderByPoDetailController>(force: true);
    }
    Get.toNamed(AppPages.receiveOrderByPoDetailPage, arguments: order);
  }

  /// 🔄 Manual Sync
  void syncPO() async {
    await loadPurchaseOrders();
  }
}
