import '../models/workspace_sign_in_model.dart';
import 'api_providers.dart';

/// The central host's email sign-in (workspace mode). Always the central API,
/// never the session's company host, and never a bearer token.
class WorkspaceProvider extends ApiProvider {
  @override
  String get requestBaseUrl => authService.endpoints.centralApiUrl;

  @override
  bool get sendsToken => false;

  /// `POST /workspace/sign-in`. Every refusal (unknown email, wrong password,
  /// inactive user, suspended company) is one 401 with one message.
  Future<WorkspaceSignInResult> signIn(String email, String password, {String? tenantId}) async {
    final body = await postMap('/workspace/sign-in', {
      'email': email,
      'password': password,
      'tenant_id': ?tenantId,
    });
    return WorkspaceSignInResult.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  /// `POST /workspace/forgot-password`: mails a reset link to every company
  /// that has [email]. Answers the same whether or not one does.
  Future<String> forgotPassword(String email) async {
    final body = await postMap('/workspace/forgot-password', {'email': email});
    return body['message']?.toString() ?? 'If that email belongs to an account, a reset link is on its way.';
  }
}
