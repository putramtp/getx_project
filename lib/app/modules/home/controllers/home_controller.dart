import 'dart:async';
import 'package:get/get.dart';
import 'package:getx_project/app/helpers/api_excecutor.dart';
import 'package:getx_project/app/models/dashboard_model.dart';
import 'package:getx_project/app/modules/home/providers/home_provider.dart';
import 'package:getx_project/app/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class HomeController extends GetxController {
  final HomeProvider provider = Get.find<HomeProvider>();

  final AuthService _authService = Get.find<AuthService>();
  final Rx<DateTime> currentTime = DateTime.now().obs;
  final dashboard = Rxn<DashboardModel>();
  var isLoading = false.obs;
  
  // final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
    loadDashboard();
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

  Future<void> loadDashboard() async {
    final thisYear =  DateTime.now().year;
    final res = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => provider.getDashboard(year:thisYear),
    );
    if (res == null) return;
    dashboard.value = res;
  }

  void reloadDashboard(){
     final defaultDashboard = DashboardModel(product: 0,receiveOrder: 0,outflowOrder: 0);
     dashboard.value = defaultDashboard;
     loadDashboard(); 
  }


  void goToProductPage() {
    Get.toNamed(AppPages.productPage);
  }

  void goToReceiveOrderHomePage() {
    Get.toNamed(AppPages.receiveHomePage);
  }

  void goToOutflowOrderHomePage() {
    Get.toNamed(AppPages.outflowHomePage);
  }

  void goToReturnPage() {
    Get.toNamed(AppPages.returnPage);
  }

  String getName() {
    String? name = _authService.currentUsername;
    return name ?? "";
  }

  String getRoles() {
    String? name = _authService.currentUserRoles;
    return name ?? "";
  }

  /// Clears the authentication token and navigates the user to the Login page.
  void logout() {
    _authService.clearToken();
    // Use offAllNamed to remove all previous routes from the stack
    Get.offAllNamed(Routes.LOGIN);
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning 🌅";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon ☀️";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening 🌇";
    } else {
      return "Good Night 🌙";
    }
  }
}
