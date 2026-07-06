import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

import '../../../global/alert.dart';
import '../../../helpers/api_excecutor.dart';
import '../../../data/providers/login_provider.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_pages.dart';


class LoginController extends GetxController {
  final LoginProvider _apiLogin = Get.find<LoginProvider>();
  final AuthService _authService = Get.find<AuthService>();
  final GetStorage _box = GetStorage();

  // Reactive states
  final RxString emailValue = ''.obs;
  final RxString passwordValue = ''.obs;
  final RxBool rememberMe = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;

  // Controllers for text fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadSavedLogin().then((_) => checkAlreadyLoggedIn());
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
      _box.write('saved_email', emailValue.value);
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
    // Use ApiExecutor to handle loading + network automatically
    final response = await ApiExecutor.run(
      isLoading: isLoading,
      task: () => _apiLogin.login(emailValue.value, passwordValue.value),
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
}
