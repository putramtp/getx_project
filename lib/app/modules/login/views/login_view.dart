import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global/size_config.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff1C3A5E), Color(0xff2D6187), Color(0xff4A7FB5)],
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

                  // Logo
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size * 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 186, 189, 199).withOpacity(0.22),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(size * 2),
                      child: Image.asset(
                        'assets/images/logo_short.png',
                        width: size * 10,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),

                  SizedBox(height: size * 3),

                  // Title
                  Text(
                    'Warehouse App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 3,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: size * 0.6),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: size * 1.4,
                    ),
                  ),

                  SizedBox(height: size * 3.5),

                  // Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(size * 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(size * 2.5),
                    child: AutofillGroup(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username field
                        Text(
                          'Username',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: size * 1.4,
                            color: const Color(0xff1C3A5E),
                          ),
                        ),
                        SizedBox(height: size * 0.8),
                        TextField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.text,
                          autofillHints: const [AutofillHints.username],
                          onChanged: (v) => controller.emailValue.value = v,
                          style: TextStyle(fontSize: size * 1.5),
                          decoration: InputDecoration(
                            hintText: 'Enter your username',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: size * 1.4),
                            prefixIcon: Icon(Icons.person_outline_rounded,
                                color: const Color(0xff2D6187), size: size * 2.2),
                            filled: true,
                            fillColor: const Color(0xffF4F7FC),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: size * 1.5, horizontal: size * 1.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(size * 1.2),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(size * 1.2),
                              borderSide: const BorderSide(color: Color(0xff2D6187), width: 1.5),
                            ),
                          ),
                        ),

                        SizedBox(height: size * 2),

                        // Password field
                        Text(
                          'Password',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: size * 1.4,
                            color: const Color(0xff1C3A5E),
                          ),
                        ),
                        SizedBox(height: size * 0.8),
                        Obx(() => TextField(
                              controller: controller.passwordController,
                              obscureText: !controller.isPasswordVisible.value,
                              autofillHints: const [AutofillHints.password],
                              onChanged: (v) => controller.passwordValue.value = v,
                              style: TextStyle(fontSize: size * 1.5),
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: size * 1.4),
                                prefixIcon: Icon(Icons.lock_outline_rounded,
                                    color: const Color(0xff2D6187), size: size * 2.2),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    controller.isPasswordVisible.value
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.grey.shade500,
                                    size: size * 2.2,
                                  ),
                                  onPressed: () => controller.isPasswordVisible.value =
                                      !controller.isPasswordVisible.value,
                                ),
                                filled: true,
                                fillColor: const Color(0xffF4F7FC),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: size * 1.5, horizontal: size * 1.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(size * 1.2),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(size * 1.2),
                                  borderSide: const BorderSide(color: Color(0xff2D6187), width: 1.5),
                                ),
                              ),
                            )),

                        SizedBox(height: size * 1.2),

                        // Remember me
                        Obx(() => Row(
                              children: [
                                SizedBox(
                                  width: size * 2.4,
                                  height: size * 2.4,
                                  child: Checkbox(
                                    value: controller.rememberMe.value,
                                    onChanged: (val) => controller.rememberMe.value = val ?? false,
                                    activeColor: const Color(0xff2D6187),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                SizedBox(width: size * 0.6),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    fontSize: size * 1.35,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            )),

                        SizedBox(height: size * 2.5),

                        // Login button
                        Obx(() => SizedBox(
                              width: double.infinity,
                              height: size * 5,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value ? null : controller.authLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff2D6187),
                                  disabledBackgroundColor: const Color(0xff2D6187).withOpacity(0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(size * 1.2),
                                  ),
                                  elevation: 3,
                                ),
                                child: controller.isLoading.value
                                    ? SizedBox(
                                        width: size * 2.2,
                                        height: size * 2.2,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: size * 1.8,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            )),
                      ],
                    ),
                    ),
                  ),

                  SizedBox(height: size * 2),

                  // Forgot password
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: size * 1.4,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white54,
                      ),
                    ),
                  ),

                  SizedBox(height: size * 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
