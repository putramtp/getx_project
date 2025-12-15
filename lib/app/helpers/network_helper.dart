import 'package:get/get.dart';

import '../global/alert.dart';
import '../services/network_service.dart';


class NetworkHelper {
  static final NetworkService _networkService = Get.find<NetworkService>();

  /// Wrap any async function that requires internet
  static Future<T?> runWithNetworkCheck<T>(Future<T> Function() task) async {
    await _networkService.checkConnection();
    if (!_networkService.isConnected.value) {
      errorAlert("No internet connection");
      return null;
    }

    try {
      return await task();
    } catch (e) {
      errorAlert("Unexpected error: $e");
      return null;
    }
  }
}
