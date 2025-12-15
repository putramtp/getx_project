import 'package:get/get.dart';
import '../../../data/providers/home_provider.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => HomeProvider());
  }
}
