import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';
import 'common/order_flow.dart';

Future<void> _openReceiveMenu(PatrolIntegrationTester $) async {
  await loginAsTestUser($);
  await $(#homeReceiveTask).tap();
  await expectScreen($, 'Receive');
}

Future<void> _openPurchaseOrders(PatrolIntegrationTester $) async {
  await _openReceiveMenu($);
  await $('By Purchase-order').tap();
  await expectScreen($, 'Purchase Orders');
  await waitForList($);
}

/// Fill page: one quantity of 1 for the selected line, through whichever
/// dialogs this item type opens (serial for manage_sn BATCH, expiry date when
/// the item manages expiry).
Future<void> _fillOneUnit(PatrolIntegrationTester $) async {
  await $(#orderFillFab).tap();
  if (await appears($, $(#serialDialogField))) {
    await $(#serialDialogField).enterText('E2E-${uniqueSuffix()}');
    await $('Save').tap();
  }
  await $(#qtyDialogField).waitUntilVisible();
  await $(#qtyDialogField).enterText('1');
  if ($(#qtyDialogExpiryField).exists) {
    // The field sits under AbsorbPointer (its GestureDetector parent opens the
    // picker), so it is never hit-testable for Patrol's own tap.
    await $.tester.tap(find.byKey(const Key('qtyDialogExpiryField')), warnIfMissed: false);
    await $.pumpAndTrySettle();
    await $('OK').tap();
  }
  await $('Save').tap();
}

/// Confirm Serials: confirms the first pending label through the scanner's
/// manual-entry button (the camera itself can't be driven in a test).
Future<void> _confirmFirstPendingLabel(PatrolIntegrationTester $) async {
  final row = find.ancestor(of: find.text('Pending').first, matching: find.byType(ListTile));
  final code = ($.tester.widget<ListTile>(row).title! as Text).data!;

  await $(#receiveConfirmScanFab).tap(settlePolicy: SettlePolicy.noSettle);
  await grantCameraIfAsked($);
  await $(#scannerManualEntryButton).waitUntilVisible();
  await $(#scannerManualEntryButton).tap(settlePolicy: SettlePolicy.noSettle);
  await $(#serialDialogField).waitUntilVisible();
  await $(#serialDialogField).enterText(code);
  await $('Save').tap(settlePolicy: SettlePolicy.noSettle);

  await $(RegExp(r'^Confirmed 1/')).waitUntilVisible(timeout: apiTimeout);
  await $('Done').tap(settlePolicy: SettlePolicy.noSettle);
  await expectScreen($, 'Confirm Serials');

  // Back pops to the PO list, which must reload (not show the stale list).
  await $(#appBarBackButton).tap();
  await expectScreen($, 'Purchase Orders');
  await waitForList($);
}

void main() {
  e2eTest('menu shows the receiving entries', skip: !hasCredentials, ($) async {
    await _openReceiveMenu($);

    expect($('Receive Orders'), findsOneWidget);
    expect($('By Purchase-order'), findsOneWidget);
    expect($('By Supplier'), findsOneWidget);
  });

  e2eTest('receive order list opens a detail', skip: !hasCredentials, ($) async {
    await _openReceiveMenu($);
    await $('Receive Orders').tap();
    await expectScreen($, 'Receive Orders');
    await waitForList($);

    await tapListCard($);
    await expectScreen($, 'Receive Order');
    await waitForList($);
  });

  e2eTest('purchase order search finds a PO by number', skip: !hasCredentials, ($) async {
    await _openPurchaseOrders($);
    expect(listCards().evaluate().length, greaterThan(1), reason: 'need 2+ POs to prove the search narrows');
    // Search for the second PO: finding the first one would pass even if search did nothing.
    final poNumber = listCardTitle($, 1);

    // The submit (check) icon only shows while the field is focused, and
    // enterText unfocuses by default.
    await $(#searchBarField).enterText(poNumber, hideKeyboard: false);
    await $(#searchBarSubmit).tap();
    await waitForList($);

    expect(listCardTitle($, 0), poNumber);
  });

  e2eTest('supplier list loads', skip: !hasCredentials, ($) async {
    await _openReceiveMenu($);
    await $('By Supplier').tap();
    await expectScreen($, 'Suppliers');
    await waitForList($);

    expect(listCards(), findsWidgets);
  });

  e2eTest('filled quantities survive leaving and reopening the PO', skip: !hasCredentials, ($) async {
    Future<void> openPoWithFill() => openOrderWithAction(
          $,
          listTitle: 'Purchase Orders',
          action: 'Fill',
          noneMessage: 'No open PO with a fillable line — reseed DemoTenantSeeder',
        );
    await _openPurchaseOrders($);
    await openPoWithFill();
    expect($(RegExp(r'receiving: [1-9]')), findsNothing, reason: 'storage is wiped per test');

    await $('Fill').first.tap();
    await expectScreen($, 'Fill Item');
    await _fillOneUnit($);
    await continueBackToSummary($, 'Fill Item');
    await $(RegExp(r'receiving: [1-9]')).waitUntilVisible();

    // Leave the PO (nothing is submitted) and open it again: the draft in the
    // local sqflite DB restores the filled line.
    await $(#appBarBackButton).tap();
    await expectScreen($, 'Purchase Orders');
    await waitForList($);
    await openPoWithFill();
    await $(RegExp(r'receiving: [1-9]')).waitUntilVisible();
  });

  e2eTest('receiving a PO line reaches confirm serials', skip: !hasCredentials, ($) async {
    await _openPurchaseOrders($);
    await openOrderWithAction(
      $,
      listTitle: 'Purchase Orders',
      action: 'Fill',
      noneMessage: 'No open PO with a fillable line — reseed DemoTenantSeeder',
    );

    await $('Fill').first.tap();
    await expectScreen($, 'Fill Item');
    await _fillOneUnit($);
    expectAboveSystemNavBar($, find.text('Continue'));
    await continueBackToSummary($, 'Fill Item');

    expectAboveSystemNavBar($, find.textContaining(RegExp('^Continue to receiving items')));
    await $(RegExp('^Continue to receiving items')).tap();
    if (await appears($, $(#receiveNumberField))) {
      await $(#receiveNumberField).enterText('E2E-${uniqueSuffix()}');
      await $('Save').tap();
    }
    await $(RegExp('^Continue to Receiving')).waitUntilVisible();
    await $('Continue').tap(settlePolicy: SettlePolicy.noSettle);

    await expectScreen($, 'Confirm Serials');
    await waitForList($);
    if ($('Nothing to confirm').exists) {
      await $('Done').tap();
      await expectScreen($, 'Purchase Orders');
      return;
    }
    await _confirmFirstPendingLabel($);
  });
}
