import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/models/purchase_order_supplier_model.dart';
import 'package:getx_project/app/modules/receive_order/controllers/receive_order_by_supplier_detail_controller.dart';
import 'package:getx_project/app/modules/receive_order/providers/receive_order_provider.dart';
import 'package:getx_project/app/routes/app_pages.dart';
import 'package:intl/intl.dart';

class ReceiveOrderBySupplierController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  var isLoading = false.obs;
  var orders = <PoSupplier>[].obs;
  var filteredSuppliers = <PoSupplier>[].obs;
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
    loadSuppliers();
  }

  void toggleSort() {
    isAscending.value = !isAscending.value;
    filteredSuppliers.sort((a, b) => isAscending.value
        ? a.name.compareTo(b.name)
        : b.name.compareTo(a.name));
    filteredSuppliers.refresh();
  }

  void clearSearch() {
    searchController.clear();
    searchFocus.unfocus();
  }

  void onSearchChanged(String value) {
    filterList(value);
  }

  Future<void> loadSuppliers() async {
    try {
      isLoading.value = true;
      final data = await provider.getSuppliers();
      orders.assignAll(data);
      filteredSuppliers.assignAll(data);
      Get.snackbar(
        'Success',
        'Suppliers loaded successfully (${data.length} records)',
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Failed',
        'Unable to load Suppliers.\nError: $e',
        backgroundColor: const Color(0xFFF44336),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔍 Filter list by supplier name
  void filterList(String query) {
    if (query.isEmpty) {
      filteredSuppliers.assignAll(orders);
    } else {
      filteredSuppliers.assignAll(
        orders.where((order) {
          final lowerQuery = query.toLowerCase();
          final nameMatch = order.name.toLowerCase().contains(lowerQuery);
          final codeMatch = order.code.toLowerCase().contains(lowerQuery);
          return nameMatch || codeMatch;
        }),
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
      Get.snackbar(
          'Filter Tanggal', 'Silakan pilih kedua tanggal terlebih dahulu');
      return;
    }

    // filteredSuppliers.assignAll(orders.where((order) {
    //   final date = order.date;
    //   return date.isAfter(startDate.value!.subtract(const Duration(days: 1))) &&
    //       date.isBefore(endDate.value!.add(const Duration(days: 1)));
    // }).toList());
  }

  /// ♻️ Clear date filter
  void clearDateFilter() {
    startDate.value = null;
    endDate.value = null;
    filteredSuppliers.assignAll(orders);
    Get.snackbar('Filter Dihapus', 'Filter tanggal telah direset');
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void openDetail(PoSupplier supplier) {
    if (Get.isRegistered<ReceiveOrderBySupplierDetailController>()) {
      Get.delete<ReceiveOrderBySupplierDetailController>(force: true);
    }
    Get.toNamed(AppPages.receiveOrderBySupplierDetailPage, arguments: supplier);
  }

  void syncPO() async {
    await loadSuppliers();
    Get.snackbar('Sinkronisasi', 'PO terbaru disinkronisasi');
  }
}
