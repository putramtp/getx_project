import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/data/providers/api_providers.dart';
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
  Set<String> skipTitles = const {},
}) async {
  final found = await openFirstCardWhere(
    $,
    listTitle: listTitle,
    maxCards: maxCards,
    skipTitles: skipTitles,
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

/// From the Outflow menu: opens [menuTile] ("By Request" → "Outflow
/// Requests", "By Customer" → "Customers"), outflows 1 unit of the first
/// open quantity-only line, then answers the "Create delivery?" prompt with
/// [createDelivery]. "Fill" = a quantity-only (manage_sn false) line; the
/// "Scan" path needs a serial-tracked line plus a serial known to be in stock.
Future<void> outflowOneLine(
  PatrolIntegrationTester $, {
  String menuTile = 'By Request',
  String listTitle = 'Outflow Requests',
  required bool createDelivery,
}) async {
  await $(menuTile).scrollTo();
  await $(menuTile).tap();
  await expectScreen($, listTitle);
  await waitForList($);
  await openOrderWithAction(
    $,
    listTitle: listTitle,
    action: 'Fill',
    noneMessage: 'No open quantity-only line under "$listTitle" — reseed DemoTenantSeeder',
  );

  await $('Fill').first.tap();
  await expectScreen($, 'Scan Item');
  await $(#orderFillFab).tap();
  await $(#qtyDialogField).enterText('1');
  await $('Save').tap();
  await $('Qty: 1').waitUntilVisible();
  expectAboveSystemNavBar($, find.text('Continue'));
  await continueBackToSummary($, 'Scan Item');
  await submitOutflow($, createDelivery: createDelivery);
}

/// On an outflow Item Summary with something scanned/filled: submits it and
/// answers the "Create delivery?" prompt with [createDelivery].
Future<void> submitOutflow(PatrolIntegrationTester $, {required bool createDelivery}) async {
  expectAboveSystemNavBar($, find.textContaining(RegExp('^Continue to outflowing items')));
  await $(RegExp('^Continue to outflowing items')).tap();
  await $('Continue to Outflowing Items?').waitUntilVisible();
  await $('Continue').tap(settlePolicy: SettlePolicy.noSettle);

  await waitForSuccess($, $('Create delivery?'));
  await $(createDelivery ? 'Create' : 'Not now').tap(settlePolicy: SettlePolicy.noSettle);
}

/// Request [requestCode]'s serial-tracked line: the SKU labels of its item
/// still in stock, read straight from the API (GET /item/{id}/serial-number —
/// read-only). Seeded by the backend's SerialTrackedFlowSampleSeeder.
Future<List<String>> inStockSerialsForRequest(String requestCode) async {
  final api = Get.find<ApiProvider>();
  final requests = (await api.getMap('/outflow-request/pagination', query: {'limit': '100'}))['data'] as List;
  final request = requests.cast<Map>().where((r) => r['code'] == requestCode).firstOrNull;
  if (request == null) fail('No outflow request $requestCode — run SerialTrackedFlowSampleSeeder');

  final lines = (await api.getMap('/outflow-request/${request['id']}/summary'))['data'] as List;
  final line = lines.cast<Map>().where((l) => l['manage_sn'] == true).firstOrNull;
  if (line == null) fail('$requestCode has no serial-tracked line');

  final item = (await api.getMap('/item/${line['item_id']}/serial-number'))['data'] as Map;
  return [for (final s in item['serials'] as List) s['internal_code'] as String];
}

/// On a Fill / Scan page, presses the bottom-bar "Continue" until the page
/// pops back to the Item Summary (it steps through the remaining items first).
Future<void> continueBackToSummary(PatrolIntegrationTester $, String pageTitle) async {
  for (var i = 0; i < 20 && $(pageTitle).exists; i++) {
    await $('Continue').tap();
  }
  await expectScreen($, 'Item Summary');
}
