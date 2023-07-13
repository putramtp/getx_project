import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/functions.dart';
import '../providers/inventory_provider.dart';

class CategoryController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final InventoryProvider _receivingOrderProvider = InventoryProvider();
  RxList<String> listCategories = RxList<String>();
  RxList<String> filteListCategories = RxList<String>();
  RxBool isSearch = false.obs;
  RxBool isLoading = true.obs;
  
  final count = 0.obs;
  @override
  void onInit() {
    getCategories();
    super.onInit();
  }

  

  void getCategories() async {
    listCategories.value = await _receivingOrderProvider.categories();
    filteListCategories.value = listCategories;
    isLoading.value = false;
  }

  void onSearch(String query) {
    if (query.isNotEmpty) {
      isSearch.value = true;
      filteListCategories.value = listCategories.where((item) => searchString(query ,item)).toList();
    } else {
      isSearch.value = false;
      filteListCategories.value = listCategories;
    }
  }
  void onCloseSearch(){
     searchController.clear();
     isSearch.value = false;
     filteListCategories.value = listCategories;
  }



  // @override
  // void onReady() {
  //   super.onReady();
  // }

  // @override
  // void onClose() {
  //   super.onClose();
  // }

}
