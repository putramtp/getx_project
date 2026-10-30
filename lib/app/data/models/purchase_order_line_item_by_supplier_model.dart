import 'package:getx_project/app/global/functions.dart';

class PurchaseOrderLineItemBySupplierModel {
  final int lineId;
  final String name;
  final String serialNumberType;
  final bool manageExpired;
  final bool manageSn;
  final num expected;
  num? received; // nullable if you prefer to derive from filled
  List<String>? filled;

  /// Why the backend would refuse to receive this line (e.g. it has no price);
  /// null when it can be received. The app shows a blocked line read-only.
  final String? blockedReason;

  PurchaseOrderLineItemBySupplierModel({
    required this.lineId,
    required this.name,
    required this.serialNumberType,
    required this.manageExpired,
    required this.manageSn,
    required this.expected,
    this.received,
    List<String>? filled,
    this.blockedReason,
  }) : filled = filled ?? [];

  // computed getter — always returns a non-null count
  int get filledCount => filled?.length ?? 0;

  // prefer explicit received if set, otherwise return filledCount
  num get receivedCount => received ?? filledCount;

  factory PurchaseOrderLineItemBySupplierModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderLineItemBySupplierModel(
      lineId: json['line_id'],
      name: json['item_name'] ?? '-',
      serialNumberType: json['serial_number_type'] ?? '-',
      manageExpired: json['manage_expired'] ?? false,
      manageSn: json['manage_sn'] ?? false,
      expected: safeToNum(json['expected_qty']),
      received: safeToNum(json['received_qty']),
      filled: (json['filled'] is List)
          ? List<String>.from(json['filled'])
          : <String>[],
      blockedReason: lineBlockedReason(json, 'can_receive'),
    );
  }

  Map<String, dynamic> toJson() => {
        'line_id': lineId,
        'name': name,
        'serial_number_type': serialNumberType,
        'manage_expired': manageExpired,
        'manage_sn': manageSn,
        'expected': expected,
        'received': received,
        'filled': filled,
      };
}
