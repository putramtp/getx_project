class ReceiveOrderModel {
  final int id;
  final String code;
  final String type;
  final String supplier;
  final DateTime date;

  /// Labels of manage_sn items not scanned yet (`pending_serial_count`).
  final int pendingSerialCount;

  ReceiveOrderModel({
    required this.id,
    required this.code,
    required this.type,
    required this.supplier,
    required this.date,
    this.pendingSerialCount = 0,
  });

  factory ReceiveOrderModel.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(dateStr);

    return ReceiveOrderModel(
      id: json['id'],
      code: json['code'],
      type: json['type']?.toString() ?? '-',
      supplier: json['supplier_name'] ?? 'N/A',
      date: parsedDate ?? DateTime.now(),
      pendingSerialCount: (json['pending_serial_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'supplier_name': supplier,
      'date': date.toIso8601String(),
      'pending_serial_count': pendingSerialCount,
    };
  }
}
