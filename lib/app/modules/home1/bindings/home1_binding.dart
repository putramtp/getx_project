import 'package:get/get.dart';

import '../controllers/home1_controller.dart';

class Home1Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<Home1Controller>(
      () => Home1Controller(),
    );
  }
}
