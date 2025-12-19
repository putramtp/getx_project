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

  /// ✅ Load saved login if "remember me" was checked
  Future<void> loadSavedLogin() async {

    final savedRemember = _box.read('remember_me') ?? false;
    final savedEmail = _box.read('saved_email') ?? '';
    final savedPassword = _box.read('saved_password') ?? '';

    rememberMe.value = savedRemember;

    if (savedRemember) {
      emailController.text = savedEmail;
      passwordController.text = savedPassword;
      emailValue.value = savedEmail;
      passwordValue.value = savedPassword;
    } else {
      emailController.clear();
      passwordController.clear();
    }
  }

  /// ✅ Save or clear login based on rememberMe checkbox
  Future<void> saveLogin() async {
    if (rememberMe.value) {
      _box.write('saved_email', emailValue.value);
      _box.write('saved_password', passwordValue.value);
      _box.write('remember_me', true);
    } else {
      _box.remove('saved_email');
      _box.remove('saved_password');
      _box.write('remember_me',false);
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

    // If response is null → network failed or exception handled
    if (response == null) return;

    try {
      // Check status code and body
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'];
        final token = data?['token'];
        final username = data?['name'];
        final roles = data?['roles'];

        if (token != null && token.isNotEmpty) {
          // ✅ Save email/password if remember me is checked
          await saveLogin();

          // ✅ Save auth data in AuthService
          _authService.setToken(token);
          _authService.setUsername(username);
          _authService.setRoles(
              (roles != null && roles.isNotEmpty) ? roles.join(', ') : '-');

          // ✅ Success alert
          successAlert("Success Login as ${username ?? 'User'}");

          // ✅ Navigate to HOME
          Get.offAllNamed(Routes.HOME);
        } else {
          errorAlert("Login successful, but token is missing.");
        }
      } else {
        final msg = response.body?['message'] ?? "Login failed. Please check your credentials.";
        errorAlert(msg);
      }
    } catch (e) {
      errorAlert("Unexpected error during login: $e");
    }
  }
}
