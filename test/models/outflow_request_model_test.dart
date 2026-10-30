import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/outlfow_request_model.dart';

void main() {
  test('a customer request can be issued from the app', () {
    final r = OutflowRequestModel.fromJson({'id': 1, 'code': 'OR-1', 'customer': 'ACME'});

    expect(r.hasCustomer, isTrue);
    expect(r.customer, 'ACME');
  });

  test('a reservation with no customer is a read-only work order reservation', () {
    for (final customer in [null, '', '  ']) {
      final r = OutflowRequestModel.fromJson({'id': 2, 'code': 'OR-RES-MR-1', 'customer': customer});

      expect(r.hasCustomer, isFalse, reason: 'customer: "$customer"');
      expect(r.customer, OutflowRequestModel.workOrderReservationLabel);
      expect(r.toJson()['customer'], isNull);
    }
  });
}
