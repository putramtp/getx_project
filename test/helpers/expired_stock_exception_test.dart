import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/providers/api_providers.dart';

void main() {
  test('the 409 expired_batch answer lists each expired batch or serial', () {
    final e = ExpiredStockException.fromBody({
      'message': 'Expired stock is about to leave: Batch LOT-1 (Valve) expired on 3 Oct 2026. Confirm to issue it anyway.',
      'error_code': 'expired_batch',
      'expired': [
        {'row': 1, 'code': 'LOT-1', 'message': 'Batch LOT-1 (Valve) expired on 3 Oct 2026'},
        {'row': 2, 'code': 'SN-9', 'message': 'Serial SN-9 (Pump) expired on 1 Oct 2026'},
      ],
    });

    expect(e.expired, [
      'Batch LOT-1 (Valve) expired on 3 Oct 2026',
      'Serial SN-9 (Pump) expired on 1 Oct 2026',
    ]);
    expect(e.toString(), startsWith('Expired stock is about to leave'));
  });

  test('a body without the list still gives a message', () {
    final e = ExpiredStockException.fromBody({'error_code': 'expired_batch'});

    expect(e.expired, isEmpty);
    expect(e.message, isNotEmpty);
  });
}
