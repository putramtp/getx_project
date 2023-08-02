
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';

class ReturnController extends GetxController  with GetSingleTickerProviderStateMixin  {
  late final TabController tabController;
  RxBool isScannedExist = false.obs;
  RxString barcodeScanResult = "".obs;
  @override
  void onInit() {
    super.onInit();
     tabController = TabController(length: 3, vsync: this);
  }
  // @override
  // void onReady() {
  //   super.onReady();
  // }
  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> scanBarcode() async {
    barcodeScanResult.value = "";
    try {
      barcodeScanResult.value = await FlutterBarcodeScanner.scanBarcode('#ff6666', 'Cancel', true, ScanMode.BARCODE);
      if (barcodeScanResult.isNotEmpty) {
          isScannedExist.value = true;
      }
    } catch (e) {
      barcodeScanResult.value = "";
    }
  }
}

//https://dummyjson.com/carts/1
class DetailModel {
  final int? id;
  final String title;
  final bool isHaveScan;
  int? price;
  int? quantity;

  DetailModel({
    required this.isHaveScan,
    required this.id,
    required this.title,
    this.price,
    this.quantity,
  });


}
