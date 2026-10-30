import 'package:getx_project/app/global/functions.dart';

class PurchaseOrderLineModel {
  final int lineId;
  final String name;
  final String serialNumberType;
  final bool manageExpired;
  final num expected;
  num? received; // nullable if you prefer to derive from filled
  List<String>? filled;

  PurchaseOrderLineModel({
    required this.lineId,
    required this.name,
    required this.serialNumberType,
    required this.manageExpired,
    required this.expected,
    this.received,
    List<String>? filled,
  }) : filled = filled ?? [];

  // computed getter — always returns a non-null count
  int get filledCount => filled?.length ?? 0;

  // prefer explicit received if set, otherwise return filledCount
  num get receivedCount => received ?? filledCount;

  factory PurchaseOrderLineModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderLineModel(
      lineId: json['line_id'],
      name: json['item_name'] ?? '-',
      serialNumberType: json['serial_number_type'] ?? '-',
      manageExpired: json['manage_expired'] ?? false,
      expected: safeToNum(json['expected_qty']),
      received: safeToNum(json['received_qty']),
      filled: (json['filled'] is List)
          ? List<String>.from(json['filled'])
          : <String>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'line_id': lineId,
        'name': name,
        'serial_number_type': serialNumberType,
        'manage_expired': manageExpired,
        'expected': expected,
        'received': received,
        'filled': filled,
      };
}
