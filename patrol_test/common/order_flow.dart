import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'harness.dart';

/// On an order list screen (PO / request / supplier / customer), opens cards
/// top-down until one's Item Summary still offers [action] ("Fill" / "Scan").
/// Fails with [noneMessage] when none of the first [maxCards] does.
Future<void> openOrderWithAction(
  PatrolIntegrationTester $, {
  required String listTitle,
  required String action,
  required String noneMessage,
  int maxCards = 8,
}) async {
  final found = await openFirstCardWhere(
    $,
    listTitle: listTitle,
    maxCards: maxCards,
    matches: () async {
      await expectScreen($, 'Item Summary');
      await waitForList($);
      // Item Summary has no errorRetry state: a failed load shows "No items
      // found." plus an error snackbar, which must not read as "nothing open".
      final error = errorSnackbarText($);
      if (error != null) fail('Item Summary failed to load: $error');
      return $(action).exists;
    },
  );
  if (!found) fail(noneMessage);
}

/// From the Outflow menu: outflows 1 unit of the first open quantity-only
/// request line, then answers the "Create delivery?" prompt with
/// [createDelivery]. "Fill" = a quantity-only (manage_sn false) line; the
/// "Scan" path needs a serial known to be in stock, which can't be picked
/// dynamically.
Future<void> outflowOneRequestLine(
  PatrolIntegrationTester $, {
  required bool createDelivery,
}) async {
  await $('By Request').scrollTo();
  await $('By Request').tap();
  await expectScreen($, 'Outflow Requests');
  await waitForList($);
  await openOrderWithAction(
    $,
    listTitle: 'Outflow Requests',
    action: 'Fill',
    noneMessage: 'No open request with a quantity-only line — reseed DemoTenantSeeder',
  );

  await $('Fill').first.tap();
  await expectScreen($, 'Scan Item');
  await $(#orderFillFab).tap();
  await $(#qtyDialogField).enterText('1');
  await $('Save').tap();
  await $('Qty: 1').waitUntilVisible();
  expectAboveSystemNavBar($, find.text('Continue'));
  await continueBackToSummary($, 'Scan Item');

  expectAboveSystemNavBar($, find.textContaining(RegExp('^Continue to outflowing items')));
  await $(RegExp('^Continue to outflowing items')).tap();
  await $('Continue to Outflowing Items?').waitUntilVisible();
  await $('Continue').tap(settlePolicy: SettlePolicy.noSettle);

  await waitForSuccess($, $('Create delivery?'));
  await $(createDelivery ? 'Create' : 'Not now').tap(settlePolicy: SettlePolicy.noSettle);
}

/// On a Fill / Scan page, presses the bottom-bar "Continue" until the page
/// pops back to the Item Summary (it steps through the remaining items first).
Future<void> continueBackToSummary(PatrolIntegrationTester $, String pageTitle) async {
  for (var i = 0; i < 20 && $(pageTitle).exists; i++) {
    await $('Continue').tap();
  }
  await expectScreen($, 'Item Summary');
}
