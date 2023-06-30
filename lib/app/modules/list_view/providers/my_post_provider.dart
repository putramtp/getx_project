import 'dart:convert';

import 'package:get/get.dart';

import '../my_post_model.dart';

class MyPostProvider extends GetConnect {
  // @override
  // void onInit() {
  //   httpClient.baseUrl = 'https://jsonplaceholder.typicode.com';
  //   log("on Init = ${httpClient.baseUrl} ");
  // }

  Future<List<MyPost>> getAllMyPost() async {
    httpClient.baseUrl = 'https://jsonplaceholder.typicode.com';
    final response = await httpClient.get('/posts');
    if (response.status.hasError) {
      return Future.error(response.statusText.toString());
    } else {
      final jsonData = json.decode(response.bodyString.toString());
      return MyPost.listFromJson(jsonData);
    }
  }
  
}
