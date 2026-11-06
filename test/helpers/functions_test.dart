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

  group('capitalizeFirstofEach', () {
    test('capitalizes each word', () {
      expect(capitalizeFirstofEach('hello world'), 'Hello World');
    });
    test('leaves empty string untouched', () {
      expect(capitalizeFirstofEach(''), '');
    });
  });

  group('url helpers', () {
    test('urlValid only accepts absolute http(s)', () {
      expect(urlValid('https://example.com'), isTrue);
      expect(urlValid('http://example.com/a'), isTrue);
      expect(urlValid('ftp://example.com'), isFalse);
      expect(urlValid('not a url'), isFalse);
    });
    test('isImageUrl / isPdfUrl by extension', () {
      expect(isImageUrl('a/b/pic.PNG'), isTrue);
      expect(isImageUrl('a/b/pic.pdf'), isFalse);
      expect(isPdfUrl('doc.pdf'), isTrue);
      expect(isPdfUrl('doc.png'), isFalse);
    });
  });

  group('searchString', () {
    test('is case- and space-insensitive substring match', () {
      expect(searchString('AB', 'x a  b y'), isTrue);
      expect(searchString('zz', 'abc'), isFalse);
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
}
