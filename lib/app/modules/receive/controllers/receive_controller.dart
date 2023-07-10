import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';

import '../../../global/functions.dart';
import '../providers/receive_provider.dart';

class ReceiveController extends GetxController {
 final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final ReceiveProvider _receivingOrderProvider = ReceiveProvider();
  RxList<String> listCategories = RxList<String>();
  RxList<String> filteListCategories = RxList<String>();
  RxBool isSearch = false.obs;
  final count = 0.obs;
  @override
  void onInit() {
    getCategories();
    super.onInit();
  }

  Future<void> scanBarcode() async {
    try {
      String barcodeScanResult = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      barcodeController.text = barcodeScanResult;
    } catch (e) {
      barcodeController.text = '';
    }
  }

  void resetBarcode() {
    barcodeController.text = "";
  }

  void getCategories() async {
    listCategories.value = await _receivingOrderProvider.categories();
    filteListCategories.value = listCategories;
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
