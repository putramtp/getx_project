import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';

/// Opens a master list (Category / Brand / Unit) from the home Quick Access.
Future<void> _openMaster(PatrolIntegrationTester $, String tile) async {
  await loginAsTestUser($);
  await $(tile).scrollTo();
  await $(tile).tap();
  await expectScreen($, tile);
  await waitForList($);
}

void main() {
  e2eTest('category card opens its products', skip: !hasCredentials, ($) async {
    await _openMaster($, 'Category');

    await tapListCard($);
    await $('Product Category').waitUntilVisible(timeout: apiTimeout);
  });

  e2eTest('brand card opens its products', skip: !hasCredentials, ($) async {
    await _openMaster($, 'Brand');

    await tapListCard($);
    await $('Product Brand').waitUntilVisible(timeout: apiTimeout);
  });

  e2eTest('unit card opens the unit dialog', skip: !hasCredentials, ($) async {
    await _openMaster($, 'Unit');

    await tapListCard($);
    await $('Product Unit').waitUntilVisible();
    await $('Close').tap();
    expect($('Product Unit'), findsNothing);
  });

  e2eTest('limit dialog rejects invalid input', skip: !hasCredentials, ($) async {
    await _openMaster($, 'Category');

    await $.tester.tap(find.byTooltip('Filter'));
    await $('Set Limit').waitUntilVisible();
    await $(#masterLimitField).enterText('0');
    await $('Apply').tap(settlePolicy: SettlePolicy.noSettle);
    // The SnackBar sits under the dialog barrier: it exists but isn't hit-testable.
    await $('Please enter a valid number').waitUntilExists();
  });
}
