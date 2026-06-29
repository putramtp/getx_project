/// A delivery status option (Pending / Shipped / Delivered / Cancelled),
/// returned by `GET /delivery-status`. The [color] is a backend-defined hex
/// string (e.g. "#EFBF04") used to tint the status pill.
class DeliveryStatusModel {
  final int id;
  final String name;
  final String color;

  DeliveryStatusModel({
    required this.id,
    required this.name,
    required this.color,
  });

  factory DeliveryStatusModel.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusModel(
      id: json['id'],
      name: json['name']?.toString() ?? '-',
      color: json['color']?.toString() ?? '#9E9E9E',
    );
  }
}
