import 'package:getx_project/app/global/functions.dart';

class OutflowRequestModel {
  final int id;
  final String code;
  final String customer;
  final num received;
  final num total;
  final String items; // e.g. "3/10 Item"
  final String status;
  final DateTime date;

  /// False for a work-order / material-requisition reservation (no customer):
  /// the backend refuses to put those on a delivery order, so the app shows
  /// them read-only — they are issued on the web (Issue by Work Order).
  final bool hasCustomer;

  static const workOrderReservationLabel = 'Work order reservation';

  OutflowRequestModel({
    required this.id,
    required this.code,
    required this.customer,
    this.hasCustomer = true,
    required this.received,
    required this.total,
    required this.items,
    required this.status,
    required this.date,
  });

  factory OutflowRequestModel.fromJson(Map<String, dynamic> json) {
    final received = safeToNum(json['received']);
    final total = safeToNum(json['total']);
    final customer = json['customer']?.toString().trim() ?? '';
    return OutflowRequestModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'Unknown',
      customer: customer.isEmpty ? workOrderReservationLabel : customer,
      hasCustomer: customer.isNotEmpty,
      received: received,
      total: total,
      items: '${formatQty(received)}/${formatQty(total)} Item',
      status: json['status'] ?? '-',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'customer': hasCustomer ? customer : null,
      'received': received,
      'total': total,
      'items': items,
      'status': status,
      'date': date.toIso8601String(),
    };
  }
}
