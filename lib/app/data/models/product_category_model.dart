import 'package:getx_project/app/global/functions.dart';

class ProductCategoryModel {
  final int id;
  final String name;
  final String initialCode;
  final String slug;

  ProductCategoryModel({
    required this.id,
    required this.name,
    required this.initialCode,
    required this.slug,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: safeToInt(json['id']),
      name: json['name']?.toString() ?? '',
      initialCode: json['initial_code']?.toString() ?? '', // nullable on the backend
      slug: json['slug']?.toString() ?? '',
    );
  }
}
