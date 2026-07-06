import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/widget/master_list_view.dart';

void main() {
  group('masterMonogram', () {
    test('uses first letters of the first two words', () {
      expect(masterMonogram('Pieces Box'), 'PB');
      expect(masterMonogram('receive order line'), 'RO');
    });

    test('uses first two letters of a single word', () {
      expect(masterMonogram('Kilogram'), 'KI');
    });

    test('single character uppercased', () {
      expect(masterMonogram('a'), 'A');
    });

    test('blank/empty → ?', () {
      expect(masterMonogram(''), '?');
      expect(masterMonogram('   '), '?');
    });
  });
}
