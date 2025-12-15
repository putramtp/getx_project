class OrCustomerModel {
  final int id;
  final String customerCode;
  final String name;
  final int received;
  final int total;
  final String items; // e.g. "3/10 Item"
  final String status;

  OrCustomerModel({
    required this.id,
    required this.customerCode,
    required this.name,
    required this.received,
    required this.total,
    required this.items,
    required this.status,
  });

  factory OrCustomerModel.fromJson(Map<String, dynamic> json) {
    return OrCustomerModel(
      id: json['id'],
      customerCode: json['code'],
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
      'code': customerCode,
      'name': name,
      'received': received,
      'total': total,
      'items': items,
      'status': status,
    };
  }
}
