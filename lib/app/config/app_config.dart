/// Centralized, build-time app configuration.
///
/// Values are injected at build time via `--dart-define` so the same source
/// ships to every environment without a hardcoded host. Example:
///
/// ```
/// flutter run   --dart-define=API_BASE_URL=https://your-tunnel.ngrok-free.app/api
/// flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com/api
/// ```
///
/// When nothing is passed, [apiBaseUrl] falls back to [_devFallbackBaseUrl]
/// (the local ngrok dev tunnel) so day-to-day development keeps working.
class AppConfig {
  AppConfig._();

  /// Dev-only fallback used when no `API_BASE_URL` is provided at build time.
  /// NOTE: ngrok-free URLs rotate on restart — always pass `--dart-define`
  /// for anything you intend to ship.
  static const String _devFallbackBaseUrl =
      'https://allowing-toucan-ghastly.ngrok-free.app/api';

  /// Base URL for all API requests. Set via `--dart-define=API_BASE_URL=...`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _devFallbackBaseUrl,
  );

  /// Global request timeout. Override with `--dart-define=API_TIMEOUT_SECONDS=...`.
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  /// True when the app is running against the dev fallback tunnel rather than
  /// an explicitly configured host. Useful for showing a dev banner.
  static const bool isUsingDevFallback =
      apiBaseUrl == _devFallbackBaseUrl;
}
