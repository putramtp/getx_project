import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';

errorAlert(String message) {
  Get.snackbar(
    '',
    message,
    titleText: Text("Error!",style: AppTextStyle.custom(SizeConfig.defaultSize, px: 14, weight: FontWeight.bold, letterSpacing: 2),),
    colorText: Colors.red,
    icon: const Icon(Icons.error),
  );
}

successAlert(String message) {
  Get.snackbar(
    '',
    message,
    titleText: Text("Success! ",style: AppTextStyle.custom(SizeConfig.defaultSize, px: 14, weight: FontWeight.bold, letterSpacing: 2),),
    colorText: Colors.white,
    icon: const Icon(Icons.check_circle_rounded,color: Colors.green,),
  );
}

successAlertBottom(String messageText ,{String? title}) {
   final String titleText = title ?? "Success";
   Get.snackbar(
      titleText,
      messageText,
      backgroundColor: Colors.green.shade50,
      colorText: Colors.green,
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
    );
}

errorAlertBottom(String messageText ,{String? title}) {
   final String titleText = title ?? "Error";
   Get.snackbar(
      titleText,
      messageText,
      backgroundColor: Colors.red.shade50,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
    );
}

warningAlertBottom(String messageText ,{String? title}) {
   final String titleText = title ?? "Warning";
   Get.snackbar(
    titleText,
    messageText,
    backgroundColor: Colors.orange.shade50,
    colorText: Colors.orange.shade800,
    snackPosition: SnackPosition.BOTTOM,
    icon: const Icon(Icons.error_outline, color: Colors.orange),
  );
}

infoAlertBottom(String messageText ,{String? title}) {
   final String titleText = title ?? "";
   Get.snackbar(
    titleText,
    messageText,
    backgroundColor:  Colors.grey.shade50,
    colorText: Colors.black,
    snackPosition: SnackPosition.BOTTOM,
    icon: const Icon(Icons.info_outline, color: Colors.grey),
  );
}
