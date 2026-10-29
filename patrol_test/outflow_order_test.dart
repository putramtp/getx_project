import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';
import 'common/order_flow.dart';

Future<void> _openOutflowMenu(PatrolIntegrationTester $) async {
  await loginAsTestUser($);
  await $(#homeOutflowTask).tap();
  await expectScreen($, 'Outflow');
}

Future<void> _openFromMenu(PatrolIntegrationTester $, String tile, String title) async {
  await $(tile).scrollTo();
  await $(tile).tap();
  await expectScreen($, title);
  await waitForList($);
}

/// Seeded by the backend's SerialTrackedFlowSampleSeeder: a request line
/// reserving a serial-tracked (manage_sn, UNIQUE) item.
const _serialRequest = 'OR-SMP-SN-01';

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
    await _openFromMenu($, 'Outflow Orders', 'Outflow Orders');

    await tapListCard($);
    await expectScreen($, 'Outflow Order');
    await waitForList($);
  });

  e2eTest('request and customer lists load', skip: !hasCredentials, ($) async {
    await _openOutflowMenu($);
    await _openFromMenu($, 'By Request', 'Outflow Requests');
    expect(listCards(), findsWidgets);

    await $(#appBarBackButton).tap();
    await expectScreen($, 'Outflow');
    await _openFromMenu($, 'By Customer', 'Customers');
    expect(listCards(), findsWidgets);
  });

  e2eTest('outflowing a request line creates a delivery', skip: !hasCredentials, ($) async {
    await _openOutflowMenu($);
    await outflowOneLine($, createDelivery: true);
    await waitForSuccess($, $('Delivery created.'));
    await expectScreen($, 'Deliveries');

    // The finished submit flow is unwound: Back goes to the Outflow menu, not
    // the submitted Item Summary.
    await $(#appBarBackButton).tap();
    await expectScreen($, 'Outflow');
    expect($('Item Summary'), findsNothing);
  });

  e2eTest('scanning a serial label outflows that unit', skip: !hasCredentials, ($) async {
    await _openOutflowMenu($);
    final inStock = await inStockSerialsForRequest(_serialRequest);
    if (inStock.isEmpty) fail('No $_serialRequest label left in stock — rerun SerialTrackedFlowSampleSeeder');
    final label = inStock.first;

    await _openFromMenu($, 'By Request', 'Outflow Requests');
    await openOrderWithAction(
      $,
      listTitle: 'Outflow Requests',
      action: 'Scan',
      noneMessage: 'No request with a serial-tracked line left to scan — rerun SerialTrackedFlowSampleSeeder',
    );
    await $('Scan').first.tap();
    await expectScreen($, 'Scan Item');

    // UNIQUE: the scanner stays open, one label per unit. The camera can't be
    // driven, so the label goes in through the keyboard button.
    await $(#orderFillFab).tap(settlePolicy: SettlePolicy.noSettle);
    await grantCameraIfAsked($);
    await $(#scannerManualEntryButton).waitUntilVisible();
    await $(#scannerManualEntryButton).tap(settlePolicy: SettlePolicy.noSettle);
    await $(#serialDialogField).waitUntilVisible();
    await $(#serialDialogField).enterText(label);
    await $('Save').tap(settlePolicy: SettlePolicy.noSettle);
    await $(RegExp(r'^Scanned \d+/')).waitUntilVisible();
    await $('Done').tap();

    await continueBackToSummary($, 'Scan Item');
    await submitOutflow($, createDelivery: false);
    await expectScreen($, 'Outflow Requests');

    // The backend attached exactly that label and took it out of stock.
    expect(await inStockSerialsForRequest(_serialRequest), isNot(contains(label)));
  });

  e2eTest('outflowing a customer line without a delivery returns to customers', skip: !hasCredentials, ($) async {
    await _openOutflowMenu($);
    // "Not now" also leaves an outflow order without a delivery, which the
    // delivery test's "Create Delivery" case looks for.
    await outflowOneLine($, menuTile: 'By Customer', listTitle: 'Customers', createDelivery: false);

    await expectScreen($, 'Customers');
    await waitForList($);
    expect(errorSnackbarText($), isNull);
    expect($('Item Summary'), findsNothing);
  });
}
