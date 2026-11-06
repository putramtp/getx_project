/// `GET /receive-order/serial-confirm-summary`: receive orders dated in the
/// last [windowDays] days that still hold unscanned labels of manage_sn items.
class SerialConfirmSummary {
  final int pendingOrders;
  final int pendingLabels;
  final int windowDays;

  const SerialConfirmSummary({
    required this.pendingOrders,
    required this.pendingLabels,
    required this.windowDays,
  });

  bool get hasPending => pendingOrders > 0;

  factory SerialConfirmSummary.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
    return SerialConfirmSummary(
      pendingOrders: asInt(json['pending_orders']),
      pendingLabels: asInt(json['pending_labels']),
      windowDays: asInt(json['window_days']),
    );
  }
}
