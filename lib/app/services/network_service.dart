import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../global/alert.dart';

class NetworkService extends GetxService {
  final connectivity = Connectivity();
  final RxBool isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Initial connectivity check (sync, but may be slightly delayed)
    connectivity.checkConnectivity().then((status) {
      isConnected.value = status != ConnectivityResult.none;
    });

    // Listen for connectivity changes
    connectivity.onConnectivityChanged.listen((status) {
      isConnected.value = status != ConnectivityResult.none;
      if (!isConnected.value) {
        infoAlertBottom(
          title: "No Internet",
          "Please check your network connection",
        );
      }
    });
  }

  Future<void> checkConnection() async {
    final status = await connectivity.checkConnectivity();
    isConnected.value = status != ConnectivityResult.none;
  }
}
