import 'package:get/get.dart';

import '../modules/outflow_order/bindings/outflow_order_list_binding.dart';
import '../modules/outflow_order/bindings/outflow_order_by_customer_binding.dart';
import '../modules/outflow_order/bindings/outflow_order_by_customer_detail_binding.dart';
import '../modules/outflow_order/bindings/outflow_order_by_request_binding.dart';
import '../modules/outflow_order/bindings/outflow_order_by_request_detail_binding.dart';
import '../modules/outflow_order/bindings/outflow_order_list_detail_binding.dart';
import '../modules/outflow_order/views/outflow_order_by_customer_detail_view.dart';
import '../modules/outflow_order/views/outflow_order_by_customer_view.dart';
import '../modules/outflow_order/views/outflow_order_by_request_detail_view.dart';
import '../modules/outflow_order/views/outflow_order_by_request_view.dart';
import '../modules/outflow_order/views/outflow_order_list_detail_view.dart';
import '../modules/outflow_order/views/outflow_order_home_view.dart';
import '../modules/outflow_order/views/outflow_order_list_view.dart';
import '../modules/product/bindings/product_transaction_list_binding.dart';
import '../modules/product/views/product_transaction_list_view.dart';
import '../modules/product/bindings/product_detail_binding.dart';
import '../modules/product/views/product_detail_view.dart';
import '../modules/receive_order/bindings/receive_order_by_po_binding.dart';
import '../modules/receive_order/bindings/receive_order_by_po_detail_binding.dart';
import '../modules/receive_order/bindings/receive_order_by_supplier_binding.dart';
import '../modules/receive_order/bindings/receive_order_by_supplier_detail_binding.dart';
import '../modules/receive_order/bindings/receive_order_list_detail_binding.dart';
import '../modules/receive_order/bindings/receive_order_list_binding.dart';
import '../modules/receive_order/views/receive_order_by_po_detail_view.dart';
import '../modules/receive_order/views/receive_order_by_supplier_detail_view.dart';
import '../modules/receive_order/views/receive_order_by_supplier_view.dart';
import '../modules/receive_order/views/receive_order_list_detail_view.dart';
import '../modules/receive_order/views/receive_order_home_view.dart';
import '../modules/receive_order/views/receive_order_by_po_view.dart';
import '../modules/receive_order/views/receive_order_list_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/product/bindings/product_binding.dart';
import '../modules/product/views/product_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/return/bindings/return_binding.dart';
import '../modules/return/views/return_view.dart';
import '../middleware/auth_middleware.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const homePage = Routes.HOME;
  static const loginPage = Routes.LOGIN;

  static const productPage = Routes.PRODUCT;
  static const productDetailPage = Routes.PRODUCT_DETAIL;
  static const productTransactionListPage = Routes.PRODUCT_TRANSACTION_LIST;

  static const itemPage = Routes.ITEM;
  //RECEIVE ORDER
  static const receiveHomePage = Routes.RECEIVE_ORDER_HOME;
  static const receiveOrderListPage = Routes.RECEIVE_ORDER_LIST;
  static const receiveOrderListDetailPage = Routes.RECEIVE_ORDER_LIST_DETAIL;
  static const receiveOrderByPoPage = Routes.RECEIVE_ORDER_BY_PO;
  static const receiveOrderByPoDetailPage = Routes.RECEIVE_ORDER_BY_PO_DETAIL;
  static const receiveOrderBySupplierPage = Routes.RECEIVE_ORDER_BY_SUPPLIER;
  static const receiveOrderBySupplierDetailPage = Routes.RECEIVE_ORDER_BY_SUPPLIER_DETAIL;
  //OUTFLOW  ORDER
  static const outflowHomePage = Routes.OUTFLOW_ORDER_HOME;
  static const outflowOrderListPage = Routes.OUTFLOW_ORDER_LIST;
  static const outflowOrderListDetailPage = Routes.OUTFLOW_ORDER_LIST_DETAIL;
  static const outflowOrderByRequestPage = Routes.OUTFLOW_ORDER_BY_REQUEST;
  static const outflowOrderByRequestDetailPage = Routes.OUTFLOW_ORDER_BY_REQUEST_DETAIL;
  static const outflowOrderByCustomerPage = Routes.OUTFLOW_ORDER_BY_CUSTOMER;
  static const outflowOrderByCustomerDetailPage = Routes.OUTFLOW_ORDER_BY_CUSTOMER_DETAIL;

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
      name: _Paths.PRODUCT,
      page: () => const ProductView(),
      binding: ProductBinding(),
    ),
    GetPage(
      name: _Paths.PRODUCT_DETAIL,
      page: () => const ProductDetailView(),
      binding: ProductDetailBinding(),
    ),
    GetPage(
      name: _Paths.PRODUCT_TRANSACTION_LIST,
      page: () => const ProductTransactionListView(),
      binding: ProductTransactionListBinding(),
    ),
    //RECEIVE ORDER
    GetPage(
      name: _Paths.RECEIVE_ORDER_HOME,
      page: () => const ReceiveOrderHomeView(),
    ),
    GetPage(
      name: _Paths.RECEIVE_ORDER_LIST,
      page: () => const ReceiveOrderListView(),
      binding: ReceiveOrderListBinding(),
    ),
    GetPage(
      name: _Paths.RECEIVE_ORDER_LIST_DETAIL,
      page: () => const ReceiveOrderListDetailView(),
      binding: ReceiveOrderListDetailBinding(),
    ),
    GetPage(
      name: _Paths.RECEIVE_ORDER_BY_PO,
      page: () => const ReceiveOrderByPoView(),
      binding: ReceiveOrderByPoBinding(),
    ),
    GetPage(
      name: _Paths.RECEIVE_ORDER_BY_PO_DETAIL,
      page: () => const ReceiveOrderByPoDetailView(),
      binding: ReceiveOrderByPoDetailBinding(),
    ),
    GetPage(
      name: _Paths.RECEIVE_ORDER_BY_SUPPLIER,
      page: () => const ReceiveOrderBySupplierView(),
      binding: ReceiveOrderBySupplierBinding(),
    ),
    GetPage(
      name: _Paths.RECEIVE_ORDER_BY_SUPPLIER_DETAIL,
      page: () => const ReceiveOrderBySupplierDetailView(),
      binding: ReceiveOrderBySupplierDetailBinding(),
    ),
    // OUTFLOW ORDER
    GetPage(
      name: _Paths.OUTFLOW_ORDER_HOME,
      page: () => const OutflowOrderHomeView(),
    ),
    GetPage(
      name: _Paths.OUTFLOW_ORDER_LIST,
      page: () => const OutflowOrderListView(),
      binding: OutflowOrderListBinding(),
    ),
    GetPage(
      name: _Paths.OUTFLOW_ORDER_LIST_DETAIL,
      page: () => const OutflowOrderDetailView(),
      binding: OutflowOrderListDetailBinding(),
    ),
    GetPage(
      name: _Paths.OUTFLOW_ORDER_BY_REQUEST,
      page: () => const OutflowOrderByRequestView(),
      binding: OutflowOrderByRequestBinding(),
    ),
    GetPage(
      name: _Paths.OUTFLOW_ORDER_BY_REQUEST_DETAIL,
      page: () => const OutflowOrderByRequestDetailView(),
      binding: OutflowOrderByRequestDetailBinding(),
    ),
    GetPage(
      name: _Paths.OUTFLOW_ORDER_BY_CUSTOMER,
      page: () => const OutflowOrderByCustomerView(),
      binding: OutflowOrderByCustomerBinding(),
    ),
    GetPage(
      name: _Paths.OUTFLOW_ORDER_BY_CUSTOMER_DETAIL,
      page: () => const OutflowOrderByCustomerDetailView(),
      binding: OutflowOrderByCustomerDetailBinding(),
    ),

    GetPage(
      name: _Paths.RETURN,
      page: () => const ReturnView(),
      binding: ReturnBinding(),
    ),
  ];
}
