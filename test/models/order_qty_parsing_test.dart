import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/outflow_request_customer_model.dart';
import 'package:getx_project/app/data/models/outflow_request_line_item_model.dart';
import 'package:getx_project/app/data/models/outlfow_request_model.dart';
import 'package:getx_project/app/data/models/purchase_order_line_item_by_supplier_model.dart';
import 'package:getx_project/app/data/models/purchase_order_line_item_model.dart';
import 'package:getx_project/app/data/models/purchase_order_line_model.dart';
import 'package:getx_project/app/data/models/purchase_order_model.dart';
import 'package:getx_project/app/data/models/purchase_order_supplier_model.dart';

// Fractional-UoM items (kg, metre) come back as doubles or DECIMAL strings;
// assigning those straight into an int crashed Item Summary, and they must
// keep their fraction.
void main() {
  final line = {
    'line_id': 1,
    'item_name': 'Cable',
    'expected_qty': '12.500000',
    'reserved_qty': 7.5,
    'received_qty': 2.5,
  };

  test('line items keep decimal quantities', () {
    final po = PurchaseOrderLineItemModel.fromJson(line);
    expect([po.expected, po.received], [12.5, 2.5]);

    final bySupplier = PurchaseOrderLineItemBySupplierModel.fromJson(line);
    expect([bySupplier.expected, bySupplier.received], [12.5, 2.5]);

    final poLine = PurchaseOrderLineModel.fromJson(line);
    expect([poLine.expected, poLine.received, poLine.manageExpired], [12.5, 2.5, false]);

    final or = OutflowRequestLineItemModel.fromJson(line);
    expect([or.expected, or.reserved, or.received], [12.5, 7.5, 2.5]);
  });

  test('reserved falls back to a decimal expected qty', () {
    final or = OutflowRequestLineItemModel.fromJson({'line_id': 1, 'expected_qty': '4.000000'});
    expect(or.reserved, 4);
  });

  test('document headers keep decimal received/total', () {
    final header = {'id': 1, 'code': 'X', 'name': 'X', 'received': '1.500000', 'total': 3.0};

    final request = OutflowRequestModel.fromJson(header);
    expect([request.received, request.total, request.items], [1.5, 3, '1.5/3 Item']);

    final po = PurchaseOrderModel.fromJson(header);
    expect([po.received, po.total, po.items], [1.5, 3, '1.5/3 Item']);

    final customer = OrCustomerModel.fromJson(header);
    expect([customer.received, customer.total, customer.items], [1.5, 3, '1.5/3 Item']);

    final supplier = PoSupplierModel.fromJson(header);
    expect([supplier.received, supplier.total, supplier.items], [1.5, 3, '1.5/3 Item']);
  });
}
