import 'api_providers.dart';
class LoginProvider extends ApiProvider {
  Future<Map<String, dynamic>> login(String username, String password) {
    return postMap('/login', {
      'username': username,
      'password': password,
    });
  }
}
