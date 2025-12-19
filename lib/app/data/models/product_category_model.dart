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
      id: json['id'],
      name: json['name'],
      initialCode: json['initial_code'],
      slug: json['slug'],
    );
  }
}
