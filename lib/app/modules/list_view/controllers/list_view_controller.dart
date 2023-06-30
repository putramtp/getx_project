

import 'package:get/get.dart';

import '../my_post_model.dart';
import '../providers/my_post_provider.dart';

class ListViewController extends GetxController {
  final MyPostProvider _apiPost = MyPostProvider();
   RxList<MyPost> listPost = <MyPost>[].obs;
  final count = 0.obs;
  @override
  void onInit() {
    test();
    super.onInit();
  }

  // @override
  // void onReady() {
  //   super.onReady();
  // }

  // @override
  // void onClose() {
  //   super.onClose();
  // }

  Future<void> test() async {
    listPost.clear();
    listPost.value = await _apiPost.getAllMyPost();
  }

  void increment() => count.value++;
}
