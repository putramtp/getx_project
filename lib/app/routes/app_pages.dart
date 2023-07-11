import 'package:get/get.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/home1/bindings/home1_binding.dart';
import '../modules/home1/views/home1_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/receive/bindings/receive_binding.dart';
import '../modules/receive/views/category_view.dart';
import '../modules/receive/views/item_view.dart';
import '../modules/receive/views/receive_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const homePage = Routes.HOME;
  static const homePage1 = Routes.HOME1;
  static const categoryPage = Routes.CATEGORY;
  static const itemPage = Routes.ITEM;
  static const receivePage = Routes.RECEIVE;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.HOME1,
      page: () => const Home1View(),
      binding: Home1Binding(),
    ),
    GetPage(
      name: _Paths.CATEGORY,
      page: () => const SearchCategory(),
      binding: ReceiveBinding(),
    ),
    GetPage(
      name: _Paths.ITEM,
      page: () => const ItemView(),
      binding: ReceiveBinding(),
    ),
    GetPage(
      name: _Paths.RECEIVE,
      page: () => const ReceiveView(),
      binding: ReceiveBinding(),
    ),
  ];
}
