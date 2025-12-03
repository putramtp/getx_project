import 'serial_number_model.dart';

class ReceiveOrderDetailModel {
  final int id;
  final String code;
  final String type;
  final int? supplierId;
  final String? supplierName;
  final int? updatedBy;
  final String? editorName;
  final int? createdBy;
  final String? creatorName;
  final DateTime? date;
  final String? receiveNumber;
  final List<ReceiveOrderLine> receiveOrderLines;

  ReceiveOrderDetailModel({
    required this.id,
    required this.code,
    required this.type,
    this.supplierId,
    this.supplierName,
    this.updatedBy,
    this.editorName,
    this.createdBy,
    this.creatorName,
    this.date,
    this.receiveNumber,
    required this.receiveOrderLines,
  });

  factory ReceiveOrderDetailModel.fromJson(Map<String, dynamic> json) {
    return ReceiveOrderDetailModel(
      id: json['id'],
      code: json['code'] ?? '-',
      type: json['type'] ?? '-',
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'],
      updatedBy: json['updated_by'],
      editorName: json['editor_name'],
      createdBy: json['created_by'],
      creatorName: json['creator_name'],
      date: json['date'] != null && json['date'].toString().isNotEmpty
          ? DateTime.tryParse(json['date'])
          : null,
      receiveNumber: json['receive_number'],
      receiveOrderLines: (json['receive_order_lines'] as List<dynamic>? ?? [])
          .map((e) => ReceiveOrderLine.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'updated_by': updatedBy,
      'editor_name': editorName,
      'created_by': createdBy,
      'creator_name': creatorName,
      'date': date?.toIso8601String(),
      'receive_number': receiveNumber,
      'receive_order_lines':
          receiveOrderLines.map((line) => line.toJson()).toList(),
    };
  }
}

class ReceiveOrderLine {
  final int id;
  final String type;
  final int itemId;
  final String itemName;
  final String poLineId;
  final int qty;
  final double pricePerUnit;
  final double priceTotal;
  final List<SerialNumberModel> serialNumbers;

  ReceiveOrderLine({
    required this.id,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.poLineId,
    required this.qty,
    required this.pricePerUnit,
    required this.priceTotal,
    required this.serialNumbers,
  });

  factory ReceiveOrderLine.fromJson(Map<String, dynamic> json) {
    return ReceiveOrderLine(
      id: json['id'],
      type: json['type'] ?? '-',
      itemId: json['item_id'],
      itemName: json['item_name'] ?? '-',
      poLineId: json['po_line_id']?.toString() ?? '',
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
      'po_line_id': poLineId,
      'qty': qty,
      'price_per_unit': pricePerUnit,
      'price_total': priceTotal,
      'serial_numbers': serialNumbers.map((s) => s.toJson()).toList(),
    };
  }
}


