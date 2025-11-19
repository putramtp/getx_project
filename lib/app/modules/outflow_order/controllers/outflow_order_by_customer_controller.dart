import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/helpers/api_excecutor.dart';
import 'package:getx_project/app/models/outflow_request_customer_model.dart';
import 'package:getx_project/app/modules/outflow_order/controllers/outflow_order_by_customer_detail_controller.dart';
import 'package:getx_project/app/modules/outflow_order/providers/outflow_order_provider.dart';
import 'package:getx_project/app/routes/app_pages.dart';
import 'package:intl/intl.dart';

class OutflowOrderByCustomerController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  var isLoading = false.obs;
  var orders = <OrCustomer>[].obs;
  var filteredCustomers = <OrCustomer>[].obs;
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
    loadCustomers();
  }

  void toggleSort() {
    isAscending.value = !isAscending.value;
    filteredCustomers.sort((a, b) => isAscending.value
        ? a.name.compareTo(b.name)
        : b.name.compareTo(a.name));
    filteredCustomers.refresh();
  }

  void clearSearch() {
    searchController.clear();
    searchFocus.unfocus();
  }

  void onSearchChanged(String value) {
    filterList(value);
  }

  Future<void> loadCustomers() async {
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getCustomers(),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;
    orders.assignAll(data);
    filteredCustomers.assignAll(data);
    successAlertBottom(
      title: 'Success',
      'Customers loaded successfully (${data.length} records)',
    );
  }

  /// 🔍 Filter list by customer name
  void filterList(String query) {
    if (query.isEmpty) {
      filteredCustomers.assignAll(orders);
    } else {
      filteredCustomers.assignAll(
        orders.where((order) {
          final lowerQuery = query.toLowerCase();
          final nameMatch = order.name.toLowerCase().contains(lowerQuery);
          final codeMatch =
              order.customerCode.toLowerCase().contains(lowerQuery);
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
      infoAlertBottom(
          title: 'Filter Tanggal',
          'Silakan pilih kedua tanggal terlebih dahulu');
      return;
    }

    // filteredCustomers.assignAll(orders.where((order) {
    //   final date = order.date;
    //   return date.isAfter(startDate.value!.subtract(const Duration(days: 1))) &&
    //       date.isBefore(endDate.value!.add(const Duration(days: 1)));
    // }).toList());
  }

  /// ♻️ Clear date filter
  void clearDateFilter() {
    startDate.value = null;
    endDate.value = null;
    filteredCustomers.assignAll(orders);
    infoAlertBottom(title: 'Filter Dihapus', 'Filter tanggal telah direset');
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void openDetail(OrCustomer customer) {
    if (Get.isRegistered<OutflowOrderByCustomerDetailController>()) {
      Get.delete<OutflowOrderByCustomerDetailController>(force: true);
    }
    Get.toNamed(AppPages.outflowOrderByCustomerDetailPage, arguments: customer);
  }

  void syncPO() async {
    await loadCustomers();
  }
}
