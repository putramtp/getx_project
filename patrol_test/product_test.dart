import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/widget/product_tile.dart';
import 'package:getx_project/app/modules/product/controllers/product_controller.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';

Future<void> _openProducts(PatrolIntegrationTester $) async {
  await loginAsTestUser($);
  await $(#homeViewProducts).tap();
  await expectScreen($, 'Products list');
  await waitForList($);
}

void main() {
  e2eTest('product list loads', skip: !hasCredentials, ($) async {
    await _openProducts($);

    expect($('TOTAL PRODUCTS'), findsOneWidget);
    expect($(ProductTile), findsWidgets);
    expect($('View details'), findsWidgets);
  });

  e2eTest('summary numbers are parsed, not zero', skip: !hasCredentials, ($) async {
    await _openProducts($);
    final c = Get.find<ProductController>();

    // The API sends DECIMAL sums as strings ("320.000000"); a parse that
    // can't read them silently shows 0 everywhere.
    expect(c.totalProducts.value, greaterThan(0));
    expect(c.stockInHand.value, greaterThan(0), reason: 'Stock in hand parsed as 0');
    expect(c.productSummaries.any((p) => p.qtyRemaining != 0), isTrue,
        reason: 'every loaded product shows 0 remaining');
  });

  e2eTest('scrolling to the end loads every page', skip: !hasCredentials, ($) async {
    await _openProducts($);
    final c = Get.find<ProductController>();
    final list = find.byWidgetPredicate((w) => w is ScrollView && w.scrollDirection == Axis.vertical).first;

    // Each fling near the end triggers loadMore (the next cursor page).
    for (var i = 0; i < 40 && !$(#noMoreDataFooter).exists; i++) {
      final error = errorSnackbarText($);
      if (error != null) fail('Loading the next page failed: $error');
      await $.tester.drag(list, const Offset(0, -800));
      await $.pump(const Duration(milliseconds: 800));
    }

    expect($(#noMoreDataFooter), findsOneWidget, reason: 'never reached "No more data"');
    expect(errorSnackbarText($), isNull);
    if (c.totalProducts.value > c.limit.value) {
      expect(c.productSummaries.length, greaterThan(c.limit.value), reason: 'page 2 never loaded');
    }
  });

  e2eTest('search narrows the list to the typed product', skip: !hasCredentials, ($) async {
    await _openProducts($);
    final before = $(ProductTile).evaluate().map((e) => (e.widget as ProductTile).product.itemName).toList();
    expect(before.length, greaterThan(1), reason: 'need 2+ products to prove the search narrows');
    // Search for the last visible product: the first would pass even if search did nothing.
    final name = before.last;

    await $.tester.tap(find.byTooltip('Search'));
    await $.pump(const Duration(milliseconds: 300));
    await $(#productSearchField).enterText(name);
    // 400 ms debounce, then the request.
    await $.pump(const Duration(milliseconds: 600));
    await waitForList($);

    final tiles = $(ProductTile).evaluate().map((e) => (e.widget as ProductTile).product.itemName);
    expect(tiles, contains(name));
    expect(tiles.first, name, reason: 'the searched product should lead the results');
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
    // The section titles render even when GET /item/{id} fails to parse.
    await $.pump(const Duration(seconds: 1));
    expect(errorSnackbarText($), isNull, reason: 'product detail failed to load');
    await $('Pricing').scrollTo();
    expect($('Pricing'), findsOneWidget);
  });

  e2eTest('view transactions opens the transaction list', skip: !hasCredentials, ($) async {
    await _openProducts($);

    await $('View Transactions').first.tap();
    await expectScreen($, 'Transactions');
    await waitForList($);
  });
}
