import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/models/workspace_sign_in_model.dart';
import '../../../data/providers/api_providers.dart';
import '../../../data/providers/login_provider.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/workspace_session.dart';
import '../../../routes/app_pages.dart';
import '../views/company_chooser_sheet.dart';
import '../views/forgot_password_dialog.dart';

/// The sign-in form's field errors, mirroring the backend's rules so a
/// request that can only fail is not sent — every attempt counts against the
/// sign-in throttle. [email] is workspace mode (`workspace/sign-in` takes an
/// email); otherwise the old `/login` (username ≥ 3). Password ≥ 6 either way.
/// Null means valid.
({String? username, String? password}) loginFieldErrors(String username, String password, {bool email = false}) => (
      username: username.trim().isEmpty
          ? (email ? 'Enter your email.' : 'Enter your username.')
          : email
              ? (GetUtils.isEmail(username.trim()) ? null : 'Enter a valid email address.')
              : username.trim().length < 3
                  ? 'Username must be at least 3 characters.'
                  : null,
      password: password.isEmpty
          ? 'Enter your password.'
          : password.length < 6
              ? 'Password must be at least 6 characters.'
              : null,
    );


/// One round of the email sign-in: the central answer, plus the signed-in
/// person when it was a handoff that completed.
typedef _WorkspaceRound = ({WorkspaceSignInResult answer, SignedInUser? user, bool passwordChange});

class LoginController extends GetxController {
  /// Email sign-in on the central host (workspace mode), else the old
  /// username/email `POST /login` on the build's one company (direct mode).
  final bool workspaceMode = AppConfig.isWorkspaceMode;

  final LoginProvider _apiLogin = Get.find<LoginProvider>();
  late final WorkspaceProvider _workspace = Get.find<WorkspaceProvider>();
  final AuthService _authService = Get.find<AuthService>();
  final GetStorage _box = GetStorage();

  // Reactive states
  final RxString emailValue = ''.obs;
  final RxString passwordValue = ''.obs;
  final RxBool rememberMe = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isSendingReset = false.obs;
  final RxnString usernameError = RxnString();
  final RxnString passwordError = RxnString();

  // Controllers for text fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadSavedLogin().then((_) => checkAlreadyLoggedIn());
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void onUsernameChanged(String v) {
    emailValue.value = v;
    usernameError.value = null;
  }

  void onPasswordChanged(String v) {
    passwordValue.value = v;
    passwordError.value = null;
  }

  /// Shows the field errors; true when the form may be sent.
  bool validate() {
    final errors = loginFieldErrors(emailValue.value, passwordValue.value, email: workspaceMode);
    usernameError.value = errors.username;
    passwordError.value = errors.password;
    return errors.username == null && errors.password == null;
  }

  /// ✅ Load saved login if "remember me" was checked.
  /// Only the email is prefilled — the password is never persisted. A returning
  /// user stays signed in via the stored token (auto-login), and otherwise
  /// re-enters their password.
  Future<void> loadSavedLogin() async {
    // Purge any password left over from a previous (insecure) build.
    _box.remove('saved_password');

    final savedRemember = _box.read('remember_me') ?? false;
    final savedEmail = _box.read('saved_email') ?? '';

    rememberMe.value = savedRemember;

    if (savedRemember) {
      emailController.text = savedEmail;
      emailValue.value = savedEmail;
    } else {
      emailController.clear();
      passwordController.clear();
    }
  }

  /// ✅ Save or clear the remembered email based on the rememberMe checkbox.
  /// The password is intentionally never written to storage.
  Future<void> saveLogin() async {
    if (rememberMe.value) {
      _box.write('saved_email', emailValue.value.trim());
      _box.write('remember_me', true);
    } else {
      _box.remove('saved_email');
      _box.write('remember_me', false);
    }
  }

  /// ✅ Check if already logged in
    Future<void> checkAlreadyLoggedIn() async {
      final token = _authService.getToken(); // or read from storage if you use GetStorage
      if (token != null && token.isNotEmpty) {
        Get.offAllNamed(Routes.HOME);
      } 
    }

  /// ✅ Login API call
  Future<void> authLogin() async {
    if (isLoading.value || !validate()) return;
    if (workspaceMode) return _workspaceLogin();
    // Use ApiExecutor to handle loading + network automatically
    final response = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => _apiLogin.login(emailValue.value.trim(), passwordValue.value),
    );

    if (response == null) return;

    final data = response['data'];
    final token = data?['token'];
    final username = data?['name'];
    final roles = data?['roles'];

    if (token == null || token.isEmpty) {
      errorAlert("Login successful, but token is missing.");
      return;
    }

    // Still on the password mailed at activation: every other call would
    // answer 403, and the app has no change-password screen. End the new
    // session on the server and stay here.
    if (data?['must_change_password'] == true) {
      unawaited(_apiLogin.revokeToken(token));
      warningAlertBottom(ApiProvider.passwordChangeNotice, title: 'Change your password');
      return;
    }

    await saveLogin();

    await _authService.setToken(token);
    _authService.setUsername(username);
    if (roles != null && roles.isNotEmpty) {
      final List<String> roleNames = (roles as List).map((role) => role['name'] as String).toList();
      _authService.setRoles(roleNames.join(', '));
    }

    successAlert("Success Login as ${username ?? 'User'}");
    Get.offAllNamed(Routes.HOME);
  }

  /// Email sign-in (workspace mode): `workspace/sign-in` on the central host,
  /// then — on a handoff — [WorkspaceSession] opens the session on the
  /// company's own host. Both run in one [ApiExecutor] call so the button
  /// stays disabled throughout. A `choose` answer (the password opens several
  /// companies) asks which one, then signs in again with its id.
  ///
  /// `sessionBound: false`: the sign-in changes the session on purpose, and
  /// its failure (an expired link, a refused account) must still be shown.
  Future<void> _workspaceLogin({String? tenantId}) async {
    final email = emailValue.value.trim();
    final round = await ApiExecutor.run<_WorkspaceRound>(
      isLoading: isLoading,
      sessionBound: false,
      task: () async {
        final answer = await _workspace.signIn(email, passwordValue.value, tenantId: tenantId);
        if (!answer.isHandoff) return (answer: answer, user: null, passwordChange: false);
        try {
          return (answer: answer, user: await WorkspaceSession().complete(answer), passwordChange: false);
        } on PasswordChangeRequiredException {
          return (answer: answer, user: null, passwordChange: true);
        }
      },
    );
    if (round == null) return;

    if (round.passwordChange) {
      warningAlertBottom(ApiProvider.passwordChangeNotice, title: 'Change your password');
      return;
    }
    if (round.answer.isChoose) {
      final picked = await showCompanyChooser(round.answer.tenants);
      if (picked != null) await _workspaceLogin(tenantId: picked.id);
      return;
    }

    await saveLogin();
    final company = _authService.currentTenantName;
    successAlert("Signed in to ${company ?? 'your company'} as ${round.user?.name ?? 'User'}");
    Get.offAllNamed(Routes.HOME);
  }

  /// "Forgot Password?": asks for the email and has the backend mail a reset
  /// link (the new password is set on the web), then the user signs in here.
  /// Workspace mode mails every company that has the email.
  Future<void> forgotPassword() async {
    final typed = emailValue.value.trim();
    final email = await Get.dialog<String>(
      ForgotPasswordDialog(initialEmail: GetUtils.isEmail(typed) ? typed : ''),
    );
    if (email == null) return;

    if (workspaceMode) {
      final message = await ApiExecutor.run(isLoading: isSendingReset, task: () => _workspace.forgotPassword(email));
      if (message == null) return;
      successAlertBottom('$message Set a new password from the link, then sign in here.', title: 'Check your email');
      return;
    }

    final sent = await ApiExecutor.run(
      isLoading: isSendingReset,
      task: () => _apiLogin.sendResetEmail(email),
    );
    if (sent == null) return;
    successAlertBottom(
      'If an account uses $email, a reset link is on its way. '
      'Set a new password from the link, then sign in here.',
      title: 'Check your email',
    );
  }
}
