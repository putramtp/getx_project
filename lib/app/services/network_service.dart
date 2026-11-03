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
    connectivity.onConnectivityChanged.listen((results) async {
      if (_noInterface(results)) {
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
    final results = await connectivity.checkConnectivity();
    if (_noInterface(results)) {
      isConnected.value = false;
      return;
    }
    isConnected.value = await _hasInternet();
  }

  /// connectivity_plus reports every active interface; offline means none.
  static bool _noInterface(List<ConnectivityResult> results) =>
      results.isEmpty || results.every((r) => r == ConnectivityResult.none);

  /// How long the DNS probe may take before it stops gating the request.
  static const probeTimeout = Duration(seconds: 8);

  /// Only a definite answer blocks: a lookup that fails (no route, host not
  /// found) means offline. A slow one — a cold resolver, a congested mobile
  /// link — is not proof of anything, so after [probeTimeout] the request goes
  /// ahead and its own timeout and error report the real problem. (A 3 s
  /// timeout that blocked used to show "No internet connection" while the
  /// network worked.)
  ///
  /// A failed lookup is tried once more after a short pause: resolvers on
  /// Android can fail transiently right after the radio wakes.
  Future<bool> _hasInternet({bool retry = true}) async {
    try {
      final result = await InternetAddress.lookup(_probeHost).timeout(probeTimeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      if (!retry) return false;
      await Future.delayed(const Duration(milliseconds: 500));
      return _hasInternet(retry: false);
    } on TimeoutException catch (_) {
      return true;
    }
  }

  static String _hostFrom(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.isNotEmpty ? host : 'example.com';
  }
}
