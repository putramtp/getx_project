import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/services/auth_service.dart';
import 'package:patrol/patrol.dart';

import 'common/harness.dart';

/// Runs in either mode (the env file decides): workspace builds show the Email
/// field and sign in on the central host; direct builds the Username field.
void main() {
  // clearPackageData (android/app/build.gradle.kts) wipes storage before each
  // test, so the app always starts logged out on the login screen.
  e2eTest('logged-out app opens on the login screen', ($) async {
    await launchApp($);

    expect($('Sign in to continue'), findsOneWidget);
    expect($(loginAccountLabel), findsOneWidget);
    expect($(loginAccountFieldKey), findsOneWidget);
    expect($('Password'), findsOneWidget);
    expect($('Sign In'), findsOneWidget);
  });

  e2eTest('an incomplete form shows field errors without calling the server', ($) async {
    await launchApp($);

    await $('Sign In').tap();
    expect($(workspaceMode ? 'Enter your email.' : 'Enter your username.'), findsOneWidget);
    expect($('Enter your password.'), findsOneWidget);

    await $(loginAccountFieldKey).enterText('ab');
    await $(#loginPasswordField).enterText('123');
    await $('Sign In').tap();
    expect(
      $(workspaceMode ? 'Enter a valid email address.' : 'Username must be at least 3 characters.'),
      findsOneWidget,
    );
    expect($('Password must be at least 6 characters.'), findsOneWidget);
    expect($('Sign in to continue'), findsOneWidget);
  });

  e2eTest('forgot password asks for a valid email', ($) async {
    await launchApp($);

    await $(#loginForgotPasswordButton).tap();
    expect($('Reset password'), findsOneWidget);
    await $(#forgotPasswordEmailField).enterText('not-an-email');
    await $('Send link').tap();
    expect($('Enter a valid email address.'), findsOneWidget);

    await $('Cancel').tap();
    expect($('Reset password'), findsNothing);
  });

  e2eTest(
    'valid credentials sign in and land on home',
    skip: !hasCredentials,
    ($) async {
      await loginViaForm($);

      expect($('Sign in to continue'), findsNothing);
      expect($('Start a task'), findsOneWidget);
      // Workspace mode: the session is on the company the email belongs to.
      if (workspaceMode) {
        final auth = Get.find<AuthService>();
        expect(auth.currentTenantName, isNotEmpty);
        expect(auth.apiBaseUrl, isNot(auth.endpoints.centralApiUrl));
      }
    },
  );

  e2eTest(
    'invalid credentials show an error',
    skip: !hasCredentials,
    ($) async {
      await launchApp($);

      await $(loginAccountFieldKey).enterText(testAccount);
      await $(#loginPasswordField).enterText('wrong-${uniqueSuffix()}');
      // noSettle: settling would run out the 3s snackbar before we look for it.
      await $('Sign In').tap(settlePolicy: SettlePolicy.noSettle);

      await $('Error!').waitUntilVisible(timeout: apiTimeout);
      if (workspaceMode) {
        // Every refusal on the central host is this one sentence.
        expect($('The email or password is incorrect.'), findsOneWidget);
      }
      expect($('Sign in to continue'), findsOneWidget);
    },
  );
}
