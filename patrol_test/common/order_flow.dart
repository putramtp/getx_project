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
  final count = listCards().evaluate().length;
  for (var i = 0; i < count && i < maxCards; i++) {
    await tapListCard($, i);
    await expectScreen($, 'Item Summary');
    await waitForList($);
    if ($(action).exists) return;

    await $(#appBarBackButton).tap();
    await expectScreen($, listTitle);
    await waitForList($);
  }
  fail(noneMessage);
}

/// On a Fill / Scan page, presses the bottom-bar "Continue" until the page
/// pops back to the Item Summary (it steps through the remaining items first).
Future<void> continueBackToSummary(PatrolIntegrationTester $, String pageTitle) async {
  for (var i = 0; i < 20 && $(pageTitle).exists; i++) {
    await $('Continue').tap();
  }
  await expectScreen($, 'Item Summary');
}
