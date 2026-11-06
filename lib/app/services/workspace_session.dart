import 'dart:async';

import 'package:get/get.dart';

import '../data/models/workspace_sign_in_model.dart';
import '../data/providers/api_providers.dart';
import 'auth_service.dart';

/// The signed-in person after [WorkspaceSession.complete].
typedef SignedInUser = ({String name, List<String> roles});

/// The account still holds the password mailed at activation: the session
/// was ended at once, and the user is told to change it on the web.
class PasswordChangeRequiredException implements Exception {
  @override
  String toString() => ApiProvider.passwordChangeNotice;
}

/// Turns a `handoff` answer of the central sign-in into a session on the
/// company's own host — the one place this sequence lives, shared by the
/// login screen and the Patrol harness:
///
/// 1. save the company (its `api_host` becomes [AuthService.apiBaseUrl]);
/// 2. `POST /sign-in/handoff {token}` on that host → the access token
///    (single use, 60 s — called at once);
/// 3. `GET /me` → name, roles, `must_change_password`;
/// 4. a password change owed → revoke the token, clear, and throw
///    [PasswordChangeRequiredException].
///
/// Any failure clears what was saved, so no half session is left behind.
/// GetConnect always prefixes `baseUrl`, so the company is saved *before* the
/// exchange rather than calling its host with an absolute URL.
class WorkspaceSession {
  WorkspaceSession({ApiProvider? api, AuthService? auth})
      : _api = api ?? Get.find<ApiProvider>(),
        _auth = auth ?? Get.find<AuthService>();

  final ApiProvider _api;
  final AuthService _auth;

  Future<SignedInUser> complete(WorkspaceSignInResult answer) async {
    final tenant = answer.tenant;
    final handoffToken = answer.handoffToken;
    if (!answer.isHandoff || tenant?.apiHost == null || handoffToken == null) {
      throw ArgumentError('complete() needs a handoff answer with a company host.');
    }

    try {
      _auth.setTenant(id: tenant!.id, name: tenant.name, apiHost: tenant.apiHost!);

      final exchanged = await _api.postMap('/sign-in/handoff', {'token': handoffToken});
      final token = (exchanged['data'] as Map?)?['token']?.toString() ?? '';
      if (token.isEmpty) throw Exception('Signed in, but the company sent no access token.');
      await _auth.setToken(token);

      final me = await _api.getMap('/me');
      final user = me['user'] is Map ? Map<String, dynamic>.from(me['user'] as Map) : const <String, dynamic>{};
      if (user['must_change_password'] == true) {
        unawaited(_api.revokeToken(token));
        await _auth.clearToken();
        throw PasswordChangeRequiredException();
      }

      final name = (user['name'] ?? (exchanged['data'] as Map?)?['name'] ?? '').toString();
      final roles = (me['roles'] is List ? me['roles'] as List : const []).map((r) => r.toString()).toList();
      _auth.setUsername(name);
      _auth.setRoles(roles.join(', '));
      return (name: name, roles: roles);
    } on PasswordChangeRequiredException {
      rethrow; // its token is revoked and cleared above
    } catch (_) {
      // A token issued before the failure (e.g. `/me` lost its answer) would
      // stay valid on the server until it expires: revoke it, then clear.
      final issued = _auth.currentToken;
      if (issued != null && issued.isNotEmpty) unawaited(_api.revokeToken(issued));
      if (_auth.currentToken != null || _auth.tenantApiHost.value != null) await _auth.clearToken();
      rethrow;
    }
  }
}
