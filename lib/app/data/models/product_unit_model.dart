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
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
    );
  }
}
