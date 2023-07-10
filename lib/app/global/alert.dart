import 'package:flutter/material.dart';
import 'package:get/get.dart';

errorAlert(String message) {
  Get.snackbar(
    '',
    message,
    titleText: const Text("Error!",style: TextStyle(fontSize:14,fontWeight: FontWeight.bold,letterSpacing: 2),),
    colorText: Colors.red,
    icon: const Icon(Icons.error),
  );
}

successAlert(String message) {
  Get.snackbar(
    '',
    message,
    titleText: const Text("Success! ",style: TextStyle(fontSize:14,fontWeight: FontWeight.bold,letterSpacing: 2),),
    colorText: Colors.green,
    icon: const Icon(Icons.check_circle_rounded,color: Colors.green,),
  );
}
