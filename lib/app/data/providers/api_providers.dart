import 'package:get/get.dart';
import '../../services/auth_service.dart';

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
      return request;
    });

  }

  void checkResponse(Response response) {
    final code = response.statusCode;
    if (code == null) {
      throw Exception('No response from server. Check the API URL or network.');
    }
    if (code < 200 || code >= 300) {
      String? serverMsg;
      if (response.body is Map) {
        serverMsg = response.body['message']?.toString();
      }
      throw Exception(
        serverMsg ?? 'HTTP $code${response.statusText != null ? ": ${response.statusText}" : ""}',
      );
    }
  }
}
