import 'package:get/get.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../routes/app_pages.dart';

class ApiProvider extends GetConnect {
  final AuthService _authService = Get.find<AuthService>();
  @override
  void onInit() {
    // Set base URL for all requests from this provider
    super.onInit();
    // Base URL + timeout come from build-time config (`--dart-define`), not a
    // hardcoded host. See AppConfig.
    httpClient.baseUrl = AppConfig.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: AppConfig.apiTimeoutSeconds);
    // You can also add interceptors here
    
    // 🔒 Automatically attach Authorization header if token exists
    httpClient.addRequestModifier<dynamic>((request) async {
      final token = _authService.currentToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      // Force JSON responses. Without this, Laravel treats the request as a
      // browser and redirects unauthenticated calls to an HTML login page
      // (302 → String body) instead of returning `401 {"message":...}` JSON.
      request.headers['Accept'] = 'application/json';
      // Skip ngrok-free's browser-warning interstitial so the tunnel
      // returns real JSON instead of an HTML page (which would make
      // response.body a String and break `body['data']` parsing).
      request.headers['ngrok-skip-browser-warning'] = 'true';
      return request;
    });

  }

  void checkResponse(Response response) {
    final code = response.statusCode;
    if (code == null) {
      throw Exception('No response from server. Check the API URL or network.');
    }
    if (code < 200 || code >= 300) {
      // Session expired: a 401 while we still hold a token means the stored
      // token is no longer valid. Clear it and bounce to login. Guarded on
      // `currentToken != null` so a 401 during the login request itself
      // (bad credentials) doesn't trigger a redirect.
      if (code == 401 && _authService.currentToken != null) {
        _authService.clearToken();
        Get.offAllNamed(Routes.LOGIN);
      }
      String? serverMsg;
      if (response.body is Map) {
        final body = response.body as Map;
        serverMsg = body['message']?.toString();
        // Surface the extra detail the backend sends alongside `message`
        // (e.g. errorResponse(..., ["error" => $e->getMessage()]) or a
        // Laravel `errors` validation map) so the real cause reaches the
        // user instead of just the generic summary.
        final detail = _stringifyDetail(body['error'] ?? body['errors']);
        if (detail != null && detail.isNotEmpty && detail != serverMsg) {
          serverMsg = serverMsg == null || serverMsg.isEmpty ? detail : '$serverMsg\n$detail';
        }
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

  /// POST [body] to an endpoint and return the JSON object response.
  /// Runs `post → checkResponse` and returns the body as a Map.
  Future<Map<String, dynamic>> postMap(String path, dynamic body) async {
    final response = await post(path, body);
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }
}
