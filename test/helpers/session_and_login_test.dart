import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/providers/api_providers.dart';
import 'package:getx_project/app/modules/login/controllers/login_controller.dart';

void main() {
  group('sessionEndNotice', () {
    test('an expired token reads as an expired session', () {
      expect(ApiProvider.sessionEndNotice(401, {'message': 'Unauthenticated.'}),
          'Your session has expired. Please sign in again.');
      expect(ApiProvider.sessionEndNotice(401, null), contains('expired'));
    });

    test('a deactivated account keeps the server message', () {
      const msg = 'This account has been deactivated. Please contact an administrator.';
      expect(ApiProvider.sessionEndNotice(401, {'message': msg}), msg);
    });

    test('a password change owed points to the web', () {
      final notice = ApiProvider.sessionEndNotice(403, {'error_code': 'PASSWORD_CHANGE_REQUIRED'});
      expect(notice, contains('on the web'));
    });

    test('suspended company and lapsed subscription end the session', () {
      expect(ApiProvider.sessionEndNotice(403, {'error_code': 'TENANT_SUSPENDED', 'message': 'Suspended.'}),
          'Suspended.');
      expect(ApiProvider.sessionEndNotice(402, {'error_code': 'SUBSCRIPTION_EXPIRED'}), contains('subscription'));
    });

    test('a plain permission denial does not', () {
      expect(ApiProvider.sessionEndNotice(403, {'message': 'Forbidden'}), isNull);
      expect(ApiProvider.sessionEndNotice(422, {'message': 'Invalid'}), isNull);
    });
  });

  group('retryAfterHint', () {
    test('seconds, minutes and unknown', () {
      expect(ApiProvider.retryAfterHint(1), 'Try again in 1 second.');
      expect(ApiProvider.retryAfterHint('42'), 'Try again in 42 seconds.');
      expect(ApiProvider.retryAfterHint(60), 'Try again in 1 minute.');
      expect(ApiProvider.retryAfterHint('3500'), 'Try again in 59 minutes.');
      expect(ApiProvider.retryAfterHint(''), 'Please wait a moment and try again.');
      expect(ApiProvider.retryAfterHint(null), 'Please wait a moment and try again.');
    });
  });

  group('loginFieldErrors', () {
    test('mirrors the backend rules', () {
      expect(loginFieldErrors('', ''), (username: 'Enter your username.', password: 'Enter your password.'));
      expect(loginFieldErrors(' ab ', '12345').username, contains('at least 3'));
      expect(loginFieldErrors('abc', '12345').password, contains('at least 6'));
      expect(loginFieldErrors('  e2e_tester ', 'secret'), (username: null, password: null));
    });

    test('workspace mode asks for an email', () {
      expect(loginFieldErrors('', 'secret', email: true).username, 'Enter your email.');
      expect(loginFieldErrors('e2e_tester', 'secret', email: true).username, 'Enter a valid email address.');
      expect(loginFieldErrors(' ann@acme.com ', 'secret', email: true), (username: null, password: null));
    });
  });
}
