import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Center(
                  child: Container(
                    width: 200,
                    height: 150,
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: controller.emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username/Email',
                    hintText: 'Enter valid email Username/Email',
                  ),
                  onChanged: (value) =>
                      controller.emailValue.value = value,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Obx(() => TextField(
                    controller: controller.passwordController,
                    obscureText: !controller.isPasswordVisible.value, // toggle here
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Password',
                      hintText: 'Enter secure password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          controller.isPasswordVisible.value =
                              !controller.isPasswordVisible.value;
                        },
                      ),
                    ),
                    onChanged: (value) {
                      controller.passwordValue.value = value;
                    },
                  )),
            ),

              // ✅ Only Checkbox needs Obx
              Row(
                children: [
                  Obx(() => Checkbox(
                        value: controller.rememberMe.value,
                        onChanged: (val) {
                          controller.rememberMe.value = val ?? false;
                        },
                      )),
                  const Text('Remember me'),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  height: 45,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.blue[200],
                    borderRadius: BorderRadius.circular(20),
                  ),

                  // ✅ Only button uses Obx for loading state
                  child: Obx(() => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.authLogin,
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue),
                                  strokeWidth: 3.0,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 21, 55, 248),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      )),
                ),
              ),

              TextButton(
                onPressed: () {
                  infoAlertBottom(
                      title:"Forgot Password", "You clicked forgot password");
                },
                child: const Text(
                  'Forgot Password',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              // const Padding(
              //   padding: EdgeInsets.only(top: 5),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Text('New User ? '),
              //       Text(
              //         'Create Account',
              //         style: TextStyle(
              //           color: Colors.blue,
              //           decoration: TextDecoration.underline,
              //           decorationColor: Colors.blue,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
