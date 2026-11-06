import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/config/app_config.dart';
import 'package:getx_project/app/data/providers/api_providers.dart';
import 'package:getx_project/app/data/models/workspace_sign_in_model.dart';
import 'package:getx_project/app/data/providers/workspace_provider.dart';
import 'package:getx_project/app/services/auth_service.dart';
import 'package:getx_project/app/services/workspace_session.dart';
import 'package:getx_project/main.dart';
import 'package:patrol/patrol.dart';

/// Real-backend credentials, passed at run time so they never live in the repo.
/// Which ones depends on the build's mode (the env file):
///
/// - **workspace** (`CENTRAL_API_URL`, e.g. `env/dev-workspace.json`) — email
///   sign-in: `--dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...`
/// - **direct** (`API_BASE_URL` only) — old `/login`:
///   `--dart-define=TEST_USERNAME=... --dart-define=TEST_PASSWORD=...`
///
/// Either may list several accounts, comma-separated, that share
/// TEST_PASSWORD: the backend allows each account only 20 sign-ins an hour,
/// fewer than the suite's one-per-test, so [loginAsTestUser] spreads the tests
/// over them ([accountFor]). The form test ([loginViaForm]) uses the first.
const _testEmails = String.fromEnvironment('TEST_EMAIL');
const _testUsernames = String.fromEnvironment('TEST_USERNAME');
const testPassword = String.fromEnvironment('TEST_PASSWORD');

/// Workspace mode only: an email that belongs to two or more companies, so the
/// sign-in answers `choose` and the company chooser opens
/// (`--dart-define=TEST_MULTI_EMAIL=...`). Its password is TEST_MULTI_PASSWORD,
/// or TEST_PASSWORD when that is not given. [loginAsTestUser] refuses such an
/// account on purpose, so it is never part of TEST_EMAIL.
const testMultiEmail = String.fromEnvironment('TEST_MULTI_EMAIL');
const _testMultiPassword = String.fromEnvironment('TEST_MULTI_PASSWORD');
String get testMultiPassword => _testMultiPassword.isNotEmpty ? _testMultiPassword : testPassword;
bool get hasMultiCompanyAccount => workspaceMode && testMultiEmail.isNotEmpty && testMultiPassword.isNotEmpty;

/// Workspace mode only: the company [loginAsTestUser] picks when a TEST_EMAIL
/// account belongs to several (`--dart-define=TEST_COMPANY=mc`) — matched
/// against the tenant id, the first label of its host (`mc` for
/// `mc.mastersystembackend.test`) or its name, ignoring case. Without it such
/// an account fails the test, since the harness can't guess the company.
const testCompany = String.fromEnvironment('TEST_COMPANY');

/// True when the build signs in by email (see [AppConfig.isWorkspaceMode]).
bool get workspaceMode => AppConfig.isWorkspaceMode;

final List<String> testAccounts = (workspaceMode ? _testEmails : _testUsernames)
    .split(',')
    .map((u) => u.trim())
    .where((u) => u.isNotEmpty)
    .toList();
String get testAccount => testAccounts.isEmpty ? '' : testAccounts.first;
final bool hasCredentials = testAccounts.isNotEmpty && testPassword != '';

/// The login form's account field: Email in workspace mode, else Username.
Symbol get loginAccountFieldKey => workspaceMode ? #loginEmailField : #loginUsernameField;
String get loginAccountLabel => workspaceMode ? 'Email' : 'Username';

/// The account a test signs in with: picked by a stable hash of its name, so a
/// test always uses the same one and the suite spreads evenly over the list.
String accountFor(String testName) {
  if (testAccounts.length < 2) return testAccount;
  final hash = testName.codeUnits.fold<int>(0, (h, c) => (h * 31 + c) & 0x7fffffff);
  return testAccounts[hash % testAccounts.length];
}

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
  Object? tags,
}) {
  patrolTest(description, skip: skip, tags: tags, ($) async {
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
/// ([loginViaForm]). Workspace mode runs the app's own sequence (central
/// `workspace/sign-in` → [WorkspaceSession]); direct mode the old `/login`.
///
/// A tunnel or flaky network occasionally drops a request outright, so a
/// failed attempt is retried up to [_loginAttempts] times before the test fails.
Future<void> loginAsTestUser(PatrolIntegrationTester $) async {
  await initServices();
  final account = accountFor($.tester.testDescription);
  var lastError = '';
  for (var attempt = 1; attempt <= _loginAttempts; attempt++) {
    try {
      await (workspaceMode ? _signInByEmail(account) : _signInByUsername(account));
      break;
    } on TestFailure {
      rethrow;
    } catch (e) {
      lastError = e.toString().replaceFirst('Exception: ', '');
      // Wrong credentials won't fix themselves — and retrying could trip a throttle.
      if (_isRefusal(lastError)) fail('Login rejected ($account): $lastError');
      if (attempt == _loginAttempts) fail('Login failed after $_loginAttempts attempts ($account): $lastError');
      // ignore: avoid_print
      print('loginAsTestUser: attempt $attempt failed ($lastError), retrying');
      // Throttled (5 a minute per address on /login): wait part of it out.
      if (lastError.contains('Too many')) {
        await Future<void>.delayed(const Duration(seconds: 25));
      }
    }
  }
  // Home's skeleton shimmer never settles, so wait for its content instead.
  await $.tester.pumpWidget(const MyApp());
  await $('Start a task').waitUntilVisible(timeout: apiTimeout);
  await $.pumpAndTrySettle();
}

/// Workspace mode: the app's own email sign-in, so the harness and the login
/// screen can never drift apart.
Future<void> _signInByEmail(String email) async {
  final provider = Get.put(WorkspaceProvider());
  var answer = await provider.signIn(email, testPassword);
  if (!answer.isHandoff) {
    final names = answer.tenants.map((t) => t.name).join(', ');
    if (testCompany.isEmpty) {
      fail('$email opens ${answer.tenants.length} companies ($names); pass '
          '--dart-define=TEST_COMPANY=<company> or use an account that belongs to one.');
    }
    final company = answer.tenants.where(_isTestCompany).firstOrNull;
    if (company == null) fail('$email has no company matching TEST_COMPANY=$testCompany ($names).');
    // The chooser's second step: sign in again with the picked company.
    answer = await provider.signIn(email, testPassword, tenantId: company.id);
  }
  await WorkspaceSession().complete(answer);
}

/// The company chooser's tile for TEST_COMPANY, matched on the texts it shows
/// (the company name, and its host — whose first label is `mc` for
/// `mc.mastersystembackend.test`). Fails when TEST_COMPANY is unset or matches none.
Finder _chooserTileForTestCompany() {
  final wanted = testCompany.trim().toLowerCase();
  final shown = <String>[];
  for (var i = 0; find.byKey(Key('loginCompanyChoice_$i')).evaluate().isNotEmpty; i++) {
    final tile = find.byKey(Key('loginCompanyChoice_$i'));
    final texts = [
      for (final e in find.descendant(of: tile, matching: find.byType(Text)).evaluate())
        ((e.widget as Text).data ?? '').trim().toLowerCase(),
    ];
    shown.add(texts.join(' / '));
    if (wanted.isNotEmpty && texts.any((t) => t == wanted || t.split('.').first == wanted)) return tile;
  }
  if (wanted.isEmpty) {
    fail('$testAccount opens the company chooser (${shown.join(', ')}); pass --dart-define=TEST_COMPANY=<company>.');
  }
  fail('No company in the chooser matches TEST_COMPANY=$testCompany (${shown.join(', ')}).');
}

bool _isTestCompany(WorkspaceTenant tenant) {
  final wanted = testCompany.trim().toLowerCase();
  return tenant.id.toLowerCase() == wanted ||
      tenant.host.toLowerCase().split('.').first == wanted ||
      (tenant.apiHost?.toLowerCase().split('.').first ?? '') == wanted ||
      tenant.name.toLowerCase() == wanted;
}

/// Direct mode: the old `POST /login` on the build's one company.
Future<void> _signInByUsername(String username) async {
  final auth = Get.find<AuthService>();
  final data = (await Get.find<ApiProvider>().postMap('/login', {
    'username': username,
    'password': testPassword,
  }))['data'];
  final token = data?['token'] as String?;
  if (token == null || token.isEmpty) fail('Login response has no token');
  // Same session LoginController.authLogin stores.
  await auth.setToken(token);
  auth.setUsername(data['name'] as String?);
  final roles = (data['roles'] as List?)?.map((r) => r['name'] as String);
  if (roles != null && roles.isNotEmpty) auth.setRoles(roles.join(', '));
}

/// The backend's "wrong account or password" answers (direct and workspace).
bool _isRefusal(String error) =>
    error.contains('credentials') || error.contains('incorrect') || error.contains('must be changed');

/// Launches the app and signs in by typing the dart-define credentials into
/// the login form. Retries like [loginAsTestUser] (the "Error!" snackbar shows
/// when the tunnel drops the request).
Future<void> loginViaForm(PatrolIntegrationTester $) async {
  await launchApp($);
  await $(loginAccountFieldKey).enterText(testAccount);
  await $(#loginPasswordField).enterText(testPassword);
  var lastError = '';
  for (var attempt = 1; attempt <= _loginAttempts; attempt++) {
    await $('Sign In').tap(settlePolicy: SettlePolicy.noSettle);
    final end = DateTime.now().add(apiTimeout);
    while (DateTime.now().isBefore(end)) {
      await $.pump(const Duration(milliseconds: 250));
      if ($('Start a task').exists) {
        await $.pumpAndTrySettle();
        return;
      }
      if ($('Error!').exists) break;
      // A multi-company account opens the chooser: pick TEST_COMPANY's tile.
      if (find.byKey(const Key('loginCompanyChoice_0')).evaluate().isNotEmpty) {
        await $.tester.tap(_chooserTileForTestCompany());
        await $.pump(const Duration(milliseconds: 250));
      }
    }
    lastError = errorSnackbarText($) ?? 'no response within ${apiTimeout.inSeconds}s';
    // Wrong credentials won't fix themselves — and retrying could trip a throttle.
    if (_isRefusal(lastError)) fail('Login rejected: $lastError');
    // ignore: avoid_print
    print('loginViaForm: attempt $attempt failed ($lastError), retrying');
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
    print('waitForList: load failed (${errorSnackbarText($) ?? 'no error snackbar'}), '
        'tapping Retry (${retry + 1}/$_listRetries)');
    await $('Retry').tap(settlePolicy: SettlePolicy.noSettle);
  }
  await _waitForListOnce($);
  if ($('Retry').exists) {
    fail('List failed to load (errorRetry state shown): ${errorSnackbarText($) ?? 'no error snackbar'}');
  }
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

/// Opens list cards top-down until [matches] returns true on the opened
/// screen; after each miss, Back must return to [listTitle]. Returns false
/// when none of the first [maxCards] matches.
///
/// Cards are tracked by their texts, not index: the list only builds the cards
/// on screen and reloads from the top after Back, so an index counted once goes
/// stale. All of a card's texts (title, code, date…) identify it, so cards that
/// share a title — work orders named "Phase 1 — work 1" on several projects —
/// are still told apart. The list is scrolled to build the cards not tried yet.
/// A card whose title is in [skipTitles] is never opened.
Future<bool> openFirstCardWhere(
  PatrolIntegrationTester $, {
  required String listTitle,
  required Future<bool> Function() matches,
  int maxCards = 8,
  Set<String> skipTitles = const {},
}) async {
  final tried = <String>{};
  while (tried.length < maxCards) {
    final key = await _nextUntriedCard($, tried, skipTitles);
    if (key == null) return false;
    tried.add(key);

    final card = _builtCardWithKey($, key);
    if (card == null) return false;
    await $.tester.ensureVisible(card);
    await $.tester.tap(card);
    await $.pumpAndTrySettle();
    if (await matches()) return true;

    await $(#appBarBackButton).tap();
    await expectScreen($, listTitle);
    await waitForList($);
  }
  return false;
}

/// The [index]-th built card's identity texts, joined — what tells two cards
/// apart. Only the main column of `orderListCard` (title, subtitle, date)
/// counts: its trailing count / status changes once the test has visited the
/// card, and a changed key would make the card look untried again.
String _cardKey(PatrolIntegrationTester $, int index) {
  final card = listCards().at(index);
  final main = find.descendant(of: card, matching: find.byType(Expanded));
  final scope = main.evaluate().isNotEmpty ? main.first : card;
  return [
    for (final e in find.descendant(of: scope, matching: find.byType(Text)).evaluate())
      (e.widget as Text).data ?? '',
  ].join(' · ');
}

Finder? _builtCardWithKey(PatrolIntegrationTester $, String key) {
  for (var i = 0; i < listCards().evaluate().length; i++) {
    if (_cardKey($, i) == key) return listCards().at(i);
  }
  return null;
}

/// Key ([_cardKey]) of the first built card not in [tried] and not titled in
/// [skipTitles], scrolling the list down to build more; null once a scroll
/// shows nothing new (end of the list).
Future<String?> _nextUntriedCard(PatrolIntegrationTester $, Set<String> tried, Set<String> skipTitles) async {
  List<String> keys() => [for (var i = 0; i < listCards().evaluate().length; i++) _cardKey($, i)];
  bool skipped(int i) => skipTitles.contains(listCardTitle($, i));

  var seen = keys();
  for (var scroll = 0; scroll < 10; scroll++) {
    for (var i = 0; i < seen.length && i < listCards().evaluate().length; i++) {
      if (seen[i].isNotEmpty && !tried.contains(seen[i]) && !skipped(i)) return seen[i];
    }
    if (seen.isEmpty) return null;

    await $.tester.drag(
      find.byWidgetPredicate((w) => w is ScrollView && w.scrollDirection == Axis.vertical).first,
      const Offset(0, -400),
    );
    await $.pumpAndTrySettle();
    // Room for an infinite-scroll page to arrive.
    await $.pump(const Duration(seconds: 1));

    final next = keys();
    if (next.every(seen.contains)) return null;
    seen = next;
  }
  return null;
}

/// Scrolls the screen's vertical list down until [finder] is built, then brings
/// it on screen; returns whether it was found before the list stopped moving. A
/// lazy list only builds the rows near the viewport, so `exists` alone misses a
/// row further down — and a row built in the cache below the viewport can't be tapped.
Future<bool> scrollUntilExists(PatrolIntegrationTester $, PatrolFinder finder, {int maxScrolls = 10}) async {
  // hitTestable: the list on the screen in front, not the one of the route under it.
  final scrollable = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).hitTestable();
  for (var i = 0; i < maxScrolls && !finder.exists; i++) {
    if (scrollable.evaluate().isEmpty) return false;
    final position = $.tester.state<ScrollableState>(scrollable.first).position;
    final before = position.pixels;
    await $.tester.drag(scrollable.first, const Offset(0, -300));
    await $.pumpAndTrySettle();
    if (position.pixels == before) break; // reached the bottom
  }
  if (!finder.exists) return false;
  await $.tester.ensureVisible(finder.first);
  await $.pumpAndTrySettle();
  return true;
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

/// Pumps until [condition] holds; fails with [reason] after [apiTimeout].
Future<void> waitUntilTrue(
  PatrolIntegrationTester $,
  bool Function() condition, {
  required String reason,
}) async {
  final end = DateTime.now().add(apiTimeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out after ${apiTimeout.inSeconds}s: $reason');
    await $.pump(const Duration(milliseconds: 200));
  }
}

/// Fails when [finder] reaches under the system navigation bar. The app runs
/// edge-to-edge, so the Android 3-button bar overlaps anything not inset by
/// SafeArea / MediaQuery padding.
void expectAboveSystemNavBar(PatrolIntegrationTester $, Finder finder) {
  final view = $.tester.view;
  final screenBottom = view.physicalSize.height / view.devicePixelRatio;
  final navBar = view.viewPadding.bottom / view.devicePixelRatio;
  expect(
    $.tester.getRect(finder.first).bottom,
    lessThanOrEqualTo(screenBottom - navBar + 0.5),
    reason: '$finder is covered by the system navigation bar (${navBar.toStringAsFixed(0)} dp)',
  );
}

/// Waits for a screen identified by its AppBar title.
Future<void> expectScreen(PatrolIntegrationTester $, String appBarTitle) =>
    $(appBarTitle).waitUntilVisible(timeout: apiTimeout);
