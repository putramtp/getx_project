import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/delivery_model.dart';
import 'package:getx_project/app/data/models/delivery_status_model.dart';

Map<String, dynamic> _row([Map<String, dynamic> extra = const {}]) => {
      'id': 7,
      'code': 'DLV-007',
      'customer': 'ACME',
      'status_id': 1,
      'status_name': 'Pending',
      'address': 'Jl. Merdeka 1',
      ...extra,
    };

void main() {
  test('the detail carries where the status may move next', () {
    final d = DeliveryModel.fromJson(_row({
      'next_statuses': [
        {'id': 2, 'name': 'Shipped', 'label': 'On the way'},
        {'id': 3, 'name': 'Delivered', 'label': 'Delivered'},
      ],
    }));

    expect(d.nextStatusIds, [2, 3]);
  });

  test('a list row has no flow, and a final status has no next move', () {
    expect(DeliveryModel.fromJson(_row()).nextStatusIds, isNull);
    expect(DeliveryModel.fromJson(_row({'next_statuses': []})).nextStatusIds, isEmpty);
  });

  test('the detail lists proof files and whether the status can be undone', () {
    final d = DeliveryModel.fromJson(_row({
      'proofs': [
        {'id': 11, 'title': 'surat-jalan.jpg', 'size': '312 KB'},
      ],
      'undo': {
        'available': true,
        'to': {'id': 2, 'name': 'Shipped', 'label': 'On the way'},
        'reason': null,
      },
    }));

    expect(d.proofs.single.title, 'surat-jalan.jpg');
    expect(d.proofs.single.size, '312 KB');
    expect(d.undoAvailable, isTrue);
    expect(d.undoToName, 'Shipped');
    expect(d.undoToLabel, 'On the way');
  });

  test('a status reads as the web names it, the stored name kept for logic', () {
    final d = DeliveryModel.fromJson(_row({'status_label': 'Scheduled'}));
    expect(d.statusName, 'Pending');
    expect(d.statusLabel, 'Scheduled');
    // An older backend without the label shows the stored name.
    expect(DeliveryModel.fromJson(_row()).statusLabel, 'Pending');

    final s = DeliveryStatusModel.fromJson({'id': 2, 'name': 'Shipped', 'label': 'On the way', 'color': '#FFFFFF'});
    expect([s.name, s.label], ['Shipped', 'On the way']);
    expect(DeliveryStatusModel.fromJson({'id': 2, 'name': 'Shipped'}).label, 'Shipped');
  });

  test('pending deliveries are counted from the per-status counts', () {
    final rows = [
      {'status_id': 1, 'name': 'Pending', 'label': 'Scheduled', 'count': 4},
      {'status_id': 2, 'name': 'Shipped', 'label': 'On the way', 'count': 2},
    ];
    expect(DeliveryStatusCount.countOf(rows.map(DeliveryStatusCount.fromJson), 'Pending'), 4);
    expect(DeliveryStatusCount.countOf(const [], 'Pending'), 0);
  });

  test('a proof knows whether it is an image the app can preview', () {
    final d = DeliveryModel.fromJson(_row({
      'proofs': [
        {'id': 11, 'title': 'foto.jpg', 'mime_type': 'image/jpeg'},
        {'id': 12, 'title': 'surat-jalan.pdf', 'mime_type': 'application/pdf'},
      ],
    }));
    expect(d.proofs.map((p) => p.isImage), [true, false]);
  });

  test('no undo block means no undo', () {
    final d = DeliveryModel.fromJson(_row({
      'undo': {'available': false, 'to': null, 'reason': 'Only a manager can do this.'},
    }));

    expect(d.undoAvailable, isFalse);
    expect(d.undoRefusal, 'Only a manager can do this.');
    expect(DeliveryModel.fromJson(_row()).proofs, isEmpty);
  });

  test('a delivered row names the receiver and the delivered time', () {
    final d = DeliveryModel.fromJson(_row({
      'receiver_name': 'Budi',
      'delivered_at': '2026-10-30T03:15:00.000000Z',
    }));
    final local = DateTime.utc(2026, 10, 30, 3, 15).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');

    expect(d.receiverName, 'Budi');
    expect(d.deliveredAt, '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}');
    expect(DeliveryModel.fromJson(_row()).deliveredAt, isNull);
  });
}
