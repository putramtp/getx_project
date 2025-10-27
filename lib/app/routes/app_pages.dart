import 'package:get/get.dart';
import 'package:getx_project/app/modules/outflow_order/bindings/outflow_order_binding.dart';
import 'package:getx_project/app/modules/outflow_order/bindings/outflow_order_detail_binding.dart';
import 'package:getx_project/app/modules/outflow_order/views/outflow_order_detail_view.dart';
import 'package:getx_project/app/modules/outflow_order/views/outflow_order_view.dart';
import 'package:getx_project/app/modules/receive_order/bindings/receive_order_binding.dart';
import 'package:getx_project/app/modules/receive_order/bindings/receive_order_detail_binding.dart';
import 'package:getx_project/app/modules/receive_order/views/receive_order_detail_view.dart';
import 'package:getx_project/app/modules/receive_order/views/receive_order_view.dart';

import '../modules/dispatch/bindings/dispatch_binding.dart';
import '../modules/dispatch/views/dispatch_detail_view.dart';
import '../modules/dispatch/views/dispatch_view.dart';
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
import '../modules/return/bindings/return_binding.dart';
import '../modules/return/views/return_view.dart';
import '../middleware/auth_middleware.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const homePage = Routes.HOME;
  static const loginPage = Routes.LOGIN;

  static const inventoryPage = Routes.INVENTORY;
  static const itemPage = Routes.ITEM;

  static const receivePage = Routes.RECEIVE;
  static const receiveDetailPage = Routes.RECEIVE_DETAIL;

  static const receiveOrderPage = Routes.RECEIVE_ORDER;
  static const receiveOrderDetailPage = Routes.RECEIVE_ORDER_DETAIL;

  static const outflowOrderPage = Routes.OUTFLOW_ORDER;
  static const outflowOrderDetailPage = Routes.OUTFLOW_ORDER_DETAIL;

  static const dispatchPage = Routes.DISPATCH;
  static const dispatchDetailPage = Routes.DISPATCH_DETAIL;

  static const returnPage = Routes.RETURN;

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
      middlewares: [AuthMiddleware()],
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
        transition: Transition.leftToRight),
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
    GetPage(
      name: _Paths.RECEIVE_ORDER,
      page: () => const ReceiveOrderView(),
      binding: ReceiveOrderBinding(),
    ),
    GetPage(
      name: _Paths.RECEIVE_ORDER_DETAIL,
      page: () => const ReceiveOrderDetailView(),
      binding: ReceiveOrderDetailBinding(),
    ),
    GetPage(
      name: _Paths.OUTFLOW_ORDER,
      page: () => const OutflowOrderView(),
      binding: OutflowOrderBinding(),
    ),
    GetPage(
      name: _Paths.OUTFLOW_ORDER_DETAIL,
      page: () => const OutflowOrderDetailView(),
      binding: OutflowOrderDetailBinding(),
    ),
    GetPage(
      name: _Paths.DISPATCH,
      page: () => const DispatchView(),
      binding: DispatchBinding(),
    ),
    GetPage(
      name: _Paths.DISPATCH_DETAIL,
      page: () => const DispatchDetailView(),
      binding: DispatchBinding(),
    ),
    GetPage(
      name: _Paths.RETURN,
      page: () => const ReturnView(),
      binding: ReturnBinding(),
    ),
  ];
}
