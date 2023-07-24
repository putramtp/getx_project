import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/functions.dart';
import '../../../models/product_model.dart';
import '../providers/inventory_provider.dart';

class AllItemController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final InventoryProvider _inventoryProvider = InventoryProvider();
  final int fixedRows = 1;

  List<ProductModel> listProduct = [];
  List<ProductModel> filterListProduct = [];
  List<DataRow> listDataRow = [];
  List<DataRow> defaultListDataRow = [];

  RxList<DataRow> filterListDataRow = RxList<DataRow>();

  RxBool isSearch = false.obs;
  RxBool isCellLoad = true.obs;

  // @override
  // void onInit() {
  //   super.onInit();
  // }

  void fetchDataRowProduct (double size) async { // calling in view
      isCellLoad.value = true;
      //Product
      listProduct  = await _inventoryProvider.allProduct();
      filterListProduct = listProduct;
      //Raw table product
      listDataRow  = filterListProduct.map((product) {return rawDataRow(product,size);}).toList();
      defaultListDataRow = listDataRow;
      filterListDataRow.value = defaultListDataRow;
      isCellLoad.value = false;
  } 
    
  void onSearch(String query,double size) {
    if (query.isNotEmpty) {
      isSearch.value = true;
      filterListProduct  = listProduct.where((item)=> searchString(query,item.title)).toList();
      listDataRow  = filterListProduct.map((product) {return rawDataRow(product,size);}).toList();
      filterListDataRow.value = listDataRow;

    } else {
      isSearch.value = false;
      filterListDataRow.value = defaultListDataRow;
    }
  }

  void onCloseSearch(){
     searchController.clear();
     isSearch.value = false;
     filterListDataRow.value = defaultListDataRow; 
  }

  // void reload(){
  //   isCellLoad.value = true;
  //   filterListDataRow.value = [];
  //   filterListDataRow.value = defaultListDataRow;
  //   isCellLoad.value = false;
  // }

  DataRow rawDataRow(ProductModel product,double size){
      return DataRow(cells: [
        DataCell(Text(product.title,style:TextStyle(fontSize: size * 1.2),)),
        DataCell(Text(product.price.toString(),style:TextStyle(fontSize: size * 1.2))),
        DataCell(Text("${product.discountPercentage} %",style:TextStyle(fontSize: size * 1.2))),
        DataCell(Text(product.stock.toString(),style:TextStyle(fontSize: size * 1.2))),
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
