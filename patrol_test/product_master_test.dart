import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';

/// Opens a master list (Category / Brand / Unit) from the home Inventory section;
/// [title] is the list's (plural) AppBar title.
Future<void> _openMaster(PatrolIntegrationTester $, String tile, String title) async {
  await loginAsTestUser($);
  await $(tile).scrollTo();
  await $(tile).tap();
  await expectScreen($, title);
  await waitForList($);
}

void main() {
  e2eTest('category card opens its products', skip: !hasCredentials, ($) async {
    await _openMaster($, 'Category', 'Categories');

    await tapListCard($);
    await $('Product Category').waitUntilVisible(timeout: apiTimeout);
  });

  e2eTest('brand card opens its products', skip: !hasCredentials, ($) async {
    await _openMaster($, 'Brand', 'Brands');

    await tapListCard($);
    await $('Product Brand').waitUntilVisible(timeout: apiTimeout);
  });

  e2eTest('unit card opens the unit dialog', skip: !hasCredentials, ($) async {
    await _openMaster($, 'Unit', 'Units');

    await tapListCard($);
    await $('Product Unit').waitUntilVisible();
    await $('Close').tap();
    expect($('Product Unit'), findsNothing);
  });

  e2eTest('limit dialog rejects invalid input', skip: !hasCredentials, ($) async {
    await _openMaster($, 'Category', 'Categories');

    await $.tester.tap(find.byTooltip('Filter'));
    await $('Set Limit').waitUntilVisible();
    await $(#masterLimitField).enterText('0');
    await $('Apply').tap(settlePolicy: SettlePolicy.noSettle);
    // The SnackBar sits under the dialog barrier: it exists but isn't hit-testable.
    await $('Please enter a valid number').waitUntilExists();
  });
}
