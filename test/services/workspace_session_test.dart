import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getx_project/app/data/models/workspace_sign_in_model.dart';
import 'package:getx_project/app/data/providers/api_providers.dart';
import 'package:getx_project/app/data/providers/workspace_provider.dart';
import 'package:getx_project/app/services/api_endpoints.dart';
import 'package:getx_project/app/services/auth_service.dart';
import 'package:getx_project/app/services/workspace_session.dart';

const _endpoints = ApiEndpoints(centralApiUrl: 'https://app.example.com/api', directApiUrl: '');

/// Answers the handoff and /me from canned bodies and records where each call
/// would have gone (the base URL at call time).
class _FakeTenantApi extends ApiProvider {
  _FakeTenantApi({this.handoff, this.me, this.handoffError});

  final Map<String, dynamic>? handoff;
  final Map<String, dynamic>? me;
  final Exception? handoffError;
  final calls = <String>[];
  final revoked = <String>[];

  @override
  Future<Map<String, dynamic>> postMap(String path, dynamic body, {String? idempotencyKey}) async {
    calls.add('POST $requestBaseUrl$path ${body is Map ? body['token'] : ''}');
    if (handoffError != null) throw handoffError!;
    return handoff!;
  }

  @override
  Future<Map<String, dynamic>> getMap(String path, {Map<String, dynamic>? query}) async {
    calls.add('GET $requestBaseUrl$path');
    return me!;
  }

  @override
  Future<void> revokeToken(String token) async => revoked.add(token);
}

/// Records the central requests instead of sending them.
class _RecordingWorkspaceProvider extends WorkspaceProvider {
  final sent = <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> postMap(String path, dynamic body, {String? idempotencyKey}) async {
    sent['url'] = '$requestBaseUrl$path';
    sent['body'] = body;
    return path.endsWith('forgot-password')
        ? {'success': true, 'message': 'If that email belongs to an account, a reset link is on its way.'}
        : {
            'data': {
              'mode': 'choose',
              'tenants': [
                {'id': 't1', 'name': 'Acme', 'host': 'acme.example.com'},
              ],
            },
          };
  }
}

const _handoffAnswer = WorkspaceSignInResult(
  mode: WorkspaceSignInResult.modeHandoff,
  tenant: WorkspaceTenant(id: 't-1', name: 'Acme', host: 'acme.example.com', apiHost: 'acme.example.com'),
  handoffToken: 'handoff-123',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthService auth;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('workspace_session_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    await GetStorage.init();
  });

  setUp(() async {
    await GetStorage().erase();
    FlutterSecureStorage.setMockInitialValues({});
    Get.reset();
    auth = await AuthService(endpoints: _endpoints).init();
    Get.put(auth);
  });

  group('WorkspaceSession.complete', () {
    test('exchanges on the company host, reads /me, and keeps the session', () async {
      final api = _FakeTenantApi(
        handoff: {
          'data': {'token': 'access-1', 'name': 'Ann'},
        },
        me: {
          'user': {'name': 'Ann Lee', 'must_change_password': false},
          'roles': ['admin', 'warehouse'],
        },
      );

      final user = await WorkspaceSession(api: api, auth: auth).complete(_handoffAnswer);

      expect(api.calls, [
        'POST https://acme.example.com/api/sign-in/handoff handoff-123',
        'GET https://acme.example.com/api/me',
      ]);
      expect(user.name, 'Ann Lee');
      expect(user.roles, ['admin', 'warehouse']);
      expect(auth.currentToken, 'access-1');
      expect(auth.currentTenantName, 'Acme');
      expect(auth.currentUserRoles, 'admin, warehouse');
      expect(auth.apiBaseUrl, 'https://acme.example.com/api');
    });

    test('a password change owed revokes the new token and leaves no session', () async {
      final api = _FakeTenantApi(
        handoff: {
          'data': {'token': 'access-2'},
        },
        me: {
          'user': {'name': 'Ann', 'must_change_password': true},
          'roles': [],
        },
      );

      await expectLater(
        WorkspaceSession(api: api, auth: auth).complete(_handoffAnswer),
        throwsA(isA<PasswordChangeRequiredException>()),
      );
      expect(api.revoked, ['access-2']);
      expect(auth.currentToken, isNull);
      expect(auth.tenantApiHost.value, isNull);
      expect(auth.apiBaseUrl, 'https://app.example.com/api');
    });

    test('a refused handoff clears the company it had saved', () async {
      final api = _FakeTenantApi(handoffError: Exception('This sign-in link has expired. Please sign in again.'));

      await expectLater(WorkspaceSession(api: api, auth: auth).complete(_handoffAnswer), throwsException);
      expect(auth.tenantApiHost.value, isNull);
      expect(auth.currentToken, isNull);
    });
  });

  group('WorkspaceProvider', () {
    test('signs in on the central host without the session token', () async {
      await auth.setToken('stale-token');
      final provider = _RecordingWorkspaceProvider();

      final result = await provider.signIn('ann@acme.com', 'secret1', tenantId: 't1');

      expect(provider.sent['url'], 'https://app.example.com/api/workspace/sign-in');
      expect(provider.sent['body'], {'email': 'ann@acme.com', 'password': 'secret1', 'tenant_id': 't1'});
      expect(provider.sendsToken, isFalse);
      expect(result.isChoose, isTrue);
    });

    test('a sign-in without a company choice sends no tenant_id', () async {
      final provider = _RecordingWorkspaceProvider();
      await provider.signIn('ann@acme.com', 'secret1');
      expect((provider.sent['body'] as Map).containsKey('tenant_id'), isFalse);
    });

    test('forgot password goes to the central host', () async {
      final provider = _RecordingWorkspaceProvider();
      final message = await provider.forgotPassword('ann@acme.com');
      expect(provider.sent['url'], 'https://app.example.com/api/workspace/forgot-password');
      expect(message, contains('reset link'));
    });
  });
}
