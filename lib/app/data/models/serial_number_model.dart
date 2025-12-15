class SerialNumberModel {
  final int id;
  final String serialNumber;
  final String internalCode;
  final DateTime? updateStockDate;
  final DateTime? expiredDate;
  final bool isActive;
  final int qty;

  SerialNumberModel({
    required this.id,
    required this.serialNumber,
    required this.internalCode,
    this.updateStockDate,
    this.expiredDate,
    required this.isActive,
    required this.qty,
  });

  factory SerialNumberModel.fromJson(Map<String, dynamic> json) {
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
      qty: json['qty'] ?? 0,
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
    };
  }
}