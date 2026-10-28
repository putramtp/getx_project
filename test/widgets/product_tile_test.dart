import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/product_summary_model.dart';
import 'package:getx_project/app/global/variables.dart';
import 'package:getx_project/app/global/widget/product_tile.dart';
import 'package:getx_project/app/global/widget/stock_level_tile.dart';

import 'pump_ui.dart';

ProductSummaryModel _product(int remaining) => ProductSummaryModel.fromJson({
      'item_id': 1,
      'item_name': 'Kardus Box 40x30',
      'item_code': 'BRG-00412',
      'qty_remaining': remaining,
      'qty_in': remaining + 5,
      'qty_out': 5,
    });

void main() {
  test('stock level: out at 0 or below, low under 10, ok from 10', () {
    expect(StockLevel.of(-2), StockLevel.out);
    expect(StockLevel.of(0), StockLevel.out);
    expect(StockLevel.of(9), StockLevel.low);
    expect(StockLevel.of(10), StockLevel.ok);
    expect(StockLevel.out.color, stockOutColor);
    expect(StockLevel.ok.color, stockInColor);
  });

  for (final (qty, level) in [(320, StockLevel.ok), (3, StockLevel.low), (0, StockLevel.out)]) {
    testWidgets('leading shows $qty left in the ${level.name} color', (tester) async {
      await pumpUi(
        tester,
        Scaffold(body: ProductTile(product: _product(qty), size: 9.6, onViewDetail: () {}, onViewTransaction: () {})),
      );
      final tile = find.byKey(const Key('productStockLevel'));
      expect(find.descendant(of: tile, matching: find.text('$qty')), findsOneWidget);
      expect(find.descendant(of: tile, matching: find.text(level.label)), findsOneWidget);
      final deco = tester.widget<Container>(tile).decoration! as BoxDecoration;
      expect((deco.border! as Border).top.color, level.color.withValues(alpha: 0.5));
      expect(tester.takeException(), isNull);
    });
  }
}
