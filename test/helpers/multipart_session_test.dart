import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getx_project/app/data/providers/api_providers.dart';
import 'package:getx_project/app/services/api_endpoints.dart';
import 'package:getx_project/app/services/auth_service.dart';

const _workspace = ApiEndpoints(centralApiUrl: 'https://app.example.com/api', directApiUrl: '');

/// A multipart body is encoded before GetConnect builds the URL, so a sign-out
/// in that wait would send it to the central host: ApiProvider drops it.
///
/// `flutter test` answers every real HTTP request with a fake 400, so a request
/// that went out has a status code and one that was dropped has none.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService auth;
  late ApiProvider api;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('multipart_session_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    await GetStorage.init();
  });

  setUp(() async {
    Get.reset();
    await GetStorage().erase();
    FlutterSecureStorage.setMockInitialValues({});
    auth = await AuthService(endpoints: _workspace).init();
    await auth.setToken('tok');
    auth.setTenant(id: 't1', name: 'Acme', apiHost: 'acme.example.com');
    Get.put(auth);
    api = Get.put(ApiProvider());
  });

  FormData photo() => FormData({'file': MultipartFile(List<int>.filled(16, 1), filename: 'proof.jpg')});

  test('an upload in the same session is sent to the company host, without the internal header', () async {
    final response = await api.post('/delivery/1/proofs', photo());

    expect(response.statusCode, isNotNull);
    expect(response.request?.url.host, 'acme.example.com');
    expect(response.request?.headers.containsKey(ApiProvider.sessionHeader), isFalse);
    expect(response.request?.headers['Authorization'], 'Bearer tok');
  });

  test('an upload whose session ends before it is sent is dropped', () async {
    final pending = api.post('/delivery/1/proofs', photo());
    await auth.clearToken(); // sign-out while the body is being encoded

    final response = await pending;
    expect(response.statusCode, isNull);
    expect(response.statusText, contains('session ended before the upload was sent'));
  });

  test('a JSON request still goes out after the session changes (POST /logout)', () async {
    final pending = api.post('/logout', const <String, dynamic>{}, headers: {'Authorization': 'Bearer tok'});
    await auth.clearToken();

    final response = await pending;
    expect(response.statusCode, isNotNull);
    expect(response.request?.url.host, 'acme.example.com');
  });
}
