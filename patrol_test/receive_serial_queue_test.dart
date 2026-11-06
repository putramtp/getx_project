import 'package:flutter_test/flutter_test.dart';

import 'common/harness.dart';

/// The Receive home's "Serials to Confirm" queue. Read-only: it opens Confirm
/// Serials and leaves without scanning, so the tenant needs at least one
/// receive order from the last 30 days with an unscanned manage_sn label
/// (receiving `PO-SMP-SN-OPEN` without finishing Confirm Serials leaves one).
void main() {
  e2eTest('serials-to-confirm card opens the queue and its confirm pass', skip: !hasCredentials, tags: 'serial_queue',
      ($) async {
    await loginAsTestUser($);
    await $(#homeReceiveTask).tap();
    await expectScreen($, 'Receive');

    final card = $(#receiveHomeSerialQueueCard);
    if (!await appears($, card)) {
      fail('No "Serials to Confirm" card — no recent receive order has unscanned labels');
    }
    expect($(RegExp(r'not scanned$')), findsOneWidget);

    await card.tap();
    await expectScreen($, 'Serials to Confirm');
    await waitForList($);
    expect(listCards().evaluate(), isNotEmpty, reason: 'the card promised pending orders');
    expect($(RegExp(r'^\d+ to scan$')), findsWidgets);

    await tapListCard($);
    await expectScreen($, 'Confirm Serials');
    await waitForList($);
    expect($('Pending'), findsWidgets, reason: 'a queued order must still have a label to scan');

    // Back returns to the queue (reloaded), then to the menu with the card.
    await $(#appBarBackButton).tap();
    await expectScreen($, 'Serials to Confirm');
    await waitForList($);
    await $(#appBarBackButton).tap();
    await expectScreen($, 'Receive');
    await card.waitUntilExists();
  });
}
