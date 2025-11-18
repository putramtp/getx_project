class OutflowOrder {
  final int id;
  final String code;
  final String type;
  final String customer;
  final DateTime date;

  OutflowOrder({
    required this.id,
    required this.code,
    required this.type,
    required this.customer,
    required this.date,
  });

  factory OutflowOrder.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(dateStr);

    return OutflowOrder(
      id: json['id'],
      code: json['code'],
      type: json['type']?.toString() ?? '-',
      customer: json['customer_name'] ?? 'N/A',
      date: parsedDate ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'customer_name': customer,
      'date': date.toIso8601String(),
    };
  }
}
