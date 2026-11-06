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
Future<void> _confirmFirstPendingLabel(PatrolIntegrationTester $, String listTitle) async {
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

  // Back pops to the order list, which must reload (not show the stale list).
  await $(#appBarBackButton).tap();
  await expectScreen($, listTitle);
  await waitForList($);
}

/// "Fill" on a line that is not one of the backend's serial samples (their
/// names end in "— serial-tracked" / "— batch-tracked").
Finder _plainFill() {
  final plainLines = find.byElementPredicate((e) =>
      e.widget.key == const Key('orderItemSummaryTile') &&
      find
          .descendant(of: find.byElementPredicate((x) => identical(x, e)), matching: find.textContaining('-tracked'))
          .evaluate()
          .isEmpty);
  return find.descendant(of: plainLines, matching: find.text('Fill'));
}

/// On an order list ("Purchase Orders" / "Suppliers"): receives 1 unit of
/// the first fillable line, submits it and finishes Confirm Serials, which
/// returns to [listTitle]. With [poNumber] it searches for that PO instead,
/// and then requires labels to confirm (a serial-tracked line).
Future<void> _receiveOneLine(
  PatrolIntegrationTester $, {
  required String listTitle,
  String? poNumber,
  Future<void> Function()? onConfirmSerials,
}) async {
  if (poNumber == null) {
    await openOrderWithAction(
      $,
      listTitle: listTitle,
      action: 'Fill',
      noneMessage: 'No open line to fill under "$listTitle" — reseed DemoTenantSeeder',
      // Leave the serial / batch sample POs' few units to their own tests —
      // by PO number on "Purchase Orders", by line on "Suppliers" (a supplier
      // card groups every PO of that supplier, the samples included).
      skipTitles: const {_serialPo, _batchPo},
      target: _plainFill(),
    );
  } else {
    await $(#searchBarField).enterText(poNumber, hideKeyboard: false);
    await $(#searchBarSubmit).tap();
    await waitForList($);
    expect(listCardTitle($, 0), poNumber, reason: '$poNumber not found — run SerialTrackedFlowSampleSeeder');
    await tapListCard($);
    await expectScreen($, 'Item Summary');
    await waitForList($);
    if (!$('Fill').exists) fail('$poNumber has nothing left to receive — rerun SerialTrackedFlowSampleSeeder');
  }

  await $(poNumber == null ? _plainFill() : find.text('Fill')).first.tap();
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
  // A failed load also lands on "Nothing to confirm" — it must not pass for one.
  final error = errorSnackbarText($);
  if (error != null) fail('Confirm Serials failed to load: $error');
  if ($('Nothing to confirm').exists) {
    if (poNumber != null) fail('Receiving serial-tracked $poNumber minted no labels to confirm');
    await $('Done').tap();
    await expectScreen($, listTitle);
    return;
  }
  // A test's own checks on Confirm Serials, before a label is confirmed.
  if (onConfirmSerials != null) await onConfirmSerials();
  await _confirmFirstPendingLabel($, listTitle);
}

/// Seeded by the backend's SerialTrackedFlowSampleSeeder: a PO line for a
/// serial-tracked (manage_sn, UNIQUE) item, still open to receive.
const _serialPo = 'PO-SMP-SN-OPEN';

/// The same for its BATCH item (one label per batch entry).
const _batchPo = 'PO-SMP-SNB-OPEN';

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
    await _receiveOneLine($, listTitle: 'Purchase Orders');
  });

  e2eTest('receiving a serial-tracked line mints labels to confirm', skip: !hasCredentials, ($) async {
    await _openPurchaseOrders($);
    // Seeded by the backend's SerialTrackedFlowSampleSeeder (manage_sn, UNIQUE).
    await _receiveOneLine($, listTitle: 'Purchase Orders', poNumber: _serialPo);
  });

  e2eTest('receiving a supplier line reaches confirm serials', skip: !hasCredentials, ($) async {
    await _openReceiveMenu($);
    await $('By Supplier').tap();
    await expectScreen($, 'Suppliers');
    await waitForList($);
    await _receiveOneLine($, listTitle: 'Suppliers');
  });

  e2eTest('receiving a batch line shows its batch label and asks before finishing', skip: !hasCredentials, tags: 'batch', ($) async {
    await _openPurchaseOrders($);
    await _receiveOneLine(
      $,
      listTitle: 'Purchase Orders',
      poNumber: _batchPo,
      onConfirmSerials: () async {
        // A manage_sn BATCH line: one label for the batch entry, marked Batch with its qty.
        expect($(#receiveConfirmSerialType).$('Batch'), findsOneWidget);
        expect($('Batch · qty 1'), findsWidgets);

        // Finishing with the label still pending asks first; Keep Scanning stays.
        await $(#receiveConfirmNextButton).tap();
        await $(#receiveConfirmPendingDialog).waitUntilVisible();
        await $('Keep Scanning').tap();
        await expectScreen($, 'Confirm Serials');
        expect($(#receiveConfirmPendingDialog), findsNothing);
        expect($('Pending'), findsWidgets);
      },
    );
  });
}
