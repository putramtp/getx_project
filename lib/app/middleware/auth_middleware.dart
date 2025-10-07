import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/modules/services/auth_service.dart';
import 'package:getx_project/app/routes/app_pages.dart';
// Adjust the path to your AuthService based on your project structure

/// Middleware class to handle authentication checks before navigating to a route.
class AuthMiddleware extends GetMiddleware {
  // Inject the AuthService instance
  // This assumes AuthService has been registered via Get.put()
  final AuthService _authService = Get.find<AuthService>();

  // This method is called before anything else.
  // Returning a RouteSettings object redirects the user.
  // Returning null allows navigation to proceed.
  @override
  RouteSettings? redirect(String? route) {
    // Attempt to retrieve the token. 
    // This safely checks the in-memory cache and GetStorage.
    final String? token = _authService.currentToken;
    log("authService.currentToken : $token");

    // Check if the token is null or empty
    if (token == null || token.isEmpty) {
      // User is not logged in. Redirect them to the login page.
      // Note: We use GetX's Routes constant for consistency.
      return const RouteSettings(name: Routes.LOGIN);
    }
    
    // Token is present. Allow navigation to the requested route.
    return null;
  }
}
