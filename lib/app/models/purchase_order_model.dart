class PurchaseOrderModel {
  final int id;
  final String poNumber;
  final String supplier;
  final int received;
  final int total;
  final String items; // e.g. "3/10 Item"
  final String status;
  final DateTime date;

  PurchaseOrderModel({
    required this.id,
    required this.poNumber,
    required this.supplier,
    required this.received,
    required this.total,
    required this.items,
    required this.status,
    required this.date,
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      id: json['id'] ?? 0,
      poNumber: json['po_number'] ?? 'Unknown',
      supplier: json['supplier'] ?? '-',
      received: json['received'] ?? 0,
      total: json['total'] ?? 0,
      items: '${json['received'] ?? 0}/${json['total'] ?? 0} Item',
      status: json['status'] ?? '-',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'po_number': poNumber,
      'supplier': supplier,
      'received': received,
      'total': total,
      'items': items,
      'status': status,
      'date': date.toIso8601String(),
    };
  }
}
