import 'package:get/get.dart';


import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/inventory/bindings/inventory_binding.dart';

import '../modules/inventory/views/inventory_view.dart';
import '../modules/inventory/views/item_category_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/receive/bindings/receive_binding.dart';
import '../modules/receive/views/receive_detail_view.dart';
import '../modules/receive/views/receive_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const homePage = Routes.HOME;
  static const itemPage = Routes.ITEM;
  static const inventoryPage = Routes.INVENTORY;
  static const receivePage = Routes.RECEIVE;
  static const receiveDetailPage = Routes.RECEIVE_DETAIL;

  static final routes = [
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.INVENTORY,
      page: () => const InventoryView(),
      binding: InventoryBinding(),
    ),
    GetPage(
      name: _Paths.ITEM,
      page: () => const ItemCategoryView(),
      binding: InventoryBinding(),
      transition: Transition.leftToRight
    ),
    GetPage(
      name: _Paths.RECEIVE,
      page: () => const ReceiveView(),
      binding: ReceiveBinding(),
    ),
    GetPage(
      name: _Paths.RECEIVE_DETAIL,
      page: () => const ReceiveDetailView(),
      binding: ReceiveBinding(),
    ),
  ];
}
