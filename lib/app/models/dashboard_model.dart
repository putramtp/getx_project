class DashboardModel {
  final int product;
  final int receiveOrder;
  final int outflowOrder;

  DashboardModel({
    required this.product,
    required this.receiveOrder,
    required this.outflowOrder,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      product: json['product'] ?? 0,
      receiveOrder: json['receive-order'] ?? 0,
      outflowOrder: json['outflow-order'] ?? 0,
    );
  }
}
