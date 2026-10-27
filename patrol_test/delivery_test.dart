import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';

Future<void> _openDeliveries(PatrolIntegrationTester $) async {
  await loginAsTestUser($);
  await $('OUTFLOW ORDER').tap();
  await expectScreen($, 'Outflow Order Menu');
  await $('Deliveries').scrollTo();
  await $('Deliveries').tap();
  // 'Deliveries' is also the menu tile's text; the search hint is unique to
  // this screen (hint text isn't hit-testable, so wait for existence).
  await $('Search code / customer...').waitUntilExists(timeout: apiTimeout);
  await waitForList($);
}

/// Status filter chips: InkWells in the horizontal ListView above the list.
Finder _statusChips() => find.descendant(
      of: find.byWidgetPredicate(
          (w) => w is ListView && w.scrollDirection == Axis.horizontal),
      matching: find.byType(InkWell),
    );

/// The value under the "Current status" label on Delivery Detail.
String _currentStatus(PatrolIntegrationTester $) {
  final column = find.ancestor(of: find.text('Current status'), matching: find.byType(Column)).first;
  final texts = find.descendant(of: column, matching: find.byType(Text)).evaluate();
  return (texts.elementAt(1).widget as Text).data!;
}

Future<void> _openFirstDelivery(PatrolIntegrationTester $) async {
  await _openDeliveries($);
  await tapListCard($);
  await expectScreen($, 'Delivery Detail');
  await $('Current status').waitUntilVisible(timeout: apiTimeout);
}

final _updated = RegExp(r'updated\.$');

void main() {
  e2eTest('delivery list loads', skip: !hasCredentials, ($) async {
    await _openDeliveries($);

    expect($('All'), findsOneWidget);
    expect(listCards(), findsWidgets);
  });

  e2eTest('status chip filters the list', skip: !hasCredentials, ($) async {
    await _openDeliveries($);
    final chip = _statusChips().at(1);
    final status = $.tester.widget<Text>(find.descendant(of: chip, matching: find.byType(Text))).data!;

    await $.tester.tap(chip);
    await waitForList($);

    if ($('No deliveries found.').exists) return;
    for (final card in listCards().evaluate()) {
      expect(
        find.descendant(of: find.byElementPredicate((e) => e == card), matching: find.text(status)),
        findsOneWidget,
        reason: 'card shown under the "$status" filter has another status',
      );
    }
  });

  e2eTest('search finds a delivery by code', skip: !hasCredentials, ($) async {
    await _openDeliveries($);
    expect(listCards().evaluate().length, greaterThan(1), reason: 'need 2+ deliveries to prove the search narrows');
    // Search for the second delivery: the first would pass even if search did nothing.
    final code = listCardTitle($, 1);

    // The submit (check) icon only shows while the field is focused.
    await $(#searchBarField).enterText(code, hideKeyboard: false);
    await $(#searchBarSubmit).tap();
    await waitForList($);

    expect(listCardTitle($, 0), code);
  });

  e2eTest('delivery detail opens', skip: !hasCredentials, ($) async {
    await _openFirstDelivery($);

    await $('Update status').scrollTo();
    expect($('Update status'), findsOneWidget);
  });

  e2eTest('saving without an address keeps the edit sheet open', skip: !hasCredentials, ($) async {
    await _openFirstDelivery($);

    await $('Edit details').scrollTo();
    await $('Edit details').tap();
    await $('Edit Delivery').waitUntilVisible();
    await $('ETA date').tap();
    await $('OK').tap();
    await $(#deliveryEditAddressField).enterText('');
    await $('Save changes').scrollTo();
    await $('Save changes').tap(settlePolicy: SettlePolicy.noSettle);

    await $('A delivery address is required.').waitUntilVisible();
    await $.pump(const Duration(seconds: 1));
    expect($('Edit Delivery'), findsOneWidget, reason: 'a failed save must not discard the form');
  });

  e2eTest('editing details then marking a status updates the delivery', skip: !hasCredentials, ($) async {
    await _openFirstDelivery($);
    final before = _currentStatus($);

    await $('Edit details').scrollTo();
    await $('Edit details').tap();
    await $('Edit Delivery').waitUntilVisible();
    await $('ETA date').tap();
    await $('OK').tap();
    await $('ETA time').tap();
    await $('OK').tap();
    await $(#deliveryEditAddressField).enterText('E2E ${uniqueSuffix()}');
    await $('Save changes').scrollTo();
    await $('Save changes').tap(settlePolicy: SettlePolicy.noSettle);
    await waitForSuccess($, $(_updated));
    await closeSnackbars($);
    expect($('Edit Delivery'), findsNothing);

    await $(RegExp('^Mark ')).scrollTo();
    await $(RegExp('^Mark ')).first.tap(settlePolicy: SettlePolicy.noSettle);
    await waitForSuccess($, $(_updated));
    await $.pumpAndTrySettle();
    expect(_currentStatus($), isNot(before));
  });
}
