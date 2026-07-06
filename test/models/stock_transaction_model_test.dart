import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/stock_transaction_model.dart';

void main() {
  group('StockTransactionModel.fromJson', () {
    test('parses a full row incl. string qty and nested order', () {
      final tx = StockTransactionModel.fromJson({
        'item_name': 'Widget',
        'type': 'RECEIVE',
        'flow_type': 'IN',
        'qty': '12.5', // API sends qty as a string
        'human_time': '2 Days Ago',
        'order': {
          'type': 'PO',
          'code': 'PO-001',
          'date': '2026-07-01',
        },
      });

      expect(tx.productName, 'Widget');
      expect(tx.type, 'RECEIVE');
      expect(tx.flowType, 'IN');
      expect(tx.qty, 12.5);
      expect(tx.time, '2 Days Ago');
      expect(tx.order, isNotNull);
      expect(tx.order!.type, 'PO');
      expect(tx.order!.code, 'PO-001');
      expect(tx.order!.date, DateTime.parse('2026-07-01'));
    });

    test('order is null when absent', () {
      final tx = StockTransactionModel.fromJson({
        'item_name': 'Widget',
        'type': 'ISSUE',
        'flow_type': 'OUT',
        'qty': 3, // numeric qty also supported
        'human_time': 'Today',
      });

      expect(tx.qty, 3.0);
      expect(tx.order, isNull);
    });
  });
}
