import 'package:flutter/foundation.dart';

/// Centralized, build-time app configuration.
///
/// Values are injected at build time via `--dart-define` (or
/// `--dart-define-from-file=env/<name>.json`), so the same source ships to
/// every environment without a hardcoded host. Two modes:
///
/// - **workspace** — `CENTRAL_API_URL` is set (e.g. `https://app.<domain>/api`).
///   Email sign-in on the central host, then every request goes to the
///   signed-in company's own host. One build serves every company.
/// - **direct** — only `API_BASE_URL` is set: one company's API, signed in
///   with the old `POST /login`. Single-tenant builds and legacy dev.
///
/// ```
/// flutter run --dart-define-from-file=env/dev.json
/// flutter build apk --release --dart-define-from-file=env/prod.json
/// ```
///
/// There is no built-in fallback host: a build without either URL stops at
/// startup with [configurationError] instead of quietly calling a wrong host.
class AppConfig {
  AppConfig._();

  /// Central (app-host) API for the email sign-in. Set → workspace mode.
  static const String centralApiUrl = String.fromEnvironment('CENTRAL_API_URL');

  /// A single company's API (direct mode, old `POST /login`).
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Debug builds only: connect to this address (`127.0.0.1`, a LAN IP,
  /// optionally `:port`) while still sending the real host in the `Host`
  /// header — how a phone reaches the dev server through `adb reverse`
  /// without a tunnel. Ignored in release builds.
  static const String _devConnectAddress = String.fromEnvironment('DEV_CONNECT_ADDRESS');

  /// Global request timeout. Override with `--dart-define=API_TIMEOUT_SECONDS=...`.
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  static bool get isWorkspaceMode => centralApiUrl.isNotEmpty;
  static bool get isDirectMode => !isWorkspaceMode;

  /// The dev connect address, or null (unset, or a release build).
  static String? get devConnectAddress =>
      kReleaseMode || _devConnectAddress.isEmpty ? null : _devConnectAddress;

  /// The API the app talks to before anyone is signed in: the central host in
  /// workspace mode, the one company's host in direct mode.
  static String get defaultApiUrl => isWorkspaceMode ? centralApiUrl : apiBaseUrl;

  /// Why this build cannot run, or null when it can. Checked by
  /// `initServices()` before anything reads a URL.
  static String? configurationError() => describeConfigurationError(
        centralApiUrl: centralApiUrl,
        apiBaseUrl: apiBaseUrl,
      );

  /// [configurationError] for given values — pure, so it can be unit-tested.
  @visibleForTesting
  static String? describeConfigurationError({required String centralApiUrl, required String apiBaseUrl}) {
    if (centralApiUrl.isEmpty && apiBaseUrl.isEmpty) {
      return 'No API configured. Build with --dart-define-from-file=env/<name>.json '
          '(CENTRAL_API_URL for email sign-in, or API_BASE_URL for one company). '
          'See env/dev.example.json.';
    }
    for (final (name, value) in [('CENTRAL_API_URL', centralApiUrl), ('API_BASE_URL', apiBaseUrl)]) {
      if (value.isEmpty) continue;
      final uri = Uri.tryParse(value);
      if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
        return '$name must be an http(s) URL such as https://app.example.com/api (got "$value").';
      }
    }
    return null;
  }
}
