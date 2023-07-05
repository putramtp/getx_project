import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Login Page"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Center(
                child: Container(
                    width: 200,
                    height: 150,
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Image.asset('assets/images/logo.png')),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                    hintText: 'Enter valid email as example@gmail.com'),
                onChanged: (value) {
                  controller.emailValue.value = value;
                  // controller.emailValue.value = "kminchelle";

                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                obscureText: true,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    hintText: 'Enter secure password'),
                onChanged: (value) {
                  // controller.passwordValue.value = value;
                  controller.passwordValue.value = "0lelplR";
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                controller.authLogin();
              },
              child: const Text(
                'Forgot Password',
                style: TextStyle(color: Colors.blue, fontSize: 15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                height: 50,
                width: 250,
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20)),
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed("/list-view");
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(
                        color: Color.fromARGB(255, 61, 27, 211), fontSize: 25),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New User ? '),
                  Text('Create Account',
                      style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
