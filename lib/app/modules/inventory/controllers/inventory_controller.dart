import 'package:get/get.dart';

class InventoryController extends GetxController {
  RxInt selectedIndex = 0.obs;

  void onBottomNavigationTapped(int index) {
    selectedIndex.value = index;
  }

  // @override
  // void onInit() {
  //   super.onInit();
  // }
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
