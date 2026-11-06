import 'package:getx_project/app/global/functions.dart';

class ProductBrandModel {
  final int id;
  final String name;
  final String initialCode;
  final String slug;

  ProductBrandModel({
    required this.id,
    required this.name,
    required this.initialCode,
    required this.slug,
  });

  factory ProductBrandModel.fromJson(Map<String, dynamic> json) {
    return ProductBrandModel(
      id: safeToInt(json['id']),
      name: json['name']?.toString() ?? '',
      initialCode: json['initial_code']?.toString() ?? '', // nullable on the backend
      slug: json['slug']?.toString() ?? '',
    );
  }
}
