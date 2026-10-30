import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/outflow_request_line_item_model.dart';
import 'package:getx_project/app/modules/outflow_order/outflow_submit.dart';

/// By Work Order submits to `POST /outflow-order/issue-by-work-order`, whose
/// lines name the reservation line, its item, the qty and the scanned serials.
void main() {
  test('a summary line carries its item id', () {
    expect(OutflowRequestLineItemModel.fromJson({'line_id': 1, 'item_id': 42}).itemId, 42);
  });

  test('only filled/scanned lines are issued, with their total and serials', () {
    final payload = workOrderIssuePayload(7, [
      {'line_id': 1, 'item_id': 10, 'scanned': [{'qty': 2.5}]},
      {'line_id': 2, 'item_id': 11, 'scanned': []},
      {
        'line_id': 3,
        'item_id': 12,
        'scanned': [
          {'serial_number': 'SN-1', 'qty': 1},
          {'serial_number': 'SN-2', 'qty': 1},
        ],
      },
    ]);

    expect(payload['work_order_id'], 7);
    expect(payload['outflow_order_lines'], [
      {'or_line_id': 1, 'item_id': 10, 'qty': 2.5, 'selected_serials': []},
      {
        'or_line_id': 3,
        'item_id': 12,
        'qty': 2,
        'selected_serials': [
          {'serial_number': 'SN-1', 'qty': 1},
          {'serial_number': 'SN-2', 'qty': 1},
        ],
      },
    ]);
  });
}
