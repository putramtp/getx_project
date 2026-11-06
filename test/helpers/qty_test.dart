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

    test('rejects exponents, hex, NaN, Infinity and signs', () {
      for (final text in ['1e3', '0x10', 'NaN', 'Infinity', '+2', '2.5.1', '2,5,1', '١٢']) {
        expect(parseQty(text), isNull, reason: text);
      }
    });

    test('refuses thousands-grouped input instead of reading it as a decimal', () {
      for (final text in ['1.000', '12,000', '1.000.000', '1,250,000']) {
        expect(parseQty(text), isNull, reason: text);
        expect(looksLikeThousands(text), isTrue, reason: text);
      }
      // A real decimal amount stays allowed.
      expect(parseQty('1.500'), 1.5);
      expect(parseQty('0,125'), 0.125);
      expect(looksLikeThousands('1.5'), isFalse);
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

  group('clearedEntriesMessage', () {
    test('names the entries and the quantity they held', () {
      expect(
        clearedEntriesMessage([{'serial_number': 'B1', 'qty': 3}], 'Paste'),
        'Removed 1 entry (qty 3) from Paste',
      );
      expect(
        clearedEntriesMessage([{'qty': 2}, {'qty': 0.5}], 'Paste'),
        'Removed 2 entries (qty 2.5) from Paste',
      );
      expect(clearedEntriesMessage(null, 'Paste'), 'Removed 0 entries (qty 0) from Paste');
    });
  });
}
