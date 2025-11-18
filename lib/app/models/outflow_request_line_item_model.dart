class OutflowRequestLineItem {
  final int lineId;
  final String name;
  final String serialNumberType;
  final bool manageExpired;
  final int expected;
  int? received; // nullable if you prefer to derive from scanned
  List<String>? scanned;

  OutflowRequestLineItem({
    required this.lineId,
    required this.name,
    required this.serialNumberType,
    required this.manageExpired,
    required this.expected,
    this.received,
    List<String>? scanned,
  }) : scanned = scanned ?? [];

  // computed getter — always returns a non-null count
  int get scannedCount => scanned?.length ?? 0;

  // prefer explicit received if set, otherwise return scannedCount
  int get receivedCount => received ?? scannedCount;

  factory OutflowRequestLineItem.fromJson(Map<String, dynamic> json) {
    return OutflowRequestLineItem(
      lineId: json['line_id'],
      name: json['item_name'] ?? '-',
      serialNumberType: json['serial_number_type'] ?? '-',
      manageExpired: json['manage_expired'] ?? '-',
      expected: json['expected_qty'] ?? 0,
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
        'expected': expected,
        'received': received,
        'scanned': scanned,
      };
}
