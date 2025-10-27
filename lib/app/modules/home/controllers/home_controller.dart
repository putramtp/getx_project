import 'dart:async';
import 'package:get/get.dart';
import 'package:getx_project/app/modules/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class HomeController extends GetxController {

  // Inject AuthService (This assumes it has been registered in main.dart)
  final AuthService _authService = Get.find<AuthService>();

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
  void goToReceiveOrderPage(){
     Get.toNamed(AppPages.receiveOrderPage);
  }
  void goToOutflowOderPage(){
     Get.toNamed(AppPages.outflowOrderPage);
  }
  void goToDispatchPage(){
     Get.toNamed(AppPages.dispatchPage);
  }
  void goToReturnPage(){
     Get.toNamed(AppPages.returnPage);
  }

  String getName(){
    String? name = _authService.currentUsername;
    return name ?? "";
  }

  String getRoles(){
    String? name = _authService.currentUserRoles;
    return name ?? "";
  }

  /// Clears the authentication token and navigates the user to the Login page.
  void logout() {
    _authService.clearToken();
    // Use offAllNamed to remove all previous routes from the stack
    Get.offAllNamed(Routes.LOGIN);
  }
}
