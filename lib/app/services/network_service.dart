import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:getx_project/app/config/app_config.dart';
import 'package:getx_project/app/global/alert.dart';

class NetworkService extends GetxService {
  final connectivity = Connectivity();
  final RxBool isConnected = true.obs;

  /// Host used for the reachability probe — the actual API host, so a positive
  /// result means we can likely reach the backend (not just "some" network).
  late final String _probeHost = _hostFrom(AppConfig.apiBaseUrl);

  @override
  void onInit() {
    super.onInit();
    // Initial check.
    checkConnection();

    // React to interface changes. A dropped interface is definitively offline;
    // a regained interface still needs a real reachability probe (see
    // checkConnection) because "connected to Wi-Fi" ≠ "has internet".
    connectivity.onConnectivityChanged.listen((status) async {
      if (status == ConnectivityResult.none) {
        isConnected.value = false;
        infoAlertBottom(
          title: "No Internet",
          "Please check your network connection",
        );
      } else {
        await checkConnection();
      }
    });
  }

  /// Authoritative connectivity gate used before every API call. Confirms an
  /// interface exists AND that the API host actually resolves — catching the
  /// "connected but no internet" case that `connectivity_plus` alone misses.
  Future<void> checkConnection() async {
    final status = await connectivity.checkConnectivity();
    if (status == ConnectivityResult.none) {
      isConnected.value = false;
      return;
    }
    isConnected.value = await _hasInternet();
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup(_probeHost)
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  static String _hostFrom(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.isNotEmpty ? host : 'example.com';
  }
}
