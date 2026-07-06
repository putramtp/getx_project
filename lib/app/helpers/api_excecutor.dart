import 'package:get/get.dart';

import '../global/alert.dart';
import '../services/network_service.dart';

class ApiExecutor {
  static final NetworkService _networkService = Get.find<NetworkService>();

  /// Automatically checks internet, sets loading, and catches errors.
  ///
  /// Pass [hasError] to let a screen distinguish a failed load from a genuinely
  /// empty result: it's set false on success and true on any failure (no
  /// connection or thrown exception), so the view can show an error+retry state
  /// instead of the "No data" empty state.
  static Future<T?> run<T>({
    required RxBool isLoading,
    required Future<T> Function() task,
    RxBool? hasError,
  }) async {
    if (isLoading.value) return null;

    isLoading.value = true;
    hasError?.value = false;

    try {
      await _networkService.checkConnection();
      if (!_networkService.isConnected.value) {
        hasError?.value = true;
        errorAlert("No internet connection");
        return null;
      }

      // ✅ Run the actual API task
      return await task();
    } catch (e) {
      hasError?.value = true;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      errorAlert(msg);
      return null;
    } finally {
      // ✅ Always turn off loading
      isLoading.value = false;
    }
  }
}
