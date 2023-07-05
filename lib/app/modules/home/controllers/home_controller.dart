
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  RxInt currentIndex  = 0.obs;
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
  void onItemTapped(int index) {
    currentIndex.value = index;
  }
  

}
