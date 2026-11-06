import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/product_brand_model.dart';
import 'package:getx_project/app/data/models/product_category_model.dart';
import 'package:getx_project/app/data/models/stock_transaction_model.dart';

/// Columns the backend allows to be null must not fail a whole list.
void main() {
  test('a brand or category without an initial code still parses', () {
    final brand = ProductBrandModel.fromJson({'id': 3, 'name': 'Acme', 'initial_code': null, 'slug': 'acme'});
    expect(brand.initialCode, '');
    final category = ProductCategoryModel.fromJson({'id': '4', 'name': 'Pipes', 'initial_code': null, 'slug': null});
    expect(category.id, 4);
    expect(category.initialCode, '');
  });

  test('a stock transaction with a null type and an undated order still parses', () {
    final st = StockTransactionModel.fromJson({
      'item_name': 'Cable 2.5 mm',
      'type': null,
      'flow_type': 'OUT',
      'qty': '12.500000',
      'human_time': '2 days ago',
      'order': {'type': 'OO', 'code': 'OO-0042', 'date': null},
    });
    expect(st.type, '');
    expect(st.qty, 12.5);
    expect(st.order?.code, 'OO-0042');
    expect(st.order?.date, isNull);
  });

  test('a whole quantity parses as a whole number', () {
    final st = StockTransactionModel.fromJson({'flow_type': 'IN', 'qty': '3.000000'});
    expect(st.qty, 3);
    expect(st.order, isNull);
  });
}
