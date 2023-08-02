import 'dart:async';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class HomeController extends GetxController {
  final Rx<DateTime> currentTime = DateTime.now().obs;

  // final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
      Timer.periodic(const Duration(seconds: 1), (timer) {
      currentTime.value = DateTime.now();
    });
  }

  // @override
  // void onReady() {
  //   super.onReady();
  // }

  // @override
  // void onClose() {
  //   super.onClose();
  // }

  // void increment() => count.value++;

  void goToInventoryPage(){
     Get.toNamed(AppPages.inventoryPage);
  }
  void goToReceivePage(){
     Get.toNamed(AppPages.receivePage);
  }
  void goToDispatchPage(){
     Get.toNamed(AppPages.dispatchPage);
  }
  void goToReturnPage(){
     Get.toNamed(AppPages.returnPage);
  }
}
