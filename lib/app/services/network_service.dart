import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:getx_project/app/services/api_endpoints.dart';
import 'package:getx_project/app/services/auth_service.dart';
import 'package:getx_project/app/global/alert.dart';

class NetworkService extends GetxService {
  final connectivity = Connectivity();
  final RxBool isConnected = true.obs;

  /// Host used for the reachability probe — the API host of the current
  /// session (the company once signed in, the central host before), or the
  /// dev connect address, so a positive result means we can likely reach the
  /// backend (not just "some" network). Read per check: it changes on sign-in.
  String get _probeHost {
    if (Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      return auth.endpoints.probeHost(auth.apiBaseUrl);
    }
    final endpoints = ApiEndpoints.fromConfig();
    return endpoints.probeHost(endpoints.apiBaseUrl());
  }

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

  /// Checks once before a screen fires several calls together (Home, the
  /// delivery detail): offline, one "No internet connection" — not one per
  /// call — and false, so the caller skips them.
  Future<bool> ensureOnline() async {
    await checkConnection();
    if (!isConnected.value) errorAlert("No internet connection");
    return isConnected.value;
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

}
