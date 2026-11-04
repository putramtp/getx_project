import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'api_endpoints.dart';

/// A GetxService responsible for managing the user's authentication token and state.
///
/// The bearer token is the one sensitive value here, so it is kept in
/// [FlutterSecureStorage] (Keychain / Keystore) rather than the unencrypted
/// `get_storage` box. Non-secret profile data (username, roles) and the
/// signed-in company (id, name, API host — workspace mode) stay in
/// `get_storage`. In-memory reactive fields act as the synchronous source of
/// truth that the request modifier and route middleware read.
class AuthService extends GetxService {
  AuthService({ApiEndpoints? endpoints}) : endpoints = endpoints ?? ApiEndpoints.fromConfig();

  /// Where this build's API lives; [apiBaseUrl] resolves the session's host.
  final ApiEndpoints endpoints;

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
  // The signed-in company (workspace mode): its API host is where every
  // request of the session goes.
  static const String _tenantIdKey = 'tenant_id_key';
  static const String _tenantNameKey = 'tenant_name_key';
  static const String _tenantApiHostKey = 'tenant_api_host_key';
  // Older builds cached the user id for a delivery's `updated_by`; the backend
  // now takes it from the token, so the stored copy is only cleaned up.
  static const String _legacyUserIdKey = 'user_id_key';

  // Reactive variables for reactivity
  final RxnString token = RxnString(null);
  final RxnString username = RxnString(null);
  final RxnString roles = RxnString(null);
  final RxnString tenantId = RxnString(null);
  final RxnString tenantName = RxnString(null);
  final RxnString tenantApiHost = RxnString(null);

  /// Bumped on every sign-in and sign-out. A request that started under an
  /// older session belongs to a user who is gone: [ApiExecutor] drops its
  /// error instead of showing it on the login screen.
  int _session = 0;
  int get session => _session;

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
    tenantId.value = _box.read<String>(_tenantIdKey);
    tenantName.value = _box.read<String>(_tenantNameKey);
    tenantApiHost.value = _box.read<String>(_tenantApiHostKey);
    await _box.remove(_legacyUserIdKey);

    // A session from a build before email sign-in has no company host to
    // send its requests to: sign in once more.
    if (endpoints.mustDropStoredSession(token: storedToken, tenantApiHost: tenantApiHost.value)) {
      await clearToken();
    }
    return this;
  }

  /// Public getter to retrieve current token directly (from memory).
  String? getToken() => token.value;

  /// Save token to memory and secure storage.
  Future<void> setToken(String newToken) async {
    _session++;
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

  /// Save the signed-in company (workspace mode). [apiHost] is the
  /// `tenant.api_host` the email sign-in answered; every later request goes
  /// to it ([apiBaseUrl]).
  void setTenant({required String id, required String name, required String apiHost}) {
    tenantId.value = id;
    tenantName.value = name;
    tenantApiHost.value = apiHost;
    _box.write(_tenantIdKey, id);
    _box.write(_tenantNameKey, name);
    _box.write(_tenantApiHostKey, apiHost);
  }

  /// Clear all credentials and the company (used on logout / session
  /// expiry); the base URL falls back to the central host.
  Future<void> clearToken() async {
    _session++;
    token.value = null;
    username.value = null;
    roles.value = null;
    tenantId.value = null;
    tenantName.value = null;
    tenantApiHost.value = null;

    await _secure.delete(key: _tokenKey);
    _box.remove(_usernameKey);
    _box.remove(_rolesKey);
    _box.remove(_tenantIdKey);
    _box.remove(_tenantNameKey);
    _box.remove(_tenantApiHostKey);
  }

  /// Convenience getters
  String? get currentToken => token.value;
  String? get currentUsername => username.value;
  String? get currentUserRoles => roles.value;
  String? get currentTenantName => tenantName.value;

  /// The API this session's requests go to (see [ApiEndpoints.apiBaseUrl]).
  String get apiBaseUrl => endpoints.apiBaseUrl(tenantApiHost: tenantApiHost.value);
}
