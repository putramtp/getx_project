import 'package:get/get.dart';
import '../../../data/providers/api_providers.dart';
class LoginProvider extends ApiProvider {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = 'https://dummyjson.com/';
  // }

  Future<Response> login(String username, String password) async {
    final response = await post(
      '/login',
      {
        'username': username,
        'password': password,
      },
    );
    return response;
  }
}
