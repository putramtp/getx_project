import 'api_providers.dart';
class LoginProvider extends ApiProvider {
  Future<Map<String, dynamic>> login(String username, String password) {
    return postMap('/login', {
      'username': username,
      'password': password,
    });
  }

  /// `POST /send-email-reset` — mails a reset link to the web's reset page.
  /// Answers the same whether or not an account uses [email].
  Future<Map<String, dynamic>> sendResetEmail(String email) {
    return postMap('/send-email-reset', {'email': email});
  }
}
