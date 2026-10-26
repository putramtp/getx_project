import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';
import 'common/order_flow.dart';

Future<void> _openOutflowMenu(PatrolIntegrationTester $) async {
  await loginAsTestUser($);
  await $('OUTFLOW ORDER').tap();
  await expectScreen($, 'Outflow Order Menu');
}

Future<void> _openFromMenu(PatrolIntegrationTester $, String tile, String title) async {
  await $(tile).scrollTo();
  await $(tile).tap();
  await expectScreen($, title);
  await waitForList($);
}

void main() {
  e2eTest('menu shows the outflow entries', skip: !hasCredentials, ($) async {
    await _openOutflowMenu($);

    expect($('Outflow Orders'), findsOneWidget);
    expect($('By Request'), findsOneWidget);
    expect($('By Customer'), findsOneWidget);
    await $('Deliveries').scrollTo();
    expect($('Deliveries'), findsOneWidget);
  });

  e2eTest('outflow order list opens a detail', skip: !hasCredentials, ($) async {
    await _openOutflowMenu($);
    await _openFromMenu($, 'Outflow Orders', 'Outflow Order List');

    await tapListCard($);
    await expectScreen($, 'Outflow Order Detail');
    await waitForList($);
  });

  e2eTest('request and customer lists load', skip: !hasCredentials, ($) async {
    await _openOutflowMenu($);
    await _openFromMenu($, 'By Request', 'Outflow Request List');
    expect(listCards(), findsWidgets);

    await $(#appBarBackButton).tap();
    await expectScreen($, 'Outflow Order Menu');
    await _openFromMenu($, 'By Customer', 'Customer List');
    expect(listCards(), findsWidgets);
  });

  e2eTest('outflowing a request line creates a delivery', skip: !hasCredentials, ($) async {
    await _openOutflowMenu($);
    await _openFromMenu($, 'By Request', 'Outflow Request List');
    // "Fill" = a quantity-only (manage_sn false) line; the "Scan" path needs a
    // serial that is known to be in stock, which can't be picked dynamically.
    await openOrderWithAction(
      $,
      listTitle: 'Outflow Request List',
      action: 'Fill',
      noneMessage: 'No open request with a quantity-only line — reseed DemoTenantSeeder',
    );

    await $('Fill').first.tap();
    await expectScreen($, 'Scan Item');
    await $(#orderFillFab).tap();
    await $(#qtyDialogField).enterText('1');
    await $('Save').tap();
    await $('Qty: 1').waitUntilVisible();
    await continueBackToSummary($, 'Scan Item');

    await $(RegExp('^Continue to outflowing items')).tap();
    await $('Continue to Outflowing Items?').waitUntilVisible();
    await $('Continue').tap(settlePolicy: SettlePolicy.noSettle);

    await waitForSuccess($, $('Create delivery?'));
    await $('Create').tap(settlePolicy: SettlePolicy.noSettle);
    await waitForSuccess($, $('Delivery created.'));
    await expectScreen($, 'Deliveries');
  });
}
