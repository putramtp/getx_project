import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';


class ReceiveController extends GetxController {
    // final ProductModel product = Get.arguments["product"];
   final String  title = "receive";
  final TextEditingController barcodeController = TextEditingController();
   final GlobalKey<FormState> formKey = GlobalKey<FormState>();


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
