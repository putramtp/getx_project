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
    await outflowOneRequestLine($, createDelivery: true);
    await waitForSuccess($, $('Delivery created.'));
    await expectScreen($, 'Deliveries');

    // The finished submit flow is unwound: Back goes to the Outflow menu, not
    // the submitted Item Summary.
    await $(#appBarBackButton).tap();
    await expectScreen($, 'Outflow');
    expect($('Item Summary'), findsNothing);
  });
}
