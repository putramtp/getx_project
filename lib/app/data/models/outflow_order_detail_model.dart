import 'serial_number_model.dart';

class OutflowOrderDetailModel {
  final int id;
  final String code;
  final String type;
  final int? customerId;
  final String? customerName;
  final int? updatedBy;
  final String? editorName;
  final int? createdBy;
  final String? creatorName;
  final DateTime? date;
  final String? billNumber;
  final List<OutflowOrderLine> outflowOrderLines;

  OutflowOrderDetailModel({
    required this.id,
    required this.code,
    required this.type,
    this.customerId,
    this.customerName,
    this.updatedBy,
    this.editorName,
    this.createdBy,
    this.creatorName,
    this.date,
    this.billNumber,
    required this.outflowOrderLines,
  });

  factory OutflowOrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OutflowOrderDetailModel(
      id: json['id'],
      code: json['code'] ?? '-',
      type: json['type'] ?? '-',
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      updatedBy: json['updated_by'],
      editorName: json['editor_name'],
      createdBy: json['created_by'],
      creatorName: json['creator_name'],
      date: DateTime.tryParse(json['date']),
      billNumber: json['bill_number'],
      outflowOrderLines: (json['outflow_order_lines'] as List<dynamic>? ?? [])
          .map((e) => OutflowOrderLine.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'customer_id': customerId,
      'customer_name': customerName,
      'updated_by': updatedBy,
      'editor_name': editorName,
      'created_by': createdBy,
      'creator_name': creatorName,
      'date': date?.toIso8601String(),
      'bill_number': billNumber,
      'outflow_order_lines':
          outflowOrderLines.map((line) => line.toJson()).toList(),
    };
  }
}

class OutflowOrderLine {
  final int id;
  final String type;
  final int itemId;
  final String itemName;
  final String orLineId;
  final int qty;
  final double pricePerUnit;
  final double priceTotal;
  final List<SerialNumberModel> serialNumbers;

  OutflowOrderLine({
    required this.id,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.orLineId,
    required this.qty,
    required this.pricePerUnit,
    required this.priceTotal,
    required this.serialNumbers,
  });

  factory OutflowOrderLine.fromJson(Map<String, dynamic> json) {
    return OutflowOrderLine(
      id: json['id'],
      type: json['type'] ?? '-',
      itemId: json['item_id'],
      itemName: json['item_name'] ?? '-',
      orLineId: json['or_line_id']?.toString() ?? '',
      qty: json['qty'] ?? 0,
      pricePerUnit: (json['price_per_unit'] ?? 0).toDouble(),
      priceTotal: (json['price_total'] ?? 0).toDouble(),
      serialNumbers: (json['serial_numbers'] as List<dynamic>? ?? [])
          .map((e) => SerialNumberModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'item_id': itemId,
      'item_name': itemName,
      'or_line_id': orLineId,
      'qty': qty,
      'price_per_unit': pricePerUnit,
      'price_total': priceTotal,
      'serial_numbers': serialNumbers.map((s) => s.toJson()).toList(),
    };
  }
}


