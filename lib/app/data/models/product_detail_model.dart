class ProductDetailModel {
  final int id;
  final String type;
  final String code;
  final String? upc;
  final int? categoryId;
  final String categoryName;
  final int? brandId;
  final String brandName;
  final int? classificationId;
  final String classificationName;
  final int? unitId;
  final String unitName;
  final String name;
  final int priceSell;
  final String serialNumberType;
  final bool manageExpired;
  final List<dynamic>? descriptions;

  ProductDetailModel({
    required this.id,
    required this.type,
    required this.code,
    required this.upc,
    required this.categoryId,
    required this.categoryName,
    required this.brandId,
    required this.brandName,
    required this.classificationId,
    required this.classificationName,
    required this.unitId,
    required this.unitName,
    required this.name,
    required this.priceSell,
    required this.serialNumberType,
    required this.manageExpired,
    this.descriptions,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      id: json["id"] ?? 0,
      type: json["type"] ?? "",
      code: json["code"] ?? "",
      upc: json["upc"],
      categoryId: json["category_id"],
      categoryName: json["category_name"] ?? "",
      brandId: json["brand_id"],
      brandName: json["brand_name"] ?? "",
      classificationId: json["classification_id"],
      classificationName: json["classification_name"] ?? "",
      unitId: json["unit_id"],
      unitName: json["unit_name"] ?? "",
      name: json["name"] ?? "",
      priceSell: json["price_sell"] ?? 0,
      serialNumberType: json["serial_number_type"] ?? "",
      manageExpired: json["manage_expired"] ?? false,
      descriptions: json["descriptions"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "type": type,
      "code": code,
      "upc": upc,
      "category_id": categoryId,
      "category_name": categoryName,
      "brand_id": brandId,
      "brand_name": brandName,
      "classification_id": classificationId,
      "classification_name": classificationName,
      "unit_id": unitId,
      "unit_name": unitName,
      "name": name,
      "price_sell": priceSell,
      "serial_number_type": serialNumberType,
      "manage_expired": manageExpired,
      "descriptions": descriptions,
    };
  }
}
