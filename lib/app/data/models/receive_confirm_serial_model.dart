class ReceiveConfirmSerialModel {
  final int id;
  final String serialNumber;
  final String internalCode;
  final int itemId;
  final String itemName;
  final String serialNumberType;
  final int qty;
  final String? scannedByName;

  /// Mutable so the confirm screen can optimistically flip it after a
  /// successful scan without re-fetching the whole list.
  bool isScanned;

  ReceiveConfirmSerialModel({
    required this.id,
    required this.serialNumber,
    required this.internalCode,
    required this.itemId,
    required this.itemName,
    required this.serialNumberType,
    required this.qty,
    required this.isScanned,
    this.scannedByName,
  });

  factory ReceiveConfirmSerialModel.fromJson(Map<String, dynamic> json) {
    return ReceiveConfirmSerialModel(
      id: json['id'],
      serialNumber: json['serial_number'] ?? '',
      internalCode: json['internal_code'] ?? '',
      itemId: json['item_id'] ?? 0,
      itemName: json['item_name'] ?? '-',
      serialNumberType: json['serial_number_type'] ?? 'OTHER',
      qty: json['qty'] ?? 0,
      isScanned: json['is_scanned'] ?? false,
      scannedByName: (json['scanned_by_name'] as String?)?.isEmpty ?? true
          ? null
          : json['scanned_by_name'],
    );
  }
}
