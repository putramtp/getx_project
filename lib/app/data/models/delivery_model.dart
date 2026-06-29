/// A delivery record, as returned by `GET /delivery`, `GET /delivery/{id}` and
/// `PUT /delivery/{id}` (all share the same `DeliveryResource` shape on the
/// backend). A delivery is header-only — it carries logistics/status data and
/// links back to one outflow order; the actual line items live on that order.
class DeliveryModel {
  final int id;
  final String code;
  final String customer;
  final int? outflowOrderId;
  final String? outflowOrderCode;
  final int statusId;
  final String statusName;
  final int? updatedBy;
  final String updatedName;

  /// Estimated delivery date, `yyyy-MM-dd` (null until first set).
  final String? estimateAt;

  /// Estimated delivery time, `HH:mm` (null until first set).
  final String? estimateTime;
  final String address;
  final String? description;

  DeliveryModel({
    required this.id,
    required this.code,
    required this.customer,
    this.outflowOrderId,
    this.outflowOrderCode,
    required this.statusId,
    required this.statusName,
    this.updatedBy,
    required this.updatedName,
    this.estimateAt,
    this.estimateTime,
    required this.address,
    this.description,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'],
      code: json['code']?.toString() ?? '-',
      customer: json['customer']?.toString() ?? 'N/A',
      outflowOrderId: json['outflow_order_id'],
      outflowOrderCode: json['outflow_order_code']?.toString(),
      statusId: (num.tryParse(json['status_id']?.toString() ?? '') ?? 0).toInt(),
      statusName: json['status_name']?.toString() ?? '-',
      updatedBy: json['updated_by'],
      updatedName: json['updated_name']?.toString() ?? 'N/A',
      estimateAt: json['estimate_at']?.toString(),
      estimateTime: json['estimate_time']?.toString(),
      address: json['address']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}
