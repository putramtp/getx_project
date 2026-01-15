import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'outflow_order_by_customer_detail_controller.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/outflow_request_customer_model.dart';
import '../../../data/providers/outflow_order_provider.dart';
import '../../../routes/app_pages.dart';

class OutflowOrderByCustomerController extends GetxController {
  final OutflowOrderProvider provider = Get.find<OutflowOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  var isLoading = false.obs;
  var orders = <OrCustomerModel>[].obs;
  var filteredCustomers = <OrCustomerModel>[].obs;
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

  void onSearchChanged(String query) {
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

  Future<void> loadCustomers() async {
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getCustomers(),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;
    orders.assignAll(data);
    filteredCustomers.assignAll(data);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void openDetail(OrCustomerModel customer) {
    if (Get.isRegistered<OutflowOrderByCustomerDetailController>()) {
      Get.delete<OutflowOrderByCustomerDetailController>(force: true);
    }
    Get.toNamed(AppPages.outflowOrderByCustomerDetailPage, arguments: customer);
  }

}
