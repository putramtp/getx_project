/// A delivery status option (Pending / Shipped / Delivered / Cancelled),
/// returned by `GET /delivery-status`. The [color] is a backend-defined hex
/// string (e.g. "#EFBF04") used to tint the status pill.
class DeliveryStatusModel {
  final int id;

  /// The stored name ("Pending") — what the app's logic compares against.
  final String name;

  /// What a person reads, as the web shows it ("Scheduled"). Display only.
  final String label;
  final String color;

  DeliveryStatusModel({
    required this.id,
    required this.name,
    String? label,
    required this.color,
  }) : label = label ?? name;

  factory DeliveryStatusModel.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '-';
    return DeliveryStatusModel(
      id: json['id'],
      name: name,
      label: json['label']?.toString() ?? name,
      color: json['color']?.toString() ?? '#9E9E9E',
    );
  }
}

/// One row of `GET /delivery/status-count`: how many deliveries sit in a status.
class DeliveryStatusCount {
  final String name;
  final int count;

  const DeliveryStatusCount({required this.name, required this.count});

  factory DeliveryStatusCount.fromJson(Map<String, dynamic> json) => DeliveryStatusCount(
        name: json['name']?.toString() ?? '',
        count: (num.tryParse(json['count']?.toString() ?? '') ?? 0).toInt(),
      );

  /// The count for the stored status [name] (e.g. "Pending"); 0 when absent.
  static int countOf(Iterable<DeliveryStatusCount> rows, String name) =>
      rows.where((r) => r.name == name).fold(0, (sum, r) => sum + r.count);
}
