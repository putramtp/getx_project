import 'package:flutter_test/flutter_test.dart';

import 'common/harness.dart';

/// Quick Access tile text → AppBar title of the screen it opens.
const _quickAccess = {
  'PRODUCT': 'Product',
  'RECEIVE ORDER': 'Receive Order Menu',
  'OUTFLOW ORDER': 'Outflow Order Menu',
  'Transaction': 'Stock Transactions',
  'Category': 'Category',
  'Brand': 'Brand',
  'Unit': 'Unit',
};

void main() {
  e2eTest('dashboard shows its sections', skip: !hasCredentials, ($) async {
    await loginAsTestUser($);

    expect($('Quick Access'), findsOneWidget);
    await $('Latest Transactions').scrollTo();
    expect($('Latest Transactions'), findsOneWidget);
    await $('Statistic').scrollTo();
    expect($('Statistic'), findsOneWidget);
  });

  e2eTest('quick access tiles open their screens', skip: !hasCredentials, ($) async {
    await loginAsTestUser($);

    for (final MapEntry(key: tile, value: title) in _quickAccess.entries) {
      await $(tile).scrollTo();
      await $(tile).tap();
      await expectScreen($, title);
      await $(#appBarBackButton).tap();
      await $('Quick Access').waitUntilVisible(timeout: apiTimeout);
    }
  });

  e2eTest('account info dialog opens and closes', skip: !hasCredentials, ($) async {
    await loginAsTestUser($);

    await $(#homeAccountButton).tap();
    await $('Account Info').tap();
    expect($('Username'), findsWidgets);
    expect($('Role'), findsOneWidget);
    await $('Close').tap();
    expect($('Account Info'), findsNothing);
  });

  e2eTest('logout returns to the login screen', skip: !hasCredentials, ($) async {
    await loginAsTestUser($);

    await $(#homeAccountButton).tap();
    await $('Logout').tap();
    await $('Sign in to continue').waitUntilVisible(timeout: apiTimeout);
  });
}
