import 'api_providers.dart';
class LoginProvider extends ApiProvider {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = 'https://dummyjson.com/';
  // }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await post('/login', {
      'username': username,
      'password': password,
    });
    checkResponse(response);
    return Map<String, dynamic>.from(response.body as Map);
  }
}
