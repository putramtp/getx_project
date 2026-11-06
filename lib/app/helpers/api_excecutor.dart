import 'package:get/get.dart';

import '../data/providers/api_providers.dart';
import '../global/alert.dart';
import '../services/auth_service.dart';
import '../services/network_service.dart';

class ApiExecutor {
  static final NetworkService _networkService = Get.find<NetworkService>();

  /// Automatically checks internet, sets loading, and catches errors.
  ///
  /// Pass [hasError] to let a screen distinguish a failed load from a genuinely
  /// empty result: it's set false on success and true on any failure (no
  /// connection or thrown exception), so the view can show an error+retry state
  /// instead of the "No data" empty state.
  ///
  /// [quiet] shows no alert on failure — for a follow-up call (a resync after
  /// a failed save) whose cause was already reported by the call before it.
  static Future<T?> run<T>({
    required RxBool isLoading,
    required Future<T> Function() task,
    RxBool? hasError,
    bool sessionBound = true,
    bool quiet = false,
  }) async {
    if (isLoading.value) return null;

    final session = _session;
    isLoading.value = true;
    hasError?.value = false;

    try {
      await _networkService.checkConnection();
      if (!_networkService.isConnected.value) {
        hasError?.value = true;
        if (!quiet) errorAlert("No internet connection");
        return null;
      }

      // ✅ Run the actual API task
      return await task();
    } catch (e) {
      hasError?.value = true;
      // The user signed out (or another user signed in) while this ran: its
      // failure — typically a 401 for the old token — is no longer theirs.
      // Pass `sessionBound: false` for the sign-in itself, which changes the
      // session on purpose and must still show why it failed.
      if (sessionBound && _session != session) return null;
      // The session-ending answer already said why on the login screen.
      if (e is SessionEndedException || quiet) return null;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      errorAlert(msg);
      return null;
    } finally {
      // ✅ Always turn off loading
      isLoading.value = false;
    }
  }

  static int? get _session =>
      Get.isRegistered<AuthService>() ? Get.find<AuthService>().session : null;
}
