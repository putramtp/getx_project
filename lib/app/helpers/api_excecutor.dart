import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/services/network_service.dart';

class ApiExecutor {
  static final NetworkService _networkService = Get.find<NetworkService>();

  /// Automatically checks internet, sets loading, and catches errors
  static Future<T?> run<T>({
    required RxBool isLoading,
    required Future<T> Function() task,
  }) async {
    if (isLoading.value) return null;

    isLoading.value = true;

    try {
      await _networkService.checkConnection();
      if (!_networkService.isConnected.value) {
        errorAlert("No internet connection");
        return null;
      }

      // ✅ Run the actual API task
      return await task();
    } catch (e) {
      errorAlert("Unexpected error: $e");
      return null;
    } finally {
      // ✅ Always turn off loading
      isLoading.value = false;
    }
  }
}
