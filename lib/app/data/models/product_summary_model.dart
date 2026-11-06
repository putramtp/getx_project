import 'package:getx_project/app/global/functions.dart';

class ProductSummaryModel {
  final int itemId;
  final String itemName;
  final String itemCode;

  // DECIMAL on the backend (kg, metre…): 0.5 kg in stock is not 0.
  final num qtyRemaining;
  final num qtyIn;
  final num qtyOut;
  final bool lowStock;

  ProductSummaryModel({
    required this.itemId,
    required this.itemName,
    required this.itemCode,
    required this.qtyRemaining,
    required this.qtyIn,
    required this.qtyOut,
    required this.lowStock,
  });

  factory ProductSummaryModel.fromJson(Map<String, dynamic> json) {
    final remaining = safeToNum(json['qty_remaining']);
    return ProductSummaryModel(
      itemId: safeToInt(json['item_id']),
      itemName: json['item_name'] ?? '',
      itemCode: json['item_code'] ?? '',
      qtyRemaining: remaining,
      qtyIn: safeToNum(json['qty_in']),
      qtyOut: safeToNum(json['qty_out']),
      lowStock: remaining < 10,
    );
  }

  Map<String, dynamic> toJson() => {
        "item_id": itemId,
        "item_name": itemName,
        "item_code": itemCode,
        "qty_remaining": qtyRemaining,
        "qty_in": qtyIn,
        "qty_out": qtyOut,
      };
}
