import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/data/providers/api_providers.dart';
import 'package:getx_project/app/services/auth_service.dart';
import 'package:getx_project/main.dart';
import 'package:patrol/patrol.dart';

/// Real-backend credentials, passed at run time so they never live in the repo:
///   patrol test -t patrol_test/login_test.dart \
///     --dart-define=TEST_USERNAME=... --dart-define=TEST_PASSWORD=...
const testUsername = String.fromEnvironment('TEST_USERNAME');
const testPassword = String.fromEnvironment('TEST_PASSWORD');
const hasCredentials = testUsername != '' && testPassword != '';

/// Matches AppConfig.apiTimeoutSeconds: a request over the ngrok tunnel can
/// take ~13s, so a shorter wait flakes before the request itself times out.
const apiTimeout = Duration(seconds: 30);

/// Placeholder strings drawn by the Skeletonizer helpers in
/// global/widget/skeleton_widgets.dart. They render as real Text, so a list is
/// only loaded once none of them is on screen.
const skeletonTexts = [
  'Loading code 0000',
  'Loading name placeholder',
  'Loading placeholder title here',
  'Loading item name',
  'Loading item name placeholder',
];

/// patrolTest that always drains GetX snackbars afterwards (also on failure).
/// A snackbar still animating when the tree is disposed fails the test with
/// "animation still running", and GetX's global snackbar queue would otherwise
/// carry the orphan into the next test and block its alerts.
void e2eTest(
  String description,
  Future<void> Function(PatrolIntegrationTester $) body, {
  bool skip = false,
}) {
  patrolTest(description, skip: skip, ($) async {
    try {
      await body($);
    } finally {
      await closeSnackbars($);
    }
  });
}

/// Closes every open/queued GetX snackbar and pumps until its exit animation
/// has finished.
Future<void> closeSnackbars(PatrolIntegrationTester $) async {
  if (!SnackbarController.isSnackbarBeingShown) return;
  Get.closeAllSnackbars();
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (SnackbarController.isSnackbarBeingShown && DateTime.now().isBefore(end)) {
    await $.pump(const Duration(milliseconds: 100));
  }
  await $.pump(const Duration(seconds: 1));
}

/// Boots the app the way main() does, minus CrashReporter.runGuarded, which
/// clashes with the test harness.
Future<void> launchApp(PatrolIntegrationTester $) async {
  await initServices();
  await $.pumpWidgetAndSettle(const MyApp());
}

/// Signs in through the API (no login form) and launches the app straight on
/// Home. clearPackageData wipes the token before every test, but typing into
/// the form each time is slow; only login_test needs the real form
/// ([loginViaForm]).
///
/// The ngrok tunnel occasionally drops a request outright, so a failed attempt
/// is retried up to [_loginAttempts] times before the test fails.
Future<void> loginAsTestUser(PatrolIntegrationTester $) async {
  await initServices();
  final auth = Get.find<AuthService>();
  var lastError = '';
  for (var attempt = 1; attempt <= _loginAttempts; attempt++) {
    try {
      final data = (await Get.find<ApiProvider>().postMap('/login', {
        'username': testUsername,
        'password': testPassword,
      }))['data'];
      final token = data?['token'] as String?;
      if (token == null || token.isEmpty) fail('Login response has no token');
      // Same session LoginController.authLogin stores.
      await auth.setToken(token);
      auth.setUsername(data['name'] as String?);
      final roles = (data['roles'] as List?)?.map((r) => r['name'] as String);
      if (roles != null && roles.isNotEmpty) auth.setRoles(roles.join(', '));
      break;
    } on TestFailure {
      rethrow;
    } catch (e) {
      lastError = e.toString().replaceFirst('Exception: ', '');
      // Wrong credentials won't fix themselves — and retrying could trip a throttle.
      if (lastError.contains('credentials')) fail('Login rejected: $lastError');
      if (attempt == _loginAttempts) fail('Login failed after $_loginAttempts attempts: $lastError');
      // ignore: avoid_print
      print('loginAsTestUser: attempt $attempt failed ($lastError), retrying');
    }
  }
  // Home's skeleton shimmer never settles, so wait for its content instead.
  await $.tester.pumpWidget(const MyApp());
  await $('Quick Access').waitUntilVisible(timeout: apiTimeout);
  await $.pumpAndTrySettle();
}

/// Launches the app and signs in by typing the dart-define credentials into
/// the login form. Retries like [loginAsTestUser] (the "Error!" snackbar shows
/// when the tunnel drops the request).
Future<void> loginViaForm(PatrolIntegrationTester $) async {
  await launchApp($);
  await $(#loginUsernameField).enterText(testUsername);
  await $(#loginPasswordField).enterText(testPassword);
  var lastError = '';
  for (var attempt = 1; attempt <= _loginAttempts; attempt++) {
    await $('Sign In').tap(settlePolicy: SettlePolicy.noSettle);
    final end = DateTime.now().add(apiTimeout);
    while (DateTime.now().isBefore(end)) {
      await $.pump(const Duration(milliseconds: 250));
      if ($('Quick Access').exists) {
        await $.pumpAndTrySettle();
        return;
      }
      if ($('Error!').exists) break;
    }
    lastError = errorSnackbarText($) ?? 'no response within ${apiTimeout.inSeconds}s';
    // Wrong credentials won't fix themselves — and retrying could trip a throttle.
    if (lastError.contains('credentials')) fail('Login rejected: $lastError');
    // ignore: avoid_print
    print('loginAsTestUser: attempt $attempt failed ($lastError), retrying');
    await closeSnackbars($);
  }
  fail('Login failed after $_loginAttempts attempts: $lastError');
}

const _loginAttempts = 3;

/// Waits until every skeleton placeholder has been replaced by real content
/// (or the empty-state text). Shimmer never settles, so pumpAndSettle can't.
///
/// Some screens start their fetch a frame or two after the first build and
/// briefly show the empty state before the skeleton, so "no skeleton" only
/// counts once it has held for [_listStableFor].
///
/// A load that lands on the errorRetry state (the ngrok tunnel drops requests
/// now and then) is retried up to [_listRetries] times before failing; a
/// genuinely broken endpoint still fails every attempt.
Future<void> waitForList(PatrolIntegrationTester $) async {
  for (var retry = 0; retry < _listRetries; retry++) {
    await _waitForListOnce($);
    if (!$('Retry').exists) return;
    // ignore: avoid_print
    print('waitForList: load failed, tapping Retry (${retry + 1}/$_listRetries)');
    await $('Retry').tap(settlePolicy: SettlePolicy.noSettle);
  }
  await _waitForListOnce($);
  if ($('Retry').exists) fail('List failed to load (errorRetry state shown)');
}

const _listRetries = 2;

Future<void> _waitForListOnce(PatrolIntegrationTester $) async {
  final end = DateTime.now().add(apiTimeout);
  var stableSince = DateTime.now();
  while (DateTime.now().difference(stableSince) < _listStableFor) {
    if (DateTime.now().isAfter(end)) {
      fail('List still loading after ${apiTimeout.inSeconds}s');
    }
    await $.pump(const Duration(milliseconds: 250));
    if (skeletonTexts.any((t) => find.text(t).evaluate().isNotEmpty)) {
      stableSince = DateTime.now();
    }
  }
}

const _listStableFor = Duration(milliseconds: 1500);

/// Tappable rows of the current list screen: orderListCard / masterListCard
/// are InkWells inside the screen's vertical ListView (horizontal ones hold
/// filter chips, e.g. the delivery status chips). Call after [waitForList].
Finder listCards() => find.descendant(
      of: find.byWidgetPredicate(
          (w) => w is ListView && w.scrollDirection == Axis.vertical),
      matching: find.byType(InkWell),
    );

/// Text of the card's first Text widget (its title: code / PO number / name).
String listCardTitle(PatrolIntegrationTester $, int index) {
  final title = find.descendant(of: listCards().at(index), matching: find.byType(Text)).first;
  return $.tester.widget<Text>(title).data ?? '';
}

/// Taps the [index]-th list card; fails with a reseed hint when there is none.
Future<void> tapListCard(PatrolIntegrationTester $, [int index = 0]) async {
  final cards = listCards();
  expect(cards.evaluate().length, greaterThan(index),
      reason: 'list has no card #$index — reseed DemoTenantSeeder');
  await $.tester.ensureVisible(cards.at(index));
  await $.tester.tap(cards.at(index));
  await $.pumpAndTrySettle();
}

/// Pumps until [finder] exists or [timeout] passes; returns whether it showed.
/// For optional UI (a dialog that only some items open).
Future<bool> appears(
  PatrolIntegrationTester $,
  PatrolFinder finder, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (finder.exists) return true;
    await $.pump(const Duration(milliseconds: 200));
  }
  return finder.exists;
}

/// Text of the GetX error snackbar on screen ("Error!" from ApiExecutor /
/// "Error" from errorAlertBottom), or null when none is showing.
String? errorSnackbarText(PatrolIntegrationTester $) {
  if (find.byType(GetSnackBar).evaluate().isEmpty) return null;
  if (!$('Error!').exists && !$('Error').exists) return null;
  return find
      .descendant(of: find.byType(GetSnackBar), matching: find.byType(Text))
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .join(' | ');
}

/// Waits for [success] after a write action. If an error snackbar shows
/// instead ("Error!" from ApiExecutor / "Error" from errorAlertBottom), fails
/// with the message the app displayed, so a backend rejection is readable.
Future<void> waitForSuccess(PatrolIntegrationTester $, PatrolFinder success) async {
  final end = DateTime.now().add(apiTimeout);
  while (DateTime.now().isBefore(end)) {
    if (success.exists) return;
    final error = errorSnackbarText($);
    if (error != null) fail('App showed an error instead of the expected result: $error');
    await $.pump(const Duration(milliseconds: 200));
  }
  fail('Timed out after ${apiTimeout.inSeconds}s waiting for $success');
}

/// Grants the native camera prompt if it shows; a no-op when the permission
/// was already granted on an earlier run.
Future<void> grantCameraIfAsked(PatrolIntegrationTester $) async {
  final mobile = $.platform.mobile;
  if (await mobile.isPermissionDialogVisible(timeout: const Duration(seconds: 3))) {
    await mobile.grantPermissionWhenInUse();
  }
}

/// Timestamp suffix so write tests never collide on receive numbers etc.
String uniqueSuffix() => DateTime.now().millisecondsSinceEpoch.toString();

/// Waits for a screen identified by its AppBar title.
Future<void> expectScreen(PatrolIntegrationTester $, String appBarTitle) =>
    $(appBarTitle).waitUntilVisible(timeout: apiTimeout);
