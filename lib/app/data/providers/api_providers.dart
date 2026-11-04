import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../config/app_config.dart';
import '../../global/alert.dart';
import '../../services/auth_service.dart';
import '../../routes/app_pages.dart';

class ApiProvider extends GetConnect {
  final AuthService _authService = Get.find<AuthService>();

  /// The API this provider's relative paths resolve against, read before
  /// every request: the signed-in company's host, the central host while
  /// signed out (workspace mode), or the one company (direct mode). See
  /// [AuthService.apiBaseUrl]. A provider bound to one host overrides it.
  String get requestBaseUrl => _authService.apiBaseUrl;

  /// Whether the bearer token rides on this provider's requests. False for a
  /// provider whose host is not the session's (the central sign-in).
  bool get sendsToken => true;

  @protected
  AuthService get authService => _authService;

  @override
  void onInit() {
    super.onInit();
    // Base URL + timeout come from build-time config (`--dart-define`), not a
    // hardcoded host. See AppConfig. The base URL is synced again before
    // every request ([_syncBaseUrl]): each provider is its own GetConnect,
    // and the company host changes when someone signs in or out.
    httpClient.baseUrl = requestBaseUrl;
    httpClient.timeout = const Duration(seconds: AppConfig.apiTimeoutSeconds);

    httpClient.addRequestModifier<dynamic>((request) async {
      // Skip ngrok-free's browser-warning interstitial so the tunnel
      // returns real JSON instead of an HTML page (which would make
      // response.body a String and break `body['data']` parsing). Only for
      // ngrok hosts: no other server needs to see it.
      if (isNgrokHost(request.url.host)) {
        request.headers['ngrok-skip-browser-warning'] = 'true';
      }
      // 🔒 Automatically attach Authorization header if token exists — unless
      // the call set its own (signOut revokes the token it is clearing).
      final token = _authService.currentToken;
      if (sendsToken && token != null && token.isNotEmpty && !request.headers.containsKey('Authorization')) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      // Force JSON responses. Without this, Laravel treats the request as a
      // browser and redirects unauthenticated calls to an HTML login page
      // (302 → String body) instead of returning `401 {"message":...}` JSON.
      request.headers['Accept'] = 'application/json';
      // Dev builds with DEV_CONNECT_ADDRESS: connect to that address (e.g.
      // 127.0.0.1 through `adb reverse`) but keep the real host in `Host` —
      // the backend picks the tenant from it.
      final target = _authService.endpoints.connect(request.url);
      if (target.hostHeader == null) return request;
      request.headers['Host'] = target.hostHeader!;
      return request.copyWith(url: target.uri);
    });
  }

  /// Points relative paths at [requestBaseUrl] for the request about to be
  /// built (GetConnect joins `baseUrl + path` when the request is created).
  void _syncBaseUrl() => httpClient.baseUrl = requestBaseUrl;

  /// True for the ngrok tunnel hosts that need `ngrok-skip-browser-warning`.
  static bool isNgrokHost(String host) {
    final h = host.toLowerCase();
    return h.endsWith('.ngrok-free.app') || h.endsWith('.ngrok.app') || h.endsWith('.ngrok.io') || h.endsWith('.ngrok-free.dev');
  }

  @override
  Future<Response<T>> post<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    _syncBaseUrl();
    return super.post<T>(url, body,
        contentType: contentType, headers: headers, query: query, decoder: decoder, uploadProgress: uploadProgress);
  }

  @override
  Future<Response<T>> put<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    _syncBaseUrl();
    return super.put<T>(url, body,
        contentType: contentType, headers: headers, query: query, decoder: decoder, uploadProgress: uploadProgress);
  }

  @override
  Future<Response<T>> patch<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    _syncBaseUrl();
    return super.patch<T>(url, body,
        contentType: contentType, headers: headers, query: query, decoder: decoder, uploadProgress: uploadProgress);
  }

  @override
  Future<Response<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) {
    _syncBaseUrl();
    return super.delete<T>(url, headers: headers, contentType: contentType, query: query, decoder: decoder);
  }

  @override
  Future<Response<T>> request<T>(
    String url,
    String method, {
    dynamic body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    _syncBaseUrl();
    return super.request<T>(url, method,
        body: body, contentType: contentType, headers: headers, query: query, decoder: decoder, uploadProgress: uploadProgress);
  }

  /// GETs are resent once when they died on a stale keep-alive socket: the
  /// tunnel closes idle connections, and the next request reusing one fails
  /// ("Broken pipe") before it ever reaches the server. Writes are never
  /// resent — the server may have applied them.
  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) async {
    Future<Response<T>> send() {
      _syncBaseUrl();
      return super.get<T>(url, headers: headers, contentType: contentType, query: query, decoder: decoder);
    }
    final response = await send();
    if (response.statusCode == null && isStaleConnection(response.statusText)) {
      return send();
    }
    return response;
  }

  /// True for transport errors caused by reusing a connection the other end
  /// already closed (safe to retry on a fresh one) — not timeouts or DNS.
  static bool isStaleConnection(String? statusText) {
    final text = (statusText ?? '').toLowerCase();
    return text.contains('broken pipe') ||
        text.contains('connection reset') ||
        text.contains('connection closed before');
  }

  void checkResponse(Response response) {
    final code = response.statusCode;
    if (code == null) {
      // GetConnect swallows the transport error and keeps it in statusText
      // ("Can not connect to server. Reason: ..."); show it rather than lose it.
      final reason = response.statusText;
      throw Exception('No response from server. Check the API URL or network.'
          '${reason != null && reason.isNotEmpty ? '\n$reason' : ''}');
    }
    if (code < 200 || code >= 300) {
      final body = response.body is Map ? response.body as Map : null;
      // An answer that ends the session (expired token, password change
      // owed, suspended company, lapsed subscription): sign out and say why.
      // Only when the request carried the *current* token: not for the login
      // request itself (bad credentials, no token), and not for a request
      // still in flight from before a logout or from the previous user's
      // session. ApiExecutor drops the thrown error — the notice says it all.
      if (_sentWithCurrentToken(response)) {
        final notice = sessionEndNotice(code, body);
        if (notice != null) {
          // A 401 token is already dead; the others are still valid — revoke them.
          signOut(notice: notice, revoke: code != 401);
          throw SessionEndedException(notice);
        }
      }
      String? serverMsg;
      if (body != null) {
        // An outflow that would take expired batches/serials out: the caller
        // shows the list and resends with `confirm_expired: true`.
        if (code == 409 && body['error_code'] == ExpiredStockException.errorCode) {
          throw ExpiredStockException.fromBody(body);
        }
        // The submit's idempotency key was already spent on a saved submit
        // (sent with another body): the caller drops the key.
        if (code == 409 && body['error_code'] == SubmitAlreadySavedException.errorCode) {
          throw SubmitAlreadySavedException(
              body['message']?.toString() ?? 'This submit was already saved. Reload the list to see it.');
        }
        serverMsg = body['message']?.toString();
        // Surface the extra detail the backend sends alongside `message`
        // (e.g. errorResponse(..., ["error" => $e->getMessage()]) or a
        // Laravel `errors` validation map) so the real cause reaches the
        // user instead of just the generic summary.
        final detail = _stringifyDetail(body['error'] ?? body['errors']);
        if (detail != null && detail.isNotEmpty && detail != serverMsg) {
          serverMsg = serverMsg == null || serverMsg.isEmpty ? detail : '$serverMsg\n$detail';
        }
        // A technical failure is logged server-side and answered with a short
        // reference instead of its raw message; show it so the user can quote it.
        final reference = body['reference']?.toString();
        if (reference != null && reference.isNotEmpty) {
          serverMsg = '${serverMsg ?? 'HTTP $code'}\nReference: $reference';
        }
      }
      // Throttled (sign-in: 5 a minute per device, 20 an hour per account):
      // say how long to wait.
      if (code == 429) {
        final hint = retryAfterHint(body?['retry_after'] ?? response.headers?['retry-after']);
        serverMsg = '${serverMsg ?? 'Too many requests.'}\n$hint';
      }
      throw Exception(
        serverMsg ?? 'HTTP $code${response.statusText != null ? ": ${response.statusText}" : ""}',
      );
    }
    // A 2xx with a non-JSON body (e.g. an ngrok/HTML interstitial or a
    // misconfigured tunnel) means parsing `body['data']` would throw a
    // cryptic "String is not a subtype of int of 'index'". Fail clean instead.
    if (response.body is String) {
      throw Exception('Unexpected response from server. Check the API URL.');
    }
  }

  /// Ends the session: revokes the token on the server (`POST /logout`, in
  /// the background — a dead tunnel must not hold up signing out), clears it
  /// locally and returns to the login screen. [notice] tells the user why.
  Future<void> signOut({String? notice, bool revoke = true}) async {
    final token = _authService.currentToken;
    if (revoke && token != null && token.isNotEmpty) unawaited(revokeToken(token));
    await _authService.clearToken();
    Get.offAllNamed(Routes.LOGIN);
    if (notice != null) warningAlertBottom(notice, title: 'Signed out');
  }

  /// `POST /logout` for [token] (not necessarily the stored one). Best effort:
  /// the token dies on its own after its lifetime anyway.
  Future<void> revokeToken(String token) async {
    try {
      await post('/logout', const <String, dynamic>{}, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static const passwordChangeNotice = 'Your password must be changed before you can use the app. '
      'Change it on the web, then sign in here again.';

  /// What to tell the user when [code] ends their session, or null when it
  /// does not. Keyed on the backend's `error_code`, since a plain 403 is also
  /// an ordinary permission denial.
  static String? sessionEndNotice(int code, Map? body) {
    final message = body?['message']?.toString();
    final errorCode = body?['error_code'];
    if (code == 401) {
      // "Unauthenticated." is the framework's expired/revoked token answer;
      // anything else (a deactivated account) is worth showing as is.
      return message == null || message.isEmpty || message == 'Unauthenticated.'
          ? 'Your session has expired. Please sign in again.'
          : message;
    }
    if (code == 403 && errorCode == 'PASSWORD_CHANGE_REQUIRED') return passwordChangeNotice;
    if (code == 403 && errorCode == 'TENANT_SUSPENDED') {
      return message ?? "This company's account is suspended. Please contact your administrator.";
    }
    if (code == 402 && errorCode == 'SUBSCRIPTION_EXPIRED') {
      return "The company's subscription has expired. Renew it on the web, then sign in here again.";
    }
    return null;
  }

  /// "Try again in 40 seconds." from a `retry_after` / `Retry-After` value.
  static String retryAfterHint(Object? retryAfter) {
    final seconds = int.tryParse('${retryAfter ?? ''}'.trim());
    if (seconds == null || seconds <= 0) return 'Please wait a moment and try again.';
    if (seconds < 60) return 'Try again in $seconds second${seconds == 1 ? '' : 's'}.';
    final minutes = (seconds / 60).ceil();
    return 'Try again in $minutes minute${minutes == 1 ? '' : 's'}.';
  }

  bool _sentWithCurrentToken(Response response) {
    final token = _authService.currentToken;
    if (token == null || token.isEmpty) return false;
    final sent = response.request?.headers['Authorization'] ?? response.request?.headers['authorization'];
    return sent == 'Bearer $token';
  }

  /// Flatten an error `detail` payload into a single human-readable string.
  /// Handles a plain string (`"error": "..."`), a list of messages, and
  /// Laravel's validation map (`"errors": {field: [msg, ...]}`).
  String? _stringifyDetail(dynamic detail) {
    if (detail == null) return null;
    if (detail is String) return detail;
    if (detail is List) return detail.join('\n');
    if (detail is Map) {
      return detail.values.expand((v) => v is List ? v : [v]).join('\n');
    }
    return detail.toString();
  }

  /// GET a `{"data": [...]}` list endpoint and map each element with [fromJson].
  /// Folds the repeated `get → checkResponse → response.body['data'].map(...)`
  /// pattern shared by every list-returning provider method.
  Future<List<T>> getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? query,
  }) async {
    final response = await get(path, query: query);
    checkResponse(response);
    final List data = response.body['data'] ?? [];
    return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET an endpoint that returns a JSON object (e.g. paginated `{data, cursor}`
  /// envelopes). Runs `get → checkResponse` and returns the body as a Map.
  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await get(path, query: query);
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }

  /// GET a file (a delivery proof) as raw bytes. GetConnect decodes every body
  /// to a string, which mangles binary data, so a successful body is read in
  /// the response interceptor — before decoding. An error body (JSON) is
  /// decoded as usual so [checkResponse] reports the server's message.
  Future<Uint8List> getBytes(String path) async {
    _syncBaseUrl();
    Future<Response<Object?>> send() => httpClient.get<Object?>(path,
        responseInterceptor: (request, type, raw) async {
      if (raw.statusCode < 200 || raw.statusCode >= 300) return null;
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in raw) {
        bytes.add(chunk);
      }
      return Response<Object?>(statusCode: raw.statusCode, body: bytes.takeBytes());
    });
    var response = await send();
    if (response.statusCode == null && isStaleConnection(response.statusText)) {
      response = await send();
    }
    checkResponse(response);
    return response.body as Uint8List;
  }

  /// Header carrying a submit's idempotency key (see `SubmitKey`). The backend
  /// replays the saved answer for a key it has seen, so a resend after a lost
  /// response does not book the document twice.
  static const idempotencyHeader = 'Idempotency-Key';

  /// POST [body] to an endpoint and return the JSON object response.
  /// Runs `post → checkResponse` and returns the body as a Map. Pass
  /// [idempotencyKey] on a submit that must not be applied twice.
  Future<Map<String, dynamic>> postMap(String path, dynamic body, {String? idempotencyKey}) async {
    final response = await post(path, body,
        headers: idempotencyKey == null ? null : {idempotencyHeader: idempotencyKey});
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }
}

/// `409 submit_already_saved`: the submit's idempotency key belongs to a
/// submit the server already saved with a different body. The key is spent —
/// drop it and reload the list.
/// The answer ended the session (expired token, password change owed,
/// suspended company, lapsed subscription): [ApiProvider.signOut] already
/// returned to login and showed [message], so [ApiExecutor] shows nothing
/// more — not even for the sign-in itself (`sessionBound: false`).
class SessionEndedException implements Exception {
  final String message;
  SessionEndedException(this.message);

  @override
  String toString() => message;
}

class SubmitAlreadySavedException implements Exception {
  static const errorCode = 'submit_already_saved';

  final String message;
  SubmitAlreadySavedException(this.message);

  @override
  String toString() => message;
}

/// `409 expired_batch`: the outflow would take expired batches or serials out
/// of stock. [expired] holds one human-readable line per batch/serial
/// ("Batch LOT-1 (Valve) expired on 3 Oct 2026"); resend with
/// `confirm_expired: true` once the user confirms.
class ExpiredStockException implements Exception {
  static const errorCode = 'expired_batch';

  final String message;
  final List<String> expired;

  ExpiredStockException(this.message, this.expired);

  factory ExpiredStockException.fromBody(Map body) {
    final list = body['expired'] is List ? body['expired'] as List : const [];
    return ExpiredStockException(
      body['message']?.toString() ?? 'Expired stock is about to leave.',
      list.whereType<Map>().map((e) => e['message']?.toString() ?? '').where((m) => m.isNotEmpty).toList(),
    );
  }

  @override
  String toString() => message;
}
