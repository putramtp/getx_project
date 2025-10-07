import 'dart:developer'; 
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; 

/// A GetxService responsible for managing the user's authentication token and state.
class AuthService extends GetxService {
  // Use GetStorage for persistent storage
  final GetStorage _storage = GetStorage();
  final String _tokenKey = 'auth_token';
  final String _usernameKey = 'username_key';
  
  // FIXED: Use reactive variables (RxnString) for observable state.
  // This replaces the plain String? variables and enables reactivity.
  final RxnString token = RxnString(null); 
  final RxnString username = RxnString(null); 

  @override
  void onInit() {
    super.onInit();
    
    // 1. Load token and username from storage into the reactive variables on service startup.
    // This happens only on Hot Restart (full app start), maintaining state otherwise.
    token.value = _storage.read<String>(_tokenKey); 
    username.value = _storage.read<String>(_usernameKey);

    if (token.value != null) {
      log('AuthService initialized. Token loaded from storage: ${token.value}'); 
    }
  }

  /// Sets the received token, saves it to storage, and updates the reactive state.
  void setToken(String newToken) {
    token.value = newToken; // Update reactive state
    _storage.write(_tokenKey, newToken); // Save token to persistent storage
    // log('Auth token set and persisted successfully: ${token.value}'); 
  }

  /// Sets the username, saves it to storage, and updates the reactive state.
  void setUsername(String? newUsername) {
    username.value = newUsername; // Update reactive state
    _storage.write(_usernameKey, newUsername); // Save username to persistent storage
    // log('Auth username set and persisted successfully: ${username.value}');
  }
  
  /// Clears the token (used during logout) from memory and storage.
  void clearToken() {
    token.value = null; // Clear reactive state
    username.value = null; // Clear reactive state
    
    _storage.remove(_tokenKey); // Remove token from persistent storage
    _storage.remove(_usernameKey); // Remove username from persistent storage
    
    log('Auth credentials cleared from memory and storage.'); 
  }

  // Helper getters for convenience (reading the reactive value)
  // Use these in your UI like: Get.find<AuthService>().currentToken
  String? get currentToken => token.value;
  String? get currentUsername => username.value;
}
