import 'package:get/get.dart';

import '../controllers/list_view_controller.dart';
import '../providers/my_post_provider.dart';

class ListViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<MyPostProvider>(MyPostProvider());
    Get.lazyPut<ListViewController>(
      () => ListViewController(),
    );
  }
}
