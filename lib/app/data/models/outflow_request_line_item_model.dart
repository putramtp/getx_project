class OutflowRequestLineItemModel {
  final int lineId;
  final String name;
  final String serialNumberType;
  final bool manageExpired;
  final bool manageSn; // master "is serial-tracked" flag
  final int expected;
  /// Issuable ceiling: the backend rejects outflows beyond the reserved qty.
  final int reserved;
  int? received; // nullable if you prefer to derive from scanned
  List<String>? scanned;

  OutflowRequestLineItemModel({
    required this.lineId,
    required this.name,
    required this.serialNumberType,
    required this.manageExpired,
    this.manageSn = false,
    required this.expected,
    required this.reserved,
    this.received,
    List<String>? scanned,
  }) : scanned = scanned ?? [];

  // computed getter — always returns a non-null count
  int get scannedCount => scanned?.length ?? 0;

  // prefer explicit received if set, otherwise return scannedCount
  int get receivedCount => received ?? scannedCount;

  factory OutflowRequestLineItemModel.fromJson(Map<String, dynamic> json) {
    return OutflowRequestLineItemModel(
      lineId: json['line_id'],
      name: json['item_name'] ?? '-',
      serialNumberType: json['serial_number_type'] ?? '-',
      manageExpired: json['manage_expired'] ?? false,
      manageSn: json['manage_sn'] ?? false,
      expected: json['expected_qty'] ?? 0,
      // Older backends don't send reserved_qty; fall back to the full request.
      reserved: ((json['reserved_qty'] ?? json['expected_qty'] ?? 0) as num).toInt(),
      received: json['received_qty'] ?? 0,
      scanned: (json['scanned'] is List)
          ? List<String>.from(json['scanned'])
          : <String>[],
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
