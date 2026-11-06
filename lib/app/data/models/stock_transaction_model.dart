import 'package:getx_project/app/global/functions.dart';

class StockTransactionModel {
  final String productName;
  final String type; 
  final String flowType; // IN / OUT
  final num qty; // DECIMAL on the backend
  final String time; // "2 Days Ago"
  final OrderInfo? order;

  StockTransactionModel({
    required this.productName,
    required this.type,
    required this.qty,
    required this.flowType,
    required this.time,
    this.order,
  });

  factory StockTransactionModel.fromJson(Map<String, dynamic> json) {
    return StockTransactionModel(
      // type and the order's date are nullable on the backend: one such row
      // must not fail the whole page.
      productName: json['item_name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      flowType: json['flow_type']?.toString() ?? '',
      qty: safeToNum(json['qty']),
      time: json['human_time']?.toString() ?? '',
       order: json['order'] != null ? OrderInfo.fromJson(json['order']) : null,
    );
  }
}


class OrderInfo {
  final String type;
  final String code;
  final DateTime? date;

  OrderInfo({
    required this.type,
    required this.code,
    this.date,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      type: json['type'] ?? '',
      code: json['code'] ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
    );
  }
}