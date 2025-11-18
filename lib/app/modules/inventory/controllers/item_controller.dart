
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/product_model.dart';
import '../providers/inventory_provider.dart';

class ItemController extends GetxController {
  String title = Get.arguments["title"];

  final InventoryProvider _receiveProvider = InventoryProvider();
  RxList<ProductModel> listProduct = RxList<ProductModel>();
  RxList<DataRow> listDataRowProduct = RxList<DataRow>();

  RxBool isCellLoad = true.obs;

  int fixedRows = 1;

  @override
  void onInit() {
    fetchDataRows(title);
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
    listProduct.value = await _receiveProvider.productCategory(categoryName);
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
}
