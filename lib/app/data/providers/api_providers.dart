import 'package:get/get.dart';
import '../../../services/auth_service.dart';

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

  Future<Response> getUser(int id) => get('users/$id');
  Future<Response> postUser(Map data) => post('users', data);
}
