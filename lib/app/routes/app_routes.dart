// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';
// DO NOT EDIT. This is code generated via package:get_cli/get_cli.dart

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const LOGIN = _Paths.LOGIN;
  static const PRODUCT = _Paths.PRODUCT;
  static const PRODUCT_DETAIL = _Paths.PRODUCT_DETAIL;
  static const PRODUCT_CATEGORY = _Paths.PRODUCT_CATEGORY;
  static const PRODUCT_BRAND    = _Paths.PRODUCT_BRAND;
  static const PRODUCT_BY_BRAND   = _Paths.PRODUCT_BY_BRAND;
  static const PRODUCT_BY_CATEGORY = _Paths.PRODUCT_BY_CATEGORY;
  static const PRODUCT_TRANSACTION_LIST = _Paths.PRODUCT_TRANSACTION_LIST;
  static const ITEM = _Paths.ITEM;
  // RECEIVE ORDER
  static const RECEIVE_ORDER_LIST = _Paths.RECEIVE_ORDER_LIST;
  static const RECEIVE_ORDER_LIST_DETAIL = _Paths.RECEIVE_ORDER_LIST_DETAIL;
  static const RECEIVE_ORDER_HOME = _Paths.RECEIVE_ORDER_HOME;
  static const RECEIVE_ORDER_BY_PO = _Paths.RECEIVE_ORDER_BY_PO;
  static const RECEIVE_ORDER_BY_PO_DETAIL = _Paths.RECEIVE_ORDER_BY_PO_DETAIL;
  static const RECEIVE_ORDER_BY_SUPPLIER = _Paths.RECEIVE_ORDER_BY_SUPPLIER;
  static const RECEIVE_ORDER_BY_SUPPLIER_DETAIL = _Paths.RECEIVE_ORDER_BY_SUPPLIER_DETAIL;
  // OUTFLOW ORDER DETAIL
  static const OUTFLOW_ORDER_LIST = _Paths.OUTFLOW_ORDER_LIST;
  static const OUTFLOW_ORDER_LIST_DETAIL = _Paths.OUTFLOW_ORDER_LIST_DETAIL;
  static const OUTFLOW_ORDER_HOME = _Paths.OUTFLOW_ORDER_HOME;
  static const OUTFLOW_ORDER_BY_REQUEST = _Paths.OUTFLOW_ORDER_BY_REQUEST;
  static const OUTFLOW_ORDER_BY_REQUEST_DETAIL = _Paths.OUTFLOW_ORDER_BY_REQUEST_DETAIL;
  static const OUTFLOW_ORDER_BY_CUSTOMER = _Paths.OUTFLOW_ORDER_BY_CUSTOMER;
  static const OUTFLOW_ORDER_BY_CUSTOMER_DETAIL = _Paths.OUTFLOW_ORDER_BY_CUSTOMER_DETAIL;

  static const RETURN = _Paths.RETURN;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const LOGIN = '/login';

  static const ITEM = '/item';
  static const PRODUCT = '/product';
  static const PRODUCT_DETAIL = '/product/detail';
  static const PRODUCT_TRANSACTION_LIST = '/product/transaction';
  static const PRODUCT_CATEGORY = '/product/category';
  static const PRODUCT_BY_CATEGORY = '/product/by-category';
  static const PRODUCT_BRAND = '/product/brand';
  static const PRODUCT_BY_BRAND = '/product/by-brand';
  // RECEIVE ORDER
  static const RECEIVE_ORDER_LIST = '/receive-order/list';
  static const RECEIVE_ORDER_LIST_DETAIL = '/receive-order/detail';
  static const RECEIVE_ORDER_HOME = '/receive-order/home';
  static const RECEIVE_ORDER_BY_PO = '/receive-order/po';
  static const RECEIVE_ORDER_BY_PO_DETAIL = '/receive-order/po/detail';
  static const RECEIVE_ORDER_BY_SUPPLIER = '/receive-order/supplier';
  static const RECEIVE_ORDER_BY_SUPPLIER_DETAIL = '/receive-order/supplier/detail';
  // OUTFLOW ORDER
  static const OUTFLOW_ORDER_LIST = '/outflow-order/list';
  static const OUTFLOW_ORDER_LIST_DETAIL = '/outflow-order/detail';
  static const OUTFLOW_ORDER_HOME = '/outflow-order/home';
  static const OUTFLOW_ORDER_BY_REQUEST = '/outflow-order/request';
  static const OUTFLOW_ORDER_BY_REQUEST_DETAIL = '/outflow-order/request/detail';
  static const OUTFLOW_ORDER_BY_CUSTOMER = '/outflow-order/customer';
  static const OUTFLOW_ORDER_BY_CUSTOMER_DETAIL = '/outflow-order/customer/detail';

  static const RETURN = '/return';
}
