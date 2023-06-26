import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final count = 0.obs;
  increment() => count.value++;
  cobaDialog() => Get.defaultDialog(
      title: 'GetX Alert',
      middleText: 'Simple GetX alert',
      textConfirm: 'Okay',
      confirmTextColor: Colors.white,
      textCancel: 'Cancel');

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
