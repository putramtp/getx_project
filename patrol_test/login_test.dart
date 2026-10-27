import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';

void main() {
  // clearPackageData (android/app/build.gradle.kts) wipes storage before each
  // test, so the app always starts logged out on the login screen.
  e2eTest('logged-out app opens on the login screen', ($) async {
    await launchApp($);

    expect($('Sign in to continue'), findsOneWidget);
    expect($('Username'), findsOneWidget);
    expect($('Password'), findsOneWidget);
    expect($('Sign In'), findsOneWidget);
  });

  e2eTest(
    'valid credentials sign in and land on home',
    skip: !hasCredentials,
    ($) async {
      await loginViaForm($);

      expect($('Sign in to continue'), findsNothing);
      expect($('Quick Access'), findsOneWidget);
    },
  );

  e2eTest(
    'invalid credentials show an error',
    skip: !hasCredentials,
    ($) async {
      await launchApp($);

      await $(#loginUsernameField).enterText(testUsername);
      await $(#loginPasswordField).enterText('wrong-${uniqueSuffix()}');
      // noSettle: settling would run out the 3s snackbar before we look for it.
      await $('Sign In').tap(settlePolicy: SettlePolicy.noSettle);

      await $('Error!').waitUntilVisible(timeout: apiTimeout);
      expect($('Sign in to continue'), findsOneWidget);
    },
  );
}
