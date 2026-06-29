import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../routes/app_pages.dart';

class ApiProvider extends GetConnect {
  final AuthService _authService = Get.find<AuthService>();
  @override
  void onInit() {
    // Set base URL for all requests from this provider
    super.onInit();
    httpClient.baseUrl = "https://allowing-toucan-ghastly.ngrok-free.app/api";
    httpClient.timeout = const Duration(seconds: 30);
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
        serverMsg = response.body['message']?.toString();
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
}
