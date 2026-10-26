import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';

Future<void> _openStockTransactions(PatrolIntegrationTester $) async {
  await loginAsTestUser($);
  await $('Transaction').scrollTo();
  await $('Transaction').tap();
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

    expect($('Stock Transactions'), findsOneWidget);
  });

  e2eTest('date filter applies and clears', skip: !hasCredentials, ($) async {
    await _openStockTransactions($);

    await _openFilter($);
    await $('Apply').tap();
    await waitForList($);
    expect($('Filter Options'), findsNothing);

    await _openFilter($);
    await $('Clear').tap(settlePolicy: SettlePolicy.noSettle);
    await $('Filter has been reset.').waitUntilVisible();
    await waitForList($);
  });
}
