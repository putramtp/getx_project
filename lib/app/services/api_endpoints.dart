import '../config/app_config.dart';

/// Where a request is actually sent, and the `Host` header it must carry.
///
/// [hostHeader] is null when nothing was rewritten (the URL's own host is
/// sent as usual).
typedef ConnectTarget = ({Uri uri, String? hostHeader});

/// Builds the API URLs of the two modes (see [AppConfig]). Pure: every value
/// comes in through the constructor, so it is unit-tested without a build.
///
/// - The central host answers the email sign-in.
/// - A company's API lives on the `api_host` the sign-in answered, with the
///   central URL's scheme: `<scheme>://<api_host>/api`.
/// - [devConnectAddress] (debug builds) sends every request to that address
///   instead, keeping the real host in the `Host` header. The backend picks
///   the tenant from `Host` (stancl `InitializeTenancyByDomain`), so the
///   phone reaches the right company through `adb reverse` with no tunnel.
class ApiEndpoints {
  const ApiEndpoints({
    required this.centralApiUrl,
    required this.directApiUrl,
    this.devConnectAddress,
  });

  /// The endpoints of this build.
  factory ApiEndpoints.fromConfig() => ApiEndpoints(
        centralApiUrl: AppConfig.centralApiUrl,
        directApiUrl: AppConfig.apiBaseUrl,
        devConnectAddress: AppConfig.devConnectAddress,
      );

  final String centralApiUrl;
  final String directApiUrl;
  final String? devConnectAddress;

  /// The scheme a company's host is called with: the central URL's (they are
  /// one deployment), else the direct URL's, else https.
  String get tenantScheme {
    for (final url in [centralApiUrl, directApiUrl]) {
      final scheme = Uri.tryParse(url)?.scheme ?? '';
      if (scheme == 'http' || scheme == 'https') return scheme;
    }
    return 'https';
  }

  bool get isWorkspaceMode => centralApiUrl.isNotEmpty;

  /// The API every request of the current session goes to:
  /// - direct mode → the one company's [directApiUrl];
  /// - workspace mode, signed in → the company's host ([tenantApiHost]);
  /// - workspace mode, signed out → the central host (the sign-in itself).
  String apiBaseUrl({String? tenantApiHost}) {
    if (!isWorkspaceMode) return directApiUrl;
    final host = tenantApiHost?.trim() ?? '';
    return host.isEmpty ? centralApiUrl : tenantApiUrl(host);
  }

  /// A session stored by an older build (a token, no company host) cannot be
  /// kept in workspace mode: nothing says which company host it belongs to,
  /// so the user signs in once more. Direct mode keeps it — its host is fixed.
  bool mustDropStoredSession({required String? token, required String? tenantApiHost}) =>
      isWorkspaceMode && (token?.isNotEmpty ?? false) && (tenantApiHost?.trim().isEmpty ?? true);

  /// `<scheme>://<api_host>/api` for the company host the sign-in answered.
  String tenantApiUrl(String apiHost) {
    final host = apiHost.trim().toLowerCase().replaceAll(RegExp(r'^\.+|\.+$'), '');
    if (host.isEmpty) throw ArgumentError.value(apiHost, 'apiHost', 'empty company host');
    return '$tenantScheme://$host/api';
  }

  /// [url] as it must be sent: unchanged, or — with a dev connect address —
  /// pointed at that address, with the original authority as the `Host`.
  ConnectTarget connect(Uri url) {
    final address = devConnectAddress?.trim() ?? '';
    if (address.isEmpty || url.host.isEmpty) return (uri: url, hostHeader: null);

    final target = Uri.parse('${url.scheme}://$address');
    final rewritten = url.replace(
      host: target.host,
      port: target.hasPort ? target.port : (url.hasPort ? url.port : null),
    );
    final hostHeader = url.hasPort ? '${url.host}:${url.port}' : url.host;
    return (uri: rewritten, hostHeader: hostHeader);
  }

  /// The host the connectivity probe should resolve for [apiUrl]: the dev
  /// connect address (a `.test` name never resolves on a phone), else the
  /// URL's own host.
  String probeHost(String apiUrl) {
    final address = devConnectAddress?.trim() ?? '';
    if (address.isNotEmpty) return Uri.parse('http://$address').host;
    final host = Uri.tryParse(apiUrl)?.host ?? '';
    return host.isNotEmpty ? host : 'example.com';
  }
}
