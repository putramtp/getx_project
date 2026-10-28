import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/modules/home/controllers/home_controller.dart';

import 'common/harness.dart';

/// Home entry point (key or visible text) → AppBar title of the screen it opens.
const _entryPoints = <Object, String>{
  #homeStatProducts: 'Products',
  #homeViewProducts: 'Products',
  #homeStatReceive: 'Receive',
  #homeStatOutflow: 'Outflow',
  #homeReceiveTask: 'Receive',
  #homeOutflowTask: 'Outflow',
  #homeDeliveries: 'Deliveries',
  'Transactions': 'Stock Transactions',
  'Category': 'Categories',
  'Brand': 'Brands',
  'Unit': 'Units',
  'See all': 'Stock Transactions',
};

void main() {
  e2eTest('dashboard shows its sections', skip: !hasCredentials, ($) async {
    await loginAsTestUser($);

    expect($('Start a task'), findsOneWidget);
    expect($('Overview'), findsOneWidget);
    expect($('Inventory'), findsOneWidget);
    await $('Latest transactions').scrollTo();
    expect($('Latest transactions'), findsOneWidget);
    await $('Serial number type').scrollTo();
    expect($('Serial number type'), findsOneWidget);
  });

  e2eTest('pull to refresh keeps real dashboard counts', skip: !hasCredentials, ($) async {
    await loginAsTestUser($);
    final home = Get.find<HomeController>();
    await waitUntilTrue($, () => home.dashboard.value.product > 0,
        reason: 'dashboard product count stayed 0 (GET /dashboard-inventory)');

    await $.tester.fling(find.byType(RefreshIndicator), const Offset(0, 400), 1000);
    await $.pump(const Duration(milliseconds: 300));
    await waitUntilTrue($, () => !home.isLoading.value, reason: 'dashboard reload never finished');

    expect(errorSnackbarText($), isNull, reason: 'reloading the dashboard showed an error');
    expect(home.dashboard.value.product, greaterThan(0), reason: 'reload reset the counts to 0');
  });

  e2eTest('home entry points open their screens', skip: !hasCredentials, ($) async {
    await loginAsTestUser($);

    for (final MapEntry(key: tile, value: title) in _entryPoints.entries) {
      await $(tile).scrollTo();
      await $(tile).tap();
      await expectScreen($, title);
      await $(#appBarBackButton).tap();
      // Home may be scrolled past the section title, so wait for existence.
      await $('Start a task').waitUntilExists(timeout: apiTimeout);
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
