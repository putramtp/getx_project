import 'dart:developer';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getx_project/app/models/purchase_order_model.dart';
import 'package:getx_project/app/modules/outflow_order/providers/outflow_order_provider.dart';
import 'package:getx_project/app/routes/app_pages.dart';
import 'package:intl/intl.dart';

class OutflowOrderController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();
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
    // fetchOrders();
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
    try {
      isLoading.value = true;
      final data = await provider.getPurchaseOrders();
      orders.assignAll(data);
      filteredOrders.assignAll(data);
      Get.snackbar(
        'Success',
        'Purchase orders loaded successfully (${data.length} records)',
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      log("loadOrders error: $e");
      Get.snackbar(
        'Failed',
        'Unable to load purchase orders.\nError: $e',
        backgroundColor: const Color(0xFFF44336),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void fetchOrders() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 800));

    orders.value = [
      PurchaseOrder(
        id: 1,
        poNumber: 'PO.10123',
        supplier: 'PT. Elektronik Jaya Abadi',
        status: 'processing',
        items: '3/5 Item',
        received: 3,
        total: 5,
        date: DateTime(2025, 10, 2),
      ),
      PurchaseOrder(
        id: 2,
        poNumber: 'PO.10124',
        supplier: 'CV. Sinar Techindo',
        status: 'waiting',
        items: '0/3 Item',
        received: 0,
        total: 3,
        date: DateTime(2025, 10, 5),
      ),
      PurchaseOrder(
        id: 3,
        poNumber: 'PO.10125',
        supplier: 'PT. Omega Supplies',
        status: 'waiting',
        items: '0/2 Item',
        received: 0,
        total: 2,
        date: DateTime(2025, 10, 7),
      ),
    ];

    filteredOrders.assignAll(orders);
    isLoading.value = false;
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
      Get.snackbar(
          'Filter Tanggal', 'Silakan pilih kedua tanggal terlebih dahulu');
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
    Get.snackbar('Filter Dihapus', 'Filter tanggal telah direset');
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void openDetail(PurchaseOrder order) {
    // Get.snackbar('Detail', 'Open ${order['po_number']}');
    Get.toNamed(AppPages.outflowOrderDetailPage, arguments: order);
  }

  /// 🔄 Manual Sync
  void syncPO() async {
    await loadPurchaseOrders();
    Get.snackbar('Sinkronisasi', 'PO terbaru disinkronisasi');
  }
}
