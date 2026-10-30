import 'package:getx_project/app/global/functions.dart';

class PoSupplierModel {
  final int id;
  final String code;
  final String name;
  final num received;
  final num total;
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
    final received = safeToNum(json['received']);
    final total = safeToNum(json['total']);
    return PoSupplierModel(
      id: json['id'],
      code: json['code'],
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
      'code': code,
      'name': name,
      'received': received,
      'total': total,
      'items': items,
      'status': status,
    };
  }
}
