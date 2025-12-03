class OutflowRequestModel {
  final int id;
  final String code;
  final String customer;
  final int received;
  final int total;
  final String items; // e.g. "3/10 Item"
  final String status;
  final DateTime date;

  OutflowRequestModel({
    required this.id,
    required this.code,
    required this.customer,
    required this.received,
    required this.total,
    required this.items,
    required this.status,
    required this.date,
  });

  factory OutflowRequestModel.fromJson(Map<String, dynamic> json) {
    return OutflowRequestModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'Unknown',
      customer: json['customer'] ?? '-',
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
      'code': code,
      'customer': customer,
      'received': received,
      'total': total,
      'items': items,
      'status': status,
      'date': date.toIso8601String(),
    };
  }
}
