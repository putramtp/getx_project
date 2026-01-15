import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../controllers/receive_order_by_supplier_detail_controller.dart';
import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/purchase_order_supplier_model.dart';
import '../../../data/providers/receive_order_provider.dart';
import '../../../routes/app_pages.dart';

class ReceiveOrderBySupplierController extends GetxController {
  final ReceiveOrderProvider provider = Get.find<ReceiveOrderProvider>();
  final searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  var isLoading = false.obs;
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

  void onSearchChanged(String query) {
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

  Future<void> loadSuppliers() async {
    final data = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getSuppliers(),
    );
    // If network failed or exception handled, data is null
    if (data == null) return;
    orders.assignAll(data);
    filteredSuppliers.assignAll(data);
  }


  void clearDateFilter() {
    filteredSuppliers.assignAll(orders);
    infoAlertBottom(title: 'Filter Dihapus', 'Filter tanggal telah direset');
  }


  void openDetail(PoSupplierModel supplier) {
    if (Get.isRegistered<ReceiveOrderBySupplierDetailController>()) {
      Get.delete<ReceiveOrderBySupplierDetailController>(force: true);
    }
    Get.toNamed(AppPages.receiveOrderBySupplierDetailPage, arguments: supplier);
  }
}
