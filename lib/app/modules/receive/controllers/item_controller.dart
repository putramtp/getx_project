import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/product_model.dart';
import '../../../routes/app_pages.dart';
import '../providers/receive_provider.dart';

class ItemController extends GetxController {
  final String title = Get.arguments["title"];
  final ReceiveProvider _receiveProvider = ReceiveProvider();
  RxList<ProductModel> listProduct = RxList<ProductModel>();
  RxList<DataRow> listDataRowProduct = RxList<DataRow>();

  RxBool isCellLoad = true.obs;

  final ScrollController scrollController = ScrollController();
  int fixedRows = 1;

  @override
  void onInit() {
    fetchDataRows();
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

  void fetchDataRows() async {
    listProduct.value = await _receiveProvider.products(title);
    listDataRowProduct.value = listProduct.map((product) {
      return DataRow(cells: [
        DataCell(Text(product.title)),
        DataCell(Center(child: Text(product.price.toString()))),
        DataCell(Center(child: Text("${product.discountPercentage} %"))),
        DataCell(Center(child: Text(product.stock.toString()))),
        DataCell(
          const Center(child: Icon(Icons.add)),
          onTap: () {
            Get.toNamed(AppPages.receivePage,arguments: {
              "product" : product
            });
            // costumAddDialogAction(product);
          },
        ),
      ]);
    }).toList();
    isCellLoad.value = false;
  }

  void costumAddDialogAction(ProductModel product) {
    Get.defaultDialog(
      title: "Add Product",
      titleStyle: const TextStyle(fontSize: 20),
      textConfirm: "Oke",
      textCancel: "Cancel",
      middleText: product.title,
      contentPadding: const EdgeInsets.all(20),
      onConfirm: () {
        Get.back();
        Get.snackbar("", "${product.id} success",
            titleText: const Text(
              "Status",
              style: TextStyle(color: Colors.green),
            ));
      },
    );
  }
}
