import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getx_project/app/services/api_endpoints.dart';
import 'package:getx_project/app/services/auth_service.dart';

const _workspace = ApiEndpoints(centralApiUrl: 'https://app.example.com/api', directApiUrl: '');
const _direct = ApiEndpoints(centralApiUrl: '', directApiUrl: 'https://acme.example.com/api');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('auth_service_tenant_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    await GetStorage.init();
  });

  setUp(() async {
    await GetStorage().erase();
    FlutterSecureStorage.setMockInitialValues({});
  });

  /// Stores a session the way a build would have left it, then boots a fresh service.
  Future<AuthService> boot(ApiEndpoints endpoints, {String? token, String? apiHost}) async {
    FlutterSecureStorage.setMockInitialValues({'auth_token': ?token});
    if (apiHost != null) await GetStorage().write('tenant_api_host_key', apiHost);
    return AuthService(endpoints: endpoints).init();
  }

  test('workspace mode drops a session from an older build (no company host)', () async {
    final auth = await boot(_workspace, token: 'old-token');

    expect(auth.currentToken, isNull);
    expect(auth.apiBaseUrl, 'https://app.example.com/api');
  });

  test('workspace mode keeps a session with its company host', () async {
    final auth = await boot(_workspace, token: 'tok', apiHost: 'acme.example.com');

    expect(auth.currentToken, 'tok');
    expect(auth.apiBaseUrl, 'https://acme.example.com/api');
  });

  test('direct mode keeps a session without a company host', () async {
    final auth = await boot(_direct, token: 'tok');

    expect(auth.currentToken, 'tok');
    expect(auth.apiBaseUrl, 'https://acme.example.com/api');
  });

  test('setTenant points the session at the company; clearToken returns to central', () async {
    final auth = await boot(_workspace);
    await auth.setToken('tok');
    auth.setTenant(id: 't-1', name: 'Acme', apiHost: 'acme.example.com');

    expect(auth.apiBaseUrl, 'https://acme.example.com/api');
    expect(auth.currentTenantName, 'Acme');
    // Persisted: a restart keeps the company.
    final restarted = await AuthService(endpoints: _workspace).init();
    expect(restarted.tenantApiHost.value, 'acme.example.com');

    await auth.clearToken();
    expect(auth.apiBaseUrl, 'https://app.example.com/api');
    expect(auth.tenantId.value, isNull);
    expect(GetStorage().read('tenant_api_host_key'), isNull);
  });

  group('ApiEndpoints.apiBaseUrl / mustDropStoredSession', () {
    test('resolve per mode', () {
      expect(_direct.apiBaseUrl(tenantApiHost: 'ignored.example.com'), 'https://acme.example.com/api');
      expect(_workspace.apiBaseUrl(), 'https://app.example.com/api');
      expect(_workspace.apiBaseUrl(tenantApiHost: ' '), 'https://app.example.com/api');
      expect(_workspace.apiBaseUrl(tenantApiHost: 'acme.example.com'), 'https://acme.example.com/api');
    });

    test('only a workspace token without a host is dropped', () {
      expect(_workspace.mustDropStoredSession(token: 'tok', tenantApiHost: null), isTrue);
      expect(_workspace.mustDropStoredSession(token: 'tok', tenantApiHost: 'a.example.com'), isFalse);
      expect(_workspace.mustDropStoredSession(token: null, tenantApiHost: null), isFalse);
      expect(_direct.mustDropStoredSession(token: 'tok', tenantApiHost: null), isFalse);
    });
  });
}
