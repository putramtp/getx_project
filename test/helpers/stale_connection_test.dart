import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/providers/api_providers.dart';

void main() {
  test('a reused socket the tunnel already closed counts as stale', () {
    expect(ApiProvider.isStaleConnection('Broken pipe'), isTrue);
    expect(ApiProvider.isStaleConnection('Can not connect to server. Reason: Connection reset by peer'), isTrue);
    expect(
      ApiProvider.isStaleConnection('Connection closed before full header was received'),
      isTrue,
    );
  });

  test('timeouts and real failures are not retried', () {
    expect(ApiProvider.isStaleConnection(null), isFalse);
    expect(ApiProvider.isStaleConnection(''), isFalse);
    expect(ApiProvider.isStaleConnection('TimeoutException after 0:00:30.000000'), isFalse);
    expect(ApiProvider.isStaleConnection('Failed host lookup: example.com'), isFalse);
  });
}
