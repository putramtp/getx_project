import 'package:get/get.dart';

import 'package:getx_project/app/modules/outflow_order/bindings/outflow_order_list_binding.dart';
import 'package:getx_project/app/modules/outflow_order/bindings/outflow_order_by_customer_binding.dart';
import 'package:getx_project/app/modules/outflow_order/bindings/outflow_order_by_customer_detail_binding.dart';
import 'package:getx_project/app/modules/outflow_order/bindings/outflow_order_by_request_binding.dart';
import 'package:getx_project/app/modules/outflow_order/bindings/outflow_order_by_request_detail_binding.dart';
import 'package:getx_project/app/modules/outflow_order/bindings/outflow_order_list_detail_binding.dart';
import 'package:getx_project/app/modules/outflow_order/views/outflow_order_by_customer_detail_view.dart';
import 'package:getx_project/app/modules/outflow_order/views/outflow_order_by_customer_view.dart';
import 'package:getx_project/app/modules/outflow_order/views/outflow_order_by_request_detail_view.dart';
import 'package:getx_project/app/modules/outflow_order/views/outflow_order_by_request_view.dart';
import 'package:getx_project/app/modules/outflow_order/views/outflow_order_list_detail_view.dart';
import 'package:getx_project/app/modules/outflow_order/views/outflow_order_home_view.dart';
import 'package:getx_project/app/modules/outflow_order/views/outflow_order_list_view.dart';
import 'package:getx_project/app/modules/product-brand/bindings/product_brand_binding.dart';
import 'package:getx_project/app/modules/product-brand/bindings/product_by_brand_binding.dart';
import 'package:getx_project/app/modules/product-brand/views/product_brand_view.dart';
import 'package:getx_project/app/modules/product-brand/views/product_by_brand_view.dart';
import 'package:getx_project/app/modules/product-category/bindings/product_by_category_binding.dart';
import 'package:getx_project/app/modules/product-category/bindings/product_category_binding.dart';
import 'package:getx_project/app/modules/product-category/views/product_by_category_view.dart';
import 'package:getx_project/app/modules/product-category/views/product_category_view.dart';
import 'package:getx_project/app/modules/product-unit/bindings/product_unit_binding.dart';
import 'package:getx_project/app/modules/product-unit/views/product_unit_view.dart';
import 'package:getx_project/app/modules/product/bindings/product_transaction_list_binding.dart';
import 'package:getx_project/app/modules/product/views/product_transaction_list_view.dart';
import 'package:getx_project/app/modules/product/bindings/product_detail_binding.dart';
import 'package:getx_project/app/modules/product/views/product_detail_view.dart';
import 'package:getx_project/app/modules/receive_order/bindings/receive_order_by_po_binding.dart';
import 'package:getx_project/app/modules/receive_order/bindings/receive_order_by_po_detail_binding.dart';
import 'package:getx_project/app/modules/receive_order/bindings/receive_order_by_supplier_binding.dart';
import 'package:getx_project/app/modules/receive_order/bindings/receive_order_by_supplier_detail_binding.dart';
import 'package:getx_project/app/modules/receive_order/bindings/receive_order_confirm_binding.dart';
import 'package:getx_project/app/modules/receive_order/bindings/receive_order_list_detail_binding.dart';
import 'package:getx_project/app/modules/receive_order/bindings/receive_order_list_binding.dart';
import 'package:getx_project/app/modules/receive_order/views/receive_order_by_po_detail_view.dart';
import 'package:getx_project/app/modules/receive_order/views/receive_order_by_supplier_detail_view.dart';
import 'package:getx_project/app/modules/receive_order/views/receive_order_by_supplier_view.dart';
import 'package:getx_project/app/modules/receive_order/views/receive_order_list_detail_view.dart';
import 'package:getx_project/app/modules/receive_order/views/receive_order_home_view.dart';
import 'package:getx_project/app/modules/receive_order/views/receive_order_by_po_view.dart';
import 'package:getx_project/app/modules/receive_order/views/receive_order_confirm_view.dart';
import 'package:getx_project/app/modules/receive_order/views/receive_order_list_view.dart';
import 'package:getx_project/app/modules/delivery/bindings/delivery_list_binding.dart';
import 'package:getx_project/app/modules/delivery/bindings/delivery_detail_binding.dart';
import 'package:getx_project/app/modules/delivery/views/delivery_list_view.dart';
import 'package:getx_project/app/modules/delivery/views/delivery_detail_view.dart';
import 'package:getx_project/app/modules/home/bindings/home_binding.dart';
import 'package:getx_project/app/modules/home/views/home_view.dart';
import 'package:getx_project/app/modules/product/bindings/product_binding.dart';
import 'package:getx_project/app/modules/product/views/product_view.dart';
import 'package:getx_project/app/modules/login/bindings/login_binding.dart';
import 'package:getx_project/app/modules/login/views/login_view.dart';
import 'package:getx_project/app/middleware/auth_middleware.dart';
import 'package:getx_project/app/modules/transaction/bindings/stock_transaction_binding.dart';
import 'package:getx_project/app/modules/transaction/views/stock_transaction_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const homePage = Routes.HOME;
  static const loginPage = Routes.LOGIN;

  static const productPage = Routes.PRODUCT;
  static const productDetailPage = Routes.PRODUCT_DETAIL;
  static const productCategory = Routes.PRODUCT_CATEGORY;
  static const productByCategory = Routes.PRODUCT_BY_CATEGORY;
  static const productBrand = Routes.PRODUCT_BRAND;
  static const productByBrand = Routes.PRODUCT_BY_BRAND;
  static const productUnit = Routes.PRODUCT_UNIT;
  static const productTransactionListPage = Routes.PRODUCT_TRANSACTION_LIST;

  static const stockTransactionPage = Routes.STOCK_TRANSACTION;

  //RECEIVE ORDER
  static const receiveHomePage = Routes.RECEIVE_ORDER_HOME;
  static const receiveOrderListPage = Routes.RECEIVE_ORDER_LIST;
  static const receiveOrderListDetailPage = Routes.RECEIVE_ORDER_LIST_DETAIL;
  static const receiveOrderByPoPage = Routes.RECEIVE_ORDER_BY_PO;
  static const receiveOrderByPoDetailPage = Routes.RECEIVE_ORDER_BY_PO_DETAIL;
  static const receiveOrderBySupplierPage = Routes.RECEIVE_ORDER_BY_SUPPLIER;
  static const receiveOrderBySupplierDetailPage = Routes.RECEIVE_ORDER_BY_SUPPLIER_DETAIL;
  static const receiveOrderConfirmPage = Routes.RECEIVE_ORDER_CONFIRM;
  //OUTFLOW  ORDER
  static const outflowHomePage = Routes.OUTFLOW_ORDER_HOME;
  static const outflowOrderListPage = Routes.OUTFLOW_ORDER_LIST;
  static const outflowOrderListDetailPage = Routes.OUTFLOW_ORDER_LIST_DETAIL;
  static const outflowOrderByRequestPage = Routes.OUTFLOW_ORDER_BY_REQUEST;
  static const outflowOrderByRequestDetailPage = Routes.OUTFLOW_ORDER_BY_REQUEST_DETAIL;
  static const outflowOrderByCustomerPage = Routes.OUTFLOW_ORDER_BY_CUSTOMER;
  static const outflowOrderByCustomerDetailPage = Routes.OUTFLOW_ORDER_BY_CUSTOMER_DETAIL;
  //DELIVERY
  static const deliveryListPage = Routes.DELIVERY_LIST;
  static const deliveryDetailPage = Routes.DELIVERY_DETAIL;

  /// Builds a route guarded by [AuthMiddleware]. Every page except LOGIN goes
  /// through this so a route can never accidentally ship unprotected.
  static GetPage _guard(
    String name,
    GetPageBuilder page, {
    Bindings? binding,
  }) {
    return GetPage(
      name: name,
      page: page,
      binding: binding,
      middlewares: [AuthMiddleware()],
    );
  }

  static final routes = [
    // Public
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),

    // Protected
    _guard(_Paths.HOME, () => const HomeView(), binding: HomeBinding()),
    _guard(_Paths.PRODUCT, () => const ProductView(),
        binding: ProductBinding()),
    _guard(_Paths.PRODUCT_DETAIL, () => const ProductDetailView(),
        binding: ProductDetailBinding()),
    _guard(_Paths.PRODUCT_CATEGORY, () => const ProductCategoryView(),
        binding: ProductCategoryBinding()),
    _guard(_Paths.PRODUCT_BY_CATEGORY, () => const ProductByCategoryView(),
        binding: ProductByCategoryBinding()),
    _guard(_Paths.PRODUCT_BRAND, () => const ProductBrandView(),
        binding: ProductBrandBinding()),
    _guard(_Paths.PRODUCT_UNIT, () => const ProductUnitView(),
        binding: ProductUnitBinding()),
    _guard(_Paths.PRODUCT_BY_BRAND, () => const ProductByBrandView(),
        binding: ProductByBrandBinding()),
    _guard(_Paths.PRODUCT_TRANSACTION_LIST,
        () => const ProductTransactionListView(),
        binding: ProductTransactionListBinding()),
    _guard(_Paths.STOCK_TRANSACTION, () => const StockTransactionView(),
        binding: StockTransactionBinding()),

    // RECEIVE ORDER
    _guard(_Paths.RECEIVE_ORDER_HOME, () => const ReceiveOrderHomeView()),
    _guard(_Paths.RECEIVE_ORDER_LIST, () => const ReceiveOrderListView(),
        binding: ReceiveOrderListBinding()),
    _guard(_Paths.RECEIVE_ORDER_LIST_DETAIL,
        () => const ReceiveOrderListDetailView(),
        binding: ReceiveOrderListDetailBinding()),
    _guard(_Paths.RECEIVE_ORDER_BY_PO, () => const ReceiveOrderByPoView(),
        binding: ReceiveOrderByPoBinding()),
    _guard(_Paths.RECEIVE_ORDER_BY_PO_DETAIL,
        () => const ReceiveOrderByPoDetailView(),
        binding: ReceiveOrderByPoDetailBinding()),
    _guard(_Paths.RECEIVE_ORDER_BY_SUPPLIER,
        () => const ReceiveOrderBySupplierView(),
        binding: ReceiveOrderBySupplierBinding()),
    _guard(_Paths.RECEIVE_ORDER_BY_SUPPLIER_DETAIL,
        () => const ReceiveOrderBySupplierDetailView(),
        binding: ReceiveOrderBySupplierDetailBinding()),
    _guard(_Paths.RECEIVE_ORDER_CONFIRM, () => const ReceiveOrderConfirmView(),
        binding: ReceiveOrderConfirmBinding()),

    // OUTFLOW ORDER
    _guard(_Paths.OUTFLOW_ORDER_HOME, () => const OutflowOrderHomeView()),
    _guard(_Paths.OUTFLOW_ORDER_LIST, () => const OutflowOrderListView(),
        binding: OutflowOrderListBinding()),
    _guard(_Paths.OUTFLOW_ORDER_LIST_DETAIL,
        () => const OutflowOrderDetailView(),
        binding: OutflowOrderListDetailBinding()),
    _guard(_Paths.OUTFLOW_ORDER_BY_REQUEST,
        () => const OutflowOrderByRequestView(),
        binding: OutflowOrderByRequestBinding()),
    _guard(_Paths.OUTFLOW_ORDER_BY_REQUEST_DETAIL,
        () => const OutflowOrderByRequestDetailView(),
        binding: OutflowOrderByRequestDetailBinding()),
    _guard(_Paths.OUTFLOW_ORDER_BY_CUSTOMER,
        () => const OutflowOrderByCustomerView(),
        binding: OutflowOrderByCustomerBinding()),
    _guard(_Paths.OUTFLOW_ORDER_BY_CUSTOMER_DETAIL,
        () => const OutflowOrderByCustomerDetailView(),
        binding: OutflowOrderByCustomerDetailBinding()),

    // DELIVERY
    _guard(_Paths.DELIVERY_LIST, () => const DeliveryListView(),
        binding: DeliveryListBinding()),
    _guard(_Paths.DELIVERY_DETAIL, () => const DeliveryDetailView(),
        binding: DeliveryDetailBinding()),
  ];
}
