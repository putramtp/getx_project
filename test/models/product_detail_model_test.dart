import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/product_detail_model.dart';

void main() {
  test('price_sell sent as a DECIMAL string parses to an int', () {
    // GET /item/{id} returns price_sell as "180000000" (a DECIMAL column).
    final model = ProductDetailModel.fromJson({'id': 1, 'price_sell': '180000000'});
    expect(model.priceSell, 180000000);
  });

  test('numeric or missing price_sell still parses', () {
    expect(ProductDetailModel.fromJson({'price_sell': 2500}).priceSell, 2500);
    expect(ProductDetailModel.fromJson({'price_sell': '320.000000'}).priceSell, 320);
    expect(ProductDetailModel.fromJson({}).priceSell, 0);
  });
}
