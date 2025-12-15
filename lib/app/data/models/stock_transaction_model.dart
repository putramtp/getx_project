class StockTransactionModel {
  final String productName;
  final String type; 
  final String flowType; // IN / OUT
  final int qty;
  final String time; // "2 Days Ago"
  final String status; // Completed / Pending / Failed
  final OrderInfo? order;

  StockTransactionModel({
    required this.productName,
    required this.type,
    required this.qty,
    required this.flowType,
    required this.time,
    required this.status,
    this.order,
  });

  factory StockTransactionModel.fromJson(Map<String, dynamic> json) {
    return StockTransactionModel(
      productName: json['item_name'],
      type: json['type'],
      flowType: json['flow_type'],
      qty: json['qty'],
      time: json['human_time'],
      status: json['status'] ?? "Completed",
       order: json['order'] != null ? OrderInfo.fromJson(json['order']) : null,
    );
  }
}


class OrderInfo {
  final String type;
  final String code;
  final DateTime  date;

  OrderInfo({
    required this.type,
    required this.code,
    required this.date,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      type: json['type'] ?? '',
      code: json['code'] ?? '',
     date: DateTime.parse(json['date']),
    );
  }
}