import 'package:flutter/material.dart';
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

  group('color helpers', () {
    test('getAccentColor is deterministic and in range', () {
      expect(getAccentColor('CODE'), getAccentColor('CODE'));
      // Should always return one of the palette colors (no crash / index error).
      expect(getAccentColor(''), isA<Color>());
    });

    test('getReadableTextColor contrasts the background', () {
      expect(getReadableTextColor(Colors.white), Colors.black);
      expect(getReadableTextColor(Colors.black), Colors.white);
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
}
