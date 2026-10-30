import 'package:flutter/material.dart';

import '../../../data/models/outflow_request_customer_model.dart';
import '../../../global/accent.dart';
import '../../../routes/app_pages.dart';
import 'outflow_order_by_customer_controller.dart';

/// By Work Order list: work orders with open material reservations (from
/// approved material requisitions). Same list as By Customer, other source.
class OutflowOrderByWorkOrderController extends OutflowOrderByCustomerController {
  @override
  String get title => 'Work Orders';
  @override
  String get searchHint => 'Search Work Order...';
  @override
  String get emptyMessage => 'No work order has material to issue.';
  @override
  AppAccent get accent => AppAccent.sage;
  @override
  IconData get icon => Icons.precision_manufacturing_rounded;
  @override
  IconData get cardIcon => Icons.engineering_rounded;
  @override
  String get detailRoute => AppPages.outflowOrderByWorkOrderDetailPage;
  @override
  Future<List<OrCustomerModel>> fetchTargets() => provider.getWorkOrders();
}
