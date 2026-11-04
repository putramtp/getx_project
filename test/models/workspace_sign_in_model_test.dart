import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/workspace_sign_in_model.dart';

void main() {
  test('a handoff answer carries the company host and the single-use token', () {
    final result = WorkspaceSignInResult.fromJson({
      'mode': 'handoff',
      'tenant': {'id': 'abc', 'name': 'Acme', 'host': 'acme.example.com', 'api_host': 'acme.api.example.com'},
      'handoff_token': 'tok',
      'handoff_url': 'https://acme.example.com/sign-in#token=tok',
      'expires_in': 60,
      'minimum_app_version': '1.1.0',
    });

    expect(result.isHandoff, isTrue);
    expect(result.tenant!.apiHost, 'acme.api.example.com');
    expect(result.tenant!.name, 'Acme');
    expect(result.handoffToken, 'tok');
  });

  test('a choose answer lists the companies (no api host yet)', () {
    final result = WorkspaceSignInResult.fromJson({
      'mode': 'choose',
      'tenants': [
        {'id': 'a', 'name': 'Acme', 'host': 'acme.example.com'},
        {'id': 'b', 'host': 'beta.example.com'},
      ],
    });

    expect(result.isChoose, isTrue);
    expect(result.tenants.map((t) => t.id), ['a', 'b']);
    expect(result.tenants.last.name, 'beta.example.com'); // no name → host
    expect(result.tenants.first.apiHost, isNull);
  });

  test('an incomplete or unknown answer is a readable FormatException', () {
    expect(() => WorkspaceSignInResult.fromJson({'mode': 'handoff', 'handoff_token': 'tok'}), throwsFormatException);
    expect(() => WorkspaceSignInResult.fromJson({'mode': 'choose', 'tenants': []}), throwsFormatException);
    expect(() => WorkspaceSignInResult.fromJson({'mode': 'weird'}), throwsFormatException);
  });
}
