import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/widget/order_list_widgets.dart';

void main() {
  final items = <Map<String, dynamic>>[
    // complete: 4 received + 2 filled >= 6
    {'expected': 6, 'received': 4, 'filled': [{'qty': 2}]},
    // partial, qty given as a string
    {'expected': 10, 'received': 1, 'filled': [{'qty': '3'}, {'qty': 1}]},
    // expected 0 never counts as complete
    {'expected': 0, 'received': 0, 'filled': []},
  ];

  test('sums expected, done and pending across lines', () {
    final t = lineTotals(items, expectedKey: 'expected', pendingKey: 'filled');
    expect(t.expected, 16);
    expect(t.done, 5);
    expect(t.pending, 6);
    expect(t.lines, 3);
    expect(t.linesDone, 1);
  });

  test('outflow uses reserved as the target and scanned as pending', () {
    final t = lineTotals([
      {'expected': 9, 'reserved': 5, 'received': 2, 'scanned': [{'serial_number': 'A', 'qty': 3}]},
    ], expectedKey: 'reserved', pendingKey: 'scanned');
    expect(t.expected, 5);
    expect(t.pending, 3);
    expect(t.linesDone, 1);
  });

  test('missing keys count as zero', () {
    final t = lineTotals([{}], expectedKey: 'expected', pendingKey: 'filled');
    expect([t.expected, t.done, t.pending, t.linesDone], [0, 0, 0, 0]);
  });
}
