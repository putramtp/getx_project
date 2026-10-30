import 'package:getx_project/app/global/functions.dart';

class OutflowRequestLineItemModel {
  final int lineId;

  /// The line's item — By Work Order sends it with each issued line.
  final int? itemId;
  final String name;
  final String serialNumberType;
  final bool manageExpired;
  final bool manageSn; // master "is serial-tracked" flag
  final num expected;
  /// Issuable ceiling: the backend rejects outflows beyond the reserved qty.
  final num reserved;
  num? received; // nullable if you prefer to derive from scanned
  List<String>? scanned;

  /// Why the backend would refuse to issue this line (unapproved request,
  /// cancelled order, ...); null when it can be issued. Shown read-only.
  final String? blockedReason;

  OutflowRequestLineItemModel({
    required this.lineId,
    this.itemId,
    required this.name,
    required this.serialNumberType,
    required this.manageExpired,
    this.manageSn = false,
    required this.expected,
    required this.reserved,
    this.received,
    List<String>? scanned,
    this.blockedReason,
  }) : scanned = scanned ?? [];

  // computed getter — always returns a non-null count
  int get scannedCount => scanned?.length ?? 0;

  // prefer explicit received if set, otherwise return scannedCount
  num get receivedCount => received ?? scannedCount;

  factory OutflowRequestLineItemModel.fromJson(Map<String, dynamic> json) {
    return OutflowRequestLineItemModel(
      lineId: json['line_id'],
      itemId: (num.tryParse(json['item_id']?.toString() ?? ''))?.toInt(),
      name: json['item_name'] ?? '-',
      serialNumberType: json['serial_number_type'] ?? '-',
      manageExpired: json['manage_expired'] ?? false,
      manageSn: json['manage_sn'] ?? false,
      expected: safeToNum(json['expected_qty']),
      // Older backends don't send reserved_qty; fall back to the full request.
      reserved: safeToNum(json['reserved_qty'] ?? json['expected_qty']),
      received: safeToNum(json['received_qty']),
      scanned: (json['scanned'] is List)
          ? List<String>.from(json['scanned'])
          : <String>[],
      blockedReason: lineBlockedReason(json, 'can_issue'),
    );
  }

  Map<String, dynamic> toJson() => {
        'line_id': lineId,
        'name': name,
        'serial_number_type': serialNumberType,
        'manage_expired': manageExpired,
        'manage_sn': manageSn,
        'expected': expected,
        'reserved': reserved,
        'received': received,
        'scanned': scanned,
      };
}
