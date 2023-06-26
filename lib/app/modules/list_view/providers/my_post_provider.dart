import 'package:get/get.dart';

import '../my_post_model.dart';

class MyPostProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.defaultDecoder = (map) {
      if (map is Map<String, dynamic>) return MyPost.fromJson(map);
      if (map is List) return map.map((item) => MyPost.fromJson(item)).toList();
    };
    httpClient.baseUrl = 'https://jsonplaceholder.typicode.com/';
  }

  Future<MyPost?> getAllMyPost() async {
    final response = await get('posts');
    return response.body;
  }
  // Future<MyPost?> getMyPost(int id) async {
  //   final response = await get('mypost/$id');
  //   return response.body;
  // }

  // Future<Response<MyPost>> postMyPost(MyPost mypost) async => await post('mypost', mypost);
  // Future<Response> deleteMyPost(int id) async => await delete('mypost/$id');
}
