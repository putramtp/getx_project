import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/providers/outflow_order_provider.dart';
import 'package:getx_project/app/modules/outflow_order/outflow_batch_check.dart';

/// The outflow scan's BATCH label check: the stock the app reads, and what it
/// lets a worker draw from a batch before the submit.
void main() {
  group('serialStockFrom', () {
    test('keys each label by both codes, with the units left', () {
      final stock = serialStockFrom({
        'data': {
          'serials': [
            {'internal_code': 'SKU-1', 'serial_number': 'SKU-1', 'qty': '6.000000'},
            {'internal_code': 'SKU-2', 'serial_number': 'LOT-B', 'qty': 4},
          ],
        },
      });
      expect(stock, {'SKU-1': 6, 'SKU-2': 4, 'LOT-B': 4});
    });

    test('an item without serials has no stock', () {
      expect(serialStockFrom({'data': {}}), isEmpty);
      expect(serialStockFrom({}), isEmpty);
    });
  });

  group('checkBatchLeft', () {
    final stock = {'B1': 5, 'B2': 2};
    Map<String, dynamic> line(int itemId, List<Map<String, dynamic>> scanned) =>
        {'item_id': itemId, 'name': 'Paste', 'scanned': scanned};

    test('a label not in stock is an unknown batch', () {
      final result = checkBatchLeft(stock, line(1, []), 'B9');
      expect(result.left, isNull);
      expect(result.refusal!.title, 'Unknown Batch');
    });

    test('what is left is the stock less what the line already scanned', () {
      final result = checkBatchLeft(stock, line(1, [{'serial_number': 'B1', 'qty': 2}]), 'B1');
      expect(result.left, 3);
      expect(result.refusal, isNull);
    });

    test('scans of the same item on other lines draw on the same batch', () {
      final current = line(1, []);
      final lines = [
        current,
        line(1, [{'serial_number': 'B1', 'qty': 4}]),
        line(2, [{'serial_number': 'B1', 'qty': 5}]), // another item: its own B1
      ];
      expect(checkBatchLeft(stock, current, 'B1', lines: lines).left, 1);
    });

    test('a batch fully scanned is used up', () {
      final result = checkBatchLeft(stock, line(1, [{'serial_number': 'B2', 'qty': 2}]), 'B2');
      expect(result.left, isNull);
      expect(result.refusal!.title, 'Batch Used Up');
    });
  });

  group('checkBatchQty', () {
    test('a qty within what is left fits', () {
      expect(checkBatchQty('B1', 3, 3), isNull);
      expect(checkBatchQty('B1', 0.1 + 0.2, 0.3), isNull, reason: 'no float drift');
    });

    test('a qty beyond it is refused', () {
      expect(checkBatchQty('B1', 4, 3)!.title, 'Not Enough in Batch');
    });
  });

  group('checkRename', () {
    final line = {
      'scanned': [
        {'serial_number': 'B1', 'qty': 1},
        {'serial_number': 'B2', 'qty': 1},
      ],
    };

    test('a new code is allowed', () => expect(checkRename(line, 'B1', 'B3'), isNull));

    test('a code already on another row is a duplicate', () {
      final refusal = checkRename(line, 'B1', 'B2');
      expect(refusal!.title, 'Duplicate Code');
      expect(refusal.isWarning, isTrue);
    });

    test('an unchanged, empty or unknown code renames nothing', () {
      expect(checkRename(line, 'B1', 'B1'), same(renameIgnored));
      expect(checkRename(line, 'B1', ''), same(renameIgnored));
      expect(checkRename(line, 'B9', 'B3'), same(renameIgnored));
    });
  });

  group('a code on another line of the same item', () {
    Map<String, dynamic> lineOf(int itemId, String type, List<String> codes) => {
          'item_id': itemId,
          'serialNumberType': type,
          'scanned': [for (final c in codes) {'serial_number': c, 'qty': 1}],
        };

    test('a unit label already on another line is a duplicate', () {
      final a = lineOf(7, 'UNIQUE', ['SN-1']);
      final b = lineOf(7, 'UNIQUE', ['SN-2']);
      expect(scannedOnOtherLine([a, b], b, 'SN-1'), isTrue);
      expect(checkRename(b, 'SN-2', 'SN-1', lines: [a, b])!.title, 'Duplicate Code');
    });

    test('another item, or a BATCH label shared by two lines, is not', () {
      final a = lineOf(7, 'UNIQUE', ['SN-1']);
      final other = lineOf(8, 'UNIQUE', ['SN-9']);
      expect(scannedOnOtherLine([a, other], other, 'SN-1'), isFalse);

      final batchA = lineOf(5, 'BATCH', ['B1']);
      final batchB = lineOf(5, 'BATCH', ['B2']);
      expect(scannedOnOtherLine([batchA, batchB], batchB, 'B1'), isFalse);
    });
  });

  test('only a serial-tracked BATCH line is checked against batch stock', () {
    expect(needsBatchCheck({'manage_sn': true, 'serialNumberType': 'BATCH'}), isTrue);
    expect(needsBatchCheck({'manage_sn': true, 'serialNumberType': 'UNIQUE'}), isFalse);
    expect(needsBatchCheck({'manage_sn': false, 'serialNumberType': 'BATCH'}), isFalse);
  });
}
