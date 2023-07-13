import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/functions.dart';
import '../../../models/product_model.dart';
import '../providers/inventory_provider.dart';

class AllItemController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final InventoryProvider _receiveProvider = InventoryProvider();
  final int fixedRows = 1;

  List<ProductModel> listProduct = [];
  List<ProductModel> filterListProduct = [];
  List<DataRow> listDataRow = [];
  List<DataRow> defaultListDataRow = [];

  RxList<DataRow> filterListDataRow = RxList<DataRow>();

  RxBool isSearch = false.obs;
  RxBool isCellLoad = true.obs;

  @override
  void onInit() {
    fetchDataRowProduct () ;
    super.onInit();
  }

  void fetchDataRowProduct () async {
      isCellLoad.value = true;
      //Product
      listProduct  = await _receiveProvider.allProduct();
      filterListProduct = listProduct;
      //Raw table product
      listDataRow  = filterListProduct.map((product) {return rawDataRow(product);}).toList();
      defaultListDataRow = listDataRow;
      filterListDataRow.value = defaultListDataRow;
      isCellLoad.value = false;
  } 
    
  void onSearch(String query) {
    if (query.isNotEmpty) {
      isSearch.value = true;
      filterListProduct  = listProduct.where((item)=> searchString(query,item.title)).toList();
      listDataRow  = filterListProduct.map((product) {return rawDataRow(product);}).toList();
      filterListDataRow.value = listDataRow;

    } else {
      isSearch.value = false;
      filterListDataRow.value = defaultListDataRow;
    }
  }

  void onCloseSearch(){
     searchController.clear();
     isSearch.value = false; 
  }

  void reload(){
    isCellLoad.value = true;
    filterListDataRow.value = [];
    filterListDataRow.value = defaultListDataRow;
    isCellLoad.value = false;
  }

  DataRow rawDataRow(ProductModel product){
      return DataRow(cells: [
        DataCell(Text(product.title)),
        DataCell(Center(child: Text(product.price.toString()))),
        DataCell(Center(child: Text("${product.discountPercentage} %"))),
        DataCell(Center(child: Text(product.stock.toString()))),
      ]);
  }






  // @override
  // void onInit() {
  //   super.onInit();
  // }

  // @override
  // void onReady() {
  //   super.onReady();
  // }

  // @override
  // void onClose() {
  //   super.onClose();
  // }
}
