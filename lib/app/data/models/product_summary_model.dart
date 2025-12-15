import '../../../global/functions.dart';

class ProductSummaryModel {
  final int itemId;
  final String itemName;
  final String itemCode;

  final int qtyRemaining;
  final int qtyIn;
  final int qtyOut;
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

    return ProductSummaryModel(
      itemId: json['item_id'] ?? 0,
      itemName: json['item_name'] ?? '',
      itemCode: json['item_code'] ?? '',
      qtyRemaining: safeToInt(json['qty_remaining']),
      qtyIn: safeToInt(json['qty_in']),
      qtyOut: safeToInt(json['qty_out']),
      lowStock: safeToInt(json['qty_remaining']) < 10 ,
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
