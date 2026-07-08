import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/services/draft_service.dart';

void main() {
  group('buildLineDraftMap', () {
    test('collects only non-empty lines, keyed by stringified line id', () {
      final items = [
        {
          'line_id': 10,
          'filled': [
            {'qty': 2, 'expired_date': null},
          ],
        },
        {
          'line_id': 20,
          'filled': <Map<String, dynamic>>[], // empty → dropped
        },
        {
          'line_id': 30,
          'filled': [
            {'serial': 'ABC', 'qty': 3, 'expired_date': '2026-01-01'},
            {'serial': 'DEF', 'qty': 2, 'expired_date': null},
          ],
        },
      ];

      final map = buildLineDraftMap(items, 'filled');

      // Empty line 20 is not persisted.
      expect(map.keys, containsAll(<String>['10', '30']));
      expect(map.containsKey('20'), isFalse);
      // Keys are strings even though line_id was an int.
      expect(map['10'], isA<List>());
      expect((map['30'] as List).length, 2);
      expect((map['10'] as List).first['qty'], 2);
    });

    test('works with the outflow "scanned" key too', () {
      final items = [
        {
          'line_id': 5,
          'scanned': [
            {'code': 'X1', 'qty': 1},
          ],
        },
      ];

      final map = buildLineDraftMap(items, 'scanned');
      expect(map['5'], isNotNull);
      expect((map['5'] as List).first['code'], 'X1');
    });

    test('returns an empty map when every line is empty', () {
      final items = [
        {'line_id': 1, 'filled': <Map<String, dynamic>>[]},
        {'line_id': 2, 'filled': null},
      ];
      expect(buildLineDraftMap(items, 'filled'), isEmpty);
    });
  });
}
