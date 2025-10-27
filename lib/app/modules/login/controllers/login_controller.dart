import 'dart:developer';
import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/modules/login/providers/login_provider.dart';
import 'package:getx_project/app/modules/services/auth_service.dart';
import 'package:getx_project/app/routes/app_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LoginController extends GetxController {
  final LoginProvider _apiLogin = Get.find<LoginProvider>();
  final AuthService _authService = Get.find<AuthService>();

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
    final prefs = await SharedPreferences.getInstance();

    final savedRemember = prefs.getBool('remember_me') ?? false;
    final savedEmail = prefs.getString('saved_email') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';

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
    final prefs = await SharedPreferences.getInstance();

    if (rememberMe.value) {
      await prefs.setString('saved_email', emailValue.value);
      await prefs.setString('saved_password', passwordValue.value);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  /// ✅ Check if already logged in
    Future<void> checkAlreadyLoggedIn() async {
      final token = _authService.getToken(); // or read from storage if you use GetStorage
      if (token != null && token.isNotEmpty) {
        log("🔑 User already logged in with token: $token");
        Get.offAllNamed(Routes.HOME);
      } else {
        log("ℹ️ No active session found, stay on login page.");
      }
    }

  /// ✅ Login API call
  Future<void> authLogin() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      final response = await _apiLogin.login(
        emailValue.value,
        passwordValue.value,
      );
      // log("Login API Response: ${response.body}", name: "LoginController");
      // log("Status Code: ${response.statusCode}", name: "LoginController");
      // log("Status Text: ${response.statusText}", name: "LoginController");
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'];
        final token = data?['token'];
        final username = data?['name'];
        final roles = data?['roles'];

        if (token != null && token.isNotEmpty) {
          await saveLogin(); // <- ✅ Save email/password if rememberMe is checked
          _authService.setToken(token);
          _authService.setUsername(username);
          var rawRoles = (roles.isNotEmpty) ? roles.join(', ') : '-';
          _authService.setRoles(rawRoles);
          successAlert("Success Login as ${username ?? 'User'}");
          Get.offAllNamed(Routes.HOME);
        } else {
          errorAlert("Login successful, but token missing.");
        }
      } else {
        final msg = response.body?['message'] ?? "Login failed. Please check your credentials.";
        errorAlert(msg);
      }
    } catch (e) {
      log("Login Error: $e");
      errorAlert("Unexpected error during login.");
    } finally {
      isLoading.value = false;
    }
  }
}
