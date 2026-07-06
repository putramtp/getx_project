import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// A GetxService responsible for managing the user's authentication token and state.
///
/// The bearer token is the one sensitive value here, so it is kept in
/// [FlutterSecureStorage] (Keychain / Keystore) rather than the unencrypted
/// `get_storage` box. Non-secret profile data (username, roles, user id) stays
/// in `get_storage`. In-memory reactive fields act as the synchronous source of
/// truth that the request modifier and route middleware read.
class AuthService extends GetxService {
  // Persistent local storage
  final GetStorage _box = GetStorage();
  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'username_key';
  static const String _rolesKey = 'roles_key';
  static const String _userIdKey = 'user_id_key';

  // Reactive variables for reactivity
  final RxnString token = RxnString(null);
  final RxnString username = RxnString(null);
  final RxnString roles = RxnString(null);

  /// Authenticated user's id. The /login response doesn't include it, so it is
  /// resolved lazily from /user/currentDetail when first needed (e.g. as the
  /// `updated_by` field when updating a delivery).
  final RxnInt userId = RxnInt(null);

  /// Loads persisted credentials into memory. Must complete before the app
  /// reads [currentToken] (registered via `Get.putAsync` in main()).
  Future<AuthService> init() async {
    // One-time migration: an older build stored the token in plaintext
    // get_storage. If we find it there, move it into secure storage so users
    // aren't forced to log in again, then wipe the plaintext copy.
    final legacyToken = _box.read<String>(_tokenKey);
    String? storedToken = await _secure.read(key: _tokenKey);
    if (storedToken == null && legacyToken != null && legacyToken.isNotEmpty) {
      await _secure.write(key: _tokenKey, value: legacyToken);
      storedToken = legacyToken;
    }
    if (legacyToken != null) {
      await _box.remove(_tokenKey);
    }

    token.value = storedToken;
    username.value = _box.read<String>(_usernameKey);
    roles.value = _box.read<String>(_rolesKey);
    userId.value = _box.read<int>(_userIdKey);
    return this;
  }

  /// Public getter to retrieve current token directly (from memory).
  String? getToken() => token.value;

  /// Save token to memory and secure storage.
  Future<void> setToken(String newToken) async {
    token.value = newToken;
    await _secure.write(key: _tokenKey, value: newToken);
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

  /// Save the authenticated user's id to memory and storage
  void setUserId(int? newUserId) {
    userId.value = newUserId;
    if (newUserId == null) {
      _box.remove(_userIdKey);
    } else {
      _box.write(_userIdKey, newUserId);
    }
  }

  /// Clear all credentials (used on logout / session expiry).
  Future<void> clearToken() async {
    token.value = null;
    username.value = null;
    roles.value = null;
    userId.value = null;

    await _secure.delete(key: _tokenKey);
    _box.remove(_usernameKey);
    _box.remove(_rolesKey);
    _box.remove(_userIdKey);
  }

  /// Convenience getters
  String? get currentToken => token.value;
  String? get currentUsername => username.value;
  String? get currentUserRoles => roles.value;
  int? get currentUserId => userId.value;
}
