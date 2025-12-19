import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; 

/// A GetxService responsible for managing the user's authentication token and state.
class AuthService extends GetxService {
  // Persistent local storage
  final GetStorage _box = GetStorage();

  // Storage keys
  final String _tokenKey = 'auth_token';
  final String _usernameKey = 'username_key';
  final String _rolesKey = 'roles_key'; 

  // Reactive variables for reactivity
  final RxnString token = RxnString(null); 
  final RxnString username = RxnString(null); 
  final RxnString roles = RxnString(null); 

  @override
  void onInit() {
    super.onInit();

    // Load saved credentials on startup
    token.value = _box.read<String>(_tokenKey); 
    username.value = _box.read<String>(_usernameKey);
    roles.value = _box.read<String>(_rolesKey);

    // if (token.value != null) {
    //   log('✅ AuthService initialized. Token loaded: ${token.value}');
    // } else {
    //   log('ℹ️ AuthService initialized with no stored token.');
    // }
  }

  /// ✅ Public getter to retrieve current token directly
  String? getToken() {
    return token.value ?? _box.read<String>(_tokenKey);
  }

  /// Save token to memory and storage
  void setToken(String newToken) {
    token.value = newToken;
    _box.write(_tokenKey, newToken); //Token saved
  }

  /// Save username to memory and storage
  void setUsername(String? newUsername) {
    username.value = newUsername;
    _box.write(_usernameKey, newUsername);
  }

  /// Save roles to memory and storage
  void setRoles(String? newRoles) {
    roles.value = newRoles;
    _box.write(_rolesKey, newRoles);
  }
  
  /// Clear all credentials (used on logout)
  void clearToken() {
    token.value = null;
    username.value = null;
    roles.value = null;

    _box.remove(_tokenKey);
    _box.remove(_usernameKey);
    _box.remove(_rolesKey);

    // log('🚪 Auth credentials cleared.');
  }

  /// Convenience getters
  String? get currentToken => token.value;
  String? get currentUsername => username.value;
  String? get currentUserRoles => roles.value;
}
