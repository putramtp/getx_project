import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class ReceivingOrderController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController barcodeController = TextEditingController();

  Future<void> scanBarcode() async {
    try {
      String barcodeScanResult = await FlutterBarcodeScanner.scanBarcode('#ff6666', 'Cancel', true, ScanMode.BARCODE);
      barcodeController.text = barcodeScanResult;
    } catch (e) {
      barcodeController.text = '';
    }
  }

  void resetBarcode(){
     barcodeController.text = "";
  }

  
}
