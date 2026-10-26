import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/main.dart';
import 'package:patrol/patrol.dart';

/// Real-backend credentials, passed at run time so they never live in the repo:
///   patrol test -t patrol_test/login_test.dart \
///     --dart-define=TEST_USERNAME=... --dart-define=TEST_PASSWORD=...
const _username = String.fromEnvironment('TEST_USERNAME');
const _password = String.fromEnvironment('TEST_PASSWORD');

Future<void> _launchApp(PatrolIntegrationTester $) async {
  await initServices();
  await $.pumpWidgetAndSettle(const MyApp());
}

void main() {
  // clearPackageData (android/app/build.gradle.kts) wipes storage before each
  // test, so the app always starts logged out on the login screen.
  patrolTest('logged-out app opens on the login screen', ($) async {
    await _launchApp($);

    expect($('Sign in to continue'), findsOneWidget);
    expect($('Username'), findsOneWidget);
    expect($('Password'), findsOneWidget);
    expect($('Sign In'), findsOneWidget);
  });

  patrolTest(
    'valid credentials sign in and land on home',
    skip: _username.isEmpty || _password.isEmpty,
    ($) async {
      await _launchApp($);

      await $(#loginUsernameField).enterText(_username);
      await $(#loginPasswordField).enterText(_password);
      await $('Sign In').tap();

      // Matches AppConfig.apiTimeoutSeconds: a login over the ngrok tunnel can
      // take ~13s, so a shorter wait flakes before the request itself times out.
      await $('Quick Access').waitUntilVisible(timeout: const Duration(seconds: 30));
      expect($('Sign in to continue'), findsNothing);
    },
  );
}
