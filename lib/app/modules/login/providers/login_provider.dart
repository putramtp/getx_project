import 'package:get/get.dart';
import 'package:getx_project/app/global/variables.dart';

class LoginProvider extends GetConnect {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = 'https://dummyjson.com/';
  // }

  Future<Response> login(String username, String password) async {
    final response = await post(
      '$baseUrlApi/login',
      {
        'username': username,
        'password': password,
      },
    );
    return response;
  }
}
