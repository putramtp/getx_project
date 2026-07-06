import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/dashboard_model.dart';

void main() {
  group('DashboardModel.fromJson', () {
    test('parses the hyphenated API keys', () {
      final model = DashboardModel.fromJson({
        'product': 12,
        'receive-order': 3,
        'outflow-order': 4,
        'product-unique': 7,
        'product-other': 5,
      });

      expect(model.product, 12);
      expect(model.receiveOrder, 3);
      expect(model.outflowOrder, 4);
      expect(model.productUnique, 7);
      expect(model.productOther, 5);
    });

    test('defaults missing/null counts to 0', () {
      final model = DashboardModel.fromJson({'product': null});

      expect(model.product, 0);
      expect(model.receiveOrder, 0);
      expect(model.outflowOrder, 0);
      expect(model.productUnique, 0);
      expect(model.productOther, 0);
    });

    test('toJson → fromJson round-trips (keeps hyphenated keys)', () {
      final original = DashboardModel(
        product: 1,
        receiveOrder: 2,
        outflowOrder: 3,
        productUnique: 4,
        productOther: 5,
      );

      final json = original.toJson();
      expect(json.containsKey('receive-order'), isTrue);
      expect(json.containsKey('outflow-order'), isTrue);

      final restored = DashboardModel.fromJson(json);
      expect(restored.product, original.product);
      expect(restored.receiveOrder, original.receiveOrder);
      expect(restored.outflowOrder, original.outflowOrder);
      expect(restored.productUnique, original.productUnique);
      expect(restored.productOther, original.productOther);
    });
  });
}
