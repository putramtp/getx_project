import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';
import 'common/order_flow.dart';

Future<void> _openDeliveries(PatrolIntegrationTester $) async {
  await loginAsTestUser($);
  await $(#homeOutflowTask).tap();
  await expectScreen($, 'Outflow');
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

/// The current status, read from the "Now: `<status>`" hint on the status panel.
String _currentStatus(PatrolIntegrationTester $) {
  final hint = $.tester.widget<Text>(find.textContaining(RegExp(r'^Now: '))).data!;
  return hint.substring('Now: '.length);
}

Future<void> _openFirstDelivery(PatrolIntegrationTester $) async {
  await _openDeliveries($);
  await tapListCard($);
  await expectScreen($, 'Delivery Detail');
  await $(RegExp(r'^Now: ')).waitUntilExists(timeout: apiTimeout);
}

/// Opens the first delivery that can still be edited and moved on — a
/// delivered (or otherwise final) one has no "Edit details" / "Mark" buttons.
Future<void> _openEditableDelivery(PatrolIntegrationTester $) async {
  await _openDeliveries($);
  final found = await openFirstCardWhere(
    $,
    listTitle: 'Deliveries',
    matches: () async {
      await expectScreen($, 'Delivery Detail');
      await $(RegExp(r'^Now: ')).waitUntilExists(timeout: apiTimeout);
      await waitForList($);
      return $('Edit details').exists && $(RegExp('^Mark ')).exists;
    },
  );
  expect(found, isTrue, reason: 'no open (not yet delivered) delivery among the recent ones');
}

/// Taps the first "Mark `<status>`" and answers its prompt: Cancelled asks for
/// confirmation, Delivered asks who received the goods.
///
/// The prompt is known from the button's label up front: waiting for one that
/// never shows would outlast the 3 s success snackbar the caller then expects.
Future<void> _markFirstStatus(PatrolIntegrationTester $) async {
  await $(RegExp('^Mark ')).scrollTo();
  // Read through the finder: the matched widget is a RichText, not a Text.
  final label = ($(RegExp('^Mark ')).first.text ?? '').toLowerCase();
  await $(RegExp('^Mark ')).first.tap(settlePolicy: SettlePolicy.noSettle);
  if (label.contains('cancel') || label.contains('fail')) {
    // The dialog's button is last in the tree.
    await $(RegExp(r'^This delivery will be marked as')).waitUntilVisible();
    await $(RegExp('^Mark ')).last.tap(settlePolicy: SettlePolicy.noSettle);
  } else if (label.contains('deliver')) {
    await $(#deliveryReceiverField).waitUntilVisible();
    await $(#deliveryReceiverField).enterText('E2E ${uniqueSuffix()}');
    await $('Mark Delivered').last.tap(settlePolicy: SettlePolicy.noSettle);
  }
}

final _updated = RegExp(r'updated\.$');

/// From the Outflow menu: opens the first outflow order that still offers
/// "Create Delivery"; false when none of the recent ones does.
Future<bool> _openOrderWithoutDelivery(PatrolIntegrationTester $) async {
  await $('Outflow Orders').tap();
  await expectScreen($, 'Outflow Orders');
  await waitForList($);
  return openFirstCardWhere(
    $,
    listTitle: 'Outflow Orders',
    matches: () async {
      await expectScreen($, 'Outflow Order');
      await waitForList($);
      return appears($, $('Create Delivery'));
    },
  );
}

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
    await _openEditableDelivery($);

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
    await _openEditableDelivery($);
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

    await _markFirstStatus($);
    await waitForSuccess($, $(_updated));
    await $.pumpAndTrySettle();
    expect(_currentStatus($), isNot(before));
  });

  e2eTest('creating a delivery from an outflow order refreshes the detail', skip: !hasCredentials, ($) async {
    await loginAsTestUser($);
    await $(#homeOutflowTask).tap();
    await expectScreen($, 'Outflow');

    if (!await _openOrderWithoutDelivery($)) {
      // Every recent order already has a delivery: make one that doesn't by
      // outflowing a request line and answering "Not now" to the prompt.
      await $(#appBarBackButton).tap();
      await expectScreen($, 'Outflow');
      await outflowOneLine($, createDelivery: false);
      await expectScreen($, 'Outflow Requests');
      for (var i = 0; i < 3 && !$('By Request').exists; i++) {
        await $(#appBarBackButton).tap();
      }
      await expectScreen($, 'Outflow');
      if (!await _openOrderWithoutDelivery($)) {
        fail('The outflow order just created (delivery skipped) offers no "Create Delivery"');
      }
    }

    await $('Create Delivery').scrollTo();
    await $('Create Delivery').tap(settlePolicy: SettlePolicy.noSettle);
    await waitForSuccess($, $('Delivery created.'));
    await $('Search code / customer...').waitUntilExists(timeout: apiTimeout);

    // Back lands on the refreshed detail, not a stale "Create Delivery".
    await $(#appBarBackButton).tap();
    await $('View Deliveries').waitUntilVisible(timeout: apiTimeout);
    expect($('Create Delivery'), findsNothing);
  });
}
