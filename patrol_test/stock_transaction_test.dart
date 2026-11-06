import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/modules/transaction/controllers/stock_transaction_controller.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';

Future<void> _openStockTransactions(PatrolIntegrationTester $) async {
  await loginAsTestUser($);
  await $('Transactions').scrollTo();
  await $('Transactions').tap();
  await expectScreen($, 'Stock Transactions');
  await waitForList($);
}

Future<void> _openFilter(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Filter'));
  await $('Filter Options').waitUntilVisible();
}

void main() {
  e2eTest('stock transaction list loads', skip: !hasCredentials, ($) async {
    await _openStockTransactions($);

    // The ledger rows are plain Cards (no InkWell), so listCards() can't see
    // them: check the loaded rows and that one is on screen.
    expect(Get.find<StockTransactionController>().trans, isNotEmpty,
        reason: 'no stock transaction listed — the ledger is empty or failed to load');
    expect(find.byType(Card), findsWidgets, reason: 'rows loaded but none is shown');
  });

  e2eTest('date filter applies and clears', skip: !hasCredentials, ($) async {
    await _openStockTransactions($);

    final ledger = Get.find<StockTransactionController>();

    await _openFilter($);
    await chooseFilterLimit($, 50);
    await $('Apply').tap();
    await waitForList($);
    expect($('Filter Options'), findsNothing);
    expect(ledger.buildParams()['limit'], '50', reason: 'the chosen limit was not sent with the list query');

    await _openFilter($);
    await $('Clear').tap(settlePolicy: SettlePolicy.noSettle);
    await $('Filter has been reset.').waitUntilVisible();
    await waitForList($);
    expect(ledger.buildParams()['limit'], '20', reason: 'Clear did not reset the limit');
  });
}
