import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/functions.dart';

void main() {
  group('safeToInt', () {
    test('handles null, int, double, string, and junk', () {
      expect(safeToInt(null), 0);
      expect(safeToInt(7), 7);
      expect(safeToInt(3.9), 3);
      expect(safeToInt('5'), 5);
      expect(safeToInt('abc'), 0);
      // MySQL SUM()/DECIMAL columns arrive as decimal strings.
      expect(safeToInt('320.000000'), 320);
      expect(safeToInt('-4.000000'), -4);
      expect(safeToInt('2.5'), 2);
      expect(safeToInt(true), 0);
    });
  });

  group('formatPrice', () {
    test('null → dash', () {
      expect(formatPrice(null), '-');
    });
    test('formats thousands with id_ID grouping', () {
      expect(formatPrice(1000), '1.000');
    });
  });

  group('linesToSubmit', () {
    test('keeps only lines with a positive qty entry', () {
      final items = [
        {'line_id': 1, 'filled': [{'qty': 2}]},
        {'line_id': 2, 'filled': []},
        {'line_id': 3}, // never opened
        {'line_id': 4, 'filled': [{'qty': 0}]},
        {'line_id': 5, 'filled': [{'qty': '0.5'}]}, // fractional still counts
      ];
      expect(linesToSubmit(items, 'filled').map((e) => e['line_id']), [1, 5]);
    });

    test('reads the outflow "scanned" entries the same way', () {
      final items = [
        {'line_id': 7, 'scanned': [{'serial_number': 'SKU-1', 'qty': 1}]},
        {'line_id': 8, 'scanned': []},
      ];
      expect(linesToSubmit(items, 'scanned').map((e) => e['line_id']), [7]);
    });
  });

  group('submitLines', () {
    test('sends only the line id and its entries, so a retry hashes the same', () {
      final entries = [{'qty': 2, 'expired_date': null}];
      final before = [{'line_id': 1, 'item_id': 9, 'received': 0, 'expected': 10, 'filled': entries}];
      // Reopened after the lost answer: the line now counts what was booked.
      final after = [{'line_id': 1, 'item_id': 9, 'received': 2, 'expected': 10, 'filled': entries}];

      expect(submitLines(before, 'filled'), [{'line_id': 1, 'filled': entries}]);
      expect(submitLines(after, 'filled'), submitLines(before, 'filled'));
    });

    test('drops lines with nothing to submit', () {
      final items = [
        {'line_id': 7, 'scanned': [{'serial_number': 'SKU-1', 'qty': 1}]},
        {'line_id': 8, 'scanned': []},
      ];
      expect(submitLines(items, 'scanned').map((e) => e['line_id']), [7]);
    });
  });

  group('sortRowsBy', () {
    test('sorts A→Z or Z→A by the key, in place', () {
      final rows = ['PO-3', 'PO-1', 'PO-2'];
      sortRowsBy(rows, (r) => r, ascending: true);
      expect(rows, ['PO-1', 'PO-2', 'PO-3']);
      sortRowsBy(rows, (r) => r, ascending: false);
      expect(rows, ['PO-3', 'PO-2', 'PO-1']);
    });

    test('a page appended below is sorted in with the rest', () {
      final rows = ['b', 'd']; // page 1, sorted A→Z
      rows.addAll(['a', 'c']); // page 2 as the server sends it
      sortRowsBy(rows, (r) => r, ascending: true);
      expect(rows, ['a', 'b', 'c', 'd']);
    });
  });
}
