import 'package:getx_project/app/global/functions.dart';

class OrCustomerModel {
  final int id;
  final String customerCode;
  final String name;
  final num received;
  final num total;
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
    final received = safeToNum(json['received']);
    final total = safeToNum(json['total']);
    return OrCustomerModel(
      id: json['id'],
      customerCode: json['code'],
      name: json['name'],
      received: received,
      total: total,
      items: '${formatQty(received)}/${formatQty(total)} Item',
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
