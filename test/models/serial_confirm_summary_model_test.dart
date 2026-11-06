import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/receive_order_model.dart';
import 'package:getx_project/app/data/models/serial_confirm_summary_model.dart';

void main() {
  test('the summary parses GET /receive-order/serial-confirm-summary', () {
    final summary = SerialConfirmSummary.fromJson({'pending_orders': 3, 'pending_labels': 12, 'window_days': 30});

    expect(summary.pendingOrders, 3);
    expect(summary.pendingLabels, 12);
    expect(summary.windowDays, 30);
    expect(summary.hasPending, isTrue);
  });

  test('an empty or partial summary has nothing pending', () {
    final summary = SerialConfirmSummary.fromJson({});

    expect(summary.pendingOrders, 0);
    expect(summary.pendingLabels, 0);
    expect(summary.hasPending, isFalse);
  });

  test('a receive order row carries its unscanned label count', () {
    final row = {'id': 1, 'code': 'RI-1', 'date': '2026-11-05', 'supplier_name': 'ACME'};

    expect(ReceiveOrderModel.fromJson({...row, 'pending_serial_count': 4}).pendingSerialCount, 4);
    expect(ReceiveOrderModel.fromJson(row).pendingSerialCount, 0);
  });
}
