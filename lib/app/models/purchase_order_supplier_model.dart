class PoSupplierModel {
  final int id;
  final String code;
  final String name;
  final int received;
  final int total;
  final String items; // e.g. "3/10 Item"
  final String status;

  PoSupplierModel({
    required this.id,
    required this.code,
    required this.name,
    required this.received,
    required this.total,
    required this.items,
    required this.status,
  });

  factory PoSupplierModel.fromJson(Map<String, dynamic> json) {
    return PoSupplierModel(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      received: json['received'] ?? 0,
      total: json['total'] ?? 0,
      items: '${json['received'] ?? 0}/${json['total'] ?? 0} Item',
      status: json['status'] ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'received': received,
      'total': total,
      'items': items,
      'status': status,
    };
  }
}
