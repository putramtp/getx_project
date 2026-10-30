import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/functions.dart';

void main() {
  group('safeToNum', () {
    test('parses decimals and keeps whole values as int', () {
      expect(safeToNum(null), 0);
      expect(safeToNum('abc'), 0);
      expect(safeToNum(2.5), 2.5);
      expect(safeToNum('12.500000'), 12.5);
      expect(safeToNum('320.000000'), isA<int>());
      expect(safeToNum(3.0), 3);
    });
  });

  group('sumQty', () {
    test('adds entry quantities without float drift', () {
      expect(sumQty([{'qty': 0.1}, {'qty': 0.2}]), 0.3);
      expect(sumQty([{'qty': 1}, {'qty': '2.5'}]), 3.5);
      expect(sumQty([]), 0);
    });
  });

  group('formatQty', () {
    test('drops trailing zeros', () {
      expect(formatQty(3), '3');
      expect(formatQty(3.0), '3');
      expect(formatQty(2.5), '2.5');
      expect(formatQty(0.1 + 0.2), '0.3');
      expect(formatQty(1.123456), '1.123456');
    });
  });

  group('parseQty', () {
    test('accepts a dot or comma decimal', () {
      expect(parseQty('2.5'), 2.5);
      expect(parseQty(' 2,5 '), 2.5);
      expect(parseQty('4'), 4);
    });

    test('rejects blank, junk, zero, negative and over 6 decimals', () {
      for (final text in ['', 'abc', '0', '-1', '1.1234567']) {
        expect(parseQty(text), isNull, reason: text);
      }
    });

    test('whole units reject fractions', () {
      expect(parseQty('2.5', wholeUnits: true), isNull);
      expect(parseQty('2', wholeUnits: true), 2);
      expect(parseQty('2.0', wholeUnits: true), 2);
    });
  });

  group('wholeUnitsOnly', () {
    test('only serial-tracked UNIQUE/BATCH lines', () {
      expect(wholeUnitsOnly({'manage_sn': true, 'serialNumberType': 'UNIQUE'}), isTrue);
      expect(wholeUnitsOnly({'manage_sn': true, 'serialNumberType': 'BATCH'}), isTrue);
      expect(wholeUnitsOnly({'manage_sn': true, 'serialNumberType': 'OTHER'}), isFalse);
      expect(wholeUnitsOnly({'manage_sn': false, 'serialNumberType': 'UNIQUE'}), isFalse);
    });
  });
}
