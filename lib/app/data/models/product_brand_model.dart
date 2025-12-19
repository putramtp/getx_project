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
      id: json['id'],
      name: json['name'],
      initialCode: json['initial_code'],
      slug: json['slug'],
    );
  }
}
