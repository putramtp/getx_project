import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/receive_confirm_serial_model.dart';

void main() {
  test('qty sent as a DECIMAL string parses, so Confirm Serials gets its labels', () {
    // GET /receive-order/{id}/serial-number returns the pivot qty as "1.000000".
    final serial = ReceiveConfirmSerialModel.fromJson({
      'id': 24,
      'serial_number': 'HONCAPECAPE-SN-PT100-000022',
      'internal_code': 'HONCAPECAPE-SN-PT100-000022',
      'item_id': 47,
      'item_name': 'Temperature Sensor PT100',
      'serial_number_type': 'UNIQUE',
      'qty': '1.000000',
      'is_scanned': false,
      'scanned_by_name': null,
    });

    expect(serial.qty, 1);
    expect(serial.serialNumber, 'HONCAPECAPE-SN-PT100-000022');
    expect(serial.isScanned, isFalse);
  });

  test('numeric or missing qty still parses', () {
    expect(ReceiveConfirmSerialModel.fromJson({'id': 1, 'qty': 3}).qty, 3);
    expect(ReceiveConfirmSerialModel.fromJson({'id': 1}).qty, 0);
  });
}
