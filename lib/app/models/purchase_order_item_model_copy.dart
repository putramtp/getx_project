class PurchaseOrderItemCopy {
  final int id;
  final String name;
  final String serialNumberType;
  final int expected;
  int? received; // nullable if you prefer to derive from scanned
  List<String>? scanned;

  PurchaseOrderItemCopy({
    required this.id,
    required this.name,
    required this.serialNumberType,
    required this.expected,
    this.received,
    List<String>? scanned,
  }) : scanned = scanned ?? [];

  // computed getter — always returns a non-null count
  int get scannedCount => scanned?.length ?? 0;

  // prefer explicit received if set, otherwise return scannedCount
  int get receivedCount => received ?? scannedCount;

  factory PurchaseOrderItemCopy.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItemCopy(
      id: json['line_id'] ?? json['id'] ?? 0,
      name: json['item_name'] ?? '-',
      serialNumberType: json['serial_number_type'] ?? '-',
      expected: json['expected_qty'] ?? 0,
      received: json['received_qty'] ?? 0,
      scanned: (json['scanned'] is List)
          ? List<String>.from(json['scanned'])
          : <String>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'serialNumberType': serialNumberType,
        'expected': expected,
        'received': received,
        'scanned': scanned,
      };
}
