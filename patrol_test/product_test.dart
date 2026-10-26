import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/widget/product_tile.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';

Future<void> _openProducts(PatrolIntegrationTester $) async {
  await loginAsTestUser($);
  await $('PRODUCT').tap();
  await expectScreen($, 'Products list');
  await waitForList($);
}

void main() {
  e2eTest('product list loads', skip: !hasCredentials, ($) async {
    await _openProducts($);

    expect($('Total Products'), findsOneWidget);
    expect($(ProductTile), findsWidgets);
    expect($('View details'), findsWidgets);
  });

  e2eTest('search narrows the list to the typed product', skip: !hasCredentials, ($) async {
    await _openProducts($);
    final name = $.tester.widget<ProductTile>($(ProductTile).first).product.itemName;

    await $.tester.tap(find.byTooltip('Search'));
    await $.pump(const Duration(milliseconds: 300));
    await $(#productSearchField).enterText(name);
    // 400 ms debounce, then the request.
    await $.pump(const Duration(milliseconds: 600));
    await waitForList($);

    final tiles = $(ProductTile).evaluate().map((e) => (e.widget as ProductTile).product.itemName);
    expect(tiles, isNotEmpty);
    expect(tiles, contains(name));
  });

  e2eTest('filter popup applies and clears', skip: !hasCredentials, ($) async {
    await _openProducts($);

    await $.tester.tap(find.byTooltip('Filter'));
    await $('Filter Options').waitUntilVisible();
    await $('Apply').tap();
    await waitForList($);
    expect($('Filter Options'), findsNothing);

    await $.tester.tap(find.byTooltip('Filter'));
    await $('Filter Options').waitUntilVisible();
    await $('Clear').tap();
    await waitForList($);
    expect($('Filter Options'), findsNothing);
  });

  e2eTest('view details opens the product detail', skip: !hasCredentials, ($) async {
    await _openProducts($);

    await $('View details').first.tap();
    await $('Basic Information').waitUntilVisible(timeout: apiTimeout);
    await $('Pricing').scrollTo();
    expect($('Pricing'), findsOneWidget);
  });

  e2eTest('view transactions opens the transaction list', skip: !hasCredentials, ($) async {
    await _openProducts($);

    await $('View Transactions').first.tap();
    await expectScreen($, 'Transaction');
    await waitForList($);
  });
}
