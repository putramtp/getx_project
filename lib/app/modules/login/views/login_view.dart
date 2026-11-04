import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/app_buttons.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  static const _background = [navyDark, navyMid, navyLight];

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: _background,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: size * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: size * 2),
                  _logo(size),
                  SizedBox(height: size * 3),
                  Text(
                    'Warehouse App',
                    style: AppTextStyle.custom(size, scale: 3, color: Colors.white, weight: FontWeight.bold, letterSpacing: 1),
                  ),
                  SizedBox(height: size * 0.6),
                  Text(
                    'Sign in to continue',
                    style: AppTextStyle.custom(size, scale: 1.4, color: Colors.white70),
                  ),
                  SizedBox(height: size * 3.5),
                  _formCard(size),
                  SizedBox(height: size * 2),
                  _forgotPassword(size),
                  SizedBox(height: size * 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo(double size) {
    final radius = BorderRadius.circular(size * 2);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: Colors.white.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset('assets/images/logo_short.png', width: size * 10, fit: BoxFit.fitWidth),
      ),
    );
  }

  Widget _formCard(double size) {
    final email = controller.workspaceMode;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      padding: EdgeInsets.all(size * 2.5),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workspace mode signs in by email (the central host finds the
            // company); direct mode keeps the old username/email field.
            _fieldLabel(size, email ? 'Email' : 'Username'),
            Obx(() => TextField(
                  key: Key(email ? 'loginEmailField' : 'loginUsernameField'),
                  controller: controller.emailController,
                  keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: [email ? AutofillHints.email : AutofillHints.username],
                  onChanged: controller.onUsernameChanged,
                  style: AppTextStyle.custom(size, scale: 1.5),
                  decoration: _fieldDecoration(
                    size,
                    hint: email ? 'you@company.com' : 'Enter your username',
                    icon: email ? Icons.mail_outline_rounded : Icons.person_outline_rounded,
                    error: controller.usernameError.value,
                  ),
                )),
            SizedBox(height: size * 2),
            _fieldLabel(size, 'Password'),
            Obx(() => TextField(
                  key: const Key('loginPasswordField'),
                  controller: controller.passwordController,
                  obscureText: !controller.isPasswordVisible.value,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onChanged: controller.onPasswordChanged,
                  onSubmitted: (_) => controller.authLogin(),
                  style: AppTextStyle.custom(size, scale: 1.5),
                  decoration: _fieldDecoration(
                    size,
                    hint: 'Enter your password',
                    icon: Icons.lock_outline_rounded,
                    error: controller.passwordError.value,
                    suffix: IconButton(
                      icon: Icon(
                        controller.isPasswordVisible.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey.shade500,
                        size: size * 2.2,
                      ),
                      onPressed: () => controller.isPasswordVisible.value = !controller.isPasswordVisible.value,
                    ),
                  ),
                )),
            SizedBox(height: size * 1.2),
            _rememberMe(size),
            SizedBox(height: size * 2.5),
            Obx(() => navyButton(
                  size,
                  'Sign In',
                  loading: controller.isLoading.value,
                  onPressed: controller.authLogin,
                )),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(double size, String text) => Padding(
        padding: EdgeInsets.only(bottom: size * 0.8),
        child: Text(text, style: AppTextStyle.custom(size, scale: 1.4, weight: FontWeight.w600, color: navyDark)),
      );

  InputDecoration _fieldDecoration(
    double size, {
    required String hint,
    required IconData icon,
    String? error,
    Widget? suffix,
  }) {
    final radius = BorderRadius.circular(size * 1.2);
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyle.custom(size, scale: 1.4, color: Colors.grey.shade400),
      errorText: error,
      prefixIcon: Icon(icon, color: navyMid, size: size * 2.2),
      suffixIcon: suffix,
      filled: true,
      fillColor: pageBackground,
      contentPadding: EdgeInsets.symmetric(vertical: size * 1.5, horizontal: size * 1.5),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: navyMid, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: stockOutColor)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: stockOutColor, width: 1.5)),
    );
  }

  Widget _rememberMe(double size) => Obx(() => Row(
        children: [
          SizedBox(
            width: size * 2.4,
            height: size * 2.4,
            child: Checkbox(
              value: controller.rememberMe.value,
              onChanged: (val) => controller.rememberMe.value = val ?? false,
              activeColor: navyMid,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          SizedBox(width: size * 0.6),
          Text('Remember me', style: AppTextStyle.custom(size, scale: 1.35, color: Colors.grey.shade700)),
        ],
      ));

  Widget _forgotPassword(double size) => Obx(() => TextButton(
        key: const Key('loginForgotPasswordButton'),
        onPressed: controller.isSendingReset.value ? null : controller.forgotPassword,
        child: Text(
          'Forgot Password?',
          style: AppTextStyle.custom(size, scale: 1.4, color: Colors.white70)
              .copyWith(decoration: TextDecoration.underline, decorationColor: Colors.white54),
        ),
      ));
}
