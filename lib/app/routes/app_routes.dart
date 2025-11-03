// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';
// DO NOT EDIT. This is code generated via package:get_cli/get_cli.dart

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const LOGIN = _Paths.LOGIN;

  static const INVENTORY = _Paths.INVENTORY;
  static const ITEM = _Paths.ITEM;

  static const RECEIVE = _Paths.RECEIVE;
  static const RECEIVE_DETAIL = _Paths.RECEIVE_DETAIL;

  static const RECEIVE_ORDER_LIST = _Paths.RECEIVE_ORDER_LIST;
  static const RECEIVE_ORDER_DETAIL = _Paths.RECEIVE_ORDER_DETAIL;
  
  static const RECEIVE_ORDER_HOME = _Paths.RECEIVE_ORDER_HOME;
  static const RECEIVE_ORDER_BY_PO = _Paths.RECEIVE_ORDER_BY_PO;
  static const RECEIVE_ORDER_BY_PO_DETAIL = _Paths.RECEIVE_ORDER_BY_PO_DETAIL;
  static const RECEIVE_ORDER_BY_SUPPLIER = _Paths.RECEIVE_ORDER_BY_SUPPLIER;
  static const RECEIVE_ORDER_BY_SUPPLIER_DETAIL = _Paths.RECEIVE_ORDER_BY_SUPPLIER_DETAIL;


  static const OUTFLOW_ORDER = _Paths.OUTFLOW_ORDER;
  static const OUTFLOW_ORDER_DETAIL = _Paths.OUTFLOW_ORDER_DETAIL;

  static const DISPATCH = _Paths.DISPATCH;
  static const DISPATCH_DETAIL = _Paths.DISPATCH_DETAIL;
  static const RETURN = _Paths.RETURN;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const LOGIN = '/login';

  static const ITEM = '/item';
  static const INVENTORY = '/inventory';

  static const RECEIVE = '/receive';
  static const RECEIVE_DETAIL = '/receive/detail';

  static const RECEIVE_ORDER_LIST = '/receive-order/list';
  static const RECEIVE_ORDER_DETAIL = '/receive-order/detail';
  static const RECEIVE_ORDER_HOME = '/receive-order/home';
  static const RECEIVE_ORDER_BY_PO = '/receive-order/po';
  static const RECEIVE_ORDER_BY_PO_DETAIL = '/receive-order/po/detail';
  static const RECEIVE_ORDER_BY_SUPPLIER = '/receive-order/supplier';
  static const RECEIVE_ORDER_BY_SUPPLIER_DETAIL = '/receive-order/supplier/detail';

  static const OUTFLOW_ORDER = '/outflow-order';
  static const OUTFLOW_ORDER_DETAIL = '/outflow-order/detail';

  static const DISPATCH = '/dispatch';
  static const DISPATCH_DETAIL = '/dispatch/detail';
  static const RETURN = '/return';
}
