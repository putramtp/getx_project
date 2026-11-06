import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/functions.dart';
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

/// The same for its BATCH item (one label per batch entry, drawn from in part).
const _batchRequest = 'OR-SMP-SNB-01';

/// Outflow scan page of a manage_sn BATCH line: scans [code] through the
/// keyboard path (scan sheet → Enter manually) and, when the label passes the
/// stock check, enters [qty] in the batch qty dialog.
Future<void> _scanBatch(PatrolIntegrationTester $, String code, {num? qty}) async {
  await closeSnackbars($);
  await $(#orderFillFab).tap();
  await $('Enter manually').tap();
  await $(#serialDialogField).waitUntilVisible();
  await $(#serialDialogField).enterText(code);
  await $('Save').tap(settlePolicy: SettlePolicy.noSettle);
  if (qty == null) return;
  await $(#qtyDialogField).waitUntilVisible(timeout: apiTimeout);
  await $(#qtyDialogField).enterText('$qty');
  await $('OK').tap(settlePolicy: SettlePolicy.noSettle);
}

void main() {
  e2eTest('menu shows the outflow entries', skip: !hasCredentials, ($) async {
    await _openOutflowMenu($);

    expect($('Outflow Orders'), findsOneWidget);
    expect($('By Request'), findsOneWidget);
    expect($('By Customer'), findsOneWidget);
    expect($('By Work Order'), findsOneWidget);
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
    // Open the UNIQUE request by name: the first request with a "Scan" line may
    // be the BATCH one, whose scan opens a scan/manual chooser, not the scanner.
    await $(#searchBarField).enterText(_serialRequest, hideKeyboard: false);
    await $(#searchBarSubmit).tap();
    await waitForList($);
    expect(listCardTitle($, 0), _serialRequest, reason: '$_serialRequest not found — run SerialTrackedFlowSampleSeeder');
    await tapListCard($);
    await expectScreen($, 'Item Summary');
    await waitForList($);
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

  e2eTest('work order list opens a work order\'s material', skip: !hasCredentials, tags: 'work_order', ($) async {
    await _openOutflowMenu($);
    await _openFromMenu($, 'By Work Order', 'Work Orders');
    expect(listCards(), findsWidgets, reason: 'no work order with open reservations — approve a material requisition');

    await tapListCard($);
    await expectScreen($, 'Item Summary');
    await waitForList($);
    expect(errorSnackbarText($), isNull);
    expect($(RegExp('^By Work Order')), findsOneWidget);
  });

  e2eTest('a batch label is checked against what is left of it', skip: !hasCredentials, tags: 'batch', ($) async {
    await _openOutflowMenu($);
    final batches = await inStockBatchesForRequest(_batchRequest);
    if (batches.isEmpty) fail('No $_batchRequest batch left in stock — rerun SerialTrackedFlowSampleSeeder');
    // The smallest batch, so the request's reserved qty leaves room past it.
    final batch = batches.entries.reduce((a, b) => a.value <= b.value ? a : b);

    await _openFromMenu($, 'By Request', 'Outflow Requests');
    await $(#searchBarField).enterText(_batchRequest, hideKeyboard: false);
    await $(#searchBarSubmit).tap();
    await waitForList($);
    expect(listCardTitle($, 0), _batchRequest, reason: '$_batchRequest not found — run SerialTrackedFlowSampleSeeder');
    await tapListCard($);
    await expectScreen($, 'Item Summary');
    await waitForList($);
    await $('Scan').first.tap();
    await expectScreen($, 'Scan Item');

    // A label that is not this item's stock is refused before the qty.
    await _scanBatch($, 'E2E-NOT-A-BATCH-${uniqueSuffix()}');
    await $('Unknown Batch').waitUntilExists(timeout: apiTimeout);
    expect($(#qtyDialogField), findsNothing);

    // More than the batch holds is refused; what it holds is taken.
    await _scanBatch($, batch.key, qty: batch.value + 1);
    await $('Not Enough in Batch').waitUntilExists(timeout: apiTimeout);
    await _scanBatch($, batch.key, qty: batch.value);
    await $('${batch.key} (qty: ${formatQty(batch.value)})').waitUntilVisible();

    // Once all of it is scanned, the batch is used up.
    await _scanBatch($, batch.key);
    await $('Batch Used Up').waitUntilExists(timeout: apiTimeout);

    // Nothing is submitted: clear the scan so no draft is left behind.
    await closeSnackbars($);
    await $('Clear').tap(settlePolicy: SettlePolicy.noSettle);
    await $(RegExp('^Removed 1 entry')).waitUntilExists();
  });

  e2eTest('scanning a serial label issues it to a work order', skip: !hasCredentials, tags: 'work_order', ($) async {
    await _openOutflowMenu($);
    final workOrder = await inStockSerialsForWorkOrder();
    if (workOrder.labels.isEmpty) fail('No serial-tracked label left in stock — rerun SerialTrackedFlowSampleSeeder');
    final label = workOrder.labels.first;

    // Open that very work order (its code is the card's subtitle; titles repeat
    // across projects), so the label belongs to the line on screen.
    await _openFromMenu($, 'By Work Order', 'Work Orders');
    if (!await scrollUntilExists($, $(workOrder.code))) fail('Work order ${workOrder.code} is not listed');
    await $(workOrder.code).tap();
    await expectScreen($, 'Item Summary');
    await waitForList($);
    expect($(RegExp('^By Work Order')), findsOneWidget);
    final scan = actionOnLine(workOrder.itemName, 'Scan');
    if (!await scrollUntilExists($, $(scan))) fail('${workOrder.code} has no ${workOrder.itemName} line to scan');
    await $(scan).first.tap();
    await expectScreen($, 'Scan Item');

    // Same UNIQUE scan as By Request: the label goes in through the scanner's
    // keyboard button, since the camera can't be driven.
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
    // A work order issue has no delivery: the success notice replaces the prompt.
    await submitOutflow($, createDelivery: null);
    await expectScreen($, 'Work Orders');

    // The backend attached exactly that label and took it out of stock.
    expect(await inStockLabels(workOrder.itemId), isNot(contains(label)));
  });

  e2eTest('a work order line the backend refuses is read-only', skip: !hasCredentials, tags: ['work_order', 'work_order_readonly'], ($) async {
    await _openOutflowMenu($);
    await _openFromMenu($, 'By Work Order', 'Work Orders');

    // A completed work order stays listed (its reservations are never closed)
    // with every line locked: the reason shows, and there is nothing to fill.
    final found = await openFirstCardWhere(
      $,
      listTitle: 'Work Orders',
      maxCards: 15,
      matches: () async {
        await expectScreen($, 'Item Summary');
        await waitForList($);
        return await scrollUntilExists($, $(#orderLineBlockedReason)) && !$('Fill').exists && !$('Scan').exists;
      },
    );
    if (!found) fail('No work order with only refused lines — complete a work order that has reservations');

    expect($(#orderLineBlockedReason), findsWidgets);
    final reason = find.descendant(of: find.byKey(const Key('orderLineBlockedReason')).first, matching: find.byType(Text));
    expect($.tester.widget<Text>(reason).data, isNotEmpty);
    expect($('Fill'), findsNothing);
    expect($('Scan'), findsNothing);
  });

  e2eTest('issuing work order material returns to work orders', skip: !hasCredentials, tags: 'work_order', ($) async {
    await _openOutflowMenu($);
    await outflowOneLine($, menuTile: 'By Work Order', listTitle: 'Work Orders', createDelivery: null);

    await expectScreen($, 'Work Orders');
    await waitForList($);
    expect($('Item Summary'), findsNothing);
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
