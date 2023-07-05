import 'package:get/get.dart';


class LoginProvider extends GetConnect {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = 'https://dummyjson.com/';
  // }

   Future<Response> login(String username, String password) async {
   final response = await post('https://dummyjson.com/auth/login',
      {
        'username': username,
        'password': password,
      },
    );
    return response;
  }
  } 
