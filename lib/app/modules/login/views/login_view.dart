import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/global/size_config.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
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
                    width: size *22,
                    height: size *17,
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
                          size: size * 2.2,
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
                  height: size * 4.5,
                  width: size *14,
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
                            ?  SizedBox(
                                width:  size * 2.2,
                                height:  size * 2.2,
                                child: const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  strokeWidth: 3.0,
                                ),
                              )
                            :  Text(
                                'Login',
                                style: TextStyle(
                                  color:  Colors.blue[900],
                                  fontSize: size * 2.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      )),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  infoAlertBottom(
                      title:"Forgot Password", "You clicked forgot password");
                },
                child:  Text(
                  'Forgot Password',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: size * 1.5,
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
