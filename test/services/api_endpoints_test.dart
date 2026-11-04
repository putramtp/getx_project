import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/config/app_config.dart';
import 'package:getx_project/app/services/api_endpoints.dart';

void main() {
  group('AppConfig.describeConfigurationError', () {
    String? check(String central, String direct) =>
        AppConfig.describeConfigurationError(centralApiUrl: central, apiBaseUrl: direct);

    test('a build needs at least one API URL', () {
      expect(check('', ''), contains('No API configured'));
    });

    test('either mode alone is valid', () {
      expect(check('https://app.example.com/api', ''), isNull);
      expect(check('', 'https://acme.example.com/api'), isNull);
      expect(check('http://mastersystembackend.test/api', 'https://x.ngrok-free.app/api'), isNull);
    });

    test('a URL without an http(s) scheme or host is refused', () {
      expect(check('app.example.com/api', ''), contains('CENTRAL_API_URL'));
      expect(check('', 'ftp://acme.example.com'), contains('API_BASE_URL'));
    });
  });

  group('ApiEndpoints', () {
    const prod = ApiEndpoints(centralApiUrl: 'https://app.example.com/api', directApiUrl: '');
    const dev = ApiEndpoints(
      centralApiUrl: 'http://mastersystembackend.test/api',
      directApiUrl: '',
      devConnectAddress: '127.0.0.1',
    );

    test('a company API takes the central scheme', () {
      expect(prod.tenantApiUrl('acme.example.com'), 'https://acme.example.com/api');
      expect(dev.tenantApiUrl('MC.mastersystembackend.test.'), 'http://mc.mastersystembackend.test/api');
      expect(() => prod.tenantApiUrl('  '), throwsArgumentError);
    });

    test('direct mode falls back to the direct URL scheme, then https', () {
      expect(const ApiEndpoints(centralApiUrl: '', directApiUrl: 'http://x.test/api').tenantScheme, 'http');
      expect(const ApiEndpoints(centralApiUrl: '', directApiUrl: '').tenantScheme, 'https');
    });

    test('without a dev address a URL is sent as is', () {
      final url = Uri.parse('https://acme.example.com/api/me');
      expect(prod.connect(url), (uri: url, hostHeader: null));
    });

    test('a dev address takes the connection and the real host rides in Host', () {
      final target = dev.connect(Uri.parse('http://mc.mastersystembackend.test/api/me?x=1'));
      expect(target.uri.toString(), 'http://127.0.0.1/api/me?x=1');
      expect(target.hostHeader, 'mc.mastersystembackend.test');
    });

    test('a dev address with a port, and a URL with a port', () {
      const lan = ApiEndpoints(centralApiUrl: '', directApiUrl: '', devConnectAddress: '192.168.1.10:8080');
      final target = lan.connect(Uri.parse('http://mc.test/api/login'));
      expect(target.uri.toString(), 'http://192.168.1.10:8080/api/login');
      expect(target.hostHeader, 'mc.test');

      final ported = dev.connect(Uri.parse('http://mc.test:8000/api/login'));
      expect(ported.uri.toString(), 'http://127.0.0.1:8000/api/login');
      expect(ported.hostHeader, 'mc.test:8000');
    });

    test('the probe resolves the dev address, else the API host', () {
      expect(dev.probeHost('http://mc.mastersystembackend.test/api'), '127.0.0.1');
      expect(prod.probeHost('https://app.example.com/api'), 'app.example.com');
      expect(prod.probeHost(''), 'example.com');
    });
  });
}
