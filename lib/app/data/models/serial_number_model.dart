class SerialNumberModel {
  final int id;
  final String serialNumber;
  final String internalCode;
  final DateTime? updateStockDate;
  final DateTime? expiredDate;
  final bool isActive;
  final int qty;

  /// Serial-confirmation status (scan-to-confirm pass). `scannedByName` is the
  /// user who confirmed it; null/empty when still pending.
  final bool isScanned;
  final String? scannedAt;
  final String? scannedByName;

  SerialNumberModel({
    required this.id,
    required this.serialNumber,
    required this.internalCode,
    this.updateStockDate,
    this.expiredDate,
    required this.isActive,
    required this.qty,
    this.isScanned = false,
    this.scannedAt,
    this.scannedByName,
  });

  factory SerialNumberModel.fromJson(Map<String, dynamic> json) {
    final scannedAt = json['scanned_at']?.toString() ?? '';
    return SerialNumberModel(
      id: json['id'],
      serialNumber: json['serial_number'] ?? '',
      internalCode: json['internal_code'] ?? '',
      updateStockDate: json['update_stock_date'] != null
          ? DateTime.tryParse(json['update_stock_date'])
          : null,
      expiredDate: json['expired_date'] != null
          ? DateTime.tryParse(json['expired_date'])
          : null,
      isActive: json['is_active'] ?? false,
      qty: (num.tryParse(json['qty']?.toString() ?? '') ?? 0).toInt(),
      isScanned: json['is_scanned'] ?? false,
      scannedAt: scannedAt.isNotEmpty ? scannedAt : null,
      scannedByName: json['scanned_by_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serial_number': serialNumber,
      'internal_code': internalCode,
      'update_stock_date': updateStockDate?.toIso8601String(),
      'expired_date': expiredDate?.toIso8601String(),
      'is_active': isActive,
      'qty': qty,
      'is_scanned': isScanned,
      'scanned_at': scannedAt,
      'scanned_by_name': scannedByName,
    };
  }
}