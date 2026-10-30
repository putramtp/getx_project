import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// A GetxService responsible for managing the user's authentication token and state.
///
/// The bearer token is the one sensitive value here, so it is kept in
/// [FlutterSecureStorage] (Keychain / Keystore) rather than the unencrypted
/// `get_storage` box. Non-secret profile data (username, roles) stays
/// in `get_storage`. In-memory reactive fields act as the synchronous source of
/// truth that the request modifier and route middleware read.
class AuthService extends GetxService {
  // Persistent local storage
  final GetStorage _box = GetStorage();
  // flutter_secure_storage v10 migrates tokens saved by the old
  // EncryptedSharedPreferences backend on first access (migrateOnAlgorithmChange
  // defaults to true). Keep v10 shipped before moving to v11, which can't read
  // the old backend.
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'username_key';
  static const String _rolesKey = 'roles_key';
  // Older builds cached the user id for a delivery's `updated_by`; the backend
  // now takes it from the token, so the stored copy is only cleaned up.
  static const String _legacyUserIdKey = 'user_id_key';

  // Reactive variables for reactivity
  final RxnString token = RxnString(null);
  final RxnString username = RxnString(null);
  final RxnString roles = RxnString(null);

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
    await _box.remove(_legacyUserIdKey);
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

  /// Clear all credentials (used on logout / session expiry).
  Future<void> clearToken() async {
    token.value = null;
    username.value = null;
    roles.value = null;

    await _secure.delete(key: _tokenKey);
    _box.remove(_usernameKey);
    _box.remove(_rolesKey);
  }

  /// Convenience getters
  String? get currentToken => token.value;
  String? get currentUsername => username.value;
  String? get currentUserRoles => roles.value;
}
