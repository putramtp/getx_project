import 'package:getx_project/app/global/functions.dart';

class ProductUnitModel {
  final int id;
  final String name;
  final String description;


  ProductUnitModel({
    required this.id,
    required this.name,
    required this.description,

  });

  factory ProductUnitModel.fromJson(Map<String, dynamic> json) {
    return ProductUnitModel(
      id: safeToInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description'] ?? '',
    );
  }
}
