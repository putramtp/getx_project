import 'dart:developer';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/models/receive_order_model.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_list_detail_controller.dart';
import 'package:getx_project/app/modules/receive_order/providers/receive_order_provider.dart';
import 'package:getx_project/app/routes/app_pages.dart';
import 'package:intl/intl.dart';

class ReceiveOrderListController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  var isLoading = false.obs;
  var orders = <ReceiveOrder>[].obs;
  var filteredOrders = <ReceiveOrder>[].obs;
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
    loadReceiveOrders();
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

  Future<void> loadReceiveOrders() async {
    try {
      isLoading.value = true;
      final data = await provider.getReceiveOrders();
      orders.assignAll(data);
      filteredOrders.assignAll(data);
      successAlertBottom('Receive orders loaded successfully (${data.length} records)');
    } catch (e, st) {
      log("loadOrders error: $e \n$st", name: 'ReceiveOrderListController');
      errorAlertBottom(title:'Failed','Unable to load receive orders.\nError: $e');
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
        orders.where((order) {
          return order.code.toLowerCase().contains(lowerQuery) ||
              order.supplier.toLowerCase().contains(lowerQuery);
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
        title:'Filter Tanggal',
        'Silakan pilih kedua tanggal terlebih dahulu',
      );
      return;
    }

    // Normalized to midnight (00:00) and end of day (23:59)
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    filteredOrders.assignAll(
      orders.where((order) {
        final date = order.date;
        return date.isAtSameMomentAs(startOfDay) ||
            date.isAtSameMomentAs(endOfDay) ||
            (date.isAfter(startOfDay) && date.isBefore(endOfDay));
      }).toList(),
    );
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

  void openDetail(ReceiveOrder order) {
     if (Get.isRegistered<ReceiveOrderListDetailController>()) {
      Get.delete<ReceiveOrderListDetailController>(force: true);
    }
    Get.toNamed(AppPages.receiveOrderListDetailPage, arguments: order);
  }

  /// 🔄 Manual Sync
  void syncReceiveOrder() async {
    await loadReceiveOrders();
    infoAlertBottom(title:'Sinkronisasi', 'PO terbaru disinkronisasi');
  }
}
