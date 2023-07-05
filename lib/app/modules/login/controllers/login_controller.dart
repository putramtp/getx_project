import 'dart:developer';

import 'package:get/get.dart';

import '../../../../global/alert.dart';
import '../providers/login_provider.dart';

class LoginController extends GetxController {
  final LoginProvider _apiLogin = LoginProvider();
  final RxString emailValue = ''.obs;
  final RxString passwordValue = ''.obs;
  // @override
  // void onInit() {
  //   super.onInit();
  // }

  // @override
  // void onReady() {
  //   super.onReady();
  // }

  // @override
  // void onClose() {
  //   super.onClose();
  // }

  void authLogin() async {
   final response =  await  _apiLogin.login(emailValue.value, passwordValue.value);
    if (response.statusCode == 200) {
      const String successMessage = "Success Login";
      successAlert(successMessage);
    } else {
      final String errorMessage = response.body['message'];
      errorAlert(errorMessage);
    }
   log(response.body.toString());
   
  }



}
