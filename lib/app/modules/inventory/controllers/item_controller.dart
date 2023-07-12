import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/product_model.dart';
import '../providers/inventory_provider.dart';

class ItemController extends GetxController {
  RxString title = "".obs;

  final InventoryProvider _receiveProvider = InventoryProvider();
  RxList<ProductModel> listProduct = RxList<ProductModel>();
  RxList<DataRow> listDataRowProduct = RxList<DataRow>();

  RxBool isCellLoad = true.obs;

  int fixedRows = 1;

  @override
  void onInit() {
    title.value = Get.arguments["title"];
    log("title : ${title.value}");
    fetchDataRows(title.value);
    super.onInit();
  }

  // @override
  // void onReady() {
  //   super.onReady();
  // }

  // @override
  // void onClose() {
  //   super.onClose();
  // }

  void fetchDataRows(String categoryName ) async {
    listProduct.value = await _receiveProvider.products(categoryName);
    listDataRowProduct.value = listProduct.map((product) {
      return DataRow(cells: [
        DataCell(Text(product.title)),
        DataCell(Center(child: Text(product.price.toString()))),
        DataCell(Center(child: Text("${product.discountPercentage} %"))),
        DataCell(Center(child: Text(product.stock.toString()))),
      ]);
    }).toList();
    isCellLoad.value = false;
  }

  // void costumAddDialogAction(ProductModel product) {
  //   Get.defaultDialog(
  //     title: "Add Product",
  //     titleStyle: const TextStyle(fontSize: 20),
  //     textConfirm: "Oke",
  //     textCancel: "Cancel",
  //     middleText: product.title,
  //     contentPadding: const EdgeInsets.all(20),
  //     onConfirm: () {
  //       Get.back();
  //       Get.snackbar("", "${product.id} success",
  //           titleText: const Text(
  //             "Status",
  //             style: TextStyle(color: Colors.green),
  //           ));
  //     },
  //   );
  // }
}
