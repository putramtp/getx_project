class DashboardModel {
  final int product;
  final int receiveOrder;
  final int outflowOrder;
  final int productUnique;
  final int productOther;

  DashboardModel({
    required this.product,
    required this.receiveOrder,
    required this.outflowOrder,
    required this.productUnique,
    required this.productOther,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      product: json['product'] ?? 0,
      receiveOrder: json['receive-order'] ?? 0,
      outflowOrder: json['outflow-order'] ?? 0,
      productUnique: json['product-unique'] ?? 0,
      productOther: json['product-other'] ?? 0,
    );
  }
}
